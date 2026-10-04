"""
Adversarial Verification Suite for Challenger 2
Tests Zero-Placeholder Policy, Error Boundaries, Failure Injections, and Exception Propagation
"""
import re
import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient

from main import app
from schemas.exam_schema import (
    Class9TestSchema,
    MCQItem,
    ShortQuestionItem,
    LongQuestionItem,
    SectionAResponse,
    SectionBResponse,
    SectionCResponse,
    MCQQuestion,
    ShortQuestion,
    LongQuestion
)
from services.llm_service import generate_test_from_context

FORBIDDEN_PLACEHOLDER_REGEXES = [
    re.compile(r"Sample MCQ", re.IGNORECASE),
    re.compile(r"Choice Alpha", re.IGNORECASE),
    re.compile(r"Choice Beta", re.IGNORECASE),
    re.compile(r"Lorem ipsum", re.IGNORECASE),
    re.compile(r"Mock MCQ", re.IGNORECASE),
    re.compile(r"Fake Question", re.IGNORECASE),
    re.compile(r"Placeholder", re.IGNORECASE),
    re.compile(r"Dummy Question", re.IGNORECASE),
]


def test_adv_qdrant_404_empty_context(client: TestClient):
    """Test 1: Empty or missing context from Qdrant vector store must raise 404 ContextNotFound with ZERO mock data."""
    for empty_val in ["", "No context found"]:
        with patch("routers.generation.retrieve_topic_context", return_value=empty_val):
            payload = {
                "subject": "Chemistry",
                "grade": 9,
                "chapter_name": "Chapter 99: Missing",
                "test_type": "topic",
                "topic_query": "Unknown Concept",
                "mcq_count": 5,
                "short_count": 3,
                "long_count": 1
            }
            res = client.post("/api/tests/draft", json=payload)
            assert res.status_code == 404, f"Expected 404 for empty context '{empty_val}', got {res.status_code}"
            data = res.json()
            assert data["success"] is False
            assert data["error"] == "ContextNotFound"
            assert "No textbook data found" in data["message"]
            assert "mcqs" not in data
            assert "short_questions" not in data
            assert "long_questions" not in data

            # Check no forbidden placeholder tokens in response text
            for regex in FORBIDDEN_PLACEHOLDER_REGEXES:
                assert not regex.search(res.text), f"Found forbidden placeholder: {regex.pattern}"


def test_adv_qdrant_whitespace_only_context_vulnerability(client: TestClient):
    """
    Adversarial Challenge Finding: Whitespace-only context from Qdrant.
    Tests whether whitespace-only string ('   \\n\\t  ') triggers 404 ContextNotFoundError.
    """
    with patch("routers.generation.retrieve_topic_context", return_value="   \n\t  "):
        payload = {
            "subject": "Chemistry",
            "grade": 9,
            "chapter_name": "Chapter 99: Missing",
            "test_type": "topic",
            "topic_query": "Unknown Concept",
            "mcq_count": 5,
            "short_count": 3,
            "long_count": 1
        }
        res = client.post("/api/tests/draft", json=payload)
        assert res.status_code == 404
        assert res.json()["error"] == "ContextNotFound"


def test_adv_qdrant_connection_failure_500(client: TestClient):
    """Test 2: Qdrant network/cluster crash raises 500 with exact error propagated and ZERO mock data."""
    with patch("routers.generation.retrieve_topic_context", side_effect=ConnectionRefusedError("Qdrant node on 6333 refused connection")):
        payload = {
            "subject": "Physics",
            "grade": 9,
            "chapter_name": "Kinematics",
            "test_type": "topic",
            "topic_query": "Velocity",
            "mcq_count": 5,
            "short_count": 3,
            "long_count": 1
        }
        res = client.post("/api/tests/draft", json=payload)
        assert res.status_code == 500
        data = res.json()
        assert data["success"] is False
        assert data["error"] == "LLMGenerationError"
        assert "Qdrant node on 6333 refused connection" in data["message"]
        assert "mcqs" not in data
        assert "short_questions" not in data
        assert "long_questions" not in data


def test_adv_llm_timeout_408(client: TestClient):
    """Test 3: LLM API Timeout raises 500 with verbatim detail and ZERO mock data."""
    with patch("routers.generation.retrieve_topic_context", return_value="Valid textbook context about Atomic Structure."):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock, side_effect=asyncio.TimeoutError("Google Gemini API request timed out after 120s")):
            payload = {
                "subject": "Chemistry",
                "grade": 9,
                "chapter_name": "Atomic Structure",
                "test_type": "topic",
                "topic_query": "Bohr Model",
                "mcq_count": 5,
                "short_count": 3,
                "long_count": 1
            }
            res = client.post("/api/tests/draft", json=payload)
            assert res.status_code == 500
            data = res.json()
            assert data["success"] is False
            assert data["error"] == "LLMGenerationError"
            assert "Google Gemini API request timed out" in data["message"]
            assert "mcqs" not in data


