import time
from datetime import datetime, timezone
from fastapi import APIRouter, Request, status
from core.config import settings
from core.logger import get_logger
from schemas.response_schemas import HealthResponse
from services.vector_store_service import check_qdrant_connection

logger = get_logger(__name__)

router = APIRouter(prefix="/api/health", tags=["Health"])

# Module start time for uptime calculation
START_TIME = time.time()


@router.get(
    "",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Backend Health Check",
    description="Verifies API operational status, uptime, Qdrant Cloud latency, and LLM readiness."
)
def health_endpoint(request: Request):
    """Detailed health check endpoint querying Qdrant latency and app state."""
    qdrant_client = getattr(request.app.state, "qdrant_client", None)
    qdrant_health = check_qdrant_connection(qdrant_client)
    
    uptime = round(time.time() - START_TIME, 2)
    current_ts = datetime.now(timezone.utc).isoformat()
    llm_ready = bool(settings.LLM_API_KEY) or bool(getattr(settings, "LLM_MODEL_NAME", None))

    return HealthResponse(
        status="ok" if qdrant_health["healthy"] else "degraded",
        qdrant_connected=qdrant_health["healthy"],
        version=settings.APP_VERSION,
        environment="production",
        uptime_seconds=uptime,
        timestamp=current_ts,
        qdrant_latency_ms=qdrant_health.get("latency_ms", 0.0),
        collection_exists=qdrant_health.get("collection_exists", False),
        llm_available=llm_ready
    )
