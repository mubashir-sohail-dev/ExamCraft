"use client";

/**
 * src/app/settings/page.tsx
 * ExamCraft AI - System Configuration, Authentication Keys, and Storage Management
 */

import * as React from "react";
import {
  Server,
  Palette,
  Trash2,
  CheckCircle2,
  Eye,
  EyeOff,
  Activity,
  Shield,
  Key,
  AlertTriangle,
  RotateCcw,
  ChevronDown,
  Globe,
} from "lucide-react";
import axios from "axios";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import {
  getSettings,
  saveSettings,
  storage,
  clearActiveDraft,
  clearRecentPapers,
  clearAllStorage,
  DEFAULT_SETTINGS,
} from "@/lib/storage";
import { AppSettings, HealthResponse } from "@/types/api";
import { SubjectType } from "@/types/exam";
import { SUBJECTS_CONFIG, DEFAULT_API_URL, DEFAULT_CLIENT_KEY } from "@/lib/constants";
import { api } from "@/lib/api";
import { useTelemetry } from "@/context/TelemetryContext";
import { useTestDraft } from "@/context/TestDraftContext";

interface PingResult {
  status: "success" | "warning" | "error";
  latencyMs: number;
  message: string;
  healthData?: HealthResponse;
}

export default function SettingsPage() {
  const { refreshHealth } = useTelemetry();
  const { resetDraft, refreshHistory } = useTestDraft();

  const [settings, setSettings] = React.useState<AppSettings>(getSettings());
  const [showClientKey, setShowClientKey] = React.useState<boolean>(false);
  const [showAdminKey, setShowAdminKey] = React.useState<boolean>(false);
  const [testResult, setTestResult] = React.useState<PingResult | null>(null);
  const [isTesting, setIsTesting] = React.useState<boolean>(false);
  const [isSaved, setIsSaved] = React.useState<boolean>(false);
  const [feedbackToast, setFeedbackToast] = React.useState<string | null>(null);

  // Storage dialog states
  const [activeModal, setActiveModal] = React.useState<"active_draft" | "recent_papers" | "clear_cache" | "factory_reset" | null>(null);

  const showNotification = (msg: string) => {
    setFeedbackToast(msg);
    setTimeout(() => setFeedbackToast(null), 3000);
  };

  const handleSave = () => {
    const cleanSettings: AppSettings = {
      ...settings,
      apiBaseUrl: settings.apiBaseUrl.trim().replace(/\/+$/, ""),
      clientApiKey: settings.clientApiKey.trim(),
      adminApiKey: settings.adminApiKey.trim(),
    };
    setSettings(cleanSettings);
    saveSettings(cleanSettings);
    storage.setAdminKey(cleanSettings.adminApiKey);
    setIsSaved(true);
    void refreshHealth();
    showNotification("Settings updated and saved successfully!");
    setTimeout(() => setIsSaved(false), 2500);
  };

  const handleTestConnection = async () => {
    setIsTesting(true);
    setTestResult(null);
    const start = performance.now();

    try {
      const baseUrl = (settings.apiBaseUrl.trim() || DEFAULT_API_URL).replace(/\/+$/, "");
      const apiKey = settings.clientApiKey.trim() || DEFAULT_CLIENT_KEY;

      const healthRes = await api.testCustomConnection(baseUrl, apiKey);
      const elapsed = Math.round(performance.now() - start);

      setTestResult({
        status: healthRes.qdrant_connected ? "success" : "warning",
        latencyMs: elapsed,
        message: `Connected successfully! (Backend v${healthRes.version || "1.0.0"}, Qdrant: ${
          healthRes.qdrant_connected ? "Online" : "Degraded"
        })`,
        healthData: healthRes,
      });
    } catch (err: unknown) {
      const elapsed = Math.round(performance.now() - start);
      let errorMsg = "Failed to connect to configured FastAPI backend URL.";

      if (axios.isAxiosError(err)) {
        if (err.response) {
          if (err.response.status === 404) {
            errorMsg = "Server reached, but /api/health returned 404 Not Found. Verify URL format.";
          } else if (err.response.status === 401 || err.response.status === 403) {
            errorMsg = `Authentication rejected (HTTP ${err.response.status}). Verify your Client API Key.`;
          } else {
            errorMsg = `Server returned HTTP ${err.response.status}: ${err.response.statusText || "Error"}`;
          }
        } else if (err.code === "ECONNABORTED" || err.message?.toLowerCase().includes("timeout")) {
          errorMsg = "Connection timed out after 8s. Check if server host is reachable.";
        } else if (err.message) {
          errorMsg = err.message;
        }
      } else if (err instanceof Error) {
        errorMsg = err.message;
      }

      if (settings.enableMockFallback) {
        setTestResult({
          status: "warning",
          latencyMs: elapsed,
          message: `${errorMsg} Offline Mock Resilience engine is active.`,
        });
      } else {
        setTestResult({
          status: "error",
          latencyMs: elapsed,
          message: errorMsg,
        });
      }
    } finally {
      setIsTesting(false);
    }
  };

  const handleResetDefaults = () => {
    if (confirm("Reset all settings to initial system defaults?")) {
      setSettings(DEFAULT_SETTINGS);
      saveSettings(DEFAULT_SETTINGS);
      void refreshHealth();
      showNotification("Settings reset to defaults.");
    }
  };

  // Storage clearing executions
  const executeClearActiveDraft = () => {
    clearActiveDraft();
    resetDraft();
    setActiveModal(null);
    showNotification("Active draft cleared.");
  };

  const executeClearRecentPapers = () => {
    clearRecentPapers();
    refreshHistory();
    setActiveModal(null);
    showNotification("Recent papers archive cleared.");
  };

  const executeClearCache = () => {
    clearAllStorage();
    resetDraft();
    refreshHistory();
    setActiveModal(null);
    showNotification("All temporary cache, drafts, and recent papers cleared.");
  };

  const executeFactoryReset = () => {
    clearAllStorage();
    setSettings(DEFAULT_SETTINGS);
    resetDraft();
    refreshHistory();
    setActiveModal(null);
    showNotification("Factory reset completed. All local storage cache cleared.");
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6 py-2">
      {/* Toast Notification */}
      {feedbackToast && (
        <div className="fixed bottom-6 right-6 z-50 p-4 rounded-xl shadow-lg border border-emerald-500/40 bg-emerald-950/90 text-emerald-200 text-xs font-medium flex items-center gap-2 transition-all animate-in fade-in slide-in-from-bottom-2">
          <CheckCircle2 className="h-4 w-4 text-emerald-400" />
          <span>{feedbackToast}</span>
        </div>
      )}

      {/* Top Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">
              Settings & Preferences
            </h1>
            <Badge variant="outline" className="text-xs">
              System Configuration
            </Badge>
          </div>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Configure FastAPI backend connection, authentication keys, generation defaults, and storage
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleResetDefaults}
            className="text-xs gap-1.5"
            title="Reset settings to system defaults"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Reset Defaults</span>
          </Button>

          <Button onClick={handleSave} className="gap-1.5 shadow-xs text-xs">
            <CheckCircle2 className="h-4 w-4" />
            <span>{isSaved ? "Settings Saved!" : "Save Settings"}</span>
          </Button>
        </div>
      </div>

      {/* Section 1: FastAPI Backend & Auth Keys */}
      <Card className="border-border/80 shadow-2xs">
        <CardHeader className="pb-3 border-b border-border/60">
          <CardTitle className="text-base font-semibold flex items-center gap-2">
            <Server className="h-4 w-4 text-primary" />
            <span>FastAPI Backend Connection & API Keys</span>
          </CardTitle>
          <CardDescription className="text-xs">
            Direct REST API endpoint serving RAG retrieval, Gemini LLM drafting, and ReportLab PDF rendering
          </CardDescription>
        </CardHeader>

        <CardContent className="p-4 sm:p-5 space-y-4 text-xs">
          {/* API Base URL */}
          <div className="space-y-1.5">
            <Label className="font-medium text-foreground text-xs flex items-center justify-between">
              <span>Backend Base URL</span>
              <span className="text-[11px] text-muted-foreground font-mono">Default: http://localhost:8000</span>
            </Label>
            <div className="flex gap-2">
              <Input
                type="url"
                value={settings.apiBaseUrl}
                onChange={(e) => setSettings({ ...settings, apiBaseUrl: e.target.value })}
                placeholder="http://localhost:8000"
                className="text-xs font-mono"
              />
              <Button
                variant="outline"
                size="sm"
                onClick={handleTestConnection}
                disabled={isTesting}
                className="shrink-0 gap-1.5 text-xs"
              >
                <Activity className={`h-3.5 w-3.5 ${isTesting ? "animate-spin" : ""}`} />
                <span>{isTesting ? "Testing..." : "Test Connection"}</span>
              </Button>
            </div>

            {/* Quick URL Presets */}
            <div className="flex flex-wrap items-center gap-2 pt-0.5">
              <span className="text-[11px] text-muted-foreground font-medium">Quick Presets:</span>
              <button
                type="button"
                onClick={() => setSettings({ ...settings, apiBaseUrl: "http://localhost:8000" })}
                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-mono border border-border/70 hover:border-primary/60 hover:bg-muted/60 transition-colors cursor-pointer"
              >
                <Server className="h-3 w-3 text-muted-foreground" />
                <span>Localhost (http://localhost:8000)</span>
              </button>
              <button
                type="button"
                onClick={() => setSettings({ ...settings, apiBaseUrl: "https://testai.ai-vision.studio" })}
                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-mono border border-border/70 hover:border-primary/60 hover:bg-muted/60 transition-colors cursor-pointer"
              >
                <Globe className="h-3 w-3 text-primary" />
                <span>Cloud Production (https://testai.ai-vision.studio)</span>
              </button>
            </div>

            {/* Test Connection Result Box */}
            {testResult && (
              <div
                className={`p-3 rounded-lg border text-xs flex flex-col sm:flex-row sm:items-center justify-between gap-2 mt-2 ${
                  testResult.status === "success"
                    ? "border-emerald-500/40 bg-emerald-50/40 dark:bg-emerald-950/20 text-emerald-800 dark:text-emerald-200"
                    : testResult.status === "warning"
                    ? "border-amber-500/40 bg-amber-50/40 dark:bg-amber-950/20 text-amber-800 dark:text-amber-200"
                    : "border-rose-500/40 bg-rose-50/40 dark:bg-rose-950/20 text-rose-800 dark:text-rose-200"
                }`}
              >
                <div className="flex items-center gap-2">
                  {testResult.status === "success" ? (
                    <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                  ) : testResult.status === "warning" ? (
                    <AlertTriangle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-rose-600 dark:text-rose-400 shrink-0" />
                  )}
                  <span>{testResult.message}</span>
                </div>
                <div className="flex items-center gap-2 font-mono text-[11px] font-semibold shrink-0">
                  <span>Ping: {testResult.latencyMs}ms</span>
                </div>
              </div>
            )}
          </div>

          {/* Client API Key */}
          <div className="pt-1">
            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs flex items-center justify-between">
                <span className="flex items-center gap-1.5">
                  <Key className="h-3.5 w-3.5 text-primary" />
                  <span>Client API Key (X-API-Key)</span>
                </span>
                <button
                  type="button"
                  onClick={() => setShowClientKey(!showClientKey)}
                  className="text-muted-foreground hover:text-foreground"
                  title={showClientKey ? "Hide key" : "Show key"}
                >
                  {showClientKey ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
                </button>
              </Label>
              <Input
                type={showClientKey ? "text" : "password"}
                value={settings.clientApiKey}
                onChange={(e) => setSettings({ ...settings, clientApiKey: e.target.value })}
                placeholder={DEFAULT_CLIENT_KEY}
                className="text-xs font-mono"
              />
              <p className="text-[10px] text-muted-foreground">
                Authenticates test generation, chapter querying, and PDF rendering requests
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Administrator API Key Input Card */}
      <Card className="border-border/80 shadow-2xs border-l-4 border-l-secondary">
        <CardHeader className="pb-3 border-b border-border/60">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base font-semibold flex items-center gap-2">
              <Shield className="h-4 w-4 text-secondary" />
              <span>Administrator API Key</span>
            </CardTitle>
            <Badge variant="outline" className="text-[10px] text-secondary border-secondary/30 bg-secondary/10">
              LocalStorage Only
            </Badge>
          </div>
          <CardDescription className="text-xs">
            Elevated administrative secret required for curriculum textbook PDF upload, chunking, and Qdrant collection upsert. Stored strictly in browser LocalStorage; never bundled into public code.
          </CardDescription>
        </CardHeader>
        <CardContent className="p-4 sm:p-5 space-y-3 text-xs">
          <div className="space-y-1.5">
            <Label className="font-medium text-foreground text-xs flex items-center justify-between">
              <span className="flex items-center gap-1.5">
                <Key className="h-3.5 w-3.5 text-secondary" />
                <span>Admin API Key (X-API-Key)</span>
              </span>
              <button
                type="button"
                onClick={() => setShowAdminKey(!showAdminKey)}
                className="text-muted-foreground hover:text-foreground flex items-center gap-1 text-[11px]"
                title={showAdminKey ? "Hide key" : "Show key"}
              >
                {showAdminKey ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
                <span>{showAdminKey ? "Hide" : "Show"}</span>
              </button>
            </Label>
            <Input
              type={showAdminKey ? "text" : "password"}
              value={settings.adminApiKey}
              onChange={(e) => setSettings({ ...settings, adminApiKey: e.target.value })}
              placeholder="Enter elevated administrator key (e.g. sk-admin-...)"
              className="text-xs font-mono"
            />
            <p className="text-[10px] text-muted-foreground">
              Stored strictly in browser LocalStorage. Authorizes textbook PDF upload on /upload.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Section 2: Generation Defaults & Application Preferences */}
      <Card className="border-border/80 shadow-2xs">
        <CardHeader className="pb-3 border-b border-border/60">
          <CardTitle className="text-base font-semibold flex items-center gap-2">
            <Palette className="h-4 w-4 text-secondary" />
            <span>Default Generation & Application Preferences</span>
          </CardTitle>
          <CardDescription className="text-xs">
            Pre-configure default assessment parameters, UI theme, and background telemetry
          </CardDescription>
        </CardHeader>

        <CardContent className="p-4 sm:p-5 space-y-4 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {/* Preferred Subject */}
            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs">Default Subject</Label>
              <div className="relative">
                <select
                  value={settings.defaultSubject}
                  onChange={(e) =>
                    setSettings({ ...settings, defaultSubject: e.target.value as SubjectType })
                  }
                  className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer"
                >
                  {(Object.keys(SUBJECTS_CONFIG) as SubjectType[]).map((subj) => (
                    <option key={subj} value={subj} className="bg-card text-foreground py-1">
                      {subj}
                    </option>
                  ))}
                </select>
                <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              </div>
            </div>

            {/* Preferred Academic Class Level */}
            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs">Default Class Level</Label>
              <div className="relative">
                <select
                  value={settings.defaultGrade || 9}
                  onChange={(e) =>
                    setSettings({ ...settings, defaultGrade: Number(e.target.value) })
                  }
                  className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer"
                >
                  <option value={9} className="bg-card text-foreground py-1">Class 9 (SSC-I)</option>
                  <option value={10} className="bg-card text-foreground py-1">Class 10 (SSC-II)</option>
                  <option value={11} className="bg-card text-foreground py-1">Class 11 (HSSC-I)</option>
                  <option value={12} className="bg-card text-foreground py-1">Class 12 (HSSC-II)</option>
                </select>
                <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              </div>
            </div>

            {/* Theme Mode */}
            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs">Theme Preference</Label>
              <div className="relative">
                <select
                  value={settings.theme}
                  onChange={(e) =>
                    setSettings({
                      ...settings,
                      theme: e.target.value as "light" | "dark" | "system",
                    })
                  }
                  className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer"
                >
                  <option value="system" className="bg-card text-foreground py-1">System Default</option>
                  <option value="light" className="bg-card text-foreground py-1">Light Mode</option>
                  <option value="dark" className="bg-card text-foreground py-1">Dark Mode</option>
                </select>
                <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              </div>
            </div>
          </div>

          <div className="pt-2 space-y-3">
            {/* Telemetry Polling */}
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label htmlFor="telemetry-switch" className="text-xs font-medium cursor-pointer">
                  Background Telemetry Polling (30s Interval)
                </Label>
                <p className="text-[11px] text-muted-foreground">
                  Periodically queries GET /api/health to track live backend, LLM, and Qdrant latency
                </p>
              </div>
              <Switch
                id="telemetry-switch"
                checked={settings.enableTelemetry}
                onCheckedChange={(val) => setSettings({ ...settings, enableTelemetry: val })}
              />
            </div>

            {/* Offline Resilience */}
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label htmlFor="mock-switch" className="text-xs font-medium cursor-pointer">
                  Offline Resilience & Mock Fallback
                </Label>
                <p className="text-[11px] text-muted-foreground">
                  Gracefully load realistic curriculum sample data (Classes 9–12) when offline or backend unreachable
                </p>
              </div>
              <Switch
                id="mock-switch"
                checked={settings.enableMockFallback}
                onCheckedChange={(val) => setSettings({ ...settings, enableMockFallback: val })}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Section 3: Storage & Local Cache Manager */}
      <Card className="border-border/80 shadow-2xs border-rose-500/20">
        <CardHeader className="pb-3 border-b border-border/60">
          <CardTitle className="text-base font-semibold text-rose-600 dark:text-rose-400 flex items-center gap-2">
            <Trash2 className="h-4 w-4" />
            <span>Local Storage & Cache Manager</span>
          </CardTitle>
          <CardDescription className="text-xs">
            Granularly purge locally stored test drafts, archived history, or reset application state
          </CardDescription>
        </CardHeader>

        <CardContent className="p-4 sm:p-5 space-y-3 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {/* Clear Active Draft */}
            <div className="p-3 rounded-lg border border-border/70 bg-card flex items-center justify-between gap-2">
              <div className="space-y-0.5">
                <span className="font-semibold text-foreground">Clear Active Draft</span>
                <p className="text-[11px] text-muted-foreground">Reset current in-progress test in Studio</p>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setActiveModal("active_draft")}
                className="text-xs shrink-0"
              >
                Clear Draft
              </Button>
            </div>

            {/* Clear Recent Papers */}
            <div className="p-3 rounded-lg border border-border/70 bg-card flex items-center justify-between gap-2">
              <div className="space-y-0.5">
                <span className="font-semibold text-foreground">Clear Recent Papers</span>
                <p className="text-[11px] text-muted-foreground">Purge history archive of generated tests</p>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setActiveModal("recent_papers")}
                className="text-xs shrink-0 text-rose-600 dark:text-rose-400 border-rose-500/30 hover:bg-rose-500/10"
              >
                Purge Archive
              </Button>
            </div>

            {/* Clear All Cache & Data */}
            <div className="p-3 rounded-lg border border-amber-500/30 bg-amber-500/5 flex items-center justify-between gap-2">
              <div className="space-y-0.5">
                <span className="font-semibold text-amber-800 dark:text-amber-300">Clear Cache &amp; Local Data</span>
                <p className="text-[11px] text-muted-foreground">Purge active draft, cached tests, and recent papers archive</p>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setActiveModal("clear_cache")}
                className="text-xs shrink-0 text-amber-600 dark:text-amber-400 border-amber-500/30 hover:bg-amber-500/10"
              >
                Clear Cache
              </Button>
            </div>

            {/* Factory Reset */}
            <div className="p-3 rounded-lg border border-rose-500/40 bg-rose-500/5 flex items-center justify-between gap-2">
              <div className="space-y-0.5">
                <span className="font-semibold text-rose-600 dark:text-rose-400">Factory Reset</span>
                <p className="text-[11px] text-muted-foreground">Wipe all storage and reset all settings</p>
              </div>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => setActiveModal("factory_reset")}
                className="text-xs shrink-0 shadow-xs"
              >
                Reset All
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Confirmation Modals */}
      {activeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-150">
          <Card className="w-full max-w-md border-border bg-card shadow-2xl p-5 space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-full bg-rose-500/10 text-rose-600 dark:text-rose-400">
                <AlertTriangle className="h-6 w-6" />
              </div>
              <div>
                <h3 className="font-bold text-sm text-foreground">
                  {activeModal === "active_draft" && "Clear Active Draft?"}
                  {activeModal === "recent_papers" && "Purge Recent Papers Archive?"}
                  {activeModal === "clear_cache" && "Clear All Cache & Local Data?"}
                  {activeModal === "factory_reset" && "Confirm Factory Reset?"}
                </h3>
                <p className="text-xs text-muted-foreground">
                  {activeModal === "active_draft" && "This will remove the current unsaved test schema from the Studio workspace."}
                  {activeModal === "recent_papers" && "This will permanently delete all saved assessment papers from your local browser storage."}
                  {activeModal === "clear_cache" && "This will remove your active draft and permanently delete all archived assessment papers from local browser storage."}
                  {activeModal === "factory_reset" && "This will wipe all local data including drafts, saved papers, and custom API settings."}
                </p>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-border/80">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setActiveModal(null)}
                className="text-xs"
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => {
                  if (activeModal === "active_draft") executeClearActiveDraft();
                  else if (activeModal === "recent_papers") executeClearRecentPapers();
                  else if (activeModal === "clear_cache") executeClearCache();
                  else if (activeModal === "factory_reset") executeFactoryReset();
                }}
                className="text-xs shadow-xs"
              >
                Confirm &amp; Clear
              </Button>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}
