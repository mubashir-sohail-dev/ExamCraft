"""
Structured-output version: Gemini returns JSON directly (chapter number,
chapter title, body text) instead of free text you then have to regex-parse.
This eliminates the CHAPTER_MARKER text-marker approach entirely — no more
guessing whether Gemini's badge-reading made it into a parseable line.

Your detect_chapter_header function becomes unnecessary for THIS pipeline —
chapter info now comes straight from page_result.chapter_number /
page_result.chapter_title. Keep a lightweight plausibility check as a
safety net only (LLMs can still misjudge a section heading as a chapter
start occasionally), not as the primary detection mechanism.

Install deps:
    pip install google-genai pillow pydantic --break-system-packages
"""

import io
import os
import re
import time
import random
import logging
import base64
import json
from typing import Optional
from pydantic import BaseModel
from openai import OpenAI
from google import genai
from google.genai import types
from google.genai.errors import ClientError, ServerError
from PIL import Image
from core.config import settings

logger = logging.getLogger(__name__)

_omni_client = None
_client = None
_last_call_time = 0.0
MODEL = "gemini-3.8-flash"
MIN_INTERVAL = 2.0
MAX_RETRIES = 4

_rapid_ocr_instance = None


def _get_omni_client() -> OpenAI:
    global _omni_client
    if _omni_client is None:
        _omni_client = OpenAI(
            base_url=settings.LLM_BASE_URL,
            api_key=settings.LLM_API_KEY
        )
    return _omni_client


def get_rapid_ocr():
    """Lazily instantiates the local RapidOCR ONNX engine."""
    global _rapid_ocr_instance
    if _rapid_ocr_instance is None:
        try:
            from rapidocr_onnxruntime import RapidOCR
            _rapid_ocr_instance = RapidOCR()
            logger.info("Initialized local RapidOCR ONNX engine for fast offline OCR fallback.")
        except Exception as e:
            logger.warning("RapidOCR engine could not be initialized: %s", e)
    return _rapid_ocr_instance


class PageOCRResult(BaseModel):
    is_chapter_start: bool
    chapter_number: Optional[int] = None
    chapter_title: Optional[str] = None
    exercise_label: Optional[str] = None  # e.g., 'Exercise 1.1', 'Review Exercise 3'
    body_text: str = ""  # full transcribed text, excluding the chapter banner itself
    is_blank: bool = False


def get_ocr_prompt(subject: str = "Mathematics") -> str:
    """
    Generates subject-tailored OCR prompt.
    Includes exercise identification for Mathematics; excludes exercise identification
    for Science subjects (Physics, Chemistry, Biology, Computer Science, etc.).
    """
    is_math = str(subject).strip().lower() in ("mathematics", "math")
    
    chapter_part = """1. CHAPTER / UNIT IDENTIFICATION:
- Determine if this page is a CHAPTER or UNIT OPENING page.
- Look for headings like "Chapter X", "Unit X", "Unit-X", or a large title banner.
- CRITICAL: Extract the TRUE, FULL, COMPLETE chapter title (e.g. "Fundamentals of Chemistry", "Physical Quantities", "Cell Biology", "Graphical Representation of Functions").
- NEVER use section sub-headings like "INTRODUCTION", "SUMMARY", "OBJECTIVES", "OVERVIEW", "EXERCISES", or fragmented word snippets like "of Functions" or "and Their Derivatives" as the chapter title.
- If this page starts a chapter:
  * is_chapter_start: true
  * chapter_number: integer (e.g. 1, 2, 3...)
  * chapter_title: complete cleaned title"""

    exercise_part = """\n\n2. EXERCISE IDENTIFICATION:
- Determine if this page contains an EXERCISE section (e.g. "EXERCISE 1.1", "Exercise 2.4", "Review Exercise 3", "Miscellaneous Exercise 4").
- Standardize the exercise label into exercise_label (e.g. "Exercise 1.1").""" if is_math else ""

    body_part = f"""\n\n{"3" if is_math else "2"}. BODY TEXT TRANSCRIPTION:
- Transcribe ALL text on the page completely and accurately into body_text:
  * Full body text, every paragraph, definition, theorem, proof, chemical equation, and scientific law.
  * Mathematical equations in clear plain text or LaTeX notation (e.g. $y = 2x^2 + 3x - 1$).
  * Question statements, numbered lists, laboratory experiments, and worked examples.
- Do not include the chapter banner itself in body_text if is_chapter_start is true.

If the page has no readable text, set is_blank to true and leave body_text empty."""

    return f"""You are an expert textbook transcription and OCR model for a digital educational archive.\n\n{chapter_part}{exercise_part}{body_part}"""


PROMPT = get_ocr_prompt("Mathematics")


def _get_client():
    global _client
    if _client is None:
        api_key = settings.GEMINI_API_KEY or os.environ.get("GEMINI_API_KEY") or settings.LLM_API_KEY
        if not api_key or api_key.startswith("sk-"):
            raise ValueError("No valid Google GenAI API key configured.")
        _client = genai.Client(api_key=api_key)
    return _client


