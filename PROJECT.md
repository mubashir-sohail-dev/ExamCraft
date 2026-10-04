# Project: ExamCraft AI Web Application Frontend

## Architecture
Next.js 15 (App Router, React 19, TypeScript) client-side and server-rendered web application located in `frontend/` interfacing with the FastAPI backend (`http://localhost:8000/api`).
- **Styling & Design System**: Tailwind CSS v3/v4 with HSL design tokens, exact Material 3 & color parity with Flutter mobile app (`flutter_app/`), NextThemes (`light`/`dark`), Lucide React icons.
- **Subject Tokens**: Dedicated tokens for 5 core subjects:
  - Physics: `#005BBF` (light) / `#ADC7FF` (dark) — Atom
  - Chemistry: `#006E2C` (light) / `#86F898` (dark) — TestTube2
  - Mathematics: `#805600` (light) / `#FFBA45` (dark) — Calculator
  - Biology: `#673AB7` (light) / `#D1C4E9` (dark) — Dna
  - Computer Science: `#00838F` (light) / `#80DEEA` (dark) — Laptop
- **State Management & Storage**: Reactive Zustand/React context store for live draft tests with immediate synchronization between Question Editor and Live WYSIWYG A4 Canvas; LocalStorage persistence for recent papers, saved questions, and settings.
- **Backend Telemetry & Client**: Centralized Axios/Fetch client handling `X-API-Key` headers (`examcraft-secret-key-2026` / `examcraft-admin-key-2026`), 30s background health poller (`GET /api/health`), and graceful offline/degraded fallbacks.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Next.js 15 App Router Scaffolding | Base Next.js 15 setup in `frontend/` with `src/`, TS, ESLint, PostCSS | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Tailwind CSS & Theme Parity | Light/Dark color palettes, surface containers, borders, exact Flutter app parity | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Subject Color & Icon Tokens | Physics, Chemistry, Math, Biology, Computer Science tokens and Lucide icons | M1 | ORIGINAL_REQUEST §R1 |
| 4 | UI Primitive Component Library | Buttons, Cards, Dialogs, Inputs, Badges, Tabs, Sliders, Switches, Steppers | M1 | ORIGINAL_REQUEST §R1 |
| 5 | TypeScript Schemas & API Client | Strict types derived from FastAPI Pydantic models, error handling, API client | M1 | ORIGINAL_REQUEST §R1 |
| 6 | Responsive Navigation Shell | Collapsible Sidebar (desktop) & Drawer (mobile) with route highlights | M2 | ORIGINAL_REQUEST §R2 |
| 7 | Application Routing & Layout | Routes for /, /dashboard, /generate, /review, /pdf-preview, /question-bank, /recent-papers, /upload, /upload/status, /settings, /about | M2 | ORIGINAL_REQUEST §R2 |
| 8 | Live Backend Telemetry Header | 30s background poller for `GET /api/health`, latency in ms, status dot badge | M2 | ORIGINAL_REQUEST §R2 |
| 9 | Global Theme Switcher | Smooth light/dark mode switcher with persistence | M2 | ORIGINAL_REQUEST §R2 |
| 10 | Interactive Test Configurator | `/generate` page: Subject selector, dynamic chapter/exercise dropdowns, topic query | M3 | ORIGINAL_REQUEST §R3 |
| 11 | Question Count Steppers & Live Marks Calculator | Steppers for MCQs (1m), Short (2m), Long (5m), live marks calculation rule `(M*1)+(S*2)+(L*5)` | M3 | ORIGINAL_REQUEST §R3 |
| 12 | Difficulty Chips, Instructions & Answer Key | Difficulty selector (Easy/Medium/Hard/Mixed), teacher custom prompt, answer key toggle | M3 | ORIGINAL_REQUEST §R3 |
| 13 | Animated 4-Step Generation Screen | 4 pipeline stages matching Flutter app (Searching KB, Context Extraction, Synthesizing AI, Assembly), progress bar, status, CTA to /review | M3 | ORIGINAL_REQUEST §R3 |
| 14 | Split-Screen Studio Layout | `/review` page: 2-pane desktop layout with collapsible panels | M4 | ORIGINAL_REQUEST §R4 |
| 15 | Interactive Question Editor | Question cards, edit modal, single question AI regen, delete, reorder, auto-renumbering | M4 | ORIGINAL_REQUEST §R4 |
| 16 | Live WYSIWYG A4 Canvas | Real-time synchronized A4 print preview with exact margins, header, 2x2 MCQs, sub/sup math/chem HTML, answer key appendix | M4 | ORIGINAL_REQUEST §R4 |
| 17 | Real-Time Marks Recalculation | Dynamic recalculation of total marks and section breakdowns upon question changes | M4 | ORIGINAL_REQUEST §R4 |
| 18 | PDF Preview & ReportLab Streamer | `/pdf-preview` calling `POST /api/tests/render-pdf`, in-browser PDF viewer, download & print | M5 | ORIGINAL_REQUEST §R5 |
| 19 | Question Bank & Recent Papers | LocalStorage saved questions, recent generated papers list, search, filters, export | M5 | ORIGINAL_REQUEST §R5 |
| 20 | Admin Textbook Upload | Drag-and-drop upload calling `POST /api/admin/upload-textbook`, indexing progress, status page | M5 | ORIGINAL_REQUEST §R5 |
| 21 | Settings & About Pages | Backend URL & API key configuration, cache reset, version, architecture details | M5 | ORIGINAL_REQUEST §R5 |
| 22 | E2E Integration, Linting & Build Verification | Strict ESLint check (0 errors, 0 warnings) and Next.js production build (`npm run build`) | M6 | ORIGINAL_REQUEST §Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Project Scaffolding & Design System | Next.js 15, Tailwind, Theme Tokens, UI Primitives, TS Schemas, API Client | none | DONE |
| 2 | M2: Navigation Shell & Live Telemetry | Shell layout, Sidebar, Drawer, Top Header, 30s Telemetry Poller, Theme Toggle, Route Stubs | M1 | DONE |
| 3 | M3: Test Generation & 4-Step Pipeline | `/generate` configurator form, dynamic Qdrant metadata, steppers, marks math, 4-step animated generating screen, draft API call | M1, M2 | DONE |
| 4 | M4: Split-Screen Studio & WYSIWYG A4 Canvas | `/review` split-screen, Question editor cards, Modal editor, AI regen, renumbering, live real-time synchronized A4 canvas | M1, M2, M3 | DONE |
| 5 | M5: PDF Preview, Question Bank, Upload & Settings | `/pdf-preview` ReportLab streaming viewer, `/question-bank`, `/recent-papers`, `/upload` & `/upload/status`, `/settings`, `/about` | M1, M2, M3, M4 | DONE |
| 6 | M6: E2E Integration, Strict Lint & Production Build | Complete E2E integration test suite, `npm run lint` (0 errors/warnings), `npm run build` (0 errors), adversarial verification | M1, M2, M3, M4, M5 | DONE |

