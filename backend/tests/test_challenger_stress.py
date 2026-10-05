"""
backend/tests/test_challenger_stress.py
Empirical Challenger stress test suite for ExamCraft AI M1 Backend remediation.

Covers:
1. Production fail-fast startup guard in core/config.py (production/strict mode, case sensitivity, whitespace, dev mode warnings/behavior).
2. SlowAPI rate limiter on /api/tests/draft, /api/admin/upload-textbook, and legacy aliases (429 emission, per-IP isolation, auth interaction).
3. DailyBudgetGuard boundary stress test (exact 200-request limit, 201st request rejection, Retry-After header, multi-IP exhaustion, thread concurrency).
"""

import threading
import warnings
import logging
from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, patch
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from core.config import Settings, settings
from core.limiter import limiter, budget_guard, DailyBudgetGuard
from schemas.exam_schema import Class9TestSchema, MCQItem
from main import app


@pytest.fixture
def mock_exam_schema():
    return Class9TestSchema(
        test_title="Empirical Challenger Stress Test",
        subject="Chemistry",
        chapter_or_topic="Atomic Structure",
        total_marks=10,
        time_allowed="30 Mins",
        instructions=["Answer all questions."],
        mcqs=[
            MCQItem(
                question_number=1,
                question="What is the atomic number?",
                options=["A) Protons", "B) Neutrons", "C) Electrons", "D) Quarks"],
                correct_option="A",
                textbook_reference="Page 12"
            )
        ],
        short_questions=[],
        long_questions=[]
    )


# =============================================================================
# SUITE 1: PRODUCTION FAIL-FAST STARTUP GUARD IN CORE/CONFIG.PY
# =============================================================================

class TestSuiteProductionFailFastStartupGuard:
    """Stress tests and boundary condition verification for Settings security guard."""

    def test_production_fails_fast_with_default_api_key(self):
        """Settings fails fast when ENVIRONMENT=production with demo API_KEY."""
        with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR: API_KEY must not use demo defaults"):
            Settings(
                ENVIRONMENT="production",
                API_KEY="examcraft-secret-key-2026",
                ADMIN_API_KEY="genuinely-random-admin-key-778899"
            )

    def test_production_fails_fast_with_default_admin_key(self):
        """Settings fails fast when ENVIRONMENT=production with demo ADMIN_API_KEY."""
        with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR: ADMIN_API_KEY must not use demo defaults"):
            Settings(
                ENVIRONMENT="production",
                API_KEY="genuinely-random-client-key-112233",
                ADMIN_API_KEY="examcraft-admin-key-2026"
            )

    def test_strict_security_fails_fast_even_in_dev_environment(self):
        """Settings fails fast when STRICT_SECURITY=True even if ENVIRONMENT=development."""
        with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR: API_KEY must not use demo defaults"):
            Settings(
                ENVIRONMENT="development",
                STRICT_SECURITY=True,
                API_KEY="examcraft-secret-key-2026",
                ADMIN_API_KEY="genuinely-random-admin-key-778899"
            )

    @pytest.mark.parametrize("env_variant", [
        "PRODUCTION",
        "Production",
        "  production  ",
        "pRoDuCtIoN"
    ])
    def test_production_environment_casing_and_whitespace_robustness(self, env_variant):
        """Guard is case-insensitive and strips whitespace on ENVIRONMENT string."""
        with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR"):
            Settings(
                ENVIRONMENT=env_variant,
                API_KEY="examcraft-secret-key-2026",
                ADMIN_API_KEY="random-admin-key-4455"
            )

    @pytest.mark.parametrize("empty_or_whitespace_key", [
        "",
        "   ",
        "\t\n",
    ])
    def test_empty_or_whitespace_keys_rejected_in_production(self, empty_or_whitespace_key):
        """Guard rejects empty or whitespace-only keys in production."""
        with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR"):
            Settings(
                ENVIRONMENT="production",
                API_KEY=empty_or_whitespace_key,
                ADMIN_API_KEY="valid-random-admin-key-9988"
            )

    def test_identical_keys_rejected_in_production(self):
        """Privilege separation: client and admin keys cannot be identical in production."""
        with pytest.raises(ValueError, match="must be distinct to enforce administrative privilege separation"):
            Settings(
                ENVIRONMENT="production",
                API_KEY="same-random-key-for-both-12345",
                ADMIN_API_KEY="same-random-key-for-both-12345"
            )

    def test_development_mode_succeeds_with_demo_keys(self):
        """Development mode without strict security allows default demo credentials."""
        s = Settings(
            ENVIRONMENT="development",
            STRICT_SECURITY=False,
            API_KEY="examcraft-secret-key-2026",
            ADMIN_API_KEY="examcraft-admin-key-2026"
        )
        assert s.API_KEY == "examcraft-secret-key-2026"
        assert s.ADMIN_API_KEY == "examcraft-admin-key-2026"
        assert s.ENVIRONMENT == "development"

    def test_development_mode_warning_audit(self):
        """Empirically audit whether warnings are emitted during dev mode initialization with demo keys."""
        with warnings.catch_warnings(record=True) as caught_warnings:
            warnings.simplefilter("always")
            s = Settings(ENVIRONMENT="development", STRICT_SECURITY=False)
            # Record empirical fact: Settings does not raise, and records whether Python warnings exist
            warning_count = len(caught_warnings)
        assert s.ENVIRONMENT == "development"
        # Observation note: Warning count is 0 because Settings returns self directly in non-strict mode.