def _throttle():
    global _last_call_time
    elapsed = time.time() - _last_call_time
    if elapsed < MIN_INTERVAL:
        time.sleep(MIN_INTERVAL - elapsed)


def _split_page_and_retry(image_bytes: bytes) -> PageOCRResult:
    """
    Fallback for RECITATION-blocked pages: split into top/bottom halves,
    transcribe each with a plain-text prompt (no chapter detection needed
    on a half-page), and merge into a PageOCRResult with no chapter info.
    """
    img = Image.open(io.BytesIO(image_bytes))
    width, height = img.size
    mid = height // 2
    halves = [img.crop((0, 0, width, mid)), img.crop((0, mid, width, height))]
    combined = []

    for i, half in enumerate(halves):
        buf = io.BytesIO()
        half.save(buf, format="PNG")
        half_bytes = buf.getvalue()

        half_prompt = """Transcribe all text on this partial page into plain text.
Include every paragraph, heading, and equation ($...$ notation). Do not summarize.
If there is no text at all, respond with the exact word: [BLANK]"""

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                _throttle()
                client = _get_client()
                resp = client.models.generate_content(
                    model=MODEL,
                    contents=[
                        types.Part.from_bytes(data=half_bytes, mime_type="image/png"),
                        half_prompt,
                    ],
                )
                global _last_call_time
                _last_call_time = time.time()
                if resp.text is not None:
                    text = resp.text.strip()
                    if text != "[BLANK]":
                        combined.append(text)
                    break
                time.sleep(2 * attempt)
            except (ClientError, ServerError):
                time.sleep(2 * attempt)
        else:
            combined.append(f"[HALF {i} FAILED — NEEDS MANUAL REVIEW]")

    return PageOCRResult(
        is_chapter_start=False,
        body_text="\n\n".join(combined).strip(),
        is_blank=len(combined) == 0,
    )


def rapid_ocr_page(image_bytes: bytes) -> PageOCRResult:
    """
    Ultra-fast local OCR fallback using RapidOCR (ONNX runtime).
    Extracts text, identifies Chapter/Unit headings, and extracts Exercise labels.
    """
    engine = get_rapid_ocr()
    if engine is None:
        return PageOCRResult(
            is_chapter_start=False,
            body_text="",
            is_blank=True,
        )

    try:
        results, _ = engine(image_bytes)
        if not results:
            return PageOCRResult(
                is_chapter_start=False,
                body_text="",
                is_blank=True,
            )

        raw_lines = [r[1] for r in results if r and len(r) > 1 and r[1]]
        full_text = "\n".join(raw_lines)

        # 1. Detect Chapter or Unit Header
        is_chap = False
        chap_num = None
        chap_title = None

        chap_match = re.search(r'(?i)\b(?:UNIT|CHAPTER)\s+(\d+)\s*:?([^\n\r]{0,60})', full_text)
        if chap_match:
            is_chap = True
            chap_num = int(chap_match.group(1))
            raw_title = chap_match.group(2).strip()
            chap_title = re.sub(r'[^a-zA-Z0-9\s\-]', '', raw_title).strip()
            if not chap_title:
                chap_title = f"Unit {chap_num}"

        # 2. Detect Exercise Label
        ex_label = None
        ex_match = re.search(
            r'(?i)\b(Exercise\s*[\r\n\s]*\d+(?:\.\d+)?|Review\s*[\r\n\s]*Exercise(?:\s*[\r\n\s]*\d+(?:\.\d+)?)?|Miscellaneous\s*[\r\n\s]*Exercise(?:\s*[\r\n\s]*\d+(?:\.\d+)?)?)\b',
            full_text
        )
        if ex_match:
            ex_label = re.sub(r'[\r\n\s]+', ' ', ex_match.group(1)).strip().title()

        return PageOCRResult(
            is_chapter_start=is_chap,
            chapter_number=chap_num,
            chapter_title=chap_title,
            exercise_label=ex_label,
            body_text=full_text,
            is_blank=len(full_text.strip()) == 0,
        )
    except Exception as err:
        logger.error("RapidOCR extraction error: %s", err)
        return PageOCRResult(
            is_chapter_start=False,
            body_text="",
            is_blank=True,
        )


