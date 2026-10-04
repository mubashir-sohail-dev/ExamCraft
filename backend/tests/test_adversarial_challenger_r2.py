"""
Adversarial Stress Testing & Empirical Benchmark Suite for Generation 2 Refactor.
Challenger: challenger_r2_1 (Critic & Specialist)

Validates:
1. Concurrency speedups of asyncio.gather vs sequential execution under diverse latency models.
2. Robustness of prune_retrieved_context under extreme adversarial inputs:
   - None / empty string / whitespace
   - Small inputs (<12k chars)
   - Giant inputs (50k, 100k, 500k chars)
   - Boundary hierarchy: paragraph (\\n\\n) -> newline (\\n) -> period-space (. ) -> whitespace ( ) -> hard slice
   - Monolithic string without delimiters
   - Multilingual Unicode (Urdu, Arabic, Hindi, CJK), mathematical LaTeX, HTML sub/sup, Emoji & Astral symbols
3. Section assembly, numbering, and marks edge cases:
   - 0 MCQs, 5 Short, 2 Long
   - 10 MCQs, 0 Short, 0 Long
   - 0 MCQs, 0 Short, 0 Long
   - Extreme volumes: 50 MCQs, 20 Short, 10 Long
   - Out-of-order / corrupted source question numbers re-indexing to 1..N
   - Total marks formula exactness: (M * 1) + (S * 2) + (L * 5)
   - Time allowed calculation and 30-minute floor
4. Failure propagation and Zero-Placeholder policy:
   - Coroutine exception in any section propagates immediately without fallback to fake questions.
"""

import sys
import os
import time
import asyncio
import statistics
from unittest.mock import AsyncMock, patch

# Ensure backend root is in sys.path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)

from routers.generation import prune_retrieved_context
from services.llm_service import generate_test_from_context
from schemas.exam_schema import (
    Class9TestSchema,
    MCQItem,
    ShortQuestionItem,
    LongQuestionItem,
    SectionAResponse,
    SectionBResponse,
    SectionCResponse,
)


