import os
import sys
from unittest.mock import MagicMock, patch
import pytest

# Ensure backend root directory is in sys.path for test discovery
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from main import app
from fastapi.testclient import TestClient


def _create_configured_mock_qdrant():
    mock_qdrant = MagicMock()
    mock_qdrant.get_collections.return_value = MagicMock(collections=[MagicMock(name="class_9_textbooks")])
    mock_qdrant.collection_exists.return_value = True
    mock_record = MagicMock()
    mock_record.payload = {
        "chapter": "Chapter 1: Chemical Reactions",
        "exercise": "1.1",
        "section": "1.1",
        "topic": "Atoms"
    }
    mock_qdrant.scroll.return_value = ([mock_record], None)
    return mock_qdrant


@pytest.fixture(scope="module")
def client():
    """Provides an authenticated FastAPI TestClient instance with Client API Key."""
    mock_qdrant = _create_configured_mock_qdrant()
    
    with patch("core.lifespan.QdrantClient", return_value=mock_qdrant):
        with patch("services.pdf_processor.ocr_engine", None):
            with TestClient(app, headers={"X-API-Key": "examcraft-secret-key-2026"}) as test_client:
                test_client.app.state.qdrant_client = mock_qdrant
                yield test_client


@pytest.fixture(scope="module")
def unauthenticated_client():
    """Provides an unauthenticated FastAPI TestClient instance (no X-API-Key header)."""
    mock_qdrant = _create_configured_mock_qdrant()
    
    with patch("core.lifespan.QdrantClient", return_value=mock_qdrant):
        with patch("services.pdf_processor.ocr_engine", None):
            with TestClient(app) as test_client:
                test_client.app.state.qdrant_client = mock_qdrant
                yield test_client


@pytest.fixture(scope="module")
def admin_client():
    """Provides an authenticated FastAPI TestClient instance with Admin API Key."""
    mock_qdrant = _create_configured_mock_qdrant()
    
    with patch("core.lifespan.QdrantClient", return_value=mock_qdrant):
        with patch("services.pdf_processor.ocr_engine", None):
            with TestClient(app, headers={"X-API-Key": "examcraft-admin-key-2026"}) as test_client:
                test_client.app.state.qdrant_client = mock_qdrant
                yield test_client

