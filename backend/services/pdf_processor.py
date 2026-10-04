import os
import re
import uuid
import time
import logging
from typing import Any, List, Dict, Optional
import fitz  # PyMuPDF
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from core.config import settings
from core.logger import get_logger
from rapidocr_onnxruntime import RapidOCR
from dotenv import load_dotenv
from .ocr_service import gemini_ocr_page, ocr_page
from .metadata_extractor import MetadataExtractor

load_dotenv()
ocr_engine = None  # Added to fix test mocking


logger = get_logger(__name__)



DEFAULT_CHUNK_SEPARATORS = [
    "\n[CHAPTER:",
    "\n[EXERCISE:",
    "\n[PAGE",
    "\n\n\n",
    "\n\n",
    "\n",
    ". ",
    " ",
    ""
]


def clean_page_text(text: str) -> str:
    """Removes PCTB watermarks, repeated page headers, and footer noise
    while preserving equations and HTML math tags."""
    if not text:
        return ""
    import re
    text = re.sub(r"\d*\s*Not for sale\s*PCTB", "", text, flags=re.IGNORECASE)
    text = re.sub(r"^\s*Page\s+\d+\s*$", "", text, flags=re.MULTILINE | re.IGNORECASE)
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return "\n".join(lines)
 
 
def is_plausible_chapter(candidate: int, last_chapter_num: int | None) -> bool:
    """
    Safety net against occasional model misjudgment (e.g. treating a
    prominent section heading as a chapter-opening page). Real chapters
    only ever move forward — allow some slack (up to +5) in case one
    chapter's detection gets missed, so we don't get permanently stuck
    the way a strict +1 check would.
    """
    if last_chapter_num is None:
        return candidate <= 3
    return last_chapter_num < candidate <= last_chapter_num + 5


def _clean_chapter_title(cand_title: str | None) -> str | None:
    """Sanitizes chapter title, filtering out introductory section titles, summaries, and fragments."""
    if not cand_title:
        return None
    cleaned = re.sub(r'[^a-zA-Z0-9\s\-]', '', cand_title).strip()
    INVALID_TITLES = {"introduction", "overview", "summary", "objectives", "exercises", "review", "contents", "preface", "unit", "chapter"}
    if cleaned.lower() in INVALID_TITLES:
        return None
    if re.match(r'^(?:of|and|in|on|at|for|to)\b', cleaned, re.IGNORECASE):
        return None
    if len(cleaned) < 3:
        return None
    return cleaned
 
 
def extract_text_from_pdf(
    pdf_path: str,
    subject: str = "Chemistry",
    progress_callback: Optional[Any] = None,
) -> tuple[str, dict]:
    if not os.path.isfile(pdf_path):
        raise FileNotFoundError(pdf_path)
 
    logger.info("Opening PDF: %s", pdf_path)
 
    try:
        with fitz.open(pdf_path) as doc:
 
            if doc.is_encrypted:
                raise ValueError("Encrypted PDFs are not supported.")
 
            if len(doc) == 0:
                raise ValueError("PDF contains 0 pages.")
 
            extracted_text = ""
 
            current_chapter = "General / Front Matter"
            last_chapter_page = -10
            last_chapter_num: int | None = None
            
            metadata_extractor = MetadataExtractor(subject=subject)
 
            for page_num in range(len(doc)):
                if progress_callback:
                    try:
                        progress_callback(page_num + 1, len(doc), current_chapter)
                    except Exception:
                        pass
                try:
                    page = doc[page_num]
 
                    # -------------------------
                    # Native extraction (fully scanned books will always
                    # get ~0 chars here, which is expected — it just means
                    # every page falls through to the OCR branch below)
                    # -------------------------
                    raw_text = page.get_text("text")
                    clean_text = clean_page_text(raw_text)
 
                    logger.info(
                        "Page %d: extracted %d chars",
                        page_num + 1,
                        len(clean_text),
                    )
 
                    # -------------------------
                    # Structured-output OCR via Gemini / RapidOCR
                    # -------------------------
                    if len(clean_text) < 50000:
                        logger.info("Running OCR on page %d", page_num + 1)
 
                        pix = page.get_pixmap(dpi=180)
                        img_bytes = pix.tobytes("png")
 
                        page_result = gemini_ocr_page(img_bytes, subject=subject)

                        if page_result.is_blank:
                            clean_text = ""
                        else:
                            clean_text = clean_page_text(page_result.body_text)

                            # If OCR explicitly detected an exercise label, register it (Math only)
                            if page_result.exercise_label and str(subject).strip().lower() in ("mathematics", "math"):
                                metadata_extractor._current["exercise"] = page_result.exercise_label
                                metadata_extractor._all_exercises.add(page_result.exercise_label)
 
                            # -------------------------
                            # Chapter / Unit detection from OCR model
                            # -------------------------
                            if (
                                page_result.is_chapter_start
                                and page_result.chapter_number is not None
                                and page_num > 1
                                and page_num > last_chapter_page + 2
                                and is_plausible_chapter(
                                    page_result.chapter_number, last_chapter_num
                                )
                            ):
                                cand_title = _clean_chapter_title(page_result.chapter_title)
                                current_chapter = (
                                    f"Chapter {page_result.chapter_number}"
                                    + (
                                        f": {cand_title}"
                                        if cand_title
                                        else ""
                                    )
                                )
                                last_chapter_page = page_num
                                last_chapter_num = page_result.chapter_number
 
                                logger.info(
                                    "*** DETECTED %s at page %d ***",
                                    current_chapter,
                                    page_num + 1,
                                )
                                metadata_extractor.track_chapter(current_chapter)
                                metadata_extractor.reset_for_new_chapter()
                    
                    # Fallback text-based Chapter or Unit detection (works on native & OCR text)
                    if clean_text:
                        chap_match = re.search(r'(?i)\b(?:UNIT|CHAPTER)\s+(\d+)\s*:?([^\n\r]{0,60})', clean_text)
                        if chap_match:
                            cand_num = int(chap_match.group(1))
                            if page_num > 1 and page_num > last_chapter_page + 2 and is_plausible_chapter(cand_num, last_chapter_num):
                                raw_title = chap_match.group(2).strip()
                                clean_title = _clean_chapter_title(raw_title)
                                current_chapter = f"Chapter {cand_num}" + (f": {clean_title}" if clean_title else "")
                                last_chapter_page = page_num
                                last_chapter_num = cand_num
                                logger.info("*** DETECTED %s via text pattern at page %d ***", current_chapter, page_num + 1)
                                metadata_extractor.track_chapter(current_chapter)
                                metadata_extractor.reset_for_new_chapter()
 
                    # -------------------------
                    # Save page
                    # -------------------------
                    page_metadata = metadata_extractor.extract_from_text(clean_text)
                    if clean_text.strip():
                        markers = f"\n[PAGE {page_num + 1}]\n[CHAPTER: {current_chapter}]\n"
                        if page_metadata.exercise:
                            markers += f"[EXERCISE: {page_metadata.exercise}]\n"
                        if page_metadata.section:
                            markers += f"[SECTION: {page_metadata.section}]\n"
                        if page_metadata.topic:
                            markers += f"[TOPIC: {page_metadata.topic}]\n"
                        extracted_text += markers + f"{clean_text}\n\n"
 
                except Exception as page_err:
                    logger.warning(
                        "Error processing page %d: %s",
                        page_num + 1,
                        page_err,
                    )
 
            logger.info(
                "Successfully extracted text from %d pages.",
                len(doc),
            )
 
            if not extracted_text.strip():
                raise ValueError("No text could be extracted from the PDF.")
 
            extraction_summary = metadata_extractor.summary
            return extracted_text, extraction_summary
 
    except Exception as e:
        logger.exception("Failed to process PDF")
        raise ValueError(str(e))
 
