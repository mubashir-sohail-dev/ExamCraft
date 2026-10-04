# Known Deviations & Technical Enhancements

## Overview
This document records minor known deviations and architectural enhancements between the original Stitch HTML specs/backend REST schemas and the final implemented Flutter application. All deviations represent deliberate usability or technical compatibility enhancements.

---

## 1. Route Naming Dual Aliases
- **Original Spec**: Stitch HTML specification references hyphenated paths (e.g. `/question-bank`, `/recent-papers`, `/pdf-preview`, `/upload/textbook`, `/generate/processing`, `/home/dashboard`).
- **Initial Code Base**: Early Flutter constants used underscore paths (e.g. `/question_bank`, `/recent_papers`, `/pdf_preview`).
- **Resolution & Enhancement**: `AppRoutes.routesMap` was updated to explicitly map **both** hyphenated and underscore route aliases to their respective screen builders. This ensures zero dead ends or 404 errors regardless of which navigation pattern is called.

## 2. Subject Enum Serialization
- **FastAPI Backend**: Backend Pydantic models expect exact strings (`Physics`, `Chemistry`, `Mathematics`, `Biology`, `Computer Science`).
- **Flutter App**: Flutter uses typed `ExamSubject` enum.
- **Resolution & Enhancement**: `SubjectUtils.apiString` and `SubjectUtils.tryParse` provide bidirectional mapping, ensuring 100% data fidelity when querying `/api/subjects` or posting to `/api/tests/draft`.

## 3. Interactive PDF Preview Canvas
- **Original Stitch Spec**: Fixed-width HTML container view.
- **Flutter Implementation**: `PdfPreviewScreen` wraps the A4 document canvas in Flutter's `InteractiveViewer`, providing pinch-to-zoom (0.5x to 3.0x), reset zoom, page indicators, and export bottom sheet.

## 4. Global Theme Toggle Action
- **Stitch Spec**: Theme toggle was presented on settings or specific screen variants.
- **Flutter Implementation**: Added a global light/dark theme toggle icon to the standard `AppBar` on all screens, backed by persistent `ThemeController` state, allowing immediate theme switching anywhere in the app.
