def test_get_subjects(client):
    """Tests GET /api/subjects returns supported subjects."""
    response = client.get("/api/subjects")
    assert response.status_code == 200
    data = response.json()
    assert "subjects" in data
    assert isinstance(data["subjects"], list)
    assert "Chemistry" in data["subjects"]
    assert "Physics" in data["subjects"]
    assert "Mathematics" in data["subjects"]


def test_get_subject_chapters(client):
    """Tests GET /api/subjects/Chemistry/chapters endpoint."""
    response = client.get("/api/subjects/Chemistry/chapters")
    assert response.status_code == 200
    data = response.json()
    assert data["subject"] == "Chemistry"
    assert "chapters" in data
    assert isinstance(data["chapters"], list)
    assert len(data["chapters"]) > 0


def test_get_subject_chapters_with_grade(client):
    """Tests GET /api/subjects/Chemistry/chapters?grade=10 endpoint."""
    response = client.get("/api/subjects/Chemistry/chapters?grade=10")
    assert response.status_code == 200
    data = response.json()
    assert data["subject"] == "Chemistry"
    assert "chapters" in data
    assert isinstance(data["chapters"], list)