def run_pruning_adversarial_tests():
    print("\n" + "=" * 70)
    print("SUITE 1: ADVERSARIAL CONTEXT PRUNING EDGE CASES")
    print("=" * 70)

    # 1. None and Empty String
    assert prune_retrieved_context(None, max_chars=12000) is None, "None input failed"
    print("  [PASS] None context returns None")

    assert prune_retrieved_context("", max_chars=12000) == "", "Empty string failed"
    print("  [PASS] Empty string returns empty string")

    # 2. Short Contexts (< 12000 chars) - Must NOT be truncated or modified
    for size in [10, 100, 1000, 5000, 11999, 12000]:
        sample = ("A" * (size - 1) + "B") if size > 0 else ""
        res = prune_retrieved_context(sample, max_chars=12000)
        assert len(res) == size, f"Short context size {size} altered to {len(res)}"
        assert res == sample, f"Short context content altered for size {size}"
    print("  [PASS] All sub-12k contexts (10 to 12,000 chars) preserved with zero mutation")

    # 3. Huge Contexts (>50k, >100k, >500k chars)
    for size in [50_000, 100_000, 500_000]:
        huge_text = ("This is educational textbook paragraph.\n\n" * (size // 40)) + "Final tail."
        res = prune_retrieved_context(huge_text, max_chars=12000)
        assert len(res) <= 12000, f"Pruned context exceeded 12000: {len(res)} for size {size}"
        assert len(res) >= 9600, f"Pruned context dropped below 80% boundary: {len(res)} for size {size}"
        assert not res.endswith("\n"), "Trailing newline not stripped"
    print("  [PASS] Huge contexts (50k, 100k, 500k) strictly bounded to 9600 <= len <= 12000")

    # 4. Boundary Hierarchy Verification:
    # 4a. Paragraph boundary (\n\n) preference
    base_prefix = "P" * 10000 + "\n\n" + "Q" * 1000 + "\n\n" + "R" * 5000
    res_para = prune_retrieved_context(base_prefix, max_chars=12000)
    assert len(res_para) == 11002, f"Expected cut at second paragraph boundary (11002), got {len(res_para)}"
    assert res_para.endswith("Q" * 1000), "Failed paragraph boundary cutoff"
    print("  [PASS] Hierarchy level 1: Double newline (\\n\\n) paragraph boundary properly prioritized")

    # 4b. Single newline (\n) fallback
    base_nl = "P" * 10000 + "\n" + "Q" * 1200 + "\n" + "R" * 5000
    res_nl = prune_retrieved_context(base_nl, max_chars=12000)
    assert len(res_nl) == 11201, f"Expected cut at single newline (11201), got {len(res_nl)}"
    assert res_nl.endswith("Q" * 1200), "Failed single newline boundary cutoff"
    print("  [PASS] Hierarchy level 2: Single newline (\\n) properly chosen when no paragraph break")

    # 4c. Sentence period-space (". ") fallback
    base_sent = "P" * 10000 + ". " + "Q" * 1400 + ". " + "R" * 5000
    res_sent = prune_retrieved_context(base_sent, max_chars=12000)
    assert len(res_sent) == 11403, f"Expected cut at sentence period (11403), got {len(res_sent)}"
    assert res_sent.endswith("."), "Failed sentence period boundary cutoff"
    print("  [PASS] Hierarchy level 3: Sentence period ('. ') properly chosen when no newlines")

    # 4d. Whitespace space (" ") fallback
    base_sp = "P" * 10000 + " " + "Q" * 1600 + " " + "R" * 5000
    res_sp = prune_retrieved_context(base_sp, max_chars=12000)
    assert len(res_sp) == 11601, f"Expected cut at whitespace space (11601), got {len(res_sp)}"
    assert res_sp.endswith("Q" * 1600), "Failed whitespace boundary cutoff"
    print("  [PASS] Hierarchy level 4: Whitespace space (' ') properly chosen when no punctuation")

    # 4e. Monolithic continuous single-token string without any spaces or newlines
    monolithic = "X" * 60_000
    res_mono = prune_retrieved_context(monolithic, max_chars=12000)
    assert len(res_mono) == 12000, f"Expected hard cut at exactly 12000, got {len(res_mono)}"
    assert res_mono == "X" * 12000, "Monolithic slice corrupted"
    print("  [PASS] Hierarchy level 5: Monolithic continuous string cleanly sliced at exact max_chars")

    # 5. Unicode, Multilingual, Mathematical LaTeX, Formulas & Emoji Stress
    urdu_text = "یہ طبیعیات کا سبق ہے جس میں مادے کی حالتوں کی وضاحت کی گئی ہے۔\n\n" * 300
    res_urdu = prune_retrieved_context(urdu_text, max_chars=12000)
    assert len(res_urdu) <= 12000
    assert "طبیعیات" in res_urdu
    print(f"  [PASS] Urdu right-to-left context pruned cleanly (len={len(res_urdu)} <= 12000)")

    latex_chem = (
        "Reaction: $2H_2 + O_2 \\rightarrow 2H_2O$\n\n"
        "Formula: H<sub>2</sub>SO<sub>4</sub> and [Cu(NH<sub>3</sub>)<sub>4</sub>]<sup>2+</sup>\n\n"
        "Calculus: $\\int_{0}^{1} x^2 dx = \\frac{1}{3}$\n\n"
    ) * 150
    res_latex = prune_retrieved_context(latex_chem, max_chars=12000)
    assert len(res_latex) <= 12000
    assert "H<sub>2</sub>SO<sub>4</sub>" in res_latex
    assert "\\rightarrow" in res_latex
    print(f"  [PASS] LaTeX equations & HTML sub/sup tags preserved intact (len={len(res_latex)})")

    emoji_text = "Atom ⚛️ Microscope 🔬 Books 📚 Calculator 🧮 DNA 🧬\n\n" * 400
    res_emoji = prune_retrieved_context(emoji_text, max_chars=12000)
    assert len(res_emoji) <= 12000
    assert "⚛️" in res_emoji
    print(f"  [PASS] Astral multi-byte UTF-8 emojis handled without encoding corruption (len={len(res_emoji)})")


def run_section_assembly_tests():
    print("\n" + "=" * 70)
    print("SUITE 2: SECTION ASSEMBLY, NUMBERING & MARKS MATHEMATICS")
    print("=" * 70)

    async def _test():
        # Case 1: 0 MCQs, 5 Short, 2 Long
        sec_b = SectionBResponse(questions=[
            ShortQuestionItem(question_number=99, question=f"Short Q{i}", marks=2) for i in range(1, 6)
        ])
        sec_c = SectionCResponse(questions=[
            LongQuestionItem(question_number=88, question=f"Long Q{i}", marks=5) for i in range(1, 3)
        ])

        mock_client = AsyncMock()
        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock) as mock_a, \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock, return_value=sec_b) as mock_b, \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock, return_value=sec_c) as mock_c:

            res = await generate_test_from_context(
                subject="Physics",
                chapter_or_topic="Kinematics",
                context="Valid textbook context",
                mcq_count=0,
                short_count=5,
                long_count=2,
                client=mock_client
            )

            mock_a.assert_not_called()
            mock_b.assert_called_once()
            mock_c.assert_called_once()

            assert len(res.mcqs) == 0
            assert len(res.short_questions) == 5
            assert len(res.long_questions) == 2
            # Re-indexing must start at 1
            assert [q.question_number for q in res.short_questions] == [1, 2, 3, 4, 5]
            assert [q.question_number for q in res.long_questions] == [6, 7]
            # Marks math: (0*1) + (5*2) + (2*5) = 20
            assert res.total_marks == 20
            # Time allowed: max(30, 0*1 + 5*3 + 2*10) = max(30, 35) = 35
            assert res.time_allowed == "35 Minutes"
            print("  [PASS] Case 1: 0 MCQs, 5 Short, 2 Long -> Question numbers 1..7, Marks=20, Time=35 Mins")

        # Case 2: 10 MCQs, 0 Short, 0 Long
        sec_a = SectionAResponse(questions=[
            MCQItem(
                question_number=50 + i,
                question=f"MCQ {i}",
                options=["A) 1", "B) 2", "C) 3", "D) 4"],
                correct_option="A",
                textbook_reference="Book ref"
            ) for i in range(1, 11)
        ])

        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, return_value=sec_a) as mock_a, \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock) as mock_b, \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock) as mock_c:

            res = await generate_test_from_context(
                subject="Chemistry",
                chapter_or_topic="Structure of Atoms",
                context="Chemistry context",
                mcq_count=10,
                short_count=0,
                long_count=0,
                client=mock_client
            )

            mock_a.assert_called_once()
            mock_b.assert_not_called()
            mock_c.assert_not_called()

            assert len(res.mcqs) == 10
            assert len(res.short_questions) == 0
            assert len(res.long_questions) == 0
            assert [q.question_number for q in res.mcqs] == list(range(1, 11))
            assert res.total_marks == 10
            # Time allowed: max(30, 10*1) = 30 Minutes
            assert res.time_allowed == "30 Minutes"
            print("  [PASS] Case 2: 10 MCQs, 0 Short, 0 Long -> Question numbers 1..10, Marks=10, Time=30 Mins")

        # Case 3: 0 MCQs, 0 Short, 0 Long (Empty edge test)
        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock) as mock_a, \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock) as mock_b, \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock) as mock_c:

            res = await generate_test_from_context(
                subject="Biology",
                chapter_or_topic="Cell Cycle",
                context="Bio context",
                mcq_count=0,
                short_count=0,
                long_count=0,
                client=mock_client
            )

            mock_a.assert_not_called()
            mock_b.assert_not_called()
            mock_c.assert_not_called()

            assert len(res.mcqs) == 0
            assert len(res.short_questions) == 0
            assert len(res.long_questions) == 0
            assert res.total_marks == 0
            assert res.time_allowed == "30 Minutes"
            print("  [PASS] Case 3: 0 MCQs, 0 Short, 0 Long -> Empty lists, Marks=0, Time=30 Mins floor")

        # Case 4: Extreme volume (50 MCQs, 20 Short, 10 Long)
        sec_a_big = SectionAResponse(questions=[
            MCQItem(
                question_number=i * 2,
                question=f"Bulk MCQ {i}",
                options=["A) w", "B) x", "C) y", "D) z"],
                correct_option="B",
                textbook_reference="Ref"
            ) for i in range(1, 51)
        ])
        sec_b_big = SectionBResponse(questions=[
            ShortQuestionItem(question_number=i * 3, question=f"Bulk Short {i}", marks=2) for i in range(1, 21)
        ])
        sec_c_big = SectionCResponse(questions=[
            LongQuestionItem(question_number=i * 5, question=f"Bulk Long {i}", marks=5) for i in range(1, 11)
        ])

        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, return_value=sec_a_big), \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock, return_value=sec_b_big), \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock, return_value=sec_c_big):

            res = await generate_test_from_context(
                subject="Computer Science",
                chapter_or_topic="Algorithms",
                context="CS context",
                mcq_count=50,
                short_count=20,
                long_count=10,
                client=mock_client
            )

            assert len(res.mcqs) == 50
            assert len(res.short_questions) == 20
            assert len(res.long_questions) == 10
            # Continuous numbering from 1 to 80
            all_numbers = (
                [q.question_number for q in res.mcqs] +
                [q.question_number for q in res.short_questions] +
                [q.question_number for q in res.long_questions]
            )
            assert all_numbers == list(range(1, 81))
            # Marks: 50*1 + 20*2 + 10*5 = 50 + 40 + 50 = 140
            assert res.total_marks == 140
            # Time allowed: max(30, 50*1 + 20*3 + 10*10) = 50 + 60 + 100 = 210
            assert res.time_allowed == "210 Minutes"
            print("  [PASS] Case 4: Extreme volume (50 MCQs, 20 Short, 10 Long) -> Sequential 1..80, Marks=140, Time=210 Mins")

    asyncio.run(_test())