def gemini_ocr_page(image_bytes: bytes, subject: str = "Mathematics") -> PageOCRResult:
    """
    Returns a structured PageOCRResult. If Gemini is unconfigured, invalid,
    rate-limited, or fails, falls back immediately to local RapidOCR.
    """
    global _last_call_time

    # Attempt to initialize Gemini client; fall back to RapidOCR immediately if unconfigured
    try:
        client = _get_client()
    except Exception as init_err:
        logger.debug("Gemini unavailable (%s). Falling back to RapidOCR.", init_err)
        return rapid_ocr_page(image_bytes)

    prompt = get_ocr_prompt(subject)

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            _throttle()
            response = client.models.generate_content(
                model=MODEL,
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type="image/png"),
                    prompt,
                ],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=PageOCRResult,
                ),
            )
            _last_call_time = time.time()

            if response.parsed is not None:
                parsed = response.parsed
                # If parsed result is blank but image has text, verify with RapidOCR
                if parsed.is_blank or not parsed.body_text.strip():
                    return rapid_ocr_page(image_bytes)
                return parsed

            # Check finish reason
            finish_reason = None
            try:
                finish_reason = response.candidates[0].finish_reason
            except (AttributeError, IndexError):
                pass

            if finish_reason and "RECITATION" in str(finish_reason):
                logger.info("Gemini blocked page (RECITATION) — splitting page and retrying.")
                return _split_page_and_retry(image_bytes)

            logger.warning("Gemini returned unparsed result (finish_reason=%s). Falling back to RapidOCR.", finish_reason)
            return rapid_ocr_page(image_bytes)

        except ClientError as e:
            err_str = str(e)
            # If API key is invalid or request is unauthorized, retrying will never work: failover immediately!
            if "API_KEY_INVALID" in err_str or "API key not valid" in err_str or "400" in err_str or "403" in err_str:
                logger.warning("Gemini API key is invalid or unauthorized (%s). Falling back immediately to RapidOCR.", e)
                return rapid_ocr_page(image_bytes)
            wait = min(60, (2 ** attempt) + random.uniform(0, 1))
            logger.warning("Gemini OCR client error (%s). Retry %d/%d in %.1fs...", e, attempt, MAX_RETRIES, wait)
            time.sleep(wait)

        except ServerError as e:
            wait = min(60, (2 ** attempt) + random.uniform(0, 1))
            logger.warning("Gemini OCR server error (%s). Retry %d/%d in %.1fs...", e, attempt, MAX_RETRIES, wait)
            time.sleep(wait)

        except Exception as e:
            logger.warning("Gemini OCR unexpected exception (%s). Falling back to RapidOCR.", e)
            return rapid_ocr_page(image_bytes)

    logger.warning("Gemini OCR exhausted retries. Falling back to RapidOCR.")
    return rapid_ocr_page(image_bytes)


def omniroute_ocr_page(image_bytes: bytes, subject: str = "Mathematics") -> PageOCRResult:
    """
    Performs multimodal Vision OCR via OmniRoute API (LLM_BASE_URL + LLM_API_KEY).
    Extracts text, true full chapter titles, and exercises in structured JSON.
    """
    global _last_call_time
    try:
        client = _get_omni_client()
    except Exception as init_err:
        logger.warning("OmniRoute client init error: %s. Falling back to RapidOCR.", init_err)
        return rapid_ocr_page(image_bytes)

    prompt = get_ocr_prompt(subject)
    b64_img = base64.b64encode(image_bytes).decode("utf-8")
    model_name = settings.LLM_MODEL_NAME if settings.LLM_MODEL_NAME not in (None, "", "auto") else "gemini-3.8-flash"

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            _throttle()
            res = client.chat.completions.create(
                model=model_name,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64_img}"}}
                        ]
                    }
                ],
                response_format={"type": "json_object"},
                max_tokens=4000,
                temperature=0.1
            )
            _last_call_time = time.time()
            raw_content = res.choices[0].message.content
            if not raw_content or not raw_content.strip():
                continue

            # Robust JSON extraction: strip code fences or extract innermost JSON object
            clean_json = raw_content.strip()
            if "```" in clean_json:
                clean_json = re.sub(r"^```(?:json)?\s*", "", clean_json, flags=re.IGNORECASE)
                clean_json = re.sub(r"\s*```$", "", clean_json)
            match = re.search(r"\{.*\}", clean_json, re.DOTALL)
            if match:
                clean_json = match.group(0)

            data = json.loads(clean_json)
            body_txt = str(data.get("body_text", "")).strip()

            return PageOCRResult(
                is_chapter_start=bool(data.get("is_chapter_start", False)),
                chapter_number=data.get("chapter_number"),
                chapter_title=data.get("chapter_title"),
                exercise_label=data.get("exercise_label"),
                body_text=body_txt,
                is_blank=bool(data.get("is_blank", False)) or len(body_txt) == 0
            )
        except Exception as err:
            wait = min(20, (2 ** attempt) + random.uniform(0, 1))
            logger.warning("OmniRoute OCR error (attempt %d/%d): %s. Retrying in %.1fs...", attempt, MAX_RETRIES, err, wait)
            time.sleep(wait)

    logger.warning("OmniRoute OCR exhausted retries. Falling back to local RapidOCR.")
    return rapid_ocr_page(image_bytes)


# Domain-level aliases: default to OmniRoute LLM OCR
ocr_page = omniroute_ocr_page
gemini_ocr_page = omniroute_ocr_page