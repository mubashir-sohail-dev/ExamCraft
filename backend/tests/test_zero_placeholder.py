import re
import pytest
from unittest.mock import AsyncMock, patch


def test_missing_chapter_context_raises_404_zero_mock(client):
    """Verifies that missing textbook context raises HTTP 404 with zero mock data."""
    with patch("routers.generation.retrieve_topic_context", return_value="No context found"):
        payload = {
            "subject": "Chemistry",
            "chapter_name": "NonExistentChapter",
            "test_type": "topic",
            "topic_query": "Unknown Concept",
            "mcq_count": 5,
            "short_count": 3,
            "long_count": 1
        }
        response = client.post("/api/tests/draft", json=payload)
        assert response.status_code == 404
        data = response.json()
        assert data.get("success") is False
        assert data.get("error") == "ContextNotFound"
        # Must NOT contain questions or mock items
        assert "mcqs" not in data
        assert "short_questions" not in data
        assert "long_questions" not in data


def test_qdrant_outage_raises_500_zero_mock(client):
    """Verifies that vector database outage raises HTTP 500 without silent fallback to mock data."""
    with patch("routers.generation.retrieve_topic_context", side_effect=Exception("Qdrant cluster unreachable")):
        payload = {
            "subject": "Physics",
            "chapter_name": "Chapter 1",
            "test_type": "topic",
            "topic_query": "Scalars and Vectors",
            "mcq_count": 5,
            "short_count": 3,
            "long_count": 1
        }
        response = client.post("/api/tests/draft", json=payload)
        assert response.status_code == 500
        data = response.json()
        assert data.get("success") is False
        assert data.get("error") == "LLMGenerationError"
        assert "Qdrant cluster unreachable" in data.get("message", "")
        # Must NOT contain question items
        assert "mcqs" not in data
        assert "short_questions" not in data
        assert "long_questions" not in data


def test_llm_api_timeout_raises_500_zero_mock(client):
    """Verifies that LLM API timeouts raise HTTP 500 without returning fake questions."""
    with patch("routers.generation.retrieve_topic_context", return_value="Real chapter context"):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock, side_effect=TimeoutError("Gemini deadline exceeded")):
            payload = {
                "subject": "Chemistry",
                "chapter_name": "Chapter 1",
                "test_type": "topic",
                "topic_query": "Atomic Structure",
                "mcq_count": 5,
                "short_count": 3,
                "long_count": 1
            }
            response = client.post("/api/tests/draft", json=payload)
            assert response.status_code == 500
            data = response.json()
            assert data.get("success") is False
            assert data.get("error") == "LLMGenerationError"
            assert "Gemini deadline exceeded" in data.get("message", "")
            assert "mcqs" not in data


def test_payload_never_contains_placeholder_patterns(client):
    """Scans error and success response schemas to verify zero placeholder tokens."""
    forbidden_patterns = [
        re.compile(r"Sample MCQ", re.IGNORECASE),
        re.compile(r"Choice Alpha", re.IGNORECASE),
        re.compile(r"Lorem ipsum", re.IGNORECASE),
        re.compile(r"Mock MCQ", re.IGNORECASE),
        re.compile(r"Fake Question", re.IGNORECASE),
    ]

    with patch("routers.generation.retrieve_topic_context", return_value=""):
        response = client.post("/api/tests/draft", json={
            "subject": "Physics",
            "chapter_name": "Kinematics",
            "test_type": "full_chapter"
        })
        content_text = response.text
        for pattern in forbidden_patterns:
            assert not pattern.search(content_text), f"Found forbidden placeholder pattern: {pattern.pattern}"
