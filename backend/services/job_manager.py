"""
services/job_manager.py
ExamCraft AI - In-Memory Asynchronous Job Manager and Real-Time SSE Dispatcher

Tracks textbook ingestion lifecycle, emits real-time progress events to SSE subscribers,
and prevents synchronous HTTP connection timeouts on heavy PDF uploads.
"""

import asyncio
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Literal, Optional
from core.logger import get_logger

logger = get_logger(__name__)

JobStatus = Literal[
    "queued",
    "extracting",
    "chunking",
    "embedding",
    "indexing",
    "completed",
    "failed",
    "cancelled",
]


class IngestionJob:
    def __init__(
        self,
        job_id: str,
        filename: str,
        subject: str,
        grade: int,
        chapter_name: Optional[str] = None,
        target_collection: str = "class_9_textbooks",
    ):
        self.job_id = job_id
        self.filename = filename
        self.subject = subject
        self.grade = grade
        self.chapter_name = chapter_name
        self.target_collection = target_collection
        self.status: JobStatus = "queued"
        self.progress_percent: int = 0
        self.current_page: int = 0
        self.total_pages: int = 0
        self.chunks_indexed: int = 0
        self.stage_message: str = "Job queued in processing worker..."
        self.started_at: float = time.time()
        self.updated_at: float = time.time()
        self.completed_at: Optional[float] = None
        self.error: Optional[str] = None
        self.result: Optional[Dict[str, Any]] = None
        self.logs: List[Dict[str, str]] = []
        self._subscribers: List[asyncio.Queue] = []

        self.add_log("INFO", f"Job registered for '{filename}' ({subject}, Class {grade})")

    @property
    def elapsed_seconds(self) -> float:
        end = self.completed_at if self.completed_at else time.time()
        return round(end - self.started_at, 2)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "job_id": self.job_id,
            "filename": self.filename,
            "subject": self.subject,
            "grade": self.grade,
            "chapter_name": self.chapter_name,
            "target_collection": self.target_collection,
            "status": self.status,
            "progress_percent": self.progress_percent,
            "current_page": self.current_page,
            "total_pages": self.total_pages,
            "chunks_indexed": self.chunks_indexed,
            "stage_message": self.stage_message,
            "elapsed_seconds": self.elapsed_seconds,
            "started_at": datetime.fromtimestamp(self.started_at, tz=timezone.utc).isoformat(),
            "updated_at": datetime.fromtimestamp(self.updated_at, tz=timezone.utc).isoformat(),
            "completed_at": datetime.fromtimestamp(self.completed_at, tz=timezone.utc).isoformat() if self.completed_at else None,
            "error": self.error,
            "result": self.result,
            "logs": self.logs[-50:],
        }

    def add_log(self, level: str, message: str) -> None:
        entry = {
            "timestamp": datetime.now(tz=timezone.utc).strftime("%H:%M:%S"),
            "level": level.upper(),
            "message": message,
        }
        self.logs.append(entry)
        self.updated_at = time.time()
        self._notify_subscribers("log", {"log": entry, "job_id": self.job_id})

    def update_progress(
        self,
        status: Optional[JobStatus] = None,
        progress_percent: Optional[int] = None,
        current_page: Optional[int] = None,
        total_pages: Optional[int] = None,
        chunks_indexed: Optional[int] = None,
        stage_message: Optional[str] = None,
    ) -> None:
        if status:
            self.status = status
        if progress_percent is not None:
            self.progress_percent = max(0, min(100, progress_percent))
        if current_page is not None:
            self.current_page = current_page
        if total_pages is not None:
            self.total_pages = total_pages
        if chunks_indexed is not None:
            self.chunks_indexed = chunks_indexed
        if stage_message is not None:
            self.stage_message = stage_message

        self.updated_at = time.time()
        self._notify_subscribers("progress", self.to_dict())

    def complete(self, result_summary: Dict[str, Any]) -> None:
        self.status = "completed"
        self.progress_percent = 100
        self.completed_at = time.time()
        self.result = result_summary
        self.stage_message = "Ingestion and Qdrant indexing completed successfully."
        self.add_log("SUCCESS", f"Indexed {self.chunks_indexed} chunks into {self.target_collection} in {self.elapsed_seconds}s")
        self._notify_subscribers("complete", self.to_dict())

    def fail(self, error_message: str) -> None:
        self.status = "failed"
        self.completed_at = time.time()
        self.error = error_message
        self.stage_message = f"Failed: {error_message}"
        self.add_log("ERROR", error_message)
        self._notify_subscribers("error", self.to_dict())

    def subscribe(self) -> asyncio.Queue:
        q: asyncio.Queue = asyncio.Queue()
        self._subscribers.append(q)
        return q

    def unsubscribe(self, q: asyncio.Queue) -> None:
        if q in self._subscribers:
            self._subscribers.remove(q)

    def _notify_subscribers(self, event_type: str, data: Dict[str, Any]) -> None:
        dead_queues = []
        for q in self._subscribers:
            try:
                q.put_nowait({"event": event_type, "data": data})
            except Exception:
                dead_queues.append(q)
        for dq in dead_queues:
            self.unsubscribe(dq)


class IngestionJobManager:
    """Singleton Ingestion Job Manager managing active and recent tasks."""

    def __init__(self):
        self._jobs: Dict[str, IngestionJob] = {}

    def create_job(
        self,
        job_id: str,
        filename: str,
        subject: str,
        grade: int,
        chapter_name: Optional[str] = None,
        target_collection: str = "class_9_textbooks",
    ) -> IngestionJob:
        job = IngestionJob(
            job_id=job_id,
            filename=filename,
            subject=subject,
            grade=grade,
            chapter_name=chapter_name,
            target_collection=target_collection,
        )
        self._jobs[job_id] = job
        logger.info(f"Registered ingestion job {job_id} for {filename}")
        self._cleanup_old_jobs()
        return job

    def get_job(self, job_id: str) -> Optional[IngestionJob]:
        return self._jobs.get(job_id)

    def list_jobs(self) -> List[Dict[str, Any]]:
        return [job.to_dict() for job in self._jobs.values()]

    def _cleanup_old_jobs(self, max_retention_seconds: int = 7200) -> None:
        now = time.time()
        stale_ids = [
            jid
            for jid, job in self._jobs.items()
            if job.completed_at and (now - job.completed_at > max_retention_seconds)
        ]
        for jid in stale_ids:
            del self._jobs[jid]


# Global singleton instance
job_manager = IngestionJobManager()