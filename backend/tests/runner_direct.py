import sys
import os

print("[1/4] Starting test runner...", flush=True)

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

print("[2/4] Importing app and test modules...", flush=True)
import asyncio
import inspect
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

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

print("[3/4] Initializing TestClient and mocks...", flush=True)

mock_qdrant = MagicMock()
mock_qdrant.get_collections.return_value = MagicMock(collections=[MagicMock(name="class_9_textbooks")])
mock_qdrant.scroll.return_value = ([MagicMock(payload={"chapter": "Chapter 1"})], None)

app.state.qdrant_client = mock_qdrant

with patch("core.lifespan.QdrantClient", return_value=mock_qdrant), \
     patch("services.pdf_processor.ocr_engine", None):
    
    client = TestClient(app, headers={"X-API-Key": "examcraft-secret-key-2026"})
    unauth_client = TestClient(app)
    admin_client = TestClient(app, headers={"X-API-Key": "examcraft-admin-key-2026"})

    modules = [
        ("Validation Tests", tv),
        ("Prompt Harness Tests", tph),
        ("Context Pruning Tests", tcp),
        ("Concurrency & LLM Tests", tcl),
        ("Zero Placeholder Tests", tzp),
        ("Endpoint Tests", te),
        ("Legacy Endpoint Tests", tl),
        ("Metadata Tests", tm),
        ("Health Tests", th),
        ("Security Tests", ts),
    ]

    dummy_schema = te.dummy_test_schema()

    total_passed = 0
    total_failed = 0

    print("[4/4] Executing test functions...", flush=True)

    for group_name, mod in modules:
        print(f"\n--- {group_name} ({mod.__name__}) ---", flush=True)
        for attr_name in sorted(dir(mod)):
            if attr_name.startswith("test_"):
                func = getattr(mod, attr_name)
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

                    try:
                        if inspect.iscoroutinefunction(func):
                            asyncio.run(func(**kwargs))
                        else:
                            func(**kwargs)
                        print(f"  [PASS] {attr_name}", flush=True)
                        total_passed += 1
                    except Exception as e:
                        print(f"  [FAIL] {attr_name}: {e}", flush=True)
                        total_failed += 1

    print("\n" + "=" * 70, flush=True)
    print(f"SUMMARY: Total Passed: {total_passed} | Total Failed: {total_failed}", flush=True)
    print("=" * 70, flush=True)

    if total_failed > 0:
        sys.exit(1)
    else:
        print("ALL TESTS PASSED WITH ZERO FAILURES!", flush=True)
        sys.exit(0)
