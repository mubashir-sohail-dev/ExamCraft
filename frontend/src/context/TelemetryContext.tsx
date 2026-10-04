"use client";

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useRef,
  useMemo,
} from "react";
import { HealthResponse } from "@/types/api";
import { api } from "@/lib/api";
import { getSettings } from "@/lib/storage";
import { DEFAULT_API_URL } from "@/lib/constants";

export type TelemetryStatus = "connected" | "degraded" | "offline" | "checking";

export interface TelemetryContextType {
  status: TelemetryStatus;
  latencyMs: number | null;
  healthData: HealthResponse | null;
  lastChecked: Date | null;
  isPolling: boolean;
  backendUrl: string;
  errorMessage: string | null;
  refreshHealth: () => Promise<void>;
  setIsPolling: React.Dispatch<React.SetStateAction<boolean>>;
}

const TelemetryContext = createContext<TelemetryContextType | undefined>(undefined);

const POLLING_INTERVAL_MS = 30000; // 30 seconds

export function TelemetryProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<TelemetryStatus>("checking");
  const [latencyMs, setLatencyMs] = useState<number | null>(null);
  const [healthData, setHealthData] = useState<HealthResponse | null>(null);
  const [lastChecked, setLastChecked] = useState<Date | null>(null);
  const [isPolling, setIsPolling] = useState<boolean>(true);
  const [backendUrl, setBackendUrl] = useState<string>(DEFAULT_API_URL);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const isMountedRef = useRef(true);

  const checkHealth = useCallback(async () => {
    const settings = getSettings();
    const targetUrl = (settings.apiBaseUrl || DEFAULT_API_URL).trim().replace(/\/+$/, "");
    setBackendUrl(targetUrl);

    const startTime = typeof performance !== "undefined" ? performance.now() : Date.now();

    try {
      const data = await api.getHealth();
      const endTime = typeof performance !== "undefined" ? performance.now() : Date.now();
      const elapsed = Math.max(1, Math.round(endTime - startTime));

      if (!isMountedRef.current) return;

      setLatencyMs(elapsed);
      setHealthData(data);
      setLastChecked(new Date());
      setErrorMessage(null);

      // Determine connected vs degraded status
      if (data.status === "ok" && data.qdrant_connected) {
        setStatus("connected");
      } else if (data.status === "degraded" || !data.qdrant_connected) {
        setStatus("degraded");
      } else {
        setStatus("connected");
      }
    } catch (err: unknown) {
      if (!isMountedRef.current) return;

      const msg = err instanceof Error ? err.message : "Failed to connect to backend service";
      setStatus("offline");
      setLatencyMs(null);
      setHealthData(null);
      setLastChecked(new Date());
      setErrorMessage(msg);
    }
  }, []);

  useEffect(() => {
    isMountedRef.current = true;

    // Initial health check on mount
    void checkHealth();

    // 30-second interval poller
    const intervalId = setInterval(() => {
      if (isPolling) {
        void checkHealth();
      }
    }, POLLING_INTERVAL_MS);

    return () => {
      isMountedRef.current = false;
      clearInterval(intervalId);
    };
  }, [checkHealth, isPolling]);

  const value = useMemo(
    () => ({
      status,
      latencyMs,
      healthData,
      lastChecked,
      isPolling,
      backendUrl,
      errorMessage,
      refreshHealth: checkHealth,
      setIsPolling,
    }),
    [status, latencyMs, healthData, lastChecked, isPolling, backendUrl, errorMessage, checkHealth]
  );

  return (
    <TelemetryContext.Provider value={value}>
      {children}
    </TelemetryContext.Provider>
  );
}

export function useTelemetry(): TelemetryContextType {
  const context = useContext(TelemetryContext);
  if (!context) {
    throw new Error("useTelemetry must be used within a TelemetryProvider");
  }
  return context;
}
