import pytest
from pydantic import ValidationError
from schemas.request_schemas import TestGenerationRequest as TestGenReq
from schemas.exam_enums import SubjectEnum, RetrievalModeEnum, DifficultyEnum


def test_test_generation_request_valid():
    """Tests valid TestGenerationRequest instantiation."""
    req = TestGenReq(
        subject="Chemistry",
        chapter_name="Chapter 1",
        test_type="topic",
        topic_query="States of Matter",
        mcq_count=5,
        short_count=3,
        long_count=1
    )
    assert req.subject == SubjectEnum.CHEMISTRY
    assert req.test_type == RetrievalModeEnum.TOPIC


def test_test_generation_request_invalid_subject():
    """Tests invalid subject enum validation failure."""
    with pytest.raises(ValidationError):
        TestGenReq(
            subject="InvalidSubjectName",
            chapter_name="Chapter 1",
            test_type="topic"
        )


def test_test_generation_request_out_of_bounds_counts():
    """Tests count limit validation failure."""
    with pytest.raises(ValidationError):
        TestGenReq(
            subject="Chemistry",
            chapter_name="Chapter 1",
            test_type="topic",
            mcq_count=50  # Max is 20
        )


def test_test_generation_request_grade_validation():
    """Tests grade boundary validation (valid: 9-12, invalid: <9 or >12)."""
    # Valid grades
    for g in [9, 10, 11, 12]:
        req = TestGenReq(
            subject="Physics",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            grade=g
        )
        assert req.grade == g

    # Invalid grades
    with pytest.raises(ValidationError):
        TestGenReq(
            subject="Physics",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            grade=8
        )

    with pytest.raises(ValidationError):
        TestGenReq(
            subject="Physics",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            grade=13
        )


def test_test_generation_request_difficulty():
    """Tests cognitive difficulty level validation and defaults."""
    # Default is mixed
    req_default = TestGenReq(
        subject="Chemistry",
        chapter_name="Chapter 1",
        test_type="full_chapter"
    )
    assert req_default.difficulty == DifficultyEnum.MIXED
    assert req_default.difficulty.value == "mixed"

    # Valid values
    for d in ["easy", "medium", "hard", "mixed"]:
        req = TestGenReq(
            subject="Chemistry",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            difficulty=d
        )
        assert req.difficulty.value == d

    # Invalid difficulty
    with pytest.raises(ValidationError):
        TestGenReq(
            subject="Chemistry",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            difficulty="impossible"
        )

