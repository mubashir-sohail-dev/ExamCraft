import pytest
from unittest.mock import AsyncMock, patch
from schemas.exam_schema import Class9TestSchema, MCQItem, ShortQuestionItem, LongQuestionItem


@pytest.fixture
def dummy_test_schema():
    """Returns a dummy Class9TestSchema object for testing."""
    return Class9TestSchema(
        test_title="Class 9 Chemistry Test",
        subject="Chemistry",
        chapter_or_topic="Chapter 1",
        total_marks=16,
        time_allowed="45 Minutes",
        instructions=["Answer all questions."],
        mcqs=[
            MCQItem(
                question_number=1,
                question="What is matter?",
                options=["A) Anything with mass", "B) Nothing", "C) Energy only", "D) Space only"],
                correct_option="A",
                textbook_reference="Page 5 concept excerpt"
            )
        ],
        short_questions=[
            ShortQuestionItem(
                question_number=2,
                question="Define solids.",
                marks=2
            )
        ],
        long_questions=[
            LongQuestionItem(
                question_number=3,
                question="Explain the states of matter with examples.",
                marks=5
            )
        ]
    )


def test_draft_test_endpoint_success(client, dummy_test_schema):
    """Tests POST /api/tests/draft with mocked context and LLM generation."""
    with patch("routers.generation.retrieve_topic_context", return_value="Sample textbook context text"):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = dummy_test_schema
            payload = {
                "subject": "Chemistry",
                "chapter_name": "Chapter 1",
                "test_type": "topic",
                "topic_query": "States of Matter",
                "mcq_count": 1,
                "short_count": 1,
                "long_count": 1
            }
            response = client.post("/api/tests/draft", json=payload)
            assert response.status_code == 200
            data = response.json()
            assert data["subject"] == "Chemistry"
            assert data["test_title"] == "Class 9 Chemistry Test"
            assert len(data["mcqs"]) == 1


def test_draft_test_context_not_found(client):
    """Tests 404 response when no textbook context is found."""
    with patch("routers.generation.retrieve_topic_context", return_value="No context found"):
        payload = {
            "subject": "Chemistry",
            "chapter_name": "NonExistentChapter",
            "test_type": "topic",
            "topic_query": "Unknown Topic"
        }
        response = client.post("/api/tests/draft", json=payload)
        assert response.status_code == 404
        assert response.json()["success"] is False
        assert response.json()["error"] == "ContextNotFound"


def test_draft_test_missing_topic_query(client):
    """Tests 400 response when mode is 'topic' but topic_query is missing."""
    payload = {
        "subject": "Chemistry",
        "chapter_name": "Chapter 1",
        "test_type": "topic"
    }
    response = client.post("/api/tests/draft", json=payload)
    assert response.status_code == 400
    assert response.json()["success"] is False


def test_render_pdf_endpoint_success(client, dummy_test_schema):
    """Tests POST /api/tests/render-pdf returns binary PDF."""
    payload = {
        "test_data": dummy_test_schema.model_dump(),
        "include_answer_key": True
    }
    response = client.post("/api/tests/render-pdf", json=payload)
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert "attachment; filename=" in response.headers["content-disposition"]
    assert len(response.content) > 0


def test_render_pdf_zero_questions(client):
    """Tests 400 response when PDF render is attempted with zero questions."""
    empty_schema = Class9TestSchema(
        test_title="Empty Test",
        subject="Chemistry",
        chapter_or_topic="Chapter 1",
        total_marks=0,
        time_allowed="30 Mins",
        instructions=[],
        mcqs=[],
        short_questions=[],
        long_questions=[]
    )
    payload = {
        "test_data": empty_schema.model_dump(),
        "include_answer_key": True
    }
    response = client.post("/api/tests/render-pdf", json=payload)
    assert response.status_code == 400
    assert response.json()["success"] is False


def test_upload_non_pdf_file(admin_client):
    """Tests 400 response when non-PDF file is uploaded."""
    files = {"file": ("notes.txt", b"plain text notes", "text/plain")}
    response = admin_client.post("/api/admin/upload-textbook", files=files)
    assert response.status_code == 400
    assert response.json()["error"] == "InvalidRequest"


def test_upload_empty_file(admin_client):
    """Tests 400 response when empty PDF is uploaded."""
    files = {"file": ("empty.pdf", b"", "application/pdf")}
    response = admin_client.post("/api/admin/upload-textbook", files=files)
    assert response.status_code == 400
    assert response.json()["error"] == "InvalidRequest"
