"""
core/limiter.py
ExamCraft AI - Rate Limiting & Daily Generation Budget Enforcement

Provides:
- SlowAPI Limiter instance for endpoint-level burst protection.
- Thread-safe in-memory DailyBudgetGuard enforcing DAILY_LLM_REQUEST_LIMIT=200 with UTC reset and Retry-After header.
- Singleton instances: limiter, budget_guard.
"""

import threading
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any
from fastapi import HTTPException, status
from slowapi import Limiter
from slowapi.util import get_remote_address
from core.config import settings
from core.logger import get_logger

logger = get_logger(__name__)

# SlowAPI Limiter keyed by client remote IP address
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[],
    headers_enabled=False,
)

try:
    import pytest

    @pytest.fixture(autouse=True)
    def _autouse_reset_rate_limits():
        """Autouse fixture resetting in-memory SlowAPI rate limits between isolated test cases."""
        limiter.reset()
        yield
        limiter.reset()
except ImportError:
    pass


class DailyBudgetGuard:
    """Thread-safe in-memory daily LLM generation budget guard.

    Enforces a strict cap of DAILY_LLM_REQUEST_LIMIT generations per UTC day.
    Rejects excess requests with HTTP 429 and OWASP-compliant Retry-After header.
    """

    DAILY_LLM_REQUEST_LIMIT: int = 200

    def __init__(self, limit: Optional[int] = None):
        self._custom_limit = limit
        self._lock = threading.Lock()
        self._current_date = datetime.now(timezone.utc).date()
        self._request_count = 0

    @property
    def limit(self) -> int:
        if self._custom_limit is not None:
            return self._custom_limit
        return getattr(settings, "DAILY_LLM_REQUEST_LIMIT", self.DAILY_LLM_REQUEST_LIMIT)

    def _reset_if_new_day(self) -> None:
        """Resets the counter if the current date differs from the recorded UTC date."""
        today = datetime.now(timezone.utc).date()
        if today != self._current_date:
            logger.info(
                "DailyBudgetGuard: New UTC day (%s -> %s). Resetting count from %d to 0.",
                self._current_date, today, self._request_count
            )
            self._current_date = today
            self._request_count = 0

    def seconds_until_midnight_utc(self) -> int:
        """Calculates remaining seconds until 00:00:00 UTC of the next day."""
        now = datetime.now(timezone.utc)
        midnight = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        return max(1, int((midnight - now).total_seconds()))

    def check_and_increment(self) -> int:
        """Atomically checks and increments the daily request count.

        Raises:
            HTTPException(429): When daily request count reaches or exceeds the limit.
        """
        with self._lock:
            self._reset_if_new_day()
            if self._request_count >= self.limit:
                retry_after = self.seconds_until_midnight_utc()
                logger.warning(
                    "Daily LLM budget exceeded: %d/%d requests used today. Rejecting request. Retry-After: %ds",
                    self._request_count, self.limit, retry_after
                )
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Daily LLM request budget exceeded ({self.limit} requests/day). Please try again tomorrow.",
                    headers={"Retry-After": str(retry_after)}
                )
            self._request_count += 1
            return self._request_count

    def get_status(self) -> Dict[str, Any]:
        """Returns the current budget tracking status."""
        with self._lock:
            self._reset_if_new_day()
            return {
                "date": str(self._current_date),
                "count": self._request_count,
                "limit": self.limit,
                "remaining": max(0, self.limit - self._request_count),
                "seconds_until_reset": self.seconds_until_midnight_utc(),
            }

    def reset_for_testing(self, count: int = 0, date: Optional[datetime] = None) -> None:
        """Test helper to reset state deterministically."""
        with self._lock:
            self._request_count = count
            if date is not None:
                self._current_date = date.date()
            else:
                self._current_date = datetime.now(timezone.utc).date()


# Global singleton instance
budget_guard = DailyBudgetGuard()
