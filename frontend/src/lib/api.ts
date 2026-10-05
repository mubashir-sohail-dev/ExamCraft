/**
 * src/lib/api.ts
 * ExamCraft AI - Centralized HTTP & API Service Client
 */

import axios, { AxiosInstance, AxiosResponse, AxiosError } from "axios";
import {
  HealthResponse,
  SubjectListResponse,
  ChapterListResponse,
  ChapterMetadataResponse,
  TestGenerationRequest,
  PDFRenderRequest,
  UploadJobAcceptedResponse,
  IngestionJobSnapshot,
  ApiErrorResponse,
  ApiErrorDetail,
} from "@/types/api";
import { Class9TestSchema } from "@/types/exam";
import { getSettings, storage } from "./storage";
import {
  DEFAULT_API_URL,
  DEFAULT_CLIENT_KEY,
} from "./constants";
import {
  getMockHealth,
  getMockSubjects,
} from "./sample-data";

/**
 * Standardized typed API error representation
 */
export class ApiError extends Error {
  public statusCode?: number;
  public errorType?: string;
  public detail?: unknown;
  public isNetworkError?: boolean;
  public isTimeout?: boolean;

  constructor(
    message: string,
    optionsOrErrorType?:
      | string
      | {
          statusCode?: number;
          errorType?: string;
          detail?: unknown;
          isNetworkError?: boolean;
          isTimeout?: boolean;
        },
    statusCode?: number,
    detail?: unknown,
    isNetworkError?: boolean,
    isTimeout?: boolean
  ) {
    super(message);
    this.name = "ApiError";
    if (typeof optionsOrErrorType === "object" && optionsOrErrorType !== null) {
      this.errorType = optionsOrErrorType.errorType;
      this.statusCode = optionsOrErrorType.statusCode;
      this.detail = optionsOrErrorType.detail;
      this.isNetworkError = optionsOrErrorType.isNetworkError;
      this.isTimeout = optionsOrErrorType.isTimeout;
    } else {
      this.errorType = optionsOrErrorType;
      this.statusCode = statusCode;
      this.detail = detail;
      this.isNetworkError = isNetworkError;
      this.isTimeout = isTimeout;
    }
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}

/**
 * Robust error message extractor and formatter
 */
export function getApiErrorMessage(
  err: unknown,
  fallback = "An unexpected error occurred."
): string {
  if (err instanceof ApiError) return err.message;
  if (err instanceof Error) return err.message;
  if (typeof err === "object" && err !== null) {
    const record = err as Record<string, unknown>;
    if (typeof record.message === "string" && record.message.trim()) {
      return record.message;
    }
    if (typeof record.detail === "string" && record.detail.trim()) {
      return record.detail;
    }
    if (Array.isArray(record.detail)) {
      return record.detail
        .map((d: unknown) => {
          if (typeof d === "object" && d !== null) {
            const det = d as { loc?: (string | number)[]; msg?: string };
            if (det.msg) {
              const loc = Array.isArray(det.loc)
                ? det.loc.filter((part) => part !== "body").join(".")
                : "";
              return loc ? `${loc}: ${det.msg}` : det.msg;
            }
          }
          return String(d);
        })
        .join("; ");
    }
    if (typeof record.error === "string" && record.error.trim()) {
      return record.error;
    }
  }
  if (typeof err === "string" && err.trim()) return err;
  return fallback;
}

class ApiClient {
  private instance: AxiosInstance;