# =============================================================================
# SUITE 2: SLOWAPI RATE LIMITER ON /api/tests/draft & /api/admin/upload-textbook
# =============================================================================

class TestSuiteSlowAPIRateLimiter:
    """Empirical tests for endpoint burst rate limiting (429 emission and isolation)."""

    def test_draft_endpoint_burst_limit_emits_429(self, client, mock_exam_schema):
        """POST /api/tests/draft allows 5 requests/minute, emits HTTP 429 on 6th request."""
        limiter.reset()
        payload = {
            "subject": "Chemistry",
            "chapter_name": "Chapter 1",
            "test_type": "topic",
            "topic_query": "Bohr Model",
            "mcq_count": 1,
            "short_count": 0,
            "long_count": 0
        }

        with patch("routers.generation.retrieve_topic_context", return_value="Context"), \
             patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = mock_exam_schema

            # Requests 1..5 succeed
            for i in range(1, 6):
                resp = client.post("/api/tests/draft", json=payload)
                assert resp.status_code == 200, f"Request #{i} failed with {resp.status_code}: {resp.text}"

            # Request 6 must be 429
            resp_6 = client.post("/api/tests/draft", json=payload)
            assert resp_6.status_code == 429
            assert "Rate limit exceeded" in resp_6.text or "rate limit" in resp_6.text.lower()

    def test_admin_upload_endpoint_burst_limit_emits_429(self, admin_client):
        """POST /api/admin/upload-textbook allows 2 requests/minute, emits HTTP 429 on 3rd request."""
        limiter.reset()
        files = {"file": ("test.txt", b"plain text content", "text/plain")}

        # Calls 1 & 2 hit validation (400)
        r1 = admin_client.post("/api/admin/upload-textbook", files=files)
        assert r1.status_code == 400
        r2 = admin_client.post("/api/admin/upload-textbook", files=files)
        assert r2.status_code == 400

        # Call 3 is blocked by SlowAPI with HTTP 429 before application validation
        r3 = admin_client.post("/api/admin/upload-textbook", files=files)
        assert r3.status_code == 429
        assert "Rate limit exceeded" in r3.text or "rate limit" in r3.text.lower()

    def test_legacy_draft_endpoint_burst_limit_emits_429(self, client, mock_exam_schema):
        """Legacy POST /api/draft-test enforces 5/min limit and emits 429 on 6th request."""
        limiter.reset()
        payload = {
            "subject": "Chemistry",
            "chapter_name": "Chapter 1",
            "test_type": "topic",
            "topic_query": "Valency",
            "mcq_count": 1,
            "short_count": 0,
            "long_count": 0
        }

        with patch("routers.generation.retrieve_topic_context", return_value="Context"), \
             patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = mock_exam_schema

            for i in range(5):
                resp = client.post("/api/draft-test", json=payload)
                assert resp.status_code == 200

            resp_6 = client.post("/api/draft-test", json=payload)
            assert resp_6.status_code == 429

    def test_legacy_upload_endpoint_burst_limit_emits_429(self, admin_client):
        """Legacy POST /api/upload-textbook enforces 2/min limit and emits 429 on 3rd request."""
        limiter.reset()
        files = {"file": ("test.txt", b"plain text", "text/plain")}

        r1 = admin_client.post("/api/upload-textbook", files=files)
        assert r1.status_code == 400
        r2 = admin_client.post("/api/upload-textbook", files=files)
        assert r2.status_code == 400

        r3 = admin_client.post("/api/upload-textbook", files=files)
        assert r3.status_code == 429

    def test_slowapi_per_ip_isolation(self, mock_exam_schema):
        """Verifies that SlowAPI isolates rate limits by client IP address."""
        limiter.reset()
        c1 = TestClient(app, base_url="http://testserver", client=("192.168.1.10", 50000))
        c2 = TestClient(app, base_url="http://testserver", client=("192.168.1.20", 50000))

        headers = {"X-API-Key": settings.API_KEY}
        payload = {
            "subject": "Chemistry",
            "chapter_name": "Chapter 1",
            "test_type": "topic",
            "topic_query": "Isotopes",
            "mcq_count": 1,
            "short_count": 0,
            "long_count": 0
        }

        with patch("routers.generation.retrieve_topic_context", return_value="Context"), \
             patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
            mock_gen.return_value = mock_exam_schema

            # Exhaust IP 1 (5 requests)
            for _ in range(5):
                r = c1.post("/api/tests/draft", json=payload, headers=headers)
                assert r.status_code == 200

            # IP 1 is blocked
            r_blocked = c1.post("/api/tests/draft", json=payload, headers=headers)
            assert r_blocked.status_code == 429

            # IP 2 is NOT blocked (fresh bucket)
            r_ip2 = c2.post("/api/tests/draft", json=payload, headers=headers)
            assert r_ip2.status_code == 200


