from fastapi import APIRouter, Depends, Query, Request, Response, status
from core.config import settings
from core.logger import get_logger
from core.security import verify_api_key
from schemas.response_schemas import SubjectListResponse, ChapterListResponse, ChapterMetadataResponse
from services.vector_store_service import (
    get_subject_chapters,
    get_chapter_metadata,
    resolve_collection_name,
)

logger = get_logger(__name__)

router = APIRouter(
    prefix="/api/subjects",
    tags=["Metadata"],
    dependencies=[Depends(verify_api_key)]
)


@router.get(
    "",
    response_model=SubjectListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Supported Subjects List",
    description="Returns list of subjects supported by the backend system."
)
def get_subjects_endpoint(response: Response):
    """Returns supported subjects list with browser cache."""
    response.headers["Cache-Control"] = "public, max-age=3600, stale-while-revalidate=86400"
    logger.info("Fetching supported subjects list")
    return SubjectListResponse(subjects=settings.SUPPORTED_SUBJECTS)


@router.get(
    "/{subject}/chapters",
    response_model=ChapterListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Genuine Database Chapters for Subject",
    description="Returns strictly genuine chapter titles extracted directly from Qdrant vector database chunks. Returns empty list if unindexed."
)
def get_subject_chapters_endpoint(
    subject: str,
    request: Request,
    response: Response,
    grade: int = Query(default=9, ge=9, le=12, description="Target educational grade (9..12)")
):
    """Retrieves unique chapter titles for a subject and grade directly from Qdrant payload metadata."""
    logger.info("Fetching database chapters for subject='%s', grade=%d", subject, grade)
    qdrant_client = getattr(request.app.state, "qdrant_client", None)
    collection_name = resolve_collection_name(qdrant_client, grade)

    chapters = []
    if collection_name:
        chapters = get_subject_chapters(
            qdrant_client=qdrant_client,
            collection_name=collection_name,
            subject=subject,
            grade=grade
        )

    logger.info(
        "Database returned %d genuine chapters for subject='%s', grade=%d",
        len(chapters),
        subject,
        grade
    )

    response.headers["Cache-Control"] = "public, max-age=300, stale-while-revalidate=600"
    return ChapterListResponse(
        subject=subject,
        chapters=chapters
    )


@router.get(
    "/{subject}/chapters/{chapter_name}/metadata",
    response_model=ChapterMetadataResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Chapter Metadata",
    description="Retrieves available exercises, sections, and topics for a given chapter dynamically from Qdrant vector index."
)
def get_chapter_metadata_endpoint(
    subject: str,
    chapter_name: str,
    request: Request,
    response: Response,
    grade: int = Query(default=9, ge=9, le=12, description="Target educational grade (9..12)")
):
    """Retrieves dynamic exercises, sections, and topics for a chapter from Qdrant vector payload."""
    logger.info("Fetching chapter metadata for subject='%s', chapter='%s', grade=%d", subject, chapter_name, grade)
    qdrant_client = getattr(request.app.state, "qdrant_client", None)
    collection_name = resolve_collection_name(qdrant_client, grade)

    metadata = {"exercises": [], "sections": [], "topics": []}
    if collection_name:
        metadata = get_chapter_metadata(
            qdrant_client=qdrant_client,
            collection_name=collection_name,
            subject=subject,
            chapter_name=chapter_name,
            grade=grade
        )

    response.headers["Cache-Control"] = "public, max-age=300, stale-while-revalidate=600"
    return ChapterMetadataResponse(
        subject=subject,
        chapter=chapter_name,
        exercises=metadata.get("exercises", []),
        sections=metadata.get("sections", []),
        topics=metadata.get("topics", [])
    )
