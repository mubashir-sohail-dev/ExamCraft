import time
from fastapi import APIRouter, Depends, Request, status
from core.config import settings
from core.exceptions import ContextNotFoundError, InvalidRequestError, LLMGenerationError
from core.logger import get_logger
from core.security import verify_api_key
from schemas.request_schemas import TestGenerationRequest
from schemas.exam_enums import RetrievalModeEnum
from schemas.exam_schema import Class9TestSchema
from services.vector_store_service import (
    retrieve_topic_context,
    retrieve_with_exercise_boost,
    resolve_collection_name,
    parse_text_into_chunks,
)
from services.llm_service import generate_test_from_context, audit_grounding

logger = get_logger(__name__)

router = APIRouter(
    prefix="/api/tests",
    tags=["Generation"],
    dependencies=[Depends(verify_api_key)]
)


def prune_retrieved_context(context: str, max_chars: int = 12000) -> str:
    """
    Prunes retrieved textbook context down to max_chars with paragraph/newline boundary awareness.
    Preserves clean structural integrity, formulas, and avoids mid-sentence cutting.
    """
    if not context or len(context) <= max_chars:
        return context

    # Candidate slice up to max_chars
    truncated = context[:max_chars]

    # Look for last double newline (paragraph boundary) in the final 20% of the slice
    search_window_start = int(max_chars * 0.8)
    search_window = truncated[search_window_start:]

    last_para_idx = search_window.rfind("\n\n")
    if last_para_idx != -1:
        cutoff = search_window_start + last_para_idx
        return truncated[:cutoff].strip()

    # Look for last single newline
    last_nl_idx = search_window.rfind("\n")
    if last_nl_idx != -1:
        cutoff = search_window_start + last_nl_idx
        return truncated[:cutoff].strip()

    # Look for last sentence period boundary (". ")
    last_sentence_idx = search_window.rfind(". ")
    if last_sentence_idx != -1:
        cutoff = search_window_start + last_sentence_idx + 1
        return truncated[:cutoff].strip()

    # Look for last whitespace
    last_space_idx = search_window.rfind(" ")
    if last_space_idx != -1:
        cutoff = search_window_start + last_space_idx
        return truncated[:cutoff].strip()

    return truncated.strip()


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
async def draft_test_endpoint(payload: TestGenerationRequest, request: Request) -> Class9TestSchema:
    """Generates a structured test JSON payload grounded strictly in retrieved textbook context."""
    endpoint_start_time = time.perf_counter()
    
    diff_val = payload.difficulty.value if hasattr(payload.difficulty, "value") else str(payload.difficulty)
    logger.info(
        "Draft test request received: subject='%s', grade=%d, chapter='%s', test_type='%s', difficulty='%s', mcqs=%d, shorts=%d, longs=%d",
        payload.subject.value, payload.grade, payload.chapter_name, payload.test_type.value,
        diff_val, payload.mcq_count, payload.short_count, payload.long_count
    )

    # 1. Input Validation: check topic query if mode is topic
    if payload.test_type == RetrievalModeEnum.TOPIC and not payload.topic_query:
        logger.warning("Rejected draft test request: topic_query is missing when test_type is 'topic'")
        raise InvalidRequestError(detail="topic_query is required when test_type is set to 'topic'.")

    qdrant_client = getattr(request.app.state, "qdrant_client", None)
    collection_name = resolve_collection_name(qdrant_client, payload.grade) or settings.COLLECTION_NAME

    # 2. Vector Context Retrieval & Timing
    retrieval_start_time = time.perf_counter()
    try:
        if payload.test_type == RetrievalModeEnum.TOPIC:
            topic_query = payload.topic_query or payload.chapter_name
            context = retrieve_topic_context(
                qdrant_client=qdrant_client,
                collection_name=collection_name,
                subject=payload.subject.value,
                topic=topic_query,
                exercise=payload.exercise,
                grade=payload.grade
            )
        else:
            context, retrieval_strategy = retrieve_with_exercise_boost(
                qdrant_client=qdrant_client,
                collection_name=collection_name,
                subject=payload.subject.value,
                chapter_name=payload.chapter_name,
                exercise=payload.exercise,
                grade=payload.grade
            )

        retrieval_duration = round(time.perf_counter() - retrieval_start_time, 2)
        logger.info("Qdrant context retrieval completed in %.2fs (raw length=%d chars)", retrieval_duration, len(context))

        # 3. Guard Clause: Ensure context exists
        if not context or not context.strip() or "No context found" in context:
            raise ContextNotFoundError(
                detail=f"No textbook data found in database for chapter/topic '{payload.chapter_name}' in subject '{payload.subject.value}'"
            )

        # Smart context chunk tagging and pruning
        tagged_context, chunk_map = parse_text_into_chunks(
            context,
            default_chapter=payload.chapter_name,
            max_chars=settings.MAX_CONTEXT_CHARS
        )
        if tagged_context:
            context = tagged_context
        else:
            context = prune_retrieved_context(context, max_chars=settings.MAX_CONTEXT_CHARS)

        # 4. Asynchronous Section-Parallel LLM Generation & Timing
        llm_start_time = time.perf_counter()
        chapter_or_topic_name = (
            payload.topic_query if payload.test_type == RetrievalModeEnum.TOPIC else payload.chapter_name
        )

        test_data_pydantic = await generate_test_from_context(
            subject=payload.subject.value,
            chapter_or_topic=chapter_or_topic_name,
            context=context,
            mcq_count=payload.mcq_count,
            short_count=payload.short_count,
            long_count=payload.long_count,
            grade=payload.grade,
            exercise=payload.exercise,
            generation_instruction=payload.generation_instruction,
            difficulty=diff_val
        )

        llm_duration = round(time.perf_counter() - llm_start_time, 2)
        total_duration = round(time.perf_counter() - endpoint_start_time, 2)

        # 5. Server-Side Grounding Citation Audit
        grounding_audit = audit_grounding(test_data_pydantic, chunk_map)

        logger.info(
            "Test generation completed for '%s': retrieval=%.2fs, llm=%.2fs, total=%.2fs | Grounding rate: %.1f%% (%d/%d verified)",
            payload.subject.value, retrieval_duration, llm_duration, total_duration,
            grounding_audit["grounding_rate"], grounding_audit["verified_citations"], grounding_audit["total_questions"]
        )

        return test_data_pydantic

    except (ContextNotFoundError, InvalidRequestError):
        raise
    except Exception as e:
        logger.exception("Failed to generate test draft: %s", str(e))
        raise LLMGenerationError(detail=f"Failed to generate test draft: {str(e)}")
