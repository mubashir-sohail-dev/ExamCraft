"""
routers/admin.py
ExamCraft AI - Admin Router with Rate Limiting

Provides:
- POST /api/admin/upload-textbook (HTTP 202, 2/min rate-limited)
- GET  /api/admin/jobs/{job_id}/stream (SSE stream)
- GET  /api/admin/jobs/{job_id} (Job status snapshot)
- GET  /api/admin/jobs (List recent jobs)
"""

from typing import Optional
from fastapi import APIRouter, Depends, File, Form, Request, UploadFile, status
from core.limiter import limiter
from core.security import verify_admin_key
from routers import upload

router = APIRouter(
    prefix="/api/admin",
    tags=["Upload"],
    dependencies=[Depends(verify_admin_key)]
)


@router.post(
    "/upload-textbook",
    status_code=status.HTTP_202_ACCEPTED,
    summary="Upload & Dispatch Ingestion Job (Non-blocking)",
    description="Accepts a textbook PDF, validates format, registers background job, and returns immediate HTTP 202 with stream URL."
)
@limiter.limit("2/minute")
async def upload_textbook(
    request: Request,
    file: UploadFile = File(...),
    subject: str = Form("Chemistry"),
    grade: int = Form(9),
    chapter_name: Optional[str] = Form(None),
):
    """Initiates asynchronous ingestion pipeline with rate limiting."""
    return await upload.upload_textbook_endpoint(
        request=request,
        file=file,
        subject=subject,
        grade=grade,
        chapter_name=chapter_name,
    )


# Attach SSE and status endpoints from upload router
router.add_api_route("/jobs/{job_id}/stream", upload.stream_job_progress, methods=["GET"], summary="Stream Job Progress (SSE)")
router.add_api_route("/jobs/{job_id}", upload.get_job_status_endpoint, methods=["GET"], summary="Get Job Status Snapshot")
router.add_api_route("/jobs", upload.list_jobs_endpoint, methods=["GET"], summary="List Recent Ingestion Jobs")

# Re-export compatibility symbols
upload_textbook_endpoint = upload_textbook
