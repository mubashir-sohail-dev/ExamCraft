"""
tests/test_config.py
Unit tests for configuration validation and fail-fast startup security guard.
"""

import pytest
from core.config import Settings


def test_config_dev_mode_defaults_pass(monkeypatch):
    """Verifies that development mode allows default demo credentials."""
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.delenv("ADMIN_API_KEY", raising=False)
    cfg = Settings(ENVIRONMENT="development", STRICT_SECURITY=False)
    assert cfg.ENVIRONMENT == "development"
    assert cfg.STRICT_SECURITY is False
    assert cfg.DAILY_LLM_REQUEST_LIMIT == 200
    assert cfg.MAX_CONTEXT_CHARS == 12000
    assert cfg.API_KEY == "examcraft-secret-key-2026"
    assert cfg.ADMIN_API_KEY == "examcraft-admin-key-2026"


def test_config_production_demo_client_key_raises_error():
    """Verifies that production mode rejects demo API_KEY."""
    with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR: API_KEY must not use demo defaults"):
        Settings(
            ENVIRONMENT="production",
            API_KEY="examcraft-secret-key-2026",
            ADMIN_API_KEY="valid-high-entropy-admin-key-999"
        )


def test_config_production_demo_admin_key_raises_error():
    """Verifies that production mode rejects demo ADMIN_API_KEY."""
    with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR: ADMIN_API_KEY must not use demo defaults"):
        Settings(
            ENVIRONMENT="production",
            API_KEY="valid-high-entropy-client-key-888",
            ADMIN_API_KEY="examcraft-admin-key-2026"
        )


@pytest.mark.parametrize("demo_key", [
    "examcraft-secret-key-2026",
    "examcraft-admin-key-2026",
    "examcraft-default-key-change-in-production",
    "admin-default-key-change-in-production",
    "",
    "   ",
])
def test_config_production_known_demo_defaults_rejected(demo_key):
    """Verifies that all known demo defaults and empty strings are rejected in production."""
    with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR"):
        Settings(
            ENVIRONMENT="production",
            API_KEY=demo_key,
            ADMIN_API_KEY="valid-high-entropy-admin-key-12345"
        )


def test_config_strict_security_enforces_production_guard():
    """Verifies that STRICT_SECURITY=True triggers guard even in development environment."""
    with pytest.raises(ValueError, match="CRITICAL PRODUCTION SECURITY ERROR"):
        Settings(
            ENVIRONMENT="development",
            STRICT_SECURITY=True,
            API_KEY="examcraft-secret-key-2026"
        )


def test_config_production_same_client_and_admin_key_rejected():
    """Verifies that API_KEY and ADMIN_API_KEY cannot be identical in production for privilege separation."""
    with pytest.raises(ValueError, match="must be distinct to enforce administrative privilege separation"):
        Settings(
            ENVIRONMENT="production",
            API_KEY="shared-high-entropy-key-12345",
            ADMIN_API_KEY="shared-high-entropy-key-12345"
        )


def test_config_production_valid_high_entropy_keys_pass():
    """Verifies that high-entropy distinct keys succeed in production mode."""
    cfg = Settings(
        ENVIRONMENT="production",
        STRICT_SECURITY=True,
        API_KEY="client-prod-key-a89c20f-genuine-auth",
        ADMIN_API_KEY="admin-prod-key-f41e93b-genuine-admin"
    )
    assert cfg.ENVIRONMENT == "production"
    assert cfg.STRICT_SECURITY is True
    assert cfg.API_KEY == "client-prod-key-a89c20f-genuine-auth"
    assert cfg.ADMIN_API_KEY == "admin-prod-key-f41e93b-genuine-admin"
