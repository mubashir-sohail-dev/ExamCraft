# Project Assumptions — ExamCraft AI Assessment Builder

## Overview
This document records all architectural, functional, and domain assumptions made during the design and development of the ExamCraft AI Assessment Builder Flutter application and FastAPI backend.

---

## 1. Platform & Environment Assumptions
1. **Target Operating System**:
   - Primary build target is Android OS (Min SDK API Level 21 / Android 5.0+, Target SDK API Level 34).
   - Generated release artifact is `app-release.apk` (or `app-debug.apk` for debug-signed verification).
2. **Backend Network Location**:
   - Default local API endpoint is assumed to be `http://localhost:8000`.
   - Dynamic base URL reconfiguration is supported at runtime via `SettingsScreen` and `SettingsProvider`.

## 2. Curriculum & Subject Domain Assumptions
1. **Mandatory Subjects**:
   - The core application domain is built around 5 mandatory secondary curriculum subjects:
     - `Physics`
     - `Chemistry`
     - `Mathematics`
     - `Biology`
     - `Computer Science`
2. **Grade Level Scope**:
   - Primary target grade level is Class 9 / Grade 9, with dropdown metadata configuration for Classes 9 through 12.

## 3. Backend & AI Pipeline Assumptions
1. **Vector Database**:
   - Qdrant Vector DB is assumed as the primary vector storage engine holding embedded textbook chunks (`examcraft_class9_textbooks`).
2. **LLM Synthesis**:
   - Google Gemini 1.5 Pro is assumed as the primary multimodal LLM for structured test JSON generation.
3. **Repository Stubs**:
   - Isolated in-memory stubs (`QuestionBankRepository`, `RecentPapersRepository`, `SettingsRepository`) are assumed for endpoints not yet exposed on the backend REST API, allowing client-side UX testing.

## 4. Design & PDF Specification Assumptions
1. **Design System Themes**:
   - `ExamCraft AI` (Light Mode) and `Luminous Material` (Dark Mode) are assumed as the primary visual design systems.
   - Theme toggle persistence is stored across sessions via `ThemeController`.
2. **PDF Paper Layout**:
   - PDF generation assumes standard A4 paper format (Portrait) with 3 sections: Section A (MCQs), Section B (Short Questions), and Section C (Long Questions), followed by an optional Answer Key.