  constructor() {
    this.instance = axios.create({
      baseURL: DEFAULT_API_URL,
      timeout: 60000,
      headers: {
        "Content-Type": "application/json",
      },
    });

    // Request interceptor: Dynamic base URL, Auth headers, Correlation ID
    this.instance.interceptors.request.use(
      (config) => {
        const settings = getSettings();
        if (settings.apiBaseUrl) {
          config.baseURL = settings.apiBaseUrl.trim().replace(/\/+$/, "");
        }

        // Determine if request is admin route
        const isAdminRoute = config.url?.includes("/admin/");
        const adminKey = (storage.getAdminKey() || settings.adminApiKey || "").trim();
        const apiKey = isAdminRoute
          ? adminKey
          : settings.clientApiKey || DEFAULT_CLIENT_KEY;

        if (apiKey) {
          config.headers["X-API-Key"] = apiKey;
        }
        if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
          config.headers["X-Request-ID"] = crypto.randomUUID();
        } else {
          config.headers["X-Request-ID"] = String(Date.now());
        }

        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor: Uniform error handling rejecting ApiError instances
    this.instance.interceptors.response.use(
      (response: AxiosResponse) => response,
      (error: AxiosError<ApiErrorResponse>) => {
        const normalizedError = this.normalizeError(error);
        return Promise.reject(normalizedError);
      }
    );
  }

  private normalizeError(error: AxiosError<ApiErrorResponse>): ApiError {
    if (error.response && error.response.data && typeof error.response.data === "object") {
      const data = error.response.data;
      let formattedMsg = data.message;

      if (!formattedMsg) {
        if (typeof data.detail === "string" && data.detail.trim()) {
          formattedMsg = data.detail;
        } else if (Array.isArray(data.detail)) {
          formattedMsg = data.detail
            .map((d: ApiErrorDetail | unknown) => {
              if (typeof d === "object" && d !== null) {
                const det = d as ApiErrorDetail;
                if (det.msg) {
                  const loc = Array.isArray(det.loc)
                    ? det.loc.filter((part) => part !== "body").join(".")
                    : "";
                  return loc ? `${loc}: ${det.msg}` : det.msg;
                }
              }
              return String(d);
            })
            .join("; ");
        } else {
          formattedMsg = `API request failed with status ${error.response.status}.`;
        }
      }

      const status = error.response.status;
      const errorType =
        data.error ||
        (status === 404
          ? "ContextNotFound"
          : status === 408
          ? "TimeoutError"
          : status === 422 || status === 400
          ? "ValidationError"
          : status >= 500
          ? "ServerError"
          : "ApiError");

      return new ApiError(formattedMsg, {
        statusCode: status,
        errorType,
        detail: data.detail,
        isNetworkError: false,
        isTimeout: status === 408,
      });
    }

    if (error.code === "ECONNABORTED" || error.message?.toLowerCase().includes("timeout")) {
      return new ApiError(
        "Request timed out while communicating with the ExamCraft backend (limit: 120s).",
        {
          statusCode: 408,
          errorType: "TimeoutError",
          isTimeout: true,
          isNetworkError: false,
        }
      );
    }

    if (!error.response) {
      return new ApiError(
        "Cannot connect to ExamCraft backend. Verify that the FastAPI service is running on port 8000.",
        {
          statusCode: 503,
          errorType: "NetworkError",
          isNetworkError: true,
          isTimeout: false,
        }
      );
    }

    return new ApiError(error.message || "An unexpected error occurred.", {
      statusCode: error.response?.status || 500,
      errorType: "UnknownError",
    });
  }

  // --- API Endpoint Methods ---

  /**
   * Check backend telemetry and health status
   */
  public async getHealth(): Promise<HealthResponse> {
    const settings = getSettings();
    try {
      const res = await this.instance.get<HealthResponse>("/api/health", {
        timeout: 10000,
      });
      return res.data;
    } catch (err) {
      if (settings.enableMockFallback) {
        return getMockHealth();
      }
      throw err;
    }
  }

  /**
   * Retrieve list of supported subjects
   */
  public async getSubjects(): Promise<SubjectListResponse> {
    const settings = getSettings();
    try {
      const res = await this.instance.get<SubjectListResponse>("/api/subjects", {
        timeout: 10000,
      });
      return res.data;
    } catch (err) {
      if (settings.enableMockFallback) {
        return getMockSubjects();
      }
      throw err;
    }
  }

  /**
   * Retrieve chapters for a specific subject directly from backend database
   */
  public async getChapters(subject: string, grade?: number): Promise<ChapterListResponse> {
    const res = await this.instance.get<ChapterListResponse>(
      `/api/subjects/${encodeURIComponent(subject)}/chapters`,
      {
        params: grade ? { grade } : undefined,
        timeout: 15000,
      }
    );
    return res.data;
  }

  /**
   * Retrieve exercises, sections, and topics metadata for a chapter from database
   */
  public async getChapterMetadata(
    subject: string,
    chapter: string,
    grade?: number
  ): Promise<ChapterMetadataResponse> {
    const res = await this.instance.get<ChapterMetadataResponse>(
      `/api/subjects/${encodeURIComponent(subject)}/chapters/${encodeURIComponent(chapter)}/metadata`,
      {
        params: grade ? { grade } : undefined,
        timeout: 15000,
      }
    );
    return res.data;
  }

  /**
   * Generate structured draft test JSON using Gemini LLM and Qdrant RAG.
   * CALIBRATED: 120 seconds timeout.
   * ZERO-PLACEHOLDER: Never falls back to dummy mock data.
   */
  public async generateDraft(payload: TestGenerationRequest): Promise<Class9TestSchema> {
    const res = await this.instance.post<Class9TestSchema>(
      "/api/tests/draft",
      payload,
      { timeout: 120000 }
    );
    return res.data;
  }

  /**
   * Alias for generateDraft
   */
  public async generateDraftTest(payload: TestGenerationRequest): Promise<Class9TestSchema> {
    return this.generateDraft(payload);
  }

  /**
   * Render approved test JSON into publication-ready A4 PDF binary stream.
   * ZERO-PLACEHOLDER: Never falls back to mock PDF blob.
   */
  public async renderPdf(payload: PDFRenderRequest): Promise<Blob> {
    const res = await this.instance.post(
      "/api/tests/render-pdf",
      payload,
      {
        responseType: "blob",
        timeout: 60000,
      }
    );
    return new Blob([res.data], { type: "application/pdf" });
  }

  /**
   * Admin: Upload and index textbook PDF
   */
  /**
   * Admin: Initiate non-blocking asynchronous textbook ingestion (HTTP 202 Accepted)
   */
  public async uploadTextbook(
    formData: FormData
  ): Promise<UploadJobAcceptedResponse> {
    const res = await this.instance.post<UploadJobAcceptedResponse>(
      "/api/admin/upload-textbook",
      formData,
      {
        headers: {
          "Content-Type": undefined,
        },
        timeout: 45000,
      }
    );
    return res.data;
  }

  /**
   * Admin: Fetch Ingestion Job Snapshot
   */
  public async getJobStatus(jobId: string): Promise<IngestionJobSnapshot> {
    const res = await this.instance.get<IngestionJobSnapshot>(
      `/api/admin/jobs/${jobId}`,
      { timeout: 10000 }
    );
    return res.data;
  }

  /**
   * Helper to verify connection with a custom URL and API Key from /settings
   */
  public async testCustomConnection(
    baseUrl: string,
    apiKey: string
  ): Promise<HealthResponse> {
    const cleanUrl = (baseUrl.trim() || DEFAULT_API_URL).replace(/\/+$/, "");
    const res = await axios.get<HealthResponse>(`${cleanUrl}/api/health`, {
      headers: { "X-API-Key": apiKey.trim() },
      timeout: 8000,
    });
    return res.data;
  }
}

export const api = new ApiClient();
export default api;