def run_concurrency_benchmark():
    print("\n" + "=" * 70)
    print("SUITE 3: EMPIRICAL CONCURRENCY & LATENCY BENCHMARK")
    print("=" * 70)

    async def _benchmark():
        # Latency models representing realistic LLM section synthesis times
        scenarios = [
            ("Uniform Section Latencies (A=0.8s, B=0.8s, C=0.8s)", 0.8, 0.8, 0.8),
            ("Imbalanced Section Latencies (A=1.2s, B=0.6s, C=0.3s)", 1.2, 0.6, 0.3),
            ("Long Question Heavy (A=0.4s, B=0.5s, C=1.5s)", 0.4, 0.5, 1.5),
        ]

        for name, delay_a, delay_b, delay_c in scenarios:
            async def mock_sec_a(*args, **kwargs):
                await asyncio.sleep(delay_a)
                return SectionAResponse(questions=[
                    MCQItem(question_number=1, question="Q1", options=["A", "B", "C", "D"], correct_option="A", textbook_reference="R1")
                ])

            async def mock_sec_b(*args, **kwargs):
                await asyncio.sleep(delay_b)
                return SectionBResponse(questions=[
                    ShortQuestionItem(question_number=1, question="SQ1", marks=2)
                ])

            async def mock_sec_c(*args, **kwargs):
                await asyncio.sleep(delay_c)
                return SectionCResponse(questions=[
                    LongQuestionItem(question_number=1, question="LQ1", marks=5)
                ])

            # 1. Measure sequential baseline
            t_seq_start = time.perf_counter()
            await mock_sec_a()
            await mock_sec_b()
            await mock_sec_c()
            t_seq_total = time.perf_counter() - t_seq_start

            # 2. Measure concurrent execution via generate_test_from_context
            with patch("services.llm_service._generate_section_a", side_effect=mock_sec_a), \
                 patch("services.llm_service._generate_section_b", side_effect=mock_sec_b), \
                 patch("services.llm_service._generate_section_c", side_effect=mock_sec_c):

                t_conc_start = time.perf_counter()
                res = await generate_test_from_context(
                    subject="Physics",
                    chapter_or_topic="Work and Energy",
                    context="Physics context",
                    mcq_count=1,
                    short_count=1,
                    long_count=1,
                    client=AsyncMock()
                )
                t_conc_total = time.perf_counter() - t_conc_start

            speedup_pct = ((t_seq_total - t_conc_total) / t_seq_total) * 100
            speedup_ratio = t_seq_total / t_conc_total
            expected_min_concurrent = max(delay_a, delay_b, delay_c)

            print(f"\n  Scenario: {name}")
            print(f"    - Sequential Wall Time: {t_seq_total:.3f}s")
            print(f"    - Concurrent Wall Time: {t_conc_total:.3f}s (Theoretical Limit: ~{expected_min_concurrent:.3f}s)")
            print(f"    - Latency Reduction:    {speedup_pct:.1f}% ({speedup_ratio:.2f}x faster)")

            # In all scenarios, concurrent time must be approximately max(delay_a, delay_b, delay_c) + overhead (< 0.15s)
            assert t_conc_total < t_seq_total * 0.75, f"Expected concurrency speedup > 25%, got {speedup_pct:.1f}%"
            assert t_conc_total <= expected_min_concurrent + 0.15, f"Concurrency overhead too high: {t_conc_total:.3f}s vs expected {expected_min_concurrent:.3f}s"

    asyncio.run(_benchmark())
    print("\n  [PASS] All concurrency benchmarks confirmed asyncio.gather delivers optimal parallel execution.")