def chunk_textbook(
    raw_text: str,
    base_metadata: Dict[str, Any] | None = None,
    chunk_size: int = 800,
    chunk_overlap: int = 120,
    separators: List[str] | None = None,
) -> List[Document]:
    """Split raw textbook text into metadata-enriched Document chunks with complete safe metadata defaults."""
    if not raw_text or not raw_text.strip():
        raise ValueError("raw_text must be a non-empty string")

    separators = separators or DEFAULT_CHUNK_SEPARATORS
    base_meta = base_metadata or {}
    document_id = str(uuid.uuid4())
    uploaded_timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=separators,
    )

    logger.info("Chunking textbook text...")
    raw_chunks = text_splitter.split_text(raw_text)
    documents: List[Document] = []

    current_page = 1
    current_chapter = base_meta.get("chapter", "General / Front Matter")
    current_exercise = None
    current_section = None
    current_topic = None

    for idx, chunk in enumerate(raw_chunks):
        page_matches = re.findall(r"\[PAGE (\d+)\]", chunk)
        chapter_matches = re.findall(r"\[CHAPTER: (.*?)\]", chunk)
        exercise_matches = re.findall(r"\[EXERCISE: (.*?)\]", chunk)
        section_matches = re.findall(r"\[SECTION: (.*?)\]", chunk)
        topic_matches = re.findall(r"\[TOPIC: (.*?)\]", chunk)

        if page_matches:
            current_page = int(page_matches[-1])
        if chapter_matches:
            current_chapter = chapter_matches[-1]
        if exercise_matches:
            current_exercise = exercise_matches[-1]
        if section_matches:
            current_section = section_matches[-1]
        if topic_matches:
            current_topic = topic_matches[-1]

        clean_content = re.sub(r"\[PAGE \d+\]\n?", "", chunk)
        clean_content = re.sub(r"\[CHAPTER: .*?\]\n?", "", clean_content)
        clean_content = re.sub(r"\[EXERCISE: .*?\]\n?", "", clean_content)
        clean_content = re.sub(r"\[SECTION: .*?\]\n?", "", clean_content)
        clean_content = re.sub(r"\[TOPIC: .*?\]\n?", "", clean_content)
        clean_content = clean_content.strip()

        if clean_content:
            # Estimate word/token count safely
            estimated_tokens = len(clean_content.split())

            is_math = str(base_meta.get("subject", "")).strip().lower() in ("mathematics", "math")
            chunk_metadata = {
                "subject": base_meta.get("subject", "Chemistry"),
                "grade": base_meta.get("grade", 9),
                "chapter": current_chapter,
                "exercise": current_exercise if is_math else None,
                "section": current_section if is_math else None,
                "topic": current_topic if is_math else None,
                "page_number": current_page,
                "chunk_index": idx,
                "source": base_meta.get("source", "uploaded_textbook.pdf"),
                "estimated_section": current_chapter,
                "source_pdf": base_meta.get("source", "uploaded_textbook.pdf"),
                "document_id": document_id,
                "uploaded_at": uploaded_timestamp,
                "token_count": estimated_tokens,
                "metadata_version": 1,
            }
            documents.append(Document(page_content=clean_content, metadata=chunk_metadata))

    logger.info("Created %d metadata-rich chunks.", len(documents))
    return documents