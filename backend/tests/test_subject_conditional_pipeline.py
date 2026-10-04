import pytest
from unittest.mock import MagicMock, patch
from services.ocr_service import (
    get_ocr_prompt,
    omniroute_ocr_page,
    gemini_ocr_page,
    ocr_page,
    PageOCRResult,
)


def test_get_ocr_prompt_mathematics():
    """Verify that Mathematics prompts include Chapter, Exercise, and Body Text instructions."""
    for math_subj in ["Mathematics", "mathematics", "Math", "math", "MATH"]:
        prompt = get_ocr_prompt(math_subj)
        assert "CHAPTER / UNIT IDENTIFICATION" in prompt
        assert "EXERCISE IDENTIFICATION" in prompt
        assert "exercise_label" in prompt
        assert "BODY TEXT TRANSCRIPTION" in prompt

    # Default should also be Mathematics
    default_prompt = get_ocr_prompt()
    assert "EXERCISE IDENTIFICATION" in default_prompt
    assert "exercise_label" in default_prompt


def test_get_ocr_prompt_non_math_subjects():
    """Verify that Non-Math subjects exclude Exercise instructions while retaining Chapter and Body Text."""
    non_math_subjects = ["Chemistry", "Physics", "Biology", "Computer Science", "General Science"]
    for subj in non_math_subjects:
        prompt = get_ocr_prompt(subj)
        assert "CHAPTER / UNIT IDENTIFICATION" in prompt
        assert "BODY TEXT TRANSCRIPTION" in prompt
        assert "EXERCISE IDENTIFICATION" not in prompt
        assert "exercise_label" not in prompt


def test_omniroute_ocr_page_uses_subject_prompt():
    """Verify that omniroute_ocr_page accepts subject and passes the corresponding prompt to the LLM client."""
    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.choices = [
        MagicMock(message=MagicMock(content='{"is_chapter_start": false, "body_text": "Sample text", "is_blank": false}'))
    ]
    mock_client.chat.completions.create.return_value = mock_response

    dummy_image = b"dummy_png_bytes"

    with patch("services.ocr_service._get_omni_client", return_value=mock_client), \
         patch("services.ocr_service._throttle"):
        
        # Test Math subject
        res_math = omniroute_ocr_page(dummy_image, subject="Mathematics")
        assert isinstance(res_math, PageOCRResult)
        assert res_math.body_text == "Sample text"
        call_args_math = mock_client.chat.completions.create.call_args[1]
        user_text_math = call_args_math["messages"][0]["content"][0]["text"]
        assert "EXERCISE IDENTIFICATION" in user_text_math

        # Test Chemistry subject
        res_chem = omniroute_ocr_page(dummy_image, subject="Chemistry")
        assert isinstance(res_chem, PageOCRResult)
        call_args_chem = mock_client.chat.completions.create.call_args[1]
        user_text_chem = call_args_chem["messages"][0]["content"][0]["text"]
        assert "EXERCISE IDENTIFICATION" not in user_text_chem
        assert "CHAPTER / UNIT IDENTIFICATION" in user_text_chem


def test_ocr_page_alias_compatibility():
    """Verify that ocr_page alias exists and behaves consistently."""
    assert ocr_page is omniroute_ocr_page


def test_metadata_extractor_math_rules():
    """Verify Math extractor has exercise, section, and topic rules and detects 'Exercise 2.3'."""
    from services.metadata_extractor import (
        MetadataExtractor,
        ExerciseExtractionRule,
        SectionExtractionRule,
        TopicExtractionRule,
    )

    for math_subj in ["Mathematics", "mathematics", "Math", "math", "MATH"]:
        extractor = MetadataExtractor(subject=math_subj)
        assert len(extractor._rules) == 3
        rule_types = [type(r) for r in extractor._rules]
        assert ExerciseExtractionRule in rule_types
        assert SectionExtractionRule in rule_types
        assert TopicExtractionRule in rule_types

        sample_text = "Unit 2: Real Numbers\nExercise 2.3\nFind the values of x and y.\nSection 2.3\nTopic 2.3.1"
        metadata = extractor.extract_from_text(sample_text)
        assert metadata.exercise == "Exercise 2.3"
        assert metadata.section == "Section 2.3"
        assert metadata.topic == "Topic 2.3"
        assert "Exercise 2.3" in extractor.detected_exercises


