"use client";

/**
 * src/hooks/use-ingestion-job.ts
 * ExamCraft AI - Resilient Real-Time SSE Ingestion Hook
 *
 * Uses Fetch Stream with X-API-Key header to read Server-Sent Events,
 * tracks active job in sessionStorage, and provides real-time progress & terminal logs.
 */

import * as React from "react";
import { IngestionJobSnapshot, IngestionLogEntry } from "@/types/api";
import { getSettings } from "@/lib/storage";
import { DEFAULT_API_URL, DEFAULT_ADMIN_KEY } from "@/lib/constants";

const STORAGE_KEY = "examcraft_active_ingestion_job_id";

export function useIngestionJob() {
  const [job, setJob] = React.useState<IngestionJobSnapshot | null>(null);
  const [logs, setLogs] = React.useState<IngestionLogEntry[]>([]);
  const [isStreaming, setIsStreaming] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const abortControllerRef = React.useRef<AbortController | null>(null);

  const stopStream = React.useCallback(() => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
      abortControllerRef.current = null;
    }
    setIsStreaming(false);
  }, []);

  const connectToStream = React.useCallback(async (jobId: string) => {
    stopStream();
    setError(null);
    setIsStreaming(true);

    const controller = new AbortController();
    abortControllerRef.current = controller;

    const settings = getSettings();
    const baseUrl = (settings.apiBaseUrl || DEFAULT_API_URL).trim().replace(/\/+$/, "");
    const adminKey = (settings.adminApiKey || DEFAULT_ADMIN_KEY).trim();
    const streamUrl = `${baseUrl}/api/admin/jobs/${jobId}/stream`;

    try {
      const response = await fetch(streamUrl, {
        method: "GET",
        headers: {
          "X-API-Key": adminKey,
          Accept: "text/event-stream",
        },
        signal: controller.signal,
      });

      if (!response.ok) {
        throw new Error(`Failed to connect to ingestion stream (HTTP ${response.status})`);
      }

      if (!response.body) {
        throw new Error("No readable stream body returned from server.");
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder("utf-8");
      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const parts = buffer.split("\n\n");
        buffer = parts.pop() || "";

        for (const part of parts) {
          const lines = part.split("\n");
          let eventType = "message";
          let dataStr = "";

          for (const line of lines) {
            if (line.startsWith("event:")) {
              eventType = line.replace("event:", "").trim();
            } else if (line.startsWith("data:")) {
              dataStr += line.replace("data:", "").trim();
            }
          }

          if (dataStr) {
            try {
              const parsed = JSON.parse(dataStr);
              if (eventType === "progress" || eventType === "complete" || eventType === "error") {
                const snapshot = parsed as IngestionJobSnapshot;
                setJob(snapshot);
                if (snapshot.logs && Array.isArray(snapshot.logs)) {
                  setLogs(snapshot.logs);
                }
                if (eventType === "complete") {
                  if (typeof window !== "undefined") {
                    window.sessionStorage.removeItem(STORAGE_KEY);
                    window.sessionStorage.setItem("examcraft_last_upload", JSON.stringify(snapshot.result || snapshot));
                  }
                  setIsStreaming(false);
                } else if (eventType === "error") {
                  setError(snapshot.error || "Ingestion pipeline encountered an error.");
                  setIsStreaming(false);
                }
              } else if (eventType === "log") {
                if (parsed.log) {
                  setLogs((prev) => [...prev.slice(-49), parsed.log]);
                }
              }
            } catch (jsonErr) {
              console.warn("Failed to parse SSE JSON payload:", jsonErr, dataStr);
            }
          }
        }
      }
    } catch (err: unknown) {
      if (controller.signal.aborted) {
        return; // Normal user abort
      }
      const msg = err instanceof Error ? err.message : "Lost connection to ingestion telemetry stream.";
      setError(msg);
      setIsStreaming(false);
    }
  }, [stopStream]);

  const startJob = React.useCallback((jobId: string) => {
    if (typeof window !== "undefined") {
      window.sessionStorage.setItem(STORAGE_KEY, jobId);
    }
    connectToStream(jobId);
  }, [connectToStream]);

  const clearJob = React.useCallback(() => {
    stopStream();
    setJob(null);
    setLogs([]);
    setError(null);
    if (typeof window !== "undefined") {
      window.sessionStorage.removeItem(STORAGE_KEY);
    }
  }, [stopStream]);

  // On mount: reconnect to ongoing job if stored in sessionStorage
  React.useEffect(() => {
    if (typeof window !== "undefined") {
      const activeJobId = window.sessionStorage.getItem(STORAGE_KEY);
      if (activeJobId && !job) {
        connectToStream(activeJobId);
      }
    }
    return () => {
      stopStream();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [connectToStream, stopStream]);

  return {
    job,
    logs,
    isStreaming,
    error,
    startJob,
    clearJob,
    progressPercent: job?.progress_percent || 0,
    stageMessage: job?.stage_message || "",
    status: job?.status || "idle",
    isComplete: job?.status === "completed",
    isFailed: job?.status === "failed",
    currentPage: job?.current_page || 0,
    totalPages: job?.total_pages || 0,
    chunksIndexed: job?.chunks_indexed || 0,
    elapsedSeconds: job?.elapsed_seconds || 0,
  };
}