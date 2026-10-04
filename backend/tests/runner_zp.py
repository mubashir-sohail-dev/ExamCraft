import sys
import os
import inspect
import time
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from main import app
import tests.test_zero_placeholder as tzp

mock_qdrant = MagicMock()
mock_qdrant.get_collections.return_value = MagicMock(collections=[MagicMock(name="class_9_textbooks")])

print("=" * 60, flush=True)
print("RUNNING ZERO PLACEHOLDER TEST SUITE", flush=True)
print("=" * 60, flush=True)

with patch("core.lifespan.QdrantClient", return_value=mock_qdrant), \
     patch("services.pdf_processor.ocr_engine", None), \
     TestClient(app, headers={"X-API-Key": "examcraft-secret-key-2026"}) as client:
    
    passed = 0
    failed = 0

    for attr in sorted(dir(tzp)):
        if attr.startswith("test_"):
            func = getattr(tzp, attr)
            if callable(func):
                t0 = time.perf_counter()
                try:
                    func(client=client)
                    dt = time.perf_counter() - t0
                    print(f"  [PASS] {attr} ({dt:.3f}s)", flush=True)
                    passed += 1
                except Exception as e:
                    dt = time.perf_counter() - t0
                    print(f"  [FAIL] {attr} ({dt:.3f}s): {e}", flush=True)
                    failed += 1

    print("\n" + "=" * 60, flush=True)
    print(f"ZERO PLACEHOLDER RESULTS: {passed} PASSED, {failed} FAILED", flush=True)
    print("=" * 60, flush=True)
    if failed > 0:
        sys.exit(1)
