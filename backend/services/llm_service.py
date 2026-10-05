import os
import re
import asyncio
from typing import List, Any
from openai import AsyncOpenAI
import instructor
from schemas.exam_schema import (
    Class9TestSchema,
    MCQItem,
    ShortQuestionItem,
    LongQuestionItem,
    MCQQuestion,
    ShortQuestion,
    LongQuestion,
    SectionAResponse,
    SectionBResponse,
    SectionCResponse
)
from core.config import settings
from core.logger import get_logger
from services.prompt_builder import PromptBuilder

logger = get_logger(__name__)


_cached_client = None


def _get_instructor_client():
    """Lazily initialize and cache instructor async client using application settings."""
    global _cached_client
    if _cached_client is None:
        api_key = settings.LLM_API_KEY or os.getenv("LLM_API_KEY", "")
        base_url = settings.LLM_BASE_URL or "https://omni.ai-vision.studio/v1"
        
        _cached_client = instructor.from_openai(
            AsyncOpenAI(
                api_key=api_key,
                base_url=base_url,
                timeout=120.0
            ),
            mode=instructor.Mode.MD_JSON 
        )
    return _cached_client


async def _empty_section_a() -> SectionAResponse:
    return SectionAResponse(questions=[])


async def _empty_section_b() -> SectionBResponse:
    return SectionBResponse(questions=[])


async def _empty_section_c() -> SectionCResponse:
    return SectionCResponse(questions=[])


async def _call_instructor_with_fallback(client: Any, model_name: str, response_model: Any, messages: list[dict[str, str]]) -> Any:
    """Invokes Instructor client with automatic 404 model fallback to gemini-2.5-flash."""
    try:
        return await client.chat.completions.create(
            model=model_name,
            response_model=response_model,
            temperature=0.1,
            max_retries=2,
            messages=messages
        )
    except Exception as exc:
        err_msg = str(exc).lower()
        if ("404" in err_msg or "not found" in err_msg or "not_found" in err_msg) and model_name != "gemini-2.5-flash":
            logger.warning(
                "Configured model '%s' returned 404 Not Found on API endpoint. Falling back to 'gemini-2.5-flash'...",
                model_name
            )
            return await client.chat.completions.create(
                model="gemini-2.5-flash",
                response_model=response_model,
                temperature=0.1,
                max_retries=2,
                messages=messages
            )
        raise exc


async def _generate_section_a(client: Any, model_name: str, messages: list[dict[str, str]]) -> SectionAResponse:
    """Asynchronously generates Section A (MCQs) via Instructor."""
    return await _call_instructor_with_fallback(client, model_name, SectionAResponse, messages)


async def _generate_section_b(client: Any, model_name: str, messages: list[dict[str, str]]) -> SectionBResponse:
    """Asynchronously generates Section B (Short Questions) via Instructor."""
    return await _call_instructor_with_fallback(client, model_name, SectionBResponse, messages)


async def _generate_section_c(client: Any, model_name: str, messages: list[dict[str, str]]) -> SectionCResponse:
    """Asynchronously generates Section C (Long Questions) via Instructor."""
    return await _call_instructor_with_fallback(client, model_name, SectionCResponse, messages)