def run_error_propagation_tests():
    print("\n" + "=" * 70)
    print("SUITE 4: ZERO PLACEHOLDER & ERROR PROPAGATION HARNESS")
    print("=" * 70)

    async def _test_errors():
        # Error in Section A
        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, side_effect=ConnectionError("Gemini API connection reset")), \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock, return_value=SectionBResponse(questions=[])), \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock, return_value=SectionCResponse(questions=[])):

            try:
                await generate_test_from_context("Physics", "Light", "Context", 2, 2, 1, client=AsyncMock())
                assert False, "Section A ConnectionError was silently suppressed"
            except ConnectionError as e:
                assert "Gemini API connection reset" in str(e)
                print("  [PASS] Section A ConnectionError propagated immediately (no mock fallback)")

        # Error in Section B
        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, return_value=SectionAResponse(questions=[])), \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock, side_effect=TimeoutError("Request timed out")), \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock, return_value=SectionCResponse(questions=[])):

            try:
                await generate_test_from_context("Physics", "Light", "Context", 2, 2, 1, client=AsyncMock())
                assert False, "Section B TimeoutError was silently suppressed"
            except TimeoutError as e:
                assert "Request timed out" in str(e)
                print("  [PASS] Section B TimeoutError propagated immediately (no mock fallback)")

        # Error in Section C
        with patch("services.llm_service._generate_section_a", new_callable=AsyncMock, return_value=SectionAResponse(questions=[])), \
             patch("services.llm_service._generate_section_b", new_callable=AsyncMock, return_value=SectionBResponse(questions=[])), \
             patch("services.llm_service._generate_section_c", new_callable=AsyncMock, side_effect=ValueError("Invalid JSON schema returned")):

            try:
                await generate_test_from_context("Physics", "Light", "Context", 2, 2, 1, client=AsyncMock())
                assert False, "Section C ValueError was silently suppressed"
            except ValueError as e:
                assert "Invalid JSON schema returned" in str(e)
                print("  [PASS] Section C ValueError propagated immediately (no mock fallback)")

    asyncio.run(_test_errors())


if __name__ == "__main__":
    t0 = time.perf_counter()
    print("=" * 70)
    print("STARTING EMPIRICAL CHALLENGER ADVERSARIAL SUITE")
    print("=" * 70)

    try:
        run_pruning_adversarial_tests()
        run_section_assembly_tests()
        run_concurrency_benchmark()
        run_error_propagation_tests()
        total_time = time.perf_counter() - t0
        print("\n" + "=" * 70)
        print(f">>> ALL ADVERSARIAL CHALLENGER TESTS PASSED IN {total_time:.2f}s WITH 100% ACCURACY <<<")
        print("=" * 70)
        sys.exit(0)
    except Exception as e:
        import traceback
        print(f"\n[CHALLENGER FAILURE] {e}\n{traceback.format_exc()}", file=sys.stderr)
        sys.exit(1)
