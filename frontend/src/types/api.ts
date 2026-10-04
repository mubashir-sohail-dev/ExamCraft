/**
 * src/types/api.ts
 * ExamCraft AI - FastAPI REST API Contracts & Settings
 */

import { Class9TestSchema, SubjectType, DifficultyLevel, RetrievalMode } from "./exam";

/**
 * Request payload for POST /api/tests/draft
 * Mirrors backend/schemas/requests.py::TestGenerationRequest
 */
export interface TestGenerationRequest {
  subject: SubjectType | string;
  grade?: number; // 9, 10, 11, or 12
  chapter_name: string;
  test_type: RetrievalMode;
  topic_query?: string | null;
  mcq_count?: number; // 1 - 20, default 5
  short_count?: number; // 0 - 10, default 3
  long_count?: number; // 0 - 5, default 1
  include_answer_key?: boolean; // default true
  exercise?: string | null; // e.g. "Exercise 1.2" for Mathematics
  generation_instruction?: string | null; // max 2000 chars
  difficulty?: DifficultyLevel;
}

/**
 * Request payload for POST /api/tests/render-pdf
 * Mirrors backend/schemas/requests.py::PDFRenderRequest
 */
export interface PDFRenderRequest {
  test_data: Class9TestSchema;
  include_answer_key?: boolean; // default true
}

/**
 * Response model for GET /api/health
 * Mirrors backend/schemas/responses.py::HealthResponse
 */
export interface HealthResponse {
  status: "ok" | "degraded";
  qdrant_connected: boolean;
  version: string;
  environment: string;
  uptime_seconds: number;
  timestamp: string;
  qdrant_latency_ms?: number | null;
  collection_exists?: boolean;
  llm_available?: boolean;
}

/**
 * Response model for GET /api/subjects
 * Mirrors backend/schemas/responses.py::SubjectListResponse
 */
export interface SubjectListResponse {
  subjects: string[];
}

/**
 * Response model for GET /api/subjects/{subject}/chapters
 * Mirrors backend/schemas/responses.py::ChapterListResponse
 */
export interface ChapterListResponse {
  subject: string;
  chapters: string[];
}

/**
 * Response model for GET /api/subjects/{subject}/chapters/{chapter}/metadata
 * Mirrors backend/schemas/responses.py::ChapterMetadataResponse
 */
export interface ChapterMetadataResponse {
  subject: string;
  chapter: string;
  exercises: string[];
  sections: string[];
  topics: string[];
}

/**
 * Response model for POST /api/admin/upload-textbook
 * Mirrors backend/schemas/responses.py::TextbookUploadResponse
 */
export interface TextbookUploadResponse {
  status: "success" | "failed" | string;
  message: string;
  subject?: string;
  grade?: string | number;
  chunks_indexed: number;
  chapters_detected?: number | string[];
  exercises_detected?: number;
  duplicates_skipped?: number;
  filename?: string;
  collection_name?: string;
  processing_time_seconds?: number;
  detected_chapters?: string[];
}

export interface UploadJobAcceptedResponse {
  status: "accepted";
  job_id: string;
  filename: string;
  subject: string;
  grade: number;
  target_collection: string;
  message: string;
  stream_url: string;
  status_url: string;
}

export interface IngestionLogEntry {
  timestamp: string;
  level: "INFO" | "SUCCESS" | "WARN" | "ERROR";
  message: string;
}

export interface IngestionJobSnapshot {
  job_id: string;
  filename: string;
  subject: string;
  grade: number;
  chapter_name?: string;
  target_collection: string;
  status: "queued" | "extracting" | "chunking" | "embedding" | "indexing" | "completed" | "failed" | "cancelled";
  progress_percent: number;
  current_page: number;
  total_pages: number;
  chunks_indexed: number;
  stage_message: string;
  elapsed_seconds: number;
  started_at: string;
  updated_at: string;
  completed_at?: string;
  error?: string;
  result?: {
    status: string;
    filename: string;
    subject: string;
    grade: number;
    chunks_indexed: number;
    duplicates_skipped: number;
    chapters_detected: number;
    exercises_detected: number;
    collection: string;
    duration_seconds: number;
  };
  logs: IngestionLogEntry[];
}

export interface ApiErrorDetail {
  loc: (string | number)[];
  msg: string;
  type: string;
}

/**
 * Standardized API Error Response
 */
export interface ApiErrorResponse {
  success?: boolean;
  error?: string;
  message: string;
  status_code?: number;
  detail?: string | ApiErrorDetail[];
}

/**
 * Client Configuration & Preferences stored in LocalStorage
 */
export interface AppSettings {
  apiBaseUrl: string; // default "http://localhost:8000"
  clientApiKey: string; // default "examcraft-secret-key-2026"
  adminApiKey: string; // default "examcraft-admin-key-2026"
  theme: "light" | "dark" | "system";
  defaultSubject: SubjectType | string;
  defaultGrade?: number; // default 9 (supports 9, 10, 11, 12)
  enableTelemetry: boolean;
  enableMockFallback: boolean; // gracefully fallback to sample data if backend unreachable
  pollingIntervalMs: number; // default 30000 (30s)
}
