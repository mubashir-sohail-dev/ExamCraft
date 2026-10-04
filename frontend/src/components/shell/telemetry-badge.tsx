"use client";

import * as React from "react";
import { useTelemetry } from "@/context/TelemetryContext";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Activity,
  Database,
  Server,
  Clock,
  RefreshCw,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  ExternalLink,
  ShieldCheck,
} from "lucide-react";
import { cn } from "@/lib/utils";

function formatUptime(seconds?: number): string {
  if (!seconds || seconds <= 0) return "0s";
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  if (parts.length === 0 || secs > 0) parts.push(`${secs}s`);
  return parts.join(" ");
}

export function TelemetryBadge({ className }: { className?: string }) {
  const {
    status,
    latencyMs,
    healthData,
    lastChecked,
    backendUrl,
    errorMessage,
    refreshHealth,
  } = useTelemetry();

  const [isOpen, setIsOpen] = React.useState(false);
  const [isRefreshing, setIsRefreshing] = React.useState(false);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refreshHealth();
    } finally {
      setIsRefreshing(false);
    }
  };

  const getStatusConfig = () => {
    switch (status) {
      case "connected":
        return {
          dotColor: "bg-emerald-500",
          pulse: true,
          label: latencyMs !== null ? `${latencyMs}ms` : "Connected",
          badgeVariant: "outline" as const,
          badgeClass: "border-emerald-200/80 bg-emerald-50/70 text-emerald-700 dark:border-emerald-900/60 dark:bg-emerald-950/40 dark:text-emerald-300 hover:bg-emerald-100/80 transition-colors",
          icon: CheckCircle2,
          iconColor: "text-emerald-500",
          title: "FastAPI Backend Connected",
          desc: "All RAG pipeline services, Qdrant vector engine, and Gemini models are healthy.",
        };
      case "degraded":
        return {
          dotColor: "bg-amber-500",
          pulse: true,
          label: latencyMs !== null ? `${latencyMs}ms (Degraded)` : "Degraded",
          badgeVariant: "outline" as const,
          badgeClass: "border-amber-200/80 bg-amber-50/70 text-amber-700 dark:border-amber-900/60 dark:bg-amber-950/40 dark:text-amber-300 hover:bg-amber-100/80 transition-colors",
          icon: AlertTriangle,
          iconColor: "text-amber-500",
          title: "Service Degraded",
          desc: "Backend is reachable but Qdrant or secondary index services are experiencing issues.",
        };
      case "offline":
        return {
          dotColor: "bg-rose-500",
          pulse: false,
          label: "Backend Offline",
          badgeVariant: "outline" as const,
          badgeClass: "border-rose-200/80 bg-rose-50/70 text-rose-700 dark:border-rose-900/60 dark:bg-rose-950/40 dark:text-rose-300 hover:bg-rose-100/80 transition-colors",
          icon: XCircle,
          iconColor: "text-rose-500",
          title: "Backend Unreachable",
          desc: "Cannot reach FastAPI server. Operating in resilient offline mock mode.",
        };
      case "checking":
      default:
        return {
          dotColor: "bg-blue-500",
          pulse: true,
          label: "Checking...",
          badgeVariant: "outline" as const,
          badgeClass: "border-blue-200/80 bg-blue-50/70 text-blue-700 dark:border-blue-900/60 dark:bg-blue-950/40 dark:text-blue-300 hover:bg-blue-100/80 transition-colors",
          icon: Activity,
          iconColor: "text-blue-500",
          title: "Pinging Telemetry",
          desc: "Connecting to FastAPI backend health endpoint...",
        };
    }
  };

  const config = getStatusConfig();
  const StatusIcon = config.icon;

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <button
          type="button"
          className={cn(
            "group inline-flex items-center gap-2 rounded-full cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
            className
          )}
          title={`Backend status: ${status}. Click for diagnostic details.`}
        >
          <Badge
            variant={config.badgeVariant}
            size="default"
            dot
            pulse={config.pulse}
            dotColor={config.dotColor}
            className={cn("px-2.5 py-1 text-xs font-medium cursor-pointer shadow-2xs", config.badgeClass)}
          >
            <span className="font-mono text-[11px] font-semibold">{config.label}</span>
          </Badge>
        </button>
      </DialogTrigger>

      <DialogContent className="sm:max-w-md">
        <DialogHeader className="pb-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className={cn("p-2 rounded-lg bg-muted/60", config.iconColor)}>
                <StatusIcon className="h-5 w-5" />
              </div>
              <div>
                <DialogTitle className="text-base font-semibold">
                  Backend Telemetry Status
                </DialogTitle>
                <DialogDescription className="text-xs">
                  Live health & diagnostics for ExamCraft AI services
                </DialogDescription>
              </div>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-3.5 py-2 text-sm">
          {/* Status Banner */}
          <div className={cn("p-3 rounded-lg border text-xs flex items-start gap-2.5", config.badgeClass)}>
            <StatusIcon className={cn("h-4 w-4 mt-0.5 shrink-0", config.iconColor)} />
            <div className="space-y-0.5">
              <p className="font-semibold">{config.title}</p>
              <p className="text-muted-foreground">{config.desc}</p>
              {errorMessage && (
                <p className="text-[11px] font-mono mt-1 text-rose-600 dark:text-rose-400">
                  {errorMessage}
                </p>
              )}
            </div>
          </div>

          {/* Diagnostic Metrics Grid */}
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="p-2.5 rounded-lg border border-border/70 bg-card/60 space-y-1">
              <div className="flex items-center gap-1.5 text-muted-foreground">
                <Server className="h-3.5 w-3.5" />
                <span>API Endpoint</span>
              </div>
              <p className="font-mono font-medium truncate text-foreground" title={backendUrl}>
                {backendUrl}
              </p>
            </div>

            <div className="p-2.5 rounded-lg border border-border/70 bg-card/60 space-y-1">
              <div className="flex items-center gap-1.5 text-muted-foreground">
                <Activity className="h-3.5 w-3.5" />
                <span>Roundtrip Ping</span>
              </div>
              <p className="font-mono font-medium text-foreground">
                {latencyMs !== null ? `${latencyMs} ms` : "N/A"}
              </p>
            </div>

            <div className="p-2.5 rounded-lg border border-border/70 bg-card/60 space-y-1">
              <div className="flex items-center gap-1.5 text-muted-foreground">
                <Database className="h-3.5 w-3.5" />
                <span>Qdrant Vector DB</span>
              </div>
              <div className="flex items-center gap-1.5 font-medium">
                {healthData?.qdrant_connected ? (
                  <span className="text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                    Connected
                  </span>
                ) : (
                  <span className="text-rose-600 dark:text-rose-400 flex items-center gap-1">
                    <span className="h-1.5 w-1.5 rounded-full bg-rose-500" />
                    {status === "offline" ? "Unreachable" : "Disconnected"}
                  </span>
                )}
              </div>
            </div>

            <div className="p-2.5 rounded-lg border border-border/70 bg-card/60 space-y-1">
              <div className="flex items-center gap-1.5 text-muted-foreground">
                <Clock className="h-3.5 w-3.5" />
                <span>Server Uptime</span>
              </div>
              <p className="font-mono font-medium text-foreground">
                {formatUptime(healthData?.uptime_seconds)}
              </p>
            </div>
          </div>

          {/* Detailed Info */}
          <div className="rounded-lg border border-border/60 bg-muted/30 p-3 space-y-1.5 text-xs">
            <div className="flex items-center justify-between text-muted-foreground">
              <span>Environment:</span>
              <span className="font-medium text-foreground font-mono">
                {healthData?.environment || "development"}
              </span>
            </div>
            <div className="flex items-center justify-between text-muted-foreground">
              <span>FastAPI Version:</span>
              <span className="font-medium text-foreground font-mono">
                v{healthData?.version || "1.0.0"}
              </span>
            </div>
            <div className="flex items-center justify-between text-muted-foreground">
              <span>LLM Engine:</span>
              <span className="font-medium text-emerald-600 dark:text-emerald-400 font-mono flex items-center gap-1">
                <ShieldCheck className="h-3.5 w-3.5" />
                Gemini 3.8 Flash
              </span>
            </div>
            <div className="flex items-center justify-between text-muted-foreground">
              <span>Last Polled:</span>
              <span className="font-mono text-[11px] text-muted-foreground">
                {lastChecked ? lastChecked.toLocaleTimeString() : "Never"}
              </span>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between pt-2 border-t border-border/60">
          <a
            href={`${backendUrl}/docs`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-xs text-primary hover:underline"
          >
            <span>Swagger API Docs</span>
            <ExternalLink className="h-3 w-3" />
          </a>

          <Button
            size="sm"
            variant="outline"
            onClick={handleRefresh}
            disabled={isRefreshing}
            className="gap-1.5"
          >
            <RefreshCw className={cn("h-3.5 w-3.5", isRefreshing && "animate-spin")} />
            <span>{isRefreshing ? "Pinging..." : "Refresh"}</span>
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
