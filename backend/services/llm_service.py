import os
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
from services.prompt_builder import PromptBuilder


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


async def _generate_section_a(client: Any, model_name: str, messages: list[dict[str, str]]) -> SectionAResponse:
    """Asynchronously generates Section A (MCQs) via Instructor."""
    return await client.chat.completions.create(
        model=model_name,
        response_model=SectionAResponse,
        temperature=0.1,
        max_retries=2,
        messages=messages
    )


async def _generate_section_b(client: Any, model_name: str, messages: list[dict[str, str]]) -> SectionBResponse:
    """Asynchronously generates Section B (Short Questions) via Instructor."""
    return await client.chat.completions.create(
        model=model_name,
        response_model=SectionBResponse,
        temperature=0.1,
        max_retries=2,
        messages=messages
    )


async def _generate_section_c(client: Any, model_name: str, messages: list[dict[str, str]]) -> SectionCResponse:
    """Asynchronously generates Section C (Long Questions) via Instructor."""
    return await client.chat.completions.create(
        model=model_name,
        response_model=SectionCResponse,
        temperature=0.1,
        max_retries=2,
        messages=messages
    )


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
                textbook_reference=item.textbook_reference
            )
        )
        q_num += 1

    reindexed_shorts: List[ShortQuestionItem] = []
    for item in sec_b.questions:
        reindexed_shorts.append(
            ShortQuestionItem(
                question_number=q_num,
                question=item.question,
                marks=getattr(item, "marks", 2) or 2
            )
        )
        q_num += 1

    reindexed_longs: List[LongQuestionItem] = []
    for item in sec_c.questions:
        reindexed_longs.append(
            LongQuestionItem(
                question_number=q_num,
                question=item.question,
                marks=getattr(item, "marks", 5) or 5
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