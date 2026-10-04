"""
Adversarial Verification Runner for Challenger 2
Runs all backend suites + adversarial stress tests with robust fixture handling.
Writes full log to both stdout and .agents/challenger_r2_2/test_results.txt
"""
import sys
import os
import asyncio
import inspect
import time
from unittest.mock import MagicMock, patch

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)

out_file_path = os.path.join(os.path.dirname(backend_dir), ".agents", "challenger_r2_2", "test_results.txt")

def log(msg=""):
    print(msg, flush=True)
    try:
        with open(out_file_path, "a", encoding="utf-8") as f:
            f.write(msg + "\n")
            f.flush()
    except Exception:
        pass

# Clear log file initially
try:
    with open(out_file_path, "w", encoding="utf-8") as f:
        f.write("")
except Exception:
    pass

from fastapi.testclient import TestClient
from main import app
from schemas.exam_schema import Class9TestSchema, MCQItem, ShortQuestionItem, LongQuestionItem
import tests.test_validation as tv
import tests.test_prompt_harness as tph
import tests.test_context_pruning as tcp
import tests.test_concurrency_llm as tcl
import tests.test_zero_placeholder as tzp
import tests.test_endpoints as te
import tests.test_legacy as tl
import tests.test_metadata as tm
import tests.test_health as th
import tests.test_security as ts
import tests.test_adversarial_challenger as tac


def run_full_adversarial_suite():
    log("=" * 75)
    log("EXAMCRAFT AI - MASTER ADVERSARIAL CHALLENGER VERIFICATION RUNNER")
    log("=" * 75)

    mock_qdrant = MagicMock()
    mock_qdrant.get_collections.return_value = MagicMock(collections=[MagicMock(name="class_9_textbooks")])
    mock_qdrant.scroll.return_value = ([MagicMock(payload={"chapter": "Chapter 1"})], None)
    mock_qdrant.collection_exists.return_value = True

    app.state.qdrant_client = mock_qdrant

    dummy_schema = Class9TestSchema(
        test_title="Class 9 Chemistry Test",
        subject="Chemistry",
        chapter_or_topic="Chapter 1",
        total_marks=16,
        time_allowed="45 Minutes",
        instructions=["Answer all questions."],
        mcqs=[
            MCQItem(
                question_number=1,
                question="What is matter?",
                options=["A) Anything with mass", "B) Nothing", "C) Energy only", "D) Space only"],
                correct_option="A",
                textbook_reference="Page 5 concept excerpt"
            )
        ],
        short_questions=[
            ShortQuestionItem(
                question_number=2,
                question="Define solids.",
                marks=2
            )
        ],
        long_questions=[
            LongQuestionItem(
                question_number=3,
                question="Explain the states of matter with examples.",
                marks=5
            )
        ]
    )

    with patch("core.lifespan.QdrantClient", return_value=mock_qdrant), \
         patch("services.pdf_processor.ocr_engine", None):

        client = TestClient(app, headers={"X-API-Key": "examcraft-secret-key-2026"})
        unauth_client = TestClient(app)
        admin_client = TestClient(app, headers={"X-API-Key": "examcraft-admin-key-2026"})

        suites = [
            ("1. Request & Grade Validation Suite", tv),
            ("2. Prompt Builder & Bloom's Taxonomy Suite", tph),
            ("3. Context Pruning & Boundary Suite", tcp),
            ("4. Concurrent Section Synthesis Suite", tcl),
            ("5. Zero-Placeholder & Error Boundary Suite", tzp),
            ("6. Generation & PDF Endpoints Suite", te),
            ("7. Legacy Compatibility Suite", tl),
            ("8. Metadata & Chapters Suite", tm),
            ("9. Health Telemetry Suite", th),
            ("10. Security & API Key Guard Suite", ts),
            ("11. Adversarial Failure Injection Suite", tac),
        ]

        total_passed = 0
        total_failed = 0
        suite_timings = {}

        for suite_name, mod in suites:
            log(f"\n[SUITE] {suite_name} ({mod.__name__})")
            suite_start = time.perf_counter()
            for attr in sorted(dir(mod)):
                if attr.startswith("test_"):
                    func = getattr(mod, attr)
                    if callable(func):
                        sig = inspect.signature(func)
                        kwargs = {}
                        if "client" in sig.parameters:
                            kwargs["client"] = client
                        if "unauthenticated_client" in sig.parameters:
                            kwargs["unauthenticated_client"] = unauth_client
                        if "admin_client" in sig.parameters:
                            kwargs["admin_client"] = admin_client
                        if "dummy_test_schema" in sig.parameters:
                            fix = getattr(mod, "dummy_test_schema", None)
                            if fix and hasattr(fix, "__wrapped__"):
                                kwargs["dummy_test_schema"] = fix.__wrapped__()
                            else:
                                kwargs["dummy_test_schema"] = dummy_schema

                        t0 = time.perf_counter()
                        try:
                            if inspect.iscoroutinefunction(func):
                                asyncio.run(func(**kwargs))
                            else:
                                func(**kwargs)
                            dt = time.perf_counter() - t0
                            log(f"  [PASS] {attr} ({dt:.3f}s)")
                            total_passed += 1
                        except Exception as e:
                            import traceback
                            dt = time.perf_counter() - t0
                            log(f"  [FAIL] {attr} ({dt:.3f}s): {e}\n{traceback.format_exc()}")
                            total_failed += 1
            suite_timings[suite_name] = round(time.perf_counter() - suite_start, 3)

    log("\n" + "=" * 75)
    log("ADVERSARIAL VERIFICATION SUMMARY REPORT")
    log("=" * 75)
    for s_name, s_dur in suite_timings.items():
        log(f"  {s_name}: {s_dur}s")
    log("-" * 75)
    log(f"TOTAL TESTS PASSED: {total_passed}")
    log(f"TOTAL TESTS FAILED: {total_failed}")
    log("=" * 75)

    if total_failed > 0:
        log(f"❌ ADVERSARIAL VERIFICATION FAILED: {total_failed} test(s) failed.")
        sys.exit(1)
    else:
        log("✅ 100% OF ADVERSARIAL & REGRESSION TESTS PASSED WITH ZERO ERRORS.")
        sys.exit(0)


if __name__ == "__main__":
    run_full_adversarial_suite()
