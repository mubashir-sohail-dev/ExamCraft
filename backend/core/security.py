import secrets
from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
from core.config import settings
from core.logger import get_logger

logger = get_logger(__name__)

# Define API Key header scheme for OpenAPI documentation
api_key_header = APIKeyHeader(
    name="X-API-Key",
    auto_error=False,
    description="Client or Admin API Key for endpoint access"
)


def verify_api_key(api_key: str = Security(api_key_header)) -> str:
    """Verifies that the incoming request contains a valid Client or Admin API key.
    
    Uses secrets.compare_digest to defend against timing attacks.
    Exempts verification if ENABLE_AUTH is set to False in settings.
    """
    if not settings.ENABLE_AUTH:
        return "auth_disabled"

    if not api_key:
        logger.warning("Unauthorized access attempt: Missing X-API-Key header.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing API Key. Include 'X-API-Key' in request headers."
        )

    # Allow access if matching either Client API Key or Admin API Key
    is_client_valid = bool(settings.API_KEY) and secrets.compare_digest(api_key, settings.API_KEY)
    is_admin_valid = bool(settings.ADMIN_API_KEY) and secrets.compare_digest(api_key, settings.ADMIN_API_KEY)

    if not (is_client_valid or is_admin_valid):
        logger.warning("Forbidden access attempt: Invalid X-API-Key provided.")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or unauthorized API Key."
        )

    return api_key


def verify_admin_key(api_key: str = Security(api_key_header)) -> str:
    """Verifies that the incoming request contains a valid Admin API key.
    
    Strictly enforced for admin-only operations (e.g., textbook ingestion).
    """
    if not settings.ENABLE_AUTH:
        return "auth_disabled"

    if not api_key:
        logger.warning("Unauthorized admin access attempt: Missing X-API-Key header.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Admin API Key. Include 'X-API-Key' in request headers."
        )

    if not (bool(settings.ADMIN_API_KEY) and secrets.compare_digest(api_key, settings.ADMIN_API_KEY)):
        logger.warning("Forbidden admin access attempt: Insufficient privileges.")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required. Provide a valid Admin API Key."
        )

    return api_key