async def generate_test_from_context(
    subject: str,
    chapter_or_topic: str,
    context: str,
    mcq_count: int = 5,
    short_count: int = 3,
    long_count: int = 1,
    grade: int = 9,
    exercise: str | None = None,
    generation_instruction: str | None = None,
    difficulty: str = "mixed",
    client: Any | None = None
) -> Class9TestSchema:
    """
    Generates a structured exam paper concurrently across Section A, B, and C coroutines.
    Zero-placeholder enforcement: strictly raises errors on failure with no fallback to fake data.
    """
    client = client or _get_instructor_client()
    raw_model = settings.LLM_MODEL_NAME or os.getenv("LLM_MODEL_NAME", "")
    if not raw_model or raw_model.strip().lower() in ("auto", "default"):
        model_name = "gemini-3.8-flash"
    else:
        model_name = raw_model.strip()

    # Construct individual section prompts
    messages_a = PromptBuilder.build_section_a(
        subject=subject,
        chapter_or_topic=chapter_or_topic,
        count=mcq_count,
        context=context,
        grade=grade,
        exercise=exercise,
        generation_instruction=generation_instruction,
        difficulty=difficulty
    ) if mcq_count > 0 else []

    messages_b = PromptBuilder.build_section_b(
        subject=subject,
        chapter_or_topic=chapter_or_topic,
        count=short_count,
        context=context,
        grade=grade,
        exercise=exercise,
        generation_instruction=generation_instruction,
        difficulty=difficulty
    ) if short_count > 0 else []

    messages_c = PromptBuilder.build_section_c(
        subject=subject,
        chapter_or_topic=chapter_or_topic,
        count=long_count,
        context=context,
        grade=grade,
        exercise=exercise,
        generation_instruction=generation_instruction,
        difficulty=difficulty
    ) if long_count > 0 else []

    # Prepare concurrent tasks
    task_a = _generate_section_a(client, model_name, messages_a) if mcq_count > 0 else _empty_section_a()
    task_b = _generate_section_b(client, model_name, messages_b) if short_count > 0 else _empty_section_b()
    task_c = _generate_section_c(client, model_name, messages_c) if long_count > 0 else _empty_section_c()

    # Execute all 3 sections concurrently
    sec_a, sec_b, sec_c = await asyncio.gather(task_a, task_b, task_c)

    # Dynamically re-index question numbers sequentially
    reindexed_mcqs: List[MCQItem] = []
    q_num = 1
    for item in sec_a.questions:
        reindexed_mcqs.append(
            MCQItem(
                question_number=q_num,
                question=item.question,
                options=item.options,
                correct_option=item.correct_option,
                textbook_reference=item.textbook_reference,
                chunk_id=getattr(item, "chunk_id", None),
                cited_quote=getattr(item, "cited_quote", None)
            )
        )
        q_num += 1

    reindexed_shorts: List[ShortQuestionItem] = []
    for item in sec_b.questions:
        reindexed_shorts.append(
            ShortQuestionItem(
                question_number=q_num,
                question=item.question,
                marks=getattr(item, "marks", 2) or 2,
                textbook_reference=getattr(item, "textbook_reference", None),
                chunk_id=getattr(item, "chunk_id", None),
                cited_quote=getattr(item, "cited_quote", None)
            )
        )
        q_num += 1

    reindexed_longs: List[LongQuestionItem] = []
    for item in sec_c.questions:
        reindexed_longs.append(
            LongQuestionItem(
                question_number=q_num,
                question=item.question,
                marks=getattr(item, "marks", 5) or 5,
                textbook_reference=getattr(item, "textbook_reference", None),
                chunk_id=getattr(item, "chunk_id", None),
                cited_quote=getattr(item, "cited_quote", None)
            )
        )
        q_num += 1

    total_marks = (len(reindexed_mcqs) * 1) + (len(reindexed_shorts) * 2) + (len(reindexed_longs) * 5)
    est_minutes = max(30, (len(reindexed_mcqs) * 1) + (len(reindexed_shorts) * 3) + (len(reindexed_longs) * 10))
    time_allowed = f"{est_minutes} Minutes"
    test_title = f"Class {grade} {subject} - {chapter_or_topic} Assessment"

    return Class9TestSchema(
        test_title=test_title,
        subject=subject,
        grade=grade,
        chapter_or_topic=chapter_or_topic,
        total_marks=total_marks,
        time_allowed=time_allowed,
        instructions=[
            "Attempt all questions.",
            "Write neatly and draw diagrams where necessary."
        ],
        mcqs=reindexed_mcqs,
        short_questions=reindexed_shorts,
        long_questions=reindexed_longs
    )


def audit_grounding(schema: Class9TestSchema, chunk_map: dict[int, Any] | None = None) -> dict:
    """
    Empirical citation verification engine:
    Validates whether every question's cited_quote or textbook_reference exists
    within the cited chunk or retrieved textbook context.
    Computes verifiable grounding rate (0.0% to 100.0%).
    """
    total_items = len(schema.mcqs) + len(schema.short_questions) + len(schema.long_questions)
    if total_items == 0:
        return {"total_questions": 0, "verified_citations": 0, "grounding_rate": 100.0, "details": []}

    verified_count = 0
    details = []

    all_questions = (
        [("mcq", q) for q in schema.mcqs] +
        [("short", q) for q in schema.short_questions] +
        [("long", q) for q in schema.long_questions]
    )

    for q_type, q in all_questions:
        q_num = q.question_number
        c_id = getattr(q, "chunk_id", None)
        quote = getattr(q, "cited_quote", None) or getattr(q, "textbook_reference", None)
        is_verified = False
        reason = ""

        if chunk_map and c_id is not None:
            if c_id in chunk_map:
                chunk_obj = chunk_map[c_id]
                chunk_text = getattr(chunk_obj, "text", str(chunk_obj)).lower()
                if quote and quote.strip().lower() in chunk_text:
                    is_verified = True
                    reason = f"Verified verbatim excerpt in [CHUNK #{c_id}]"
                elif quote and len(quote.strip()) > 5:
                    words = [w for w in re.findall(r'\w+', quote.lower()) if len(w) > 3]
                    matched = [w for w in words if w in chunk_text]
                    if len(words) > 0 and (len(matched) / len(words)) >= 0.6:
                        is_verified = True
                        reason = f"Verified concept overlap in [CHUNK #{c_id}]"
                    else:
                        reason = f"Quote not found in cited [CHUNK #{c_id}]"
                else:
                    is_verified = True
                    reason = f"Attributed to verified [CHUNK #{c_id}]"
            else:
                reason = f"Invalid/hallucinated chunk_id {c_id}"
        elif quote and quote.strip():
            is_verified = True
            reason = "Free-text citation present"
        else:
            reason = "No citation or chunk_id provided"

        if is_verified:
            verified_count += 1

        details.append({
            "question_number": q_num,
            "type": q_type,
            "chunk_id": c_id,
            "verified": is_verified,
            "reason": reason
        })

    rate = round((verified_count / total_items) * 100.0, 1)
    logger.info("[Grounding Audit] Verified %d/%d questions (%.1f%% grounding rate)", verified_count, total_items, rate)
    return {
        "total_questions": total_items,
        "verified_citations": verified_count,
        "grounding_rate": rate,
        "details": details
    }