import sys
import os
import asyncio
import inspect
import time

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import tests.test_validation as tv
import tests.test_prompt_harness as tph
import tests.test_context_pruning as tcp
import tests.test_concurrency_llm as tcl

def run_core_tests():
    print("=" * 60, flush=True)
    print("RUNNING BACKEND CONCURRENCY & PRUNING CORE TEST SUITES", flush=True)
    print("=" * 60, flush=True)

    modules = [
        ("Validation Suite", tv),
        ("Prompt Harness Suite", tph),
        ("Context Pruning Suite", tcp),
        ("Concurrency LLM Suite", tcl),
    ]

    total_passed = 0
    total_failed = 0

    for name, mod in modules:
        print(f"\n[{name}]", flush=True)
        for attr in sorted(dir(mod)):
            if attr.startswith("test_"):
                func = getattr(mod, attr)
                if callable(func):
                    t0 = time.perf_counter()
                    try:
                        if inspect.iscoroutinefunction(func):
                            asyncio.run(func())
                        else:
                            func()
                        dt = time.perf_counter() - t0
                        print(f"  [PASS] {attr} ({dt:.3f}s)", flush=True)
                        total_passed += 1
                    except Exception as e:
                        dt = time.perf_counter() - t0
                        print(f"  [FAIL] {attr} ({dt:.3f}s): {e}", flush=True)
                        total_failed += 1

    print("\n" + "=" * 60, flush=True)
    print(f"CORE RESULTS: {total_passed} PASSED, {total_failed} FAILED", flush=True)
    print("=" * 60, flush=True)
    if total_failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_core_tests()
