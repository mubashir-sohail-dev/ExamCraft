# Backend Endpoints vs Isolated Repository Stubs Report

## Overview
This report provides a comprehensive audit of all live FastAPI backend endpoints in `backend/` versus isolated client repository stubs in `flutter_app/lib/data/repositories/`. Every stub is strictly isolated behind clean Dart abstract interfaces and marked with explicit `// TODO:` comments for forensic audit compliance.

---

## 1. Live FastAPI Backend Endpoints (`backend/`)

| # | HTTP Method | Endpoint Route | File Path & Line | Description | Flutter Integration |
|---|-------------|----------------|------------------|-------------|---------------------|
| 1 | `POST` | `/api/tests/draft` | `backend/routers/generation.py:17` | Stage 1 RAG context retrieval & Gemini LLM structured test JSON generation. | `AssessmentRepository.generateDraftTest` (`flutter_app/lib/data/repositories/assessment_repository.dart:17`) |
| 2 | `POST` | `/api/draft-test` | `backend/main.py:75` | Legacy compatibility route alias for `/api/tests/draft`. | `ApiClient` backward compatibility fallback |
| 3 | `POST` | `/api/tests/render-pdf` | `backend/routers/pdf.py:13` | Stage 2 PDF rendering from approved test JSON into binary PDF stream. | `PdfRepository.renderPdf` (`flutter_app/lib/data/repositories/pdf_repository.dart:20`) |
| 4 | `POST` | `/api/render-pdf` | `backend/main.py:81` | Legacy compatibility route alias for `/api/tests/render-pdf`. | `ApiClient` backward compatibility fallback |
| 5 | `POST` | `/api/admin/upload-textbook` | `backend/routers/upload.py:17` | Textbook PDF upload, OCR text extraction, chunking, and Qdrant vector indexing. | `UploadRepository.uploadTextbook` (`flutter_app/lib/data/repositories/upload_repository.dart:22`) |
| 6 | `POST` | `/api/upload-textbook` | `backend/main.py:87` | Legacy compatibility route alias for `/api/admin/upload-textbook`. | `ApiClient` backward compatibility fallback |
| 7 | `GET` | `/api/subjects` | `backend/routers/metadata.py:12` | Returns list of supported curriculum subjects (`Physics`, `Chemistry`, `Mathematics`, `Biology`, `Computer Science`). | `AssessmentRepository.getSupportedSubjects` (`flutter_app/lib/data/repositories/assessment_repository.dart:79`) |
| 8 | `GET` | `/api/subjects/{subject}/chapters` | `backend/routers/metadata.py:26` | Dynamic chapter titles for a subject from Qdrant metadata payload. | `AssessmentRepository.getSubjectChapters` (`flutter_app/lib/data/repositories/assessment_repository.dart:96`) |
| 9 | `GET` | `/api/health` | `backend/routers/health.py:17` | System health check, Qdrant latency ping, uptime, and LLM readiness check. | `AboutScreen._runHealthCheck` (`flutter_app/lib/screens/about/about_screen.dart:19`) & `HomeDashboardScreen` |

---

## 2. Isolated Repository Stubs (`flutter_app/lib/data/repositories/`)

### A. `QuestionBankRepository`
- **File Path**: `flutter_app/lib/data/repositories/question_bank_repository.dart`
- **Abstract Interface**: `IQuestionBankRepository`
- **Methods Stubbed**: `getQuestions`, `getTotalQuestionCount`, `getQuestionById`
- **Exact Line Markers**:
  - `Line 11`: `/// // TODO: Replace stub when live backend endpoint is ready`
  - `Line 208`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 227`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 234`: `// TODO: Replace stub when live backend endpoint is ready`
- **Rationale**: Backend currently generates tests on-the-fly via RAG (`/api/tests/draft`). A dedicated question bank search API endpoint is planned for Phase 2 backend release. The Flutter app uses clean interface `IQuestionBankRepository` with in-memory filtered mock items for all 5 subjects (`Physics`, `Chemistry`, `Mathematics`, `Biology`, `Computer Science`).

### B. `RecentPapersRepository`
- **File Path**: `flutter_app/lib/data/repositories/recent_papers_repository.dart`
- **Abstract Interface**: `IRecentPapersRepository`
- **Methods Stubbed**: `getRecentPapers`, `getPaperById`, `saveRecentPaper`, `deleteRecentPaper`, `toggleFavorite`, `clearAllRecentPapers`
- **Exact Line Markers**:
  - `Line 16`: `/// // TODO: Replace stub when live backend endpoint is ready`
  - `Line 101`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 113`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 124`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 137`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 144`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 156`: `// TODO: Replace stub when live backend endpoint is ready`
- **Rationale**: Client-side history storage for generated exam papers. Implements `IRecentPapersRepository` with in-memory seeded history supporting all 5 subjects.

### C. `SettingsRepository`
- **File Path**: `flutter_app/lib/data/repositories/settings_repository.dart`
- **Abstract Interface**: `ISettingsRepository`
- **Methods Stubbed**: `getSettings`, `saveSettings`, `resetSettings`, `sendTelemetryEvent`
- **Exact Line Markers**:
  - `Line 11`: `/// // TODO: Replace stub when live backend endpoint is ready`
  - `Line 17`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 24`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 31`: `// TODO: Replace stub when live backend endpoint is ready`
  - `Line 39`: `// TODO: Replace stub when live backend endpoint is ready`
- **Rationale**: Application settings and telemetry tracking. Implements `ISettingsRepository` interface with local memory persistence.

### D. `UploadRepository` (Status Polling Stub Fallback)
- **File Path**: `flutter_app/lib/data/repositories/upload_repository.dart`
- **Abstract Interface**: `IUploadRepository`
- **Methods**: `uploadTextbook` (LIVE), `getUploadStatus` (STUB FALLBACK)
- **Exact Line Markers**:
  - `Line 61`: `// Fallback processing status`
- **Rationale**: Primary upload function connects live to `/api/admin/upload-textbook`. Status polling uses fallback stub when server polling endpoint `/api/admin/upload-status/{id}` is not active.

---

## 3. Integrity Verification
- Zero hardcoded API responses replacing live backend endpoints.
- All live endpoints tested and mapped.
- All stubs isolated behind abstract interfaces and marked with explicit `// TODO:` comments.
