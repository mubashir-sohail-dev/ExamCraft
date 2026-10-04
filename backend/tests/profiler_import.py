import sys
import os
import time

def profile_import(name, func):
    t0 = time.perf_counter()
    func()
    t1 = time.perf_counter()
    print(f"Import {name}: {t1 - t0:.2f}s", flush=True)

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

profile_import("fastapi", lambda: __import__("fastapi"))
profile_import("core.config", lambda: __import__("core.config"))
profile_import("schemas.exam_schema", lambda: __import__("schemas.exam_schema"))
profile_import("services.prompt_builder", lambda: __import__("services.prompt_builder"))
profile_import("services.llm_service", lambda: __import__("services.llm_service"))
profile_import("routers.generation", lambda: __import__("routers.generation"))
profile_import("main", lambda: __import__("main"))
profile_import("tests.test_validation", lambda: __import__("tests.test_validation"))
profile_import("tests.test_prompt_harness", lambda: __import__("tests.test_prompt_harness"))
profile_import("tests.test_context_pruning", lambda: __import__("tests.test_context_pruning"))
profile_import("tests.test_concurrency_llm", lambda: __import__("tests.test_concurrency_llm"))
profile_import("tests.test_zero_placeholder", lambda: __import__("tests.test_zero_placeholder"))
