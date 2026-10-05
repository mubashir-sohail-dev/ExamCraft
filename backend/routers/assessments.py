"""
routers/assessments.py
ExamCraft AI - Assessment Generation Router with Rate Limiting & Daily Budget Guard

Provides:
- POST /api/tests/draft (HTTP 200, 5/min, 50/hr rate-limited, daily budget guarded)
"""

from fastapi import APIRouter, Depends, Request, status
from core.limiter import limiter, budget_guard
from core.security import verify_api_key
from schemas.request_schemas import TestGenerationRequest
from schemas.exam_schema import Class9TestSchema
from routers import generation

router = APIRouter(
    prefix="/api/tests",
    tags=["Generation"],
    dependencies=[Depends(verify_api_key)]
)


@router.post(
    "/draft",
    response_model=Class9TestSchema,
    status_code=status.HTTP_200_OK,
    summary="Generate Test Draft (JSON)",
    description=(
        "Retrieves textbook context from Qdrant vector database and concurrently generates a "
        "zero-hallucination structured test JSON paper via Section-parallel Gemini LLM synthesis."
    )
)
@limiter.limit("5/minute;50/hour")
async def generate_draft_test(payload: TestGenerationRequest, request: Request) -> Class9TestSchema:
    """Generates a structured test JSON payload with rate limiting and daily budget guarding."""
    budget_guard.check_and_increment()
    return await generation.draft_test_endpoint(payload=payload, request=request)


# Re-export compatibility symbols
draft_test_endpoint = generate_draft_test
prune_retrieved_context = generation.prune_retrieved_context
