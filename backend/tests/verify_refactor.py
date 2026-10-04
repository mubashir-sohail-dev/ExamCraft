import sys
import os
import asyncio
import inspect
import time
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)

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


def main():
    print("=" * 75, flush=True)
    print("EXAMCRAFT AI - MASTER REFACTOR VERIFICATION RUNNER", flush=True)
    print("=" * 75, flush=True)

    mock_qdrant = MagicMock()
    mock_qdrant.get_collections.return_value = MagicMock(collections=[MagicMock(name="class_9_textbooks")])
    mock_qdrant.scroll.return_value = ([MagicMock(payload={"chapter": "Chapter 1"})], None)
    mock_qdrant.collection_exists.return_value = True

    app.state.qdrant_client = mock_qdrant

    total_passed = 0
    total_failed = 0
    results = []

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
            ("Validation Suite (Grade Boundaries & Schema)", tv),
            ("Prompt Harness Suite (Specialized Prompts & Bloom's)", tph),
            ("Context Pruning Suite (12000 Chars Boundary Awareness)", tcp),
            ("Concurrency & LLM Synthesis Suite (asyncio.gather & Reindexing)", tcl),
            ("Zero-Placeholder Policy Suite (Explicit 404/500 Boundaries)", tzp),
            ("Generation & PDF Endpoints Suite", te),
            ("Legacy API Compatibility Suite", tl),
            ("Subject & Chapter Metadata Suite", tm),
            ("Health Telemetry Suite", th),
            ("Security & Key Authentication Suite", ts),
        ]

        for suite_name, mod in suites:
            print(f"\n[SUITE] {suite_name}", flush=True)
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
                            print(f"  [PASS] {attr} ({dt:.3f}s)", flush=True)
                            total_passed += 1
                            results.append((attr, True, dt, ""))
                        except Exception as e:
                            import traceback
                            dt = time.perf_counter() - t0
                            print(f"  [FAIL] {attr} ({dt:.3f}s) -> {repr(e)}\n{traceback.format_exc()}", flush=True)
                            total_failed += 1
                            results.append((attr, False, dt, str(e)))

    print("\n" + "=" * 75, flush=True)
    print("FINAL EXECUTION VERIFICATION SUMMARY", flush=True)
    print("=" * 75, flush=True)
    print(f"Total Test Cases Executed: {total_passed + total_failed}", flush=True)
    print(f"Total Tests PASSED:        {total_passed}", flush=True)
    print(f"Total Tests FAILED:        {total_failed}", flush=True)
    print("=" * 75, flush=True)

    if total_failed > 0:
        print("FAILED TESTS DETECTED!", flush=True)
        sys.exit(1)
    else:
        print(">>> ALL 35+ BACKEND TESTS PASSED WITH 100% SUCCESS RATE <<<", flush=True)
        sys.exit(0)


if __name__ == "__main__":
    main()