## Code Layout
```
frontend/
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── postcss.config.mjs
├── next.config.ts
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx                       # Landing / Home
│   │   ├── dashboard/page.tsx             # Overview & Quick Actions
│   │   ├── generate/page.tsx              # Interactive Configurator & 4-Step Pipeline
│   │   ├── review/page.tsx                # Split-Screen Studio & Live A4 Canvas
│   │   ├── pdf-preview/page.tsx           # ReportLab PDF In-Browser Viewer
│   │   ├── question-bank/page.tsx         # Question Bank Explorer
│   │   ├── recent-papers/page.tsx         # Saved Papers & History
│   │   ├── upload/page.tsx                # Admin Drag & Drop Textbook Ingestion
│   │   ├── upload/status/page.tsx         # Ingestion Progress & Metadata
│   │   ├── settings/page.tsx              # Backend URL & API Key Config
│   │   ├── about/page.tsx                 # Architecture & System Info
│   │   └── globals.css                    # Tailwind & Subject HSL variables
│   ├── components/
│   │   ├── shell/                         # Sidebar, Drawer, Header, TelemetryBadge, ThemeToggle
│   │   ├── ui/                            # Button, Card, Dialog, Input, Slider, Switch, Badge, Tabs, Stepper
│   │   ├── studio/                        # QuestionCard, QuestionEditModal, A4Canvas, QuestionRegenModal
│   │   ├── generate/                      # SubjectSelector, ChapterDropdown, StepProgress, StepperControls
│   │   └── shared/                        # HtmlRenderer (sub/sup), SubjectBadge, StatusBadge, EmptyState
│   ├── context/
│   │   ├── TestDraftContext.tsx           # Active test draft state & real-time sync
│   │   └── TelemetryContext.tsx           # 30s backend health poller & latency tracker
│   ├── lib/
│   │   ├── api.ts                         # Centralized Axios/Fetch API client with fallbacks
│   │   ├── constants.ts                   # Subject themes, tokens, colors, 4-step pipeline constants
│   │   ├── storage.ts                     # LocalStorage manager (recent tests, questions, settings)
│   │   ├── utils.ts                       # cn helper, marks calculator, question renumbering
│   │   └── sample-data.ts                 # Realistic mock papers for offline/demo resilience
│   └── types/
│       ├── api.ts                         # Backend request/response types
│       └── exam.ts                        # Exam schemas, MCQ, Short, Long, SubjectEnum
```
