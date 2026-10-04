import uvicorn
from fastapi import FastAPI, Request, File, UploadFile, Form, Depends
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from core.logger import setup_logging
from core.lifespan import lifespan
from core.middleware import RequestTrackingMiddleware
from core.security import verify_api_key, verify_admin_key
from core.exceptions import ExamCraftException, examcraft_exception_handler, generic_exception_handler
from routers import generation, pdf_router, upload, metadata, health
from schemas.request_schemas import TestGenerationRequest, PDFRenderRequest

# 1. Initialize logging
setup_logging()
# Updated at 2026-09-13

# 2. Instantiate FastAPI Application with Lifespan
app = FastAPI(
    title=settings.APP_TITLE,
    version=settings.APP_VERSION,
    description=settings.APP_DESCRIPTION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_tags=[
        {
            "name": "Generation",
            "description": "Stage 1 Draft Generation: Context retrieval + Gemini LLM structured JSON output."
        },
        {
            "name": "PDF",
            "description": "Stage 2 PDF Rendering: Converts approved test JSON into a formatted PDF paper."
        },
        {
            "name": "Metadata",
            "description": "Dynamic subject and chapter metadata endpoints for mobile client integration."
        },
        {
            "name": "Upload",
            "description": "Textbook document upload, OCR extraction, chunking, and Qdrant indexing."
        },
        {
            "name": "Health",
            "description": "API status, uptime, Qdrant latency, and readiness checks."
        }
    ]
)

# 3. Configure Middleware (Request tracking & CORS)
app.add_middleware(RequestTrackingMiddleware)

is_wildcard_cors = "*" in settings.ALLOWED_ORIGINS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=not is_wildcard_cors,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"],
    allow_headers=["*"],
)

# 4. Register Exception Handlers
app.add_exception_handler(ExamCraftException, examcraft_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)

# 5. Include API Routers
app.include_router(generation.router)
app.include_router(pdf_router.router)
app.include_router(upload.router)
app.include_router(metadata.router)
app.include_router(health.router)


# =============================================================================
# LEGACY BACKWARD COMPATIBILITY ENDPOINTS
# Ensure legacy clients calling /api/draft-test, /api/render-pdf, or
# /api/upload-textbook continue working seamlessly.
# =============================================================================

@app.post("/api/draft-test", tags=["Legacy Compatibility"], dependencies=[Depends(verify_api_key)], include_in_schema=True)
async def legacy_draft_test(payload: TestGenerationRequest, request: Request):
    """Legacy route alias for POST /api/tests/draft."""
    return await generation.draft_test_endpoint(payload=payload, request=request)


@app.post("/api/render-pdf", tags=["Legacy Compatibility"], dependencies=[Depends(verify_api_key)], include_in_schema=True)
def legacy_render_pdf(payload: PDFRenderRequest):
    """Legacy route alias for POST /api/tests/render-pdf."""
    return pdf_router.render_pdf_endpoint(payload=payload)


@app.post("/api/upload-textbook", tags=["Legacy Compatibility"], dependencies=[Depends(verify_admin_key)], include_in_schema=True)
def legacy_upload_textbook(
    request: Request,
    file: UploadFile = File(...),
    subject: str = Form("Chemistry"),
    grade: int = Form(9)
):
    """Legacy route alias for POST /api/admin/upload-textbook."""
    return upload.upload_textbook_endpoint(request=request, file=file, subject=subject, grade=grade)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")