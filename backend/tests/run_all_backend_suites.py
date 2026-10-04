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
    sys.stdout.reconfigure(line_buffering=True)

from main import app
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


def run_full_suite():
    print("=" * 70, flush=True)
    print("EXAMCRAFT AI - FULL BACKEND TEST & INTEGRITY SUITE", flush=True)
    print("=" * 70, flush=True)

    mock_qdrant = MagicMock()
    mock_qdrant.get_collections.return_value = MagicMock(collections=[MagicMock(name="class_9_textbooks")])
    mock_qdrant.scroll.return_value = ([MagicMock(payload={"chapter": "Chapter 1"})], None)

    app.state.qdrant_client = mock_qdrant

    with patch("core.lifespan.QdrantClient", return_value=mock_qdrant), \
         patch("services.pdf_processor.ocr_engine", None), \
         TestClient(app, headers={"X-API-Key": "examcraft-secret-key-2026"}) as client, \
         TestClient(app) as unauth_client, \
         TestClient(app, headers={"X-API-Key": "examcraft-admin-key-2026"}) as admin_client:

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
        ]

        dummy_schema = te.dummy_test_schema()

        total_passed = 0
        total_failed = 0
        suite_timings = {}

        for suite_name, mod in suites:
            print(f"\n--- {suite_name} ({mod.__name__}) ---", flush=True)
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
                        except Exception as e:
                            dt = time.perf_counter() - t0
                            print(f"  [FAIL] {attr} ({dt:.3f}s): {e}", flush=True)
                            total_failed += 1
            suite_timings[suite_name] = round(time.perf_counter() - suite_start, 3)

    print("\n" + "=" * 70, flush=True)
    print("BACKEND VERIFICATION SUMMARY REPORT", flush=True)
    print("=" * 70, flush=True)
    for s_name, s_dur in suite_timings.items():
        print(f"  {s_name}: {s_dur}s", flush=True)
    print("-" * 70, flush=True)
    print(f"TOTAL TESTS PASSED: {total_passed}", flush=True)
    print(f"TOTAL TESTS FAILED: {total_failed}", flush=True)
    print("=" * 70, flush=True)

    if total_failed > 0:
        sys.exit(1)
    else:
        print(">>> 100% OF BACKEND UNIT & INTEGRATION TESTS PASSED WITH ZERO REGRESSIONS <<<", flush=True)
        sys.exit(0)


if __name__ == "__main__":
    run_full_suite()