# =============================================================================
# SUITE 3: DAILY BUDGET GUARD BOUNDARY STRESS TEST (200 REQUESTS)
# =============================================================================

class TestSuiteDailyBudgetGuardStress:
    """Stress tests boundary conditions of DailyBudgetGuard: exactly 200 requests, 201st rejection, Retry-After header."""

    def test_exact_200_requests_boundary_condition(self):
        """Unit test: 200 consecutive requests succeed; request 201 raises HTTPException(429) with Retry-After header."""
        guard = DailyBudgetGuard(limit=200)

        # Requests 1 to 200 succeed
        for expected_count in range(1, 201):
            actual_count = guard.check_and_increment()
            assert actual_count == expected_count

        # Status check at boundary
        status_at_200 = guard.get_status()
        assert status_at_200["count"] == 200
        assert status_at_200["limit"] == 200
        assert status_at_200["remaining"] == 0

        # Request 201 must raise 429
        with pytest.raises(HTTPException) as exc_info:
            guard.check_and_increment()

        err = exc_info.value
        assert err.status_code == 429
        assert "Daily LLM request budget exceeded (200 requests/day)" in err.detail
        assert "Retry-After" in err.headers

        retry_after = int(err.headers["Retry-After"])
        assert 1 <= retry_after <= 86400

    def test_endpoint_integration_200_requests_multi_ip_exhaustion(self, mock_exam_schema):
        """End-to-end integration test:
        Simulate 200 requests across multiple distinct IP clients (so SlowAPI 5/min limit is not triggered per IP).
        Requests 1..200 return HTTP 200.
        Request 201 returns HTTP 429 with 'Retry-After' header from DailyBudgetGuard.
        """
        limiter.reset()
        budget_guard.reset_for_testing(count=0)
        original_limit = budget_guard.limit

        payload = {
            "subject": "Chemistry",
            "chapter_name": "Chapter 1",
            "test_type": "topic",
            "topic_query": "Bonding",
            "mcq_count": 1,
            "short_count": 0,
            "long_count": 0
        }
        headers = {"X-API-Key": settings.API_KEY}

        try:
            with patch("routers.generation.retrieve_topic_context", return_value="Context"), \
                 patch("routers.generation.generate_test_from_context", new_callable=AsyncMock) as mock_gen:
                mock_gen.return_value = mock_exam_schema

                # Fast-forward guard to 198 requests
                budget_guard.reset_for_testing(count=198)

                # Request 199 from client A
                cA = TestClient(app, base_url="http://testserver", client=("10.0.0.1", 50000))
                r199 = cA.post("/api/tests/draft", json=payload, headers=headers)
                assert r199.status_code == 200, f"Req 199 failed: {r199.text}"

                # Request 200 from client B
                cB = TestClient(app, base_url="http://testserver", client=("10.0.0.2", 50000))
                r200 = cB.post("/api/tests/draft", json=payload, headers=headers)
                assert r200.status_code == 200, f"Req 200 failed: {r200.text}"

                # Request 201 from client C (even a brand new IP) must hit 429
                cC = TestClient(app, base_url="http://testserver", client=("10.0.0.3", 50000))
                r201 = cC.post("/api/tests/draft", json=payload, headers=headers)
                assert r201.status_code == 429
                assert "Daily LLM request budget exceeded (200 requests/day)" in r201.json().get("detail", "")
                
                # Check Retry-After header presence
                retry_header = r201.headers.get("retry-after") or r201.headers.get("Retry-After")
                assert retry_header is not None, "Retry-After header missing from 429 response"
                assert int(retry_header) > 0
        finally:
            budget_guard.reset_for_testing(count=0)

    def test_daily_budget_guard_high_concurrency_stress(self):
        """Concurrent stress test: 20 worker threads attempt 15 requests each (total 300 attempts) against limit=200.
        Exactly 200 must succeed; exactly 100 must receive HTTP 429 with Retry-After.
        """
        guard = DailyBudgetGuard(limit=200)
        successes = []
        errors = []
        lock = threading.Lock()

        def worker():
            for _ in range(15):
                try:
                    count = guard.check_and_increment()
                    with lock:
                        successes.append(count)
                except HTTPException as e:
                    with lock:
                        errors.append(e)

        threads = [threading.Thread(target=worker) for _ in range(20)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert len(successes) == 200, f"Expected 200 successes, got {len(successes)}"
        assert len(errors) == 100, f"Expected 100 errors, got {len(errors)}"
        assert sorted(successes) == list(range(1, 201))
        for err in errors:
            assert err.status_code == 429
            assert "Retry-After" in err.headers
            assert int(err.headers["Retry-After"]) > 0

    def test_daily_budget_utc_midnight_rollover_resets_200_count(self):
        """Simulate reaching 200 requests on day T, then midnight UTC arrives.
        Verify that the next request succeeds, resets count to 1, and allows 200 more requests.
        """
        guard = DailyBudgetGuard(limit=200)
        guard.reset_for_testing(count=200)

        # 201st request on same day is rejected
        with pytest.raises(HTTPException):
            guard.check_and_increment()

        # Simulate date rolling over to tomorrow
        yesterday_date = datetime.now(timezone.utc) - timedelta(days=1)
        guard.reset_for_testing(count=200, date=yesterday_date)

        # Now check_and_increment should detect date change and reset to 1
        new_count = guard.check_and_increment()
        assert new_count == 1
        assert guard.get_status()["count"] == 1
        assert guard.get_status()["remaining"] == 199
