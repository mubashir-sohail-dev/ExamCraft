from fastapi import Request, status
from fastapi.responses import JSONResponse
from core.logger import get_logger

logger = get_logger(__name__)


class ExamCraftException(Exception):
    """Base exception for all ExamCraft application errors."""
    def __init__(self, message: str, status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR, error_type: str = "InternalServerError"):
        self.message = message
        self.status_code = status_code
        self.error_type = error_type
        super().__init__(self.message)


class InvalidRequestError(ExamCraftException):
    """Raised when request payload or parameters are invalid (HTTP 400)."""
    def __init__(self, detail: str = "Invalid request parameters"):
        super().__init__(message=detail, status_code=status.HTTP_400_BAD_REQUEST, error_type="InvalidRequest")


class ContextNotFoundError(ExamCraftException):
    """Raised when Qdrant vector retrieval returns empty or no relevant textbook context (HTTP 404)."""
    def __init__(self, detail: str = "No textbook data found in database for the requested topic/chapter"):
        super().__init__(message=detail, status_code=status.HTTP_404_NOT_FOUND, error_type="ContextNotFound")


class QdrantOperationError(ExamCraftException):
    """Raised when vector database operations fail (HTTP 500)."""
    def __init__(self, detail: str = "Database operation failed"):
        super().__init__(message=detail, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, error_type="QdrantError")


class LLMGenerationError(ExamCraftException):
    """Raised when Gemini or Instructor structured extraction fails (HTTP 500)."""
    def __init__(self, detail: str = "Test generation failed during LLM processing"):
        super().__init__(message=detail, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, error_type="LLMGenerationError")


class PDFProcessingError(ExamCraftException):
    """Raised when PDF extraction, OCR, or rendering fails (HTTP 400/500)."""
    def __init__(self, detail: str = "PDF processing failed", status_code: int = status.HTTP_400_BAD_REQUEST):
        super().__init__(message=detail, status_code=status_code, error_type="PDFProcessingError")


async def examcraft_exception_handler(request: Request, exc: ExamCraftException) -> JSONResponse:
    """Global exception handler for custom ExamCraft exceptions returning standardized error JSON."""
    logger.error("ExamCraft error on %s %s: %s (Status %d)", request.method, request.url.path, exc.message, exc.status_code)
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": exc.error_type,
            "message": exc.message,
            "status_code": exc.status_code
        }
    )


from core.config import settings

async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Global fallback exception handler preventing sensitive traceback exposure in production."""
    logger.exception("Unhandled error on %s %s: %s", request.method, request.url.path, str(exc))
    
    # Hide raw internal exception strings in production to prevent information leakage
    client_message = (
        f"An internal error occurred: {str(exc)}"
        if getattr(settings, "LOG_LEVEL", "INFO").upper() == "DEBUG"
        else "An internal server error occurred. Please contact the system administrator."
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": "InternalServerError",
            "message": client_message,
            "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR
        }
    )
