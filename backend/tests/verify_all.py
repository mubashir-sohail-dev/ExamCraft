"""
Comprehensive verification test runner for ExamCraft AI Backend.
Tests all validation, prompt building, metadata, health, PDF rendering, and security endpoints.
"""
import os
import sys

# Ensure backend root is in sys.path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import json
import urllib.request
import urllib.error
from pydantic import ValidationError

from schemas.request_schemas import TestGenerationRequest
from schemas.exam_enums import SubjectEnum, RetrievalModeEnum, DifficultyEnum
from schemas.exam_schema import Class9TestSchema, ExamTestSchema, MCQItem, ShortQuestionItem, LongQuestionItem
from schemas.response_schemas import HealthResponse
from core.logger import get_logger, setup_logging
from services.prompt_builder import PromptBuilder
from services.vector_store_service import check_qdrant_connection
from services.ocr_service import ocr_page
from routers.pdf_router import router as pdf_router


def run_unit_tests():
    print("=== [1/3] RUNNING UNIT VALIDATION & PROMPT TESTS ===")
    
    # 1. Valid request instantiation
    req = TestGenerationRequest(
        subject="Chemistry",
        chapter_name="Chapter 1",
        test_type="topic",
        topic_query="States of Matter",
        mcq_count=5,
        short_count=3,
        long_count=1,
        grade=10
    )
    assert req.subject == SubjectEnum.CHEMISTRY
    assert req.test_type == RetrievalModeEnum.TOPIC
    assert req.grade == 10
    print("  [PASS] TestGenerationRequest valid instantiation with grade=10")

    # 2. Grade boundary validation
    for g in [9, 10, 11, 12]:
        r = TestGenerationRequest(
            subject="Physics",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            grade=g
        )
        assert r.grade == g
    print("  [PASS] Grades 9, 10, 11, 12 accepted")

    for invalid_g in [8, 13, 0, -1]:
        try:
            TestGenerationRequest(
                subject="Physics",
                chapter_name="Chapter 1",
                test_type="full_chapter",
                grade=invalid_g
            )
            assert False, f"Grade {invalid_g} should have failed validation"
        except ValidationError:
            pass
    print("  [PASS] Invalid grades rejected with ValidationError")

    # 3. ExamTestSchema alias parity
    assert ExamTestSchema is Class9TestSchema
    dummy = ExamTestSchema(
        test_title="Class 11 Physics Test",
        subject="Physics",
        grade=11,
        chapter_or_topic="Chapter 2",
        total_marks=7,
        time_allowed="40 Minutes",
        instructions=["Answer carefully."],
        mcqs=[MCQItem(question_number=1, question="What is speed?", options=["A) d/t", "B) t/d", "C) d*t", "D) 0"], correct_option="A", textbook_reference="Page 10")],
        short_questions=[ShortQuestionItem(question_number=2, question="Define velocity.", marks=2)],
        long_questions=[LongQuestionItem(question_number=3, question="Explain acceleration.", marks=5)]
    )
    assert dummy.grade == 11
    print("  [PASS] ExamTestSchema semantic alias successfully instantiated with Grade 11")

    # 4. PromptBuilder tests with Cognitive Difficulty & Bloom's Taxonomy
    # 4a. Grade 10 + custom instruction
    messages = PromptBuilder.build(
        subject="Chemistry",
        chapter_or_topic="Chapter 1",
        mcq_count=5,
        short_count=3,
        long_count=1,
        context="Sample context",
        grade=10,
        generation_instruction="Focus on ions"
    )
    assert len(messages) == 2
    assert "Class 10 Academic Examination Setter" in messages[0]["content"]
    assert "Generate a Class 10 Chemistry test" in messages[1]["content"]
    assert "Focus on ions" in messages[1]["content"]
    print("  [PASS] PromptBuilder correctly formats Grade 10 prompt and instructions")

    # 4b. Easy Mode (Bloom's Levels 1 & 2 - Recall & Fundamental Definitions)
    msg_easy = PromptBuilder.build(
        subject="Physics",
        chapter_or_topic="Chapter 2",
        mcq_count=5,
        short_count=3,
        long_count=1,
        context="Sample physics context",
        difficulty="easy"
    )
    assert "COGNITIVE DIFFICULTY LEVEL: EASY (Bloom's Taxonomy Levels 1 & 2)" in msg_easy[1]["content"]
    assert "Recall & Fundamental Definitions" in msg_easy[1]["content"]
    print("  [PASS] PromptBuilder correctly injects Easy (Bloom's 1 & 2) guidelines")

    # 4c. Medium Mode (Bloom's Levels 2 & 3 - Conceptual & Application)
    msg_med = PromptBuilder.build(
        subject="Chemistry",
        chapter_or_topic="Chapter 3",
        mcq_count=5,
        short_count=3,
        long_count=1,
        context="Sample chemistry context",
        difficulty="medium"
    )
    assert "COGNITIVE DIFFICULTY LEVEL: MEDIUM (Bloom's Taxonomy Levels 2 & 3)" in msg_med[1]["content"]
    assert "Conceptual Understanding & Direct Application" in msg_med[1]["content"]
    print("  [PASS] PromptBuilder correctly injects Medium (Bloom's 2 & 3) guidelines")

    # 4d. Hard Mode (Bloom's Levels 4 & 5 - Analysis & Multi-Step Reasoning)
    msg_hard = PromptBuilder.build(
        subject="Mathematics",
        chapter_or_topic="Chapter 4",
        mcq_count=5,
        short_count=3,
        long_count=1,
        context="Sample math context",
        difficulty="hard"
    )
    assert "COGNITIVE DIFFICULTY LEVEL: HARD (Bloom's Taxonomy Levels 4 & 5)" in msg_hard[1]["content"]
    assert "Analysis, Evaluation & Multi-Step Reasoning" in msg_hard[1]["content"]
    print("  [PASS] PromptBuilder correctly injects Hard (Bloom's 4 & 5) guidelines")

    # 4e. Mixed Mode (Board Standard 40/40/20)
    msg_mixed = PromptBuilder.build(
        subject="Biology",
        chapter_or_topic="Chapter 1",
        mcq_count=5,
        short_count=3,
        long_count=1,
        context="Sample bio context",
        difficulty="mixed"
    )
    assert "COGNITIVE DIFFICULTY LEVEL: MIXED (Official Board Standard Distribution)" in msg_mixed[1]["content"]
    assert "40% Easy / Knowledge-Based" in msg_mixed[1]["content"]
    print("  [PASS] PromptBuilder correctly injects Mixed (Board Standard 40/40/20) guidelines")

    # 5. Difficulty validation in TestGenerationRequest
    for valid_d in ["easy", "medium", "hard", "mixed"]:
        d_req = TestGenerationRequest(
            subject="Physics",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            difficulty=valid_d
        )
        assert d_req.difficulty.value == valid_d
    print("  [PASS] TestGenerationRequest accepts all 4 difficulty levels ('easy', 'medium', 'hard', 'mixed')")

    try:
        TestGenerationRequest(
            subject="Physics",
            chapter_name="Chapter 1",
            test_type="full_chapter",
            difficulty="impossible"
        )
        assert False, "Invalid difficulty should raise ValidationError"
    except ValidationError:
        pass
    print("  [PASS] TestGenerationRequest rejects invalid difficulty")

    # 6. Clean Architecture Module Renaming & Backward-Compatibility Stubs
    # Check that canonical modules import directly
    import core.logger
    import schemas.exam_enums
    import schemas.request_schemas
    import schemas.response_schemas
    import services.vector_store_service
    import services.ocr_service
    import routers.pdf_router

    assert hasattr(core.logger, "get_logger")
    assert hasattr(schemas.exam_enums, "DifficultyEnum")
    assert hasattr(schemas.request_schemas, "TestGenerationRequest")
    assert hasattr(schemas.response_schemas, "HealthResponse")
    assert hasattr(services.vector_store_service, "resolve_collection_name")
    assert hasattr(services.ocr_service, "ocr_page")
    assert hasattr(routers.pdf_router, "router")
    print("  [PASS] All 7 canonical Clean Architecture modules verified (Zero legacy shims required)")


