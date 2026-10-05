"""
tests/test_rate_limiting.py
Unit and integration tests for SlowAPI rate limiting and DailyBudgetGuard enforcement.
"""

import threading
from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, patch
import pytest
from fastapi import HTTPException
from core.limiter import limiter, budget_guard, DailyBudgetGuard
from schemas.exam_schema import Class9TestSchema, MCQItem


@pytest.fixture
def dummy_test_schema():
    """Mock test schema for generation endpoint tests."""
    return Class9TestSchema(
        test_title="Rate Limiting Verification Test",
        subject="Chemistry",
        chapter_or_topic="Chapter 1",
        total_marks=10,
        time_allowed="30 Mins",
        instructions=["Answer all questions."],
        mcqs=[
            MCQItem(
                question_number=1,
                question="What is an atom?",
                options=["A) Fundamental unit", "B) Molecule", "C) Compound", "D) Mixture"],
                correct_option="A",
                textbook_reference="Page 1"
            )
        ],
        short_questions=[],
        long_questions=[]
    )


def test_slowapi_draft_rate_limit(client, dummy_test_schema):
    """Verifies that POST /api/tests/draft enforces 5/minute limit, rejecting the 6th call with HTTP 429."""
    limiter.reset()
    payload = {
        "subject": "Chemistry",
        "chapter_name": "Chapter 1",
        "test_type": "topic",
        "topic_query": "Atomic Theory",
        "mcq_count": 1,
        "short_count": 0,
        "long_count": 0
    }

    with patch("routers.generation.retrieve_topic_context", return_value="Textbook context"):
        with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = dummy_test_schema

            # First 5 calls must succeed (status 200)
            for i in range(5):
                resp = client.post("/api/tests/draft", json=payload)
                assert resp.status_code == 200, f"Call {i+1} failed with status {resp.status_code}"

            # 6th call within the same minute must be rejected by SlowAPI with HTTP 429
            resp_6 = client.post("/api/tests/draft", json=payload)
            assert resp_6.status_code == 429
            assert "rate limit" in resp_6.text.lower()


def test_slowapi_upload_rate_limit(admin_client):
    """Verifies that POST /api/admin/upload-textbook enforces 2/minute limit, rejecting the 3rd call with HTTP 429."""
    limiter.reset()
    files = {"file": ("notes.txt", b"plain text notes", "text/plain")}

    # First 2 calls hit application logic (400 InvalidRequest due to non-PDF)
    resp_1 = admin_client.post("/api/admin/upload-textbook", files=files)
    assert resp_1.status_code == 400

    resp_2 = admin_client.post("/api/admin/upload-textbook", files=files)
    assert resp_2.status_code == 400

    # 3rd call within the same minute must be rejected by SlowAPI with HTTP 429
    resp_3 = admin_client.post("/api/admin/upload-textbook", files=files)
    assert resp_3.status_code == 429
    assert "rate limit" in resp_3.text.lower()


def test_daily_budget_guard_unit_limit_and_retry_after():
    """Verifies DailyBudgetGuard raises HTTPException(429) with Retry-After header when limit is exceeded."""
    guard = DailyBudgetGuard(limit=3)

    # 3 calls within limit succeed
    assert guard.check_and_increment() == 1
    assert guard.check_and_increment() == 2
    assert guard.check_and_increment() == 3

    # 4th call exceeds limit
    with pytest.raises(HTTPException) as exc_info:
        guard.check_and_increment()

    err = exc_info.value
    assert err.status_code == 429
    assert "Daily LLM request budget exceeded (3 requests/day)" in err.detail
    assert "Retry-After" in err.headers
    retry_after = int(err.headers["Retry-After"])
    assert 0 < retry_after <= 86400


def test_daily_budget_guard_utc_midnight_reset():
    """Verifies DailyBudgetGuard resets count to 0 when crossing UTC midnight date boundary."""
    guard = DailyBudgetGuard(limit=2)
    assert guard.check_and_increment() == 1
    assert guard.check_and_increment() == 2

    # Verify exhausted
    with pytest.raises(HTTPException):
        guard.check_and_increment()

    # Simulate UTC day boundary crossing (yesterday's date)
    yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).date()
    guard._current_date = yesterday

    # Next check should detect new day, reset count, and succeed
    new_count = guard.check_and_increment()
    assert new_count == 1
    assert guard.get_status()["count"] == 1


def test_daily_budget_guard_endpoint_integration(client, dummy_test_schema):
    """Integration test verifying DailyBudgetGuard returns 429 with Retry-After header through the API endpoint."""
    limiter.reset()
    budget_guard._custom_limit = 2
    budget_guard.reset_for_testing(count=0)

    payload = {
        "subject": "Chemistry",
        "chapter_name": "Chapter 1",
        "test_type": "topic",
        "topic_query": "Periodic Trends",
        "mcq_count": 1,
        "short_count": 0,
        "long_count": 0
    }

    try:
        with patch("routers.generation.retrieve_topic_context", return_value="Context"):
            with patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
                mock_gen.return_value = dummy_test_schema

                # Call 1 succeeds
                r1 = client.post("/api/tests/draft", json=payload)
                assert r1.status_code == 200

                # Call 2 succeeds
                r2 = client.post("/api/tests/draft", json=payload)
                assert r2.status_code == 200

                # Call 3 exceeds daily budget -> HTTP 429 with Retry-After
                r3 = client.post("/api/tests/draft", json=payload)
                assert r3.status_code == 429
                assert "Daily LLM request budget exceeded" in r3.text
                assert "retry-after" in r3.headers or "Retry-After" in r3.headers
    finally:
        budget_guard._custom_limit = None
        budget_guard.reset_for_testing(count=0)


def test_daily_budget_guard_thread_safety():
    """Verifies thread-safety under concurrent access across multiple worker threads."""
    guard = DailyBudgetGuard(limit=100)
    errors = []
    success_count = [0]
    lock = threading.Lock()

    def worker():
        for _ in range(10):
            try:
                guard.check_and_increment()
                with lock:
                    success_count[0] += 1
            except HTTPException as e:
                with lock:
                    errors.append(e)

    threads = [threading.Thread(target=worker) for _ in range(12)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    # Total attempts = 120, limit = 100
    assert success_count[0] == 100
    assert len(errors) == 20
    assert all(err.status_code == 429 for err in errors)


def test_daily_budget_guard_status_dict():
    """Verifies get_status returns accurate dictionary structure."""
    guard = DailyBudgetGuard(limit=50)
    guard.check_and_increment()
    status = guard.get_status()
    assert status["count"] == 1
    assert status["limit"] == 50
    assert status["remaining"] == 49
    assert status["seconds_until_reset"] > 0
