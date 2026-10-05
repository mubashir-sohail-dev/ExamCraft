import pytest
from unittest.mock import AsyncMock, patch
from schemas.exam_schema import Class9TestSchema, MCQItem


@pytest.fixture
def dummy_test_schema():
    return Class9TestSchema(
        test_title="Legacy Test Paper",
        subject="Physics",
        chapter_or_topic="Kinematics",
        total_marks=10,
        time_allowed="30 Mins",
        instructions=["Attempt all."],
        mcqs=[
            MCQItem(
                question_number=1,
                question="What is velocity?",
                options=["A) Speed with direction", "B) Distance", "C) Time", "D) Mass"],
                correct_option="A",
                textbook_reference="Page 12"
            )
        ],
        short_questions=[],
        long_questions=[]
    )


def test_legacy_draft_test(client, dummy_test_schema):
    with patch("routers.generation.retrieve_topic_context", return_value="Physics textbook context"):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = dummy_test_schema
            payload = {
                "subject": "Physics",
                "chapter_name": "Kinematics",
                "test_type": "topic",
                "topic_query": "Velocity"
            }
            response = client.post("/api/draft-test", json=payload)
            assert response.status_code == 200
            assert response.json()["subject"] == "Physics"


def test_legacy_render_pdf(client, dummy_test_schema):
    payload = {
        "test_data": dummy_test_schema.model_dump(),
        "include_answer_key": True
    }
    response = client.post("/api/render-pdf", json=payload)
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
