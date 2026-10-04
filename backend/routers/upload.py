"""
routers/upload.py
ExamCraft AI - Asynchronous Textbook Ingestion & Real-Time SSE Telemetry Router

Provides:
- POST /api/admin/upload-textbook (HTTP 202 Accepted, dispatches async ingestion worker)
- GET  /api/admin/jobs/{job_id}/stream (Server-Sent Events streaming live progress & logs)
- GET  /api/admin/jobs/{job_id} (REST status snapshot)
- GET  /api/admin/jobs (List recent jobs)
"""

import os
import time
import uuid
import json
import asyncio
from typing import Optional
from fastapi import APIRouter, Depends, File, Form, Request, UploadFile, status, HTTPException
from fastapi.responses import StreamingResponse
from core.config import settings
from core.exceptions import PDFProcessingError, InvalidRequestError
from core.logger import get_logger
from core.security import verify_admin_key
from services.pdf_processor import extract_text_from_pdf, chunk_textbook
from services.vector_store_service import (
    upload_chunks_to_qdrant,
    qdrant_setup,
    clear_metadata_cache,
    resolve_collection_name,
)
from services.job_manager import job_manager, IngestionJob

logger = get_logger(__name__)

router = APIRouter(
    prefix="/api/admin",
    tags=["Upload"],
    dependencies=[Depends(verify_admin_key)]
)


async def run_ingestion_pipeline(
    job_id: str,
    temp_file_path: str,
    filename: str,
    subject: str,
    grade: int,
    chapter_override: Optional[str],
    qdrant_client: any,
    collection_name: str,
) -> None:
    """Asynchronous worker executing PyMuPDF extraction, FastEmbed chunking, and Qdrant indexing."""
    job = job_manager.get_job(job_id)
    if not job:
        logger.error(f"Worker could not find job {job_id}")
        return

    try:
        job.update_progress(
            status="extracting",
            progress_percent=5,
            stage_message="Parsing document layout & validating PDF structures...",
        )
        job.add_log("INFO", "Initialized background ingestion pipeline")

        # Define page progress callback for real-time extraction telemetry
        def on_page_progress(current_page: int, total_pages: int, chapter_title: str) -> None:
            pct = 5 + int((current_page / total_pages) * 45)  # 5% to 50%
            job.update_progress(
                status="extracting",
                progress_percent=pct,
                current_page=current_page,
                total_pages=total_pages,
                stage_message=f"Extracting Page {current_page} of {total_pages} ({chapter_title})...",
            )
            if current_page % 10 == 0 or current_page == 1 or current_page == total_pages:
                job.add_log("INFO", f"Extracted Page {current_page}/{total_pages} - {chapter_title}")

        # Run extraction in worker threadpool to keep event loop reactive
        raw_text, extraction_summary = await asyncio.to_thread(
            extract_text_from_pdf,
            temp_file_path,
            subject=subject,
            progress_callback=on_page_progress,
        )

        job.update_progress(
            status="chunking",
            progress_percent=55,
            stage_message="Generating overlapping semantic chunks with curriculum metadata...",
        )
        job.add_log("INFO", f"PyMuPDF finished. Detected {extraction_summary.get('chapters_detected', 0)} chapters")

        # Chunk document
        base_meta = {
            "subject": subject,
            "grade": grade,
            "source": filename,
        }
        if chapter_override and chapter_override.strip():
            base_meta["chapter"] = chapter_override.strip()

        chunks = await asyncio.to_thread(
            chunk_textbook,
            raw_text,
            base_metadata=base_meta,
        )

        job.update_progress(
            status="embedding",
            progress_percent=65,
            chunks_indexed=len(chunks),
            stage_message=f"Computing FastEmbed 384d dense + BM25 sparse vectors for {len(chunks)} chunks...",
        )
        job.add_log("INFO", f"Constructed {len(chunks)} semantic chunks. Starting FastEmbed embeddings...")

        # Setup collection if needed
        if qdrant_client:
            await asyncio.to_thread(qdrant_setup, qdrant_client, collection_name)

        job.update_progress(
            status="indexing",
            progress_percent=85,
            stage_message=f"Upserting hybrid points into Qdrant collection '{collection_name}'...",
        )

        # Upload chunks to Qdrant Cloud
        upload_stats = await asyncio.to_thread(
            upload_chunks_to_qdrant,
            qdrant_client,
            collection_name,
            chunks,
        )

        # Invalidate metadata cache so new chapters appear immediately in UI
        clear_metadata_cache()

        result_summary = {
            "status": "success",
            "filename": filename,
            "subject": subject,
            "grade": grade,
            "chunks_indexed": upload_stats.get("chunks_indexed", len(chunks)),
            "duplicates_skipped": upload_stats.get("duplicates_skipped", 0),
            "chapters_detected": extraction_summary.get("chapters_detected", 0),
            "exercises_detected": extraction_summary.get("exercises_detected", 0),
            "collection": collection_name,
            "duration_seconds": job.elapsed_seconds,
        }

        job.update_progress(
            chunks_indexed=upload_stats.get("chunks_indexed", len(chunks)),
            progress_percent=100,
        )
        job.complete(result_summary)
        logger.info(f"Ingestion job {job_id} successfully completed in {job.elapsed_seconds}s")

    except Exception as e:
        logger.exception(f"Ingestion job {job_id} failed: {e}")
        job.fail(str(e))

    finally:
        # Guarantee removal of temporary disk file
        if os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
                job.add_log("INFO", "Cleaned up temporary staging file")
            except Exception as rm_err:
                logger.warning(f"Failed to delete temp file {temp_file_path}: {rm_err}")


