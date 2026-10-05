# E2E Test Infra: ExamCraft AI Web Application Frontend

## Test Philosophy
- Requirement-driven, opaque-box and grey-box verification derived from `ORIGINAL_REQUEST.md`.
- Verifies exact theme parity, live telemetry, interactive configurator, marks calculation formula, split-screen live synchronization, A4 WYSIWYG rendering with HTML subscript/superscript tags, PDF streaming, local storage persistence, textbook upload flow, and strict zero-error builds.

## Feature Inventory & Test Coverage
| # | Feature | Requirement | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---------|-------------|:------:|:------:|:------:|:------:|
| 1 | Scaffolding & Theme Parity | R1 | 5 | 5 | ✓ | ✓ |
| 2 | Subject Color Tokens & Icons | R1 | 5 | 5 | ✓ | ✓ |
| 3 | Navigation Shell & Drawer | R2 | 5 | 5 | ✓ | ✓ |
| 4 | Live Backend Telemetry Poller | R2 | 5 | 5 | ✓ | ✓ |
| 5 | Test Generator Form & Qdrant | R3 | 5 | 5 | ✓ | ✓ |
| 6 | Question Steppers & Marks Math | R3 | 5 | 5 | ✓ | ✓ |
| 7 | 4-Step Animated Pipeline Screen | R3 | 5 | 5 | ✓ | ✓ |
| 8 | Split-Screen Crafting Studio | R4 | 5 | 5 | ✓ | ✓ |
| 9 | Question Editor & AI Regen | R4 | 5 | 5 | ✓ | ✓ |
| 10 | Live Synchronized A4 Canvas | R4 | 5 | 5 | ✓ | ✓ |
| 11 | PDF Preview & ReportLab Stream | R5 | 5 | 5 | ✓ | ✓ |
| 12 | Question Bank & Recent Papers | R5 | 5 | 5 | ✓ | ✓ |
| 13 | Admin Textbook Upload Flow | R5 | 5 | 5 | ✓ | ✓ |
| 14 | Settings & About Configuration | R5 | 5 | 5 | ✓ | ✓ |
| 15 | Zero-Error Linting & Build | AC | 5 | 5 | ✓ | ✓ |

## Test Architecture
- **Build & Lint Verification**:
  - `npm run lint` (0 ESLint errors, 0 ESLint warnings)
  - `npm run build` (0 TypeScript type errors, 0 Next.js compilation errors)
- **Component & Integration Verification**:
  - Verification of responsive layout, navigation routes, theme switching, telemetry polling hook, marks recalculation logic, A4 canvas HTML rendering, LocalStorage persistence, and PDF download blob handling.

## Real-World Application Scenarios (Tier 4)
1. **Scenario 1**: Teacher creates a 25-mark Chemistry Midterm test (10 MCQs, 5 Short, 1 Long) with dynamic chapters from Qdrant, watches the 4-step generation animation, edits Question 3 in the Studio with instant A4 canvas sync, and exports as ReportLab PDF.
2. **Scenario 2**: Mathematics instructor generates an assessment with specific Exercise 1.2 selection, edits marks in the split-screen studio, confirms the live math recalculates immediately, and saves to Recent Papers.
3. **Scenario 3**: Offline / Degraded resilience: When backend is offline, telemetry badge shows red/amber, poller handles timeout gracefully, and sample demo tests are loaded into the studio with full WYSIWYG editing.
4. **Scenario 4**: Admin uploads a 9th Grade Physics textbook via drag-and-drop, views chunk indexing status, and navigates back to generator with newly indexed chapters.
5. **Scenario 5**: Dark/Light mode toggle preserves readability, exact Flutter theme tokens, and A4 print canvas maintains crisp white paper background with dark print-ready typography in both modes.
