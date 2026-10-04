def test_health_endpoint(client):
    """Tests GET /api/health endpoint returns status 200 and expected schema."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "qdrant_connected" in data
    assert "version" in data