@router.post(
    "/upload-textbook",
    status_code=status.HTTP_202_ACCEPTED,
    summary="Upload & Dispatch Ingestion Job (Non-blocking)",
    description="Accepts a textbook PDF, validates format, registers background job, and returns immediate HTTP 202 with stream URL."
)
async def upload_textbook_endpoint(
    request: Request,
    file: UploadFile = File(...),
    subject: str = Form("Chemistry"),
    grade: int = Form(9),
    chapter_name: Optional[str] = Form(None),
):
    """Initiates asynchronous ingestion pipeline, eliminating client timeouts."""
    logger.info("Received textbook upload: file='%s', subject='%s', grade=%d", file.filename, subject, grade)

    # 1. Validation: File extension
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise InvalidRequestError(detail="Invalid file type. Only PDF files (.pdf) are allowed.")

    # 2. Validation: MIME type
    if file.content_type and file.content_type.lower() not in ["application/pdf", "application/x-pdf", "octet-stream"]:
        raise InvalidRequestError(detail="Invalid content type. Uploaded file must be a PDF document.")

    job_id = f"job_{uuid.uuid4().hex[:12]}"
    temp_dir = settings.PDF_TEMP_DIRECTORY
    os.makedirs(temp_dir, exist_ok=True)
    temp_file_path = os.path.join(temp_dir, f"staging_{job_id}_{os.path.basename(file.filename)}")

    # 3. Save uploaded file to staging & check magic bytes and size
    try:
        file_bytes_written = 0
        max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
        first_chunk = True

        with open(temp_file_path, "wb") as buffer:
            while chunk := await file.read(1024 * 1024):
                if first_chunk:
                    if not chunk.startswith(b"%PDF"):
                        raise InvalidRequestError(detail="Invalid file format. Uploaded file does not contain a valid PDF signature (%PDF).")
                    first_chunk = False
                file_bytes_written += len(chunk)
                if file_bytes_written > max_bytes:
                    raise InvalidRequestError(detail=f"File size exceeds maximum allowed limit of {settings.MAX_UPLOAD_SIZE_MB}MB.")
                buffer.write(chunk)

        if file_bytes_written == 0:
            raise InvalidRequestError(detail="Uploaded file is empty (0 bytes).")

    except Exception:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        raise

    qdrant_client = getattr(request.app.state, "qdrant_client", None)
    collection_name = resolve_collection_name(qdrant_client, grade)

    # 4. Register job in JobManager
    job = job_manager.create_job(
        job_id=job_id,
        filename=file.filename,
        subject=subject,
        grade=grade,
        chapter_name=chapter_name,
        target_collection=collection_name,
    )

    # 5. Spawn background processing coroutine
    asyncio.create_task(
        run_ingestion_pipeline(
            job_id=job_id,
            temp_file_path=temp_file_path,
            filename=file.filename,
            subject=subject,
            grade=grade,
            chapter_override=chapter_name,
            qdrant_client=qdrant_client,
            collection_name=collection_name,
        )
    )

    logger.info(f"Dispatched background ingestion task {job_id} for {file.filename}")

    return {
        "status": "accepted",
        "job_id": job.job_id,
        "filename": file.filename,
        "subject": subject,
        "grade": grade,
        "target_collection": collection_name,
        "message": f"Textbook '{file.filename}' accepted for processing.",
        "stream_url": f"/api/admin/jobs/{job.job_id}/stream",
        "status_url": f"/api/admin/jobs/{job.job_id}",
    }


@router.get(
    "/jobs/{job_id}/stream",
    summary="Stream Ingestion Job Real-Time Telemetry via SSE",
    description="Streams Server-Sent Events (SSE) including progress percentage, page milestones, live logs, and completion status."
)
async def stream_job_progress(job_id: str, request: Request):
    """SSE streaming endpoint for real-time ingestion telemetry."""
    job = job_manager.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Ingestion job '{job_id}' not found.")

    async def sse_event_generator():
        q = job.subscribe()
        try:
            # Emit immediate initial snapshot
            initial_data = json.dumps(job.to_dict())
            yield f"event: progress\ndata: {initial_data}\n\n"

            # If already completed or failed, emit terminal event
            if job.status == "completed":
                yield f"event: complete\ndata: {initial_data}\n\n"
                return
            elif job.status == "failed":
                yield f"event: error\ndata: {initial_data}\n\n"
                return

            while True:
                # Check for client disconnect
                if await request.is_disconnected():
                    logger.debug(f"Client disconnected from SSE stream {job_id}")
                    break

                try:
                    # Wait up to 15s for next event, else send keep-alive heartbeat
                    msg = await asyncio.wait_for(q.get(), timeout=15.0)
                    evt_name = msg.get("event", "progress")
                    evt_data = json.dumps(msg.get("data", {}))
                    yield f"event: {evt_name}\ndata: {evt_data}\n\n"

                    if evt_name in ["complete", "error"]:
                        break

                except asyncio.TimeoutError:
                    # Heartbeat comment to keep connection alive through reverse proxies
                    yield ": keep-alive\n\n"

        finally:
            job.unsubscribe(q)

    return StreamingResponse(
        sse_event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Disables proxy buffering in Nginx
        }
    )


@router.get(
    "/jobs/{job_id}",
    summary="Get Ingestion Job Snapshot",
    description="Returns current JSON snapshot of the ingestion job for fallback polling."
)
async def get_job_status_endpoint(job_id: str):
    """Returns current state snapshot of an ingestion job."""
    job = job_manager.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Ingestion job '{job_id}' not found.")
    return job.to_dict()


@router.get(
    "/jobs",
    summary="List Recent Ingestion Jobs",
    description="Returns a list of all active and recently completed ingestion jobs."
)
async def list_jobs_endpoint():
    """Lists recent ingestion jobs."""
    return {"jobs": job_manager.list_jobs()}