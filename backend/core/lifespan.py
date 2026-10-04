import os
import time
import glob
from contextlib import asynccontextmanager
from fastapi import FastAPI
from qdrant_client import QdrantClient
from qdrant_client.http import models
from core.config import settings
from core.logger import get_logger

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI Lifespan Context Manager.
    Initializes Qdrant client connection, embedding models, and payload indexes on startup.
    Cleans up client state on shutdown.
    """
    logger.info("Initializing application startup...")

    # Clean up stale temp upload files if any
    try:
        upload_dir = settings.UPLOAD_DIR
        if os.path.exists(upload_dir):
            now = time.time()
            for f in glob.glob(os.path.join(upload_dir, "temp_*")):
                if os.path.isfile(f) and (now - os.path.getmtime(f)) > 3600:
                    try:
                        os.remove(f)
                    except Exception:
                        pass
    except Exception as e:
        logger.debug("Temp directory sweep exception: %s", str(e))
    
    # 1. Initialize Qdrant connection from settings
    logger.info("Connecting to Qdrant Cloud at %s...", settings.QDRANT_URL)
    qdrant_client = QdrantClient(
        url=settings.QDRANT_URL,
        api_key=settings.QDRANT_API_KEY,
        check_compatibility=False
    )

    # 2. Configure FastEmbed models on startup
    try:
        qdrant_client.set_model(settings.DENSE_MODEL_NAME)
        qdrant_client.set_sparse_model(settings.SPARSE_MODEL_NAME)
        logger.info("Configured FastEmbed models: dense=%s, sparse=%s", settings.DENSE_MODEL_NAME, settings.SPARSE_MODEL_NAME)
    except Exception as e:
        logger.warning("FastEmbed model configuration warning: %s", str(e))

    # 3. Ensure payload indices for metadata filtering
    try:
        qdrant_client.create_payload_index(
            collection_name=settings.COLLECTION_NAME,
            field_name="grade",
            field_schema=models.PayloadSchemaType.INTEGER
        )
        qdrant_client.create_payload_index(
            collection_name=settings.COLLECTION_NAME,
            field_name="chapter",
            field_schema=models.PayloadSchemaType.KEYWORD
        )
        qdrant_client.create_payload_index(
            collection_name=settings.COLLECTION_NAME,
            field_name="subject",
            field_schema=models.PayloadSchemaType.KEYWORD
        )
        qdrant_client.create_payload_index(
            collection_name=settings.COLLECTION_NAME,
            field_name="exercise",
            field_schema=models.PayloadSchemaType.KEYWORD
        )
        logger.info("Verified Qdrant payload indices for 'grade', 'chapter', 'subject', and 'exercise'.")
    except Exception:
        # Fails silently if indices already exist
        pass

    # Store client in application state for dependency injection
    app.state.qdrant_client = qdrant_client
    logger.info("Application startup complete. Ready to handle requests.")

    yield

    logger.info("Application shutdown initiated. Releasing resources...")
    try:
        qdrant_client.close()
    except Exception as e:
        logger.warning("Error closing Qdrant client connection: %s", str(e))
    logger.info("Shutdown complete.")