def test_metadata_extractor_science_clean_payload():
    """Verify Chemistry, Physics, Biology, CS extractors have 0 rules and return clean None metadata."""
    from services.metadata_extractor import MetadataExtractor

    science_subjects = ["Chemistry", "chemistry", "Physics", "physics", "Biology", "Computer Science"]
    for subj in science_subjects:
        extractor = MetadataExtractor(subject=subj)
        assert len(extractor._rules) == 0, f"Subject {subj} should have 0 extraction rules"

        sample_text = (
            "Chapter 1: Fundamentals of Chemistry\n"
            "Section 1.2: Atomic Number\n"
            "Topic 1.2.1\n"
            "Exercise 1.1\n"
            "Review Exercise 1\n"
            "What is an atom?"
        )
        metadata = extractor.extract_from_text(sample_text)
        assert metadata.exercise is None
        assert metadata.section is None
        assert metadata.topic is None
        assert len(extractor.detected_exercises) == 0
        assert extractor.summary["exercises_detected"] == 0


def test_chunk_textbook_subject_isolation():
    """Verify chunk_textbook with Math retains exercises/sections/topics, while Science zeroes them out."""
    from services.pdf_processor import chunk_textbook

    raw_text = (
        "[PAGE 5]\n"
        "[CHAPTER: Chapter 2: Real Numbers]\n"
        "[EXERCISE: Exercise 2.3]\n"
        "[SECTION: Section 2.3]\n"
        "[TOPIC: Topic 2.3.1]\n"
        "Solve the following linear equations with one variable."
    )

    # 1. Mathematics retains exercise, section, topic
    math_meta = {"subject": "Mathematics", "grade": 10, "source": "math10.pdf"}
    math_chunks = chunk_textbook(raw_text, base_metadata=math_meta)
    assert len(math_chunks) > 0
    assert math_chunks[0].metadata["subject"] == "Mathematics"
    assert math_chunks[0].metadata["chapter"] == "Chapter 2: Real Numbers"
    assert math_chunks[0].metadata["exercise"] == "Exercise 2.3"
    assert math_chunks[0].metadata["section"] == "Section 2.3"
    assert math_chunks[0].metadata["topic"] == "Topic 2.3.1"

    # 2. Chemistry zeroes out exercise, section, topic even if markers exist
    chem_meta = {"subject": "Chemistry", "grade": 9, "source": "chem9.pdf"}
    chem_chunks = chunk_textbook(raw_text, base_metadata=chem_meta)
    assert len(chem_chunks) > 0
    assert chem_chunks[0].metadata["subject"] == "Chemistry"
    assert chem_chunks[0].metadata["chapter"] == "Chapter 2: Real Numbers"
    assert chem_chunks[0].metadata["exercise"] is None
    assert chem_chunks[0].metadata["section"] is None
    assert chem_chunks[0].metadata["topic"] is None

    # 3. Physics zeroes out exercise, section, topic as well
    physics_meta = {"subject": "Physics", "grade": 9, "source": "physics9.pdf"}
    physics_chunks = chunk_textbook(raw_text, base_metadata=physics_meta)
    assert len(physics_chunks) > 0
    assert physics_chunks[0].metadata["exercise"] is None
    assert physics_chunks[0].metadata["section"] is None
    assert physics_chunks[0].metadata["topic"] is None