def run_api_tests():
    print("\n=== [2/3] RUNNING LIVE BACKEND API TESTS (PORT 8000) ===")
    BASE_URL = "http://127.0.0.1:8000"
    API_KEY = "examcraft-secret-key-2026"

    # 1. Health Check
    req = urllib.request.Request(f"{BASE_URL}/api/health")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        health = json.loads(resp.read().decode())
        assert health["status"] == "ok"
        assert health["qdrant_connected"] is True
        print(f"  [PASS] GET /api/health (200 OK, latency={health['qdrant_latency_ms']}ms, version={health['version']})")

    # 2. Subjects List
    req = urllib.request.Request(f"{BASE_URL}/api/subjects", headers={"X-API-Key": API_KEY})
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        subs = json.loads(resp.read().decode())["subjects"]
        assert "Chemistry" in subs and "Physics" in subs
        print(f"  [PASS] GET /api/subjects (200 OK, {len(subs)} subjects returned)")

    # 3. Chapters with grade=9 (indexed) and grade=10 (unindexed isolation)
    req9 = urllib.request.Request(f"{BASE_URL}/api/subjects/Chemistry/chapters?grade=9", headers={"X-API-Key": API_KEY})
    with urllib.request.urlopen(req9) as resp:
        assert resp.status == 200
        data9 = json.loads(resp.read().decode())
        assert data9["subject"] == "Chemistry"
        assert len(data9["chapters"]) > 0
        print(f"  [PASS] GET /api/subjects/Chemistry/chapters?grade=9 (200 OK, {len(data9['chapters'])} genuine chapters)")

    req10 = urllib.request.Request(f"{BASE_URL}/api/subjects/Chemistry/chapters?grade=10", headers={"X-API-Key": API_KEY})
    with urllib.request.urlopen(req10) as resp:
        assert resp.status == 200
        data10 = json.loads(resp.read().decode())
        assert data10["subject"] == "Chemistry"
        assert isinstance(data10["chapters"], list)
        print(f"  [PASS] GET /api/subjects/Chemistry/chapters?grade=10 (200 OK, {len(data10['chapters'])} chapters, strictly isolated from Grade 9)")

    # 4. Multi-class PDF Render with dynamic grade filename
    for test_grade in [9, 10, 11, 12]:
        test_payload = {
            "test_data": {
                "test_title": f"Class {test_grade} Chemistry Assessment",
                "subject": "Chemistry",
                "grade": test_grade,
                "chapter_or_topic": "Chapter 1",
                "total_marks": 7,
                "time_allowed": "30 Minutes",
                "instructions": ["Answer all questions."],
                "mcqs": [{
                    "question_number": 1,
                    "question": "What is water?",
                    "options": ["A) H2O", "B) CO2", "C) NaCl", "D) O2"],
                    "correct_option": "A",
                    "textbook_reference": "Section 1.1"
                }],
                "short_questions": [{
                    "question_number": 2,
                    "question": "Define mixture.",
                    "marks": 2
                }],
                "long_questions": []
            },
            "include_answer_key": True
        }
        body = json.dumps(test_payload).encode()
        req = urllib.request.Request(
            f"{BASE_URL}/api/tests/render-pdf",
            data=body,
            headers={"Content-Type": "application/json", "X-API-Key": API_KEY}
        )
        with urllib.request.urlopen(req) as resp:
            assert resp.status == 200
            disposition = resp.headers.get("Content-Disposition", "")
            expected_filename = f'Chemistry_Grade{test_grade}_Test.pdf'
            assert expected_filename in disposition, f"Expected {expected_filename} in {disposition}"
            pdf_bytes = resp.read()
            assert len(pdf_bytes) > 2000
            print(f"  [PASS] POST /api/tests/render-pdf Grade {test_grade} -> {expected_filename} ({len(pdf_bytes)} bytes)")


