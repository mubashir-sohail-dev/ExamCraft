import time
import asyncio
import pytest
from unittest.mock import AsyncMock, patch
from schemas.exam_schema import (
    MCQItem,
    ShortQuestionItem,
    LongQuestionItem,
    SectionAResponse,
    SectionBResponse,
    SectionCResponse,
    Class9TestSchema
)
from services.llm_service import (
    generate_test_from_context,
    _get_instructor_client
)


def test_async_parallel_execution_timing():
    """Verifies that Section A, B, and C coroutines execute concurrently via asyncio.gather."""
    async def _run():
        async def delayed_sec_a(*args, **kwargs):
            await asyncio.sleep(0.3)
            return SectionAResponse(questions=[
                MCQItem(
                    question_number=1,
                    question="MCQ 1",
                    options=["A) 1", "B) 2", "C) 3", "D) 4"],
                    correct_option="A",
                    textbook_reference="Ref 1"
                )
            ])

        async def delayed_sec_b(*args, **kwargs):
            await asyncio.sleep(0.3)
            return SectionBResponse(questions=[
                ShortQuestionItem(question_number=1, question="Short 1", marks=2)
            ])

        async def delayed_sec_c(*args, **kwargs):
            await asyncio.sleep(0.3)
            return SectionCResponse(questions=[
                LongQuestionItem(question_number=1, question="Long 1", marks=5)
            ])

        with patch("services.llm_service._generate_section_a", side_effect=delayed_sec_a):
            with patch("services.llm_service._generate_section_b", side_effect=delayed_sec_b):
                with patch("services.llm_service._generate_section_c", side_effect=delayed_sec_c):
                    mock_client = AsyncMock()
                    start = time.perf_counter()
                    result = await generate_test_from_context(
                        subject="Physics",
                        chapter_or_topic="Motion",
                        context="Valid physics textbook context",
                        mcq_count=1,
                        short_count=1,
                        long_count=1,
                        client=mock_client
                    )
                    duration = time.perf_counter() - start

                    # Sequential execution would take ~0.90s; parallel execution must complete in < 0.55s
                    assert duration < 0.55, f"Expected concurrent execution under 0.55s, but took {duration:.2f}s"
                    assert isinstance(result, Class9TestSchema)
                    assert len(result.mcqs) == 1
                    assert len(result.short_questions) == 1
                    assert len(result.long_questions) == 1

    asyncio.run(_run())


def test_section_restitching_numbering_and_marks():
    """Verifies sequential question re-indexing and accurate marks calculation."""
    async def _run():
        sec_a = SectionAResponse(questions=[
            MCQItem(question_number=99, question="Q1", options=["A) a", "B) b", "C) c", "D) d"], correct_option="A", textbook_reference="R1"),
            MCQItem(question_number=88, question="Q2", options=["A) a", "B) b", "C) c", "D) d"], correct_option="B", textbook_reference="R2"),
            MCQItem(question_number=77, question="Q3", options=["A) a", "B) b", "C) c", "D) d"], correct_option="C", textbook_reference="R3"),
        ])
        sec_b = SectionBResponse(questions=[
            ShortQuestionItem(question_number=10, question="SQ1", marks=2),
            ShortQuestionItem(question_number=20, question="SQ2", marks=2),
        ])
        sec_c = SectionCResponse(questions=[
            LongQuestionItem(question_number=5, question="LQ1", marks=5),
        ])

        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, return_value=sec_a):
            with patch("services.llm_service._generate_section_b", new_callable=AsyncMock, return_value=sec_b):
                with patch("services.llm_service._generate_section_c", new_callable=AsyncMock, return_value=sec_c):
                    result = await generate_test_from_context(
                        subject="Chemistry",
                        chapter_or_topic="Periodic Table",
                        context="Sample chemistry context",
                        mcq_count=3,
                        short_count=2,
                        long_count=1,
                        client=AsyncMock()
                    )

                    # Question numbering must be strictly sequential 1..6
                    assert [q.question_number for q in result.mcqs] == [1, 2, 3]
                    assert [q.question_number for q in result.short_questions] == [4, 5]
                    assert [q.question_number for q in result.long_questions] == [6]

                    # Total marks: 3*1 + 2*2 + 1*5 = 12
                    assert result.total_marks == 12

    asyncio.run(_run())


def test_empty_section_handling():
    """Verifies that requesting 0 questions for a section skips the coroutine and returns empty list."""
    async def _run():
        sec_b = SectionBResponse(questions=[
            ShortQuestionItem(question_number=1, question="SQ1", marks=2),
            ShortQuestionItem(question_number=2, question="SQ2", marks=2),
        ])

        mock_gen_a = AsyncMock()
        mock_gen_c = AsyncMock()

        with patch("services.llm_service._generate_section_a", mock_gen_a):
            with patch("services.llm_service._generate_section_b", new_callable=AsyncMock, return_value=sec_b):
                with patch("services.llm_service._generate_section_c", mock_gen_c):
                    result = await generate_test_from_context(
                        subject="Biology",
                        chapter_or_topic="Cell Biology",
                        context="Cell biology context",
                        mcq_count=0,
                        short_count=2,
                        long_count=0,
                        client=AsyncMock()
                    )

                    # Section A and C generators must NOT be called when count is 0
                    mock_gen_a.assert_not_called()
                    mock_gen_c.assert_not_called()

                    assert len(result.mcqs) == 0
                    assert len(result.short_questions) == 2
                    assert len(result.long_questions) == 0
                    assert result.short_questions[0].question_number == 1
                    assert result.short_questions[1].question_number == 2
                    assert result.total_marks == 4

    asyncio.run(_run())


def test_concurrent_section_failure_propagation():
    """Verifies that an error in any section coroutine propagates immediately without fallback to dummy data."""
    async def _run():
        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, return_value=SectionAResponse(questions=[])):
            with patch("services.llm_service._generate_section_b", new_callable=AsyncMock, side_effect=RuntimeError("LLM API Timeout")):
                with patch("services.llm_service._generate_section_c", new_callable=AsyncMock, return_value=SectionCResponse(questions=[])):
                    with pytest.raises(RuntimeError, match="LLM API Timeout"):
                        await generate_test_from_context(
                            subject="Physics",
                            chapter_or_topic="Electricity",
                            context="Electricity context",
                            mcq_count=2,
                            short_count=2,
                            long_count=1,
                            client=AsyncMock()
                        )

    asyncio.run(_run())