@patch("services.pdf_processor.fitz.open")
@patch("services.pdf_processor.gemini_ocr_page")
def test_extract_text_from_pdf_ocr_subject_and_exercise_guard(mock_ocr, mock_fitz_open):
    """Verify extract_text_from_pdf passes subject to OCR and guards exercise label for science."""
    from services.pdf_processor import extract_text_from_pdf

    mock_page = MagicMock()
    mock_page.get_text.return_value = ""  # empty native text triggers OCR branch
    mock_page.get_pixmap.return_value.tobytes.return_value = b"fake_png"

    mock_doc = MagicMock()
    mock_doc.is_encrypted = False
    mock_doc.__len__.return_value = 1
    mock_doc.__getitem__.return_value = mock_page
    mock_fitz_open.return_value.__enter__.return_value = mock_doc

    mock_ocr.return_value = PageOCRResult(
        is_chapter_start=False,
        chapter_number=None,
        chapter_title=None,
        exercise_label="Exercise 1.1",
        body_text="Chemistry text content without math equations.",
        is_blank=False,
    )

    with patch("os.path.isfile", return_value=True):
        # 1. Non-Math subject (Chemistry)
        text_chem, summary_chem = extract_text_from_pdf("dummy.pdf", subject="Chemistry")
        mock_ocr.assert_called_with(b"fake_png", subject="Chemistry")
        assert summary_chem["exercises_detected"] == 0
        assert "[EXERCISE:" not in text_chem

        # 2. Math subject (Mathematics)
        text_math, summary_math = extract_text_from_pdf("dummy.pdf", subject="Mathematics")
        mock_ocr.assert_called_with(b"fake_png", subject="Mathematics")
        assert summary_math["exercises_detected"] == 1
        assert "[EXERCISE: Exercise 1.1]" in text_math


def test_get_chapter_metadata_non_math_short_circuit():
    """Verify non-Math subjects fast short-circuit immediately without querying Qdrant facet or scroll."""
    from services.vector_store_service import get_chapter_metadata

    mock_client = MagicMock()
    non_math_subjects = ["Chemistry", "Physics", "Biology", "Computer Science"]

    for subj in non_math_subjects:
        res = get_chapter_metadata(mock_client, "col_test", subj, "Chapter 1", 9)
        assert res == {"exercises": [], "sections": [], "topics": []}

    mock_client.facet.assert_not_called()
    mock_client.scroll.assert_not_called()


def test_get_chapter_metadata_math_queries_qdrant():
    """Verify Math subject queries Qdrant facet/scroll and parses exercises as expected."""
    from services.vector_store_service import get_chapter_metadata, _METADATA_CACHE

    _METADATA_CACHE.clear()

    mock_client = MagicMock()
    mock_hit = MagicMock()
    mock_hit.value = "Exercise 1.1"
    mock_client.facet.return_value = MagicMock(hits=[mock_hit])

    mock_record = MagicMock()
    mock_record.payload = {"exercise": "Exercise 1.1", "section": "Section 1.1", "topic": "Topic 1.1"}
    mock_client.scroll.return_value = ([mock_record], None)

    res = get_chapter_metadata(mock_client, "col_math_test", "Mathematics", "Chapter 1", 9)
    assert "Exercise 1.1" in res["exercises"]
    assert "Section 1.1" in res["sections"]
    assert "Topic 1.1" in res["topics"]

    assert mock_client.facet.called or mock_client.scroll.called


def test_prompt_builder_physics_guidance():
    """Verify that Physics prompts in PromptBuilder include SI units and physical law guidance."""
    from services.prompt_builder import PromptBuilder

    for builder_fn in [
        lambda: PromptBuilder.build_section_a(subject="Physics", chapter_or_topic="Kinematics", count=5, context="ctx"),
        lambda: PromptBuilder.build_section_b(subject="Physics", chapter_or_topic="Kinematics", count=3, context="ctx"),
        lambda: PromptBuilder.build_section_c(subject="Physics", chapter_or_topic="Kinematics", count=1, context="ctx"),
        lambda: PromptBuilder.build(subject="Physics", chapter_or_topic="Kinematics", mcq_count=5, short_count=3, long_count=1, context="ctx"),
    ]:
        messages = builder_fn()
        user_content = messages[1]["content"]
        assert "### Subject Guidelines (Physics):" in user_content
        assert "SI units (m/s, N, J, W, kg)" in user_content
        assert "governing physical law/principle" in user_content