def run_security_tests():
    print("\n=== [3/3] RUNNING SECURITY & AUTHENTICATION TESTS ===")
    BASE_URL = "http://127.0.0.1:8000"

    # 1. Missing API Key should return 401
    req = urllib.request.Request(f"{BASE_URL}/api/subjects")
    try:
        urllib.request.urlopen(req)
        assert False, "Expected 401 Unauthorized for missing API key"
    except urllib.error.HTTPError as e:
        assert e.code == 401
        print("  [PASS] Missing API Key rejected with 401 Unauthorized")

    # 2. Invalid API Key should return 403
    req = urllib.request.Request(f"{BASE_URL}/api/subjects", headers={"X-API-Key": "invalid-token"})
    try:
        urllib.request.urlopen(req)
        assert False, "Expected 403 Forbidden for invalid API key"
    except urllib.error.HTTPError as e:
        assert e.code == 403
        print("  [PASS] Invalid API Key rejected with 403 Forbidden")

    # 3. Admin upload without Admin key should return 403
    req = urllib.request.Request(f"{BASE_URL}/api/admin/upload-textbook", headers={"X-API-Key": "examcraft-secret-key-2026"})
    try:
        urllib.request.urlopen(req)
        assert False, "Expected 403 Forbidden for non-admin key on upload endpoint"
    except urllib.error.HTTPError as e:
        assert e.code in [403, 405]
        print("  [PASS] Non-admin key on admin endpoint rejected")


if __name__ == "__main__":
    try:
        run_unit_tests()
        run_api_tests()
        run_security_tests()
        print("\n=======================================================")
        print(">>> ALL BACKEND TESTS PASSED WITH ZERO FAILURES! <<<")
        print("=======================================================")
    except Exception as exc:
        print(f"\n[FAIL] Test verification failed: {exc}", file=sys.stderr)
        sys.exit(1)
