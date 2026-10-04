import sys
import os
import pytest

# Ensure backend root is in sys.path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

if __name__ == "__main__":
    test_args = [
        "-v",
        "-s",
        "--tb=short",
        os.path.join(backend_dir, "tests", "test_validation.py"),
        os.path.join(backend_dir, "tests", "test_prompt_harness.py"),
        os.path.join(backend_dir, "tests", "test_context_pruning.py"),
        os.path.join(backend_dir, "tests", "test_concurrency_llm.py"),
        os.path.join(backend_dir, "tests", "test_zero_placeholder.py"),
        os.path.join(backend_dir, "tests", "test_endpoints.py"),
        os.path.join(backend_dir, "tests", "test_legacy.py"),
        os.path.join(backend_dir, "tests", "test_metadata.py"),
        os.path.join(backend_dir, "tests", "test_health.py"),
        os.path.join(backend_dir, "tests", "test_security.py"),
    ]
    print(f"Running pytest with args: {test_args}", flush=True)
    exit_code = pytest.main(test_args)
    print(f"\nPytest exited with code: {exit_code}", flush=True)
    sys.exit(exit_code)