def test_prompt_builder_chemistry_guidance():
    """Verify that Chemistry prompts include balanced chemical equation and IUPAC guidance."""
    from services.prompt_builder import PromptBuilder

    for subj in ["Chemistry", "chemistry"]:
        for builder_fn in [
            lambda s=subj: PromptBuilder.build_section_a(subject=s, chapter_or_topic="Acids", count=5, context="ctx"),
            lambda s=subj: PromptBuilder.build_section_b(subject=s, chapter_or_topic="Acids", count=3, context="ctx"),
            lambda s=subj: PromptBuilder.build_section_c(subject=s, chapter_or_topic="Acids", count=1, context="ctx"),
            lambda s=subj: PromptBuilder.build(subject=s, chapter_or_topic="Acids", mcq_count=5, short_count=3, long_count=1, context="ctx"),
        ]:
            messages = builder_fn()
            user_content = messages[1]["content"]
            assert "### Subject Guidelines (Chemistry):" in user_content
            assert "strictly balanced with state symbols (s, l, g, aq)" in user_content
            assert "authentic IUPAC names" in user_content


def test_prompt_builder_biology_guidance():
    """Verify that Biology prompts include biological terminology and structure vs function guidance."""
    from services.prompt_builder import PromptBuilder

    for builder_fn in [
        lambda: PromptBuilder.build_section_a(subject="Biology", chapter_or_topic="Cells", count=5, context="ctx"),
        lambda: PromptBuilder.build_section_b(subject="Biology", chapter_or_topic="Cells", count=3, context="ctx"),
        lambda: PromptBuilder.build_section_c(subject="Biology", chapter_or_topic="Cells", count=1, context="ctx"),
        lambda: PromptBuilder.build(subject="Biology", chapter_or_topic="Cells", mcq_count=5, short_count=3, long_count=1, context="ctx"),
    ]:
        messages = builder_fn()
        user_content = messages[1]["content"]
        assert "### Subject Guidelines (Biology):" in user_content
        assert "Anatomical & Cellular Terminology" in user_content
        assert "relationship between biological structure and physiological function" in user_content


def test_prompt_builder_cs_guidance():
    """Verify that Computer Science prompts include pseudocode/syntax and deterministic execution guidance."""
    from services.prompt_builder import PromptBuilder

    for subj in ["Computer Science", "computer_science", "cs", "CS"]:
        for builder_fn in [
            lambda s=subj: PromptBuilder.build_section_a(subject=s, chapter_or_topic="Loops", count=5, context="ctx"),
            lambda s=subj: PromptBuilder.build_section_b(subject=s, chapter_or_topic="Loops", count=3, context="ctx"),
            lambda s=subj: PromptBuilder.build_section_c(subject=s, chapter_or_topic="Loops", count=1, context="ctx"),
            lambda s=subj: PromptBuilder.build(subject=s, chapter_or_topic="Loops", mcq_count=5, short_count=3, long_count=1, context="ctx"),
        ]:
            messages = builder_fn()
            user_content = messages[1]["content"]
            assert "### Subject Guidelines (Computer Science):" in user_content
            assert "clean, standard pseudocode, C/C++ or Python syntax" in user_content
            assert "deterministic, unambiguously traceable execution paths" in user_content


def test_prompt_builder_math_guidance():
    """Verify that Mathematics prompts include mathematical rigor and time-allocated solvability guidance."""
    from services.prompt_builder import PromptBuilder

    for subj in ["Mathematics", "mathematics", "Math", "math"]:
        for builder_fn in [
            lambda s=subj: PromptBuilder.build_section_a(subject=s, chapter_or_topic="Matrices", count=5, context="ctx"),
            lambda s=subj: PromptBuilder.build_section_b(subject=s, chapter_or_topic="Matrices", count=3, context="ctx"),
            lambda s=subj: PromptBuilder.build_section_c(subject=s, chapter_or_topic="Matrices", count=1, context="ctx"),
            lambda s=subj: PromptBuilder.build(subject=s, chapter_or_topic="Matrices", mcq_count=5, short_count=3, long_count=1, context="ctx"),
        ]:
            messages = builder_fn()
            user_content = messages[1]["content"]
            assert "### Subject Guidelines (Mathematics):" in user_content
            assert "Provide exact numerical values or simplified algebraic expressions" in user_content
            assert "solvable within standard exam time allocations" in user_content