def test_adv_llm_rate_limit_429(client: TestClient):
    """Test 4: LLM rate limit (429) propagates error without mock fallback."""
    with patch("routers.generation.retrieve_topic_context", return_value="Valid textbook context about Cell Biology."):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock, side_effect=Exception("429 Resource has been exhausted (e.g. check quota)")):
            payload = {
                "subject": "Biology",
                "grade": 9,
                "chapter_name": "Cell Biology",
                "test_type": "full_chapter",
                "mcq_count": 5,
                "short_count": 3,
                "long_count": 1
            }
            with patch("routers.generation.retrieve_with_exercise_boost", return_value=("Valid textbook context about Cell Biology.", "full_chapter")):
                res = client.post("/api/tests/draft", json=payload)
                assert res.status_code == 500
                data = res.json()
                assert data["success"] is False
                assert data["error"] == "LLMGenerationError"
                assert "429 Resource has been exhausted" in data["message"]
                assert "mcqs" not in data


def test_adv_llm_malformed_json_422(client: TestClient):
    """Test 5: LLM returning malformed or incomplete JSON schema raises error with zero mock data."""
    with patch("routers.generation.retrieve_topic_context", return_value="Valid context"):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock, side_effect=ValueError("Instructor failed to deserialize JSON: Unterminated string at line 4 column 12")):
            payload = {
                "subject": "Mathematics",
                "grade": 9,
                "chapter_name": "Matrices",
                "test_type": "topic",
                "topic_query": "Determinants",
                "mcq_count": 5,
                "short_count": 3,
                "long_count": 1
            }
            res = client.post("/api/tests/draft", json=payload)
            assert res.status_code == 500
            data = res.json()
            assert data["success"] is False
            assert "Instructor failed to deserialize JSON" in data["message"]
            assert "mcqs" not in data


@pytest.mark.asyncio
async def test_adv_parallel_section_failure_coroutine_gather():
    """Test 6: In parallel synthesis, if one section coroutine fails, the entire batch fails cleanly without partial mock fill."""
    mock_client = MagicMock()
    
    # Section A succeeds
    async def mock_sec_a(*args, **kwargs):
        return SectionAResponse(questions=[
            MCQQuestion(
                question_number=1,
                question="What is the unit of force?",
                options=["A) Newton", "B) Joule", "C) Watt", "D) Pascal"],
                correct_option="A",
                textbook_reference="PTB Physics Ch 3 Pg 45"
            )
        ])

    # Section B raises synthesis error
    async def mock_sec_b(*args, **kwargs):
        raise RuntimeError("Section B short questions LLM extraction failed: token cutoff")

    # Section C succeeds
    async def mock_sec_c(*args, **kwargs):
        return SectionCResponse(questions=[
            LongQuestion(
                question_number=1,
                question="State and explain Newton's Second Law of Motion.",
                marks=5
            )
        ])

    with patch("services.llm_service._generate_section_a", side_effect=mock_sec_a), \
         patch("services.llm_service._generate_section_b", side_effect=mock_sec_b), \
         patch("services.llm_service._generate_section_c", side_effect=mock_sec_c):
        
        with pytest.raises(RuntimeError) as exc_info:
            await generate_test_from_context(
                subject="Physics",
                chapter_or_topic="Dynamics",
                context="Newton's laws of motion are three basic laws of classical mechanics...",
                mcq_count=1,
                short_count=1,
                long_count=1,
                grade=9,
                client=mock_client
            )
        assert "Section B short questions LLM extraction failed" in str(exc_info.value)


def test_adv_pdf_render_empty_payload_raises_422(client: TestClient):
    """Test 7: PDF Rendering with empty/invalid payload raises 422 validation error, never returns mock PDF blob."""
    res = client.post("/api/tests/render-pdf", json={})
    assert res.status_code == 422
    assert "application/pdf" not in res.headers.get("content-type", "")


def test_adv_admin_upload_empty_file_fails(admin_client: TestClient):
    """Test 8: Admin textbook upload with empty file or missing data raises error, never gives fake success."""
    res = admin_client.post(
        "/api/admin/upload-textbook",
        files={"file": ("empty.pdf", b"", "application/pdf")},
        data={"subject": "Chemistry", "grade": 9}
    )
    assert res.status_code in [400, 422, 500]
    data = res.json()
    assert data.get("status") != "success"
    assert data.get("success") is not True
