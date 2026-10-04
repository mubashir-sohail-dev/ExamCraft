import pytest


def test_public_health_endpoint_without_key(unauthenticated_client):
    """Verifies that GET /api/health is accessible publicly without any API key header."""
    response = unauthenticated_client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_missing_api_key_returns_401(unauthenticated_client):
    """Verifies that accessing protected routes without X-API-Key returns HTTP 401 Unauthorized."""
    response = unauthenticated_client.get("/api/subjects")
    assert response.status_code == 401
    assert "Missing API Key" in response.json()["detail"]


def test_invalid_api_key_returns_403(unauthenticated_client):
    """Verifies that accessing protected routes with an invalid X-API-Key returns HTTP 403 Forbidden."""
    headers = {"X-API-Key": "wrong-and-invalid-key"}
    response = unauthenticated_client.get("/api/subjects", headers=headers)
    assert response.status_code == 403
    assert "Invalid or unauthorized API Key" in response.json()["detail"]


def test_valid_client_api_key_returns_200(client):
    """Verifies that accessing protected routes with valid Client X-API-Key returns HTTP 200 OK."""
    response = client.get("/api/subjects")
    assert response.status_code == 200
    assert "subjects" in response.json()


def test_admin_endpoint_rejects_client_key(client):
    """Verifies that calling admin routes with standard Client API Key returns HTTP 403 Forbidden."""
    files = {"file": ("test.pdf", b"%PDF-1.4", "application/pdf")}
    # 'client' fixture uses client API key, not admin API key
    response = client.post("/api/admin/upload-textbook", files=files)
    assert response.status_code == 403
    assert "Admin privileges required" in response.json()["detail"]


def test_admin_endpoint_accepts_admin_key(admin_client):
    """Verifies that calling admin routes with Admin API Key bypasses security barrier."""
    files = {"file": ("notes.txt", b"plain text", "text/plain")}
    # admin_client has valid admin key; fails validation (400) rather than auth (401/403)
    response = admin_client.post("/api/admin/upload-textbook", files=files)
    assert response.status_code == 400
    assert response.json()["error"] == "InvalidRequest"


def test_security_headers_present_on_responses(unauthenticated_client):
    """Verifies that all responses include strict OWASP security headers."""
    response = unauthenticated_client.get("/api/health")
    assert response.status_code == 200
    assert response.headers.get("X-Content-Type-Options") == "nosniff"
    assert response.headers.get("X-Frame-Options") == "DENY"
    assert response.headers.get("X-XSS-Protection") == "1; mode=block"
    assert response.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"


def test_fake_pdf_magic_byte_rejected(admin_client):
    """Verifies that an executable disguised as .pdf is rejected by magic byte inspection."""
    files = {"file": ("malicious.pdf", b"MZ\x90\x00\x03\x00\x00\x00", "application/pdf")}
    response = admin_client.post("/api/admin/upload-textbook", files=files)
    assert response.status_code == 400
    assert "valid PDF signature" in response.json()["message"]


def test_metadata_endpoint_grade_bounds_rejected(client):
    """Verifies that querying out-of-range educational grades returns HTTP 422 validation error."""
    response = client.get("/api/subjects/Chemistry/chapters?grade=99")
    assert response.status_code == 422

