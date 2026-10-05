"use client";

/**
 * src/app/upload/page.tsx
 * ExamCraft AI - Asynchronous Textbook Ingestion & Real-Time SSE Telemetry Hub
 */

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  UploadCloud,
  FileText,
  CheckCircle2,
  AlertCircle,
  Loader2,
  BookOpen,
  Database,
  ArrowRight,
  ShieldCheck,
  ChevronDown,
  Terminal,
  Clock,
  ExternalLink,
  ChevronUp,
  RotateCcw,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { SubjectType } from "@/types/exam";
import { SUBJECTS_CONFIG } from "@/lib/constants";
import { api, getApiErrorMessage } from "@/lib/api";
import { useIngestionJob } from "@/hooks/use-ingestion-job";
import { storage } from "@/lib/storage";

export default function UploadPage() {
  const router = useRouter();

  // Ingestion Hook providing real-time SSE telemetry
  const {
    job,
    logs,
    isStreaming,
    error: sseError,
    startJob,
    clearJob,
    progressPercent,
    stageMessage,
    status,
    isComplete,
    currentPage,
    totalPages,
    chunksIndexed,
    elapsedSeconds,
  } = useIngestionJob();

  // Form states
  const [adminKey, setAdminKey] = React.useState<string>("");
  const [selectedSubject, setSelectedSubject] = React.useState<SubjectType>("Chemistry");
  const [selectedGrade, setSelectedGrade] = React.useState<number>(9);
  const [chapterName, setChapterName] = React.useState<string>("");
  const [selectedFile, setSelectedFile] = React.useState<File | null>(null);
  const [isDragging, setIsDragging] = React.useState<boolean>(false);
  const [isUploading, setIsUploading] = React.useState<boolean>(false);
  const [errorMessage, setErrorMessage] = React.useState<string | null>(null);
  const [showTerminal, setShowTerminal] = React.useState<boolean>(false);

  React.useEffect(() => {
    setAdminKey(storage.getAdminKey());
  }, []);

  const hasAdminKey = Boolean(adminKey.trim());

  const logsEndRef = React.useRef<HTMLDivElement>(null);

  // Auto-scroll terminal to bottom when new logs arrive
  React.useEffect(() => {
    if (showTerminal && logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [logs, showTerminal]);

  // Handle completion redirect
  React.useEffect(() => {
    if (isComplete) {
      const timer = setTimeout(() => {
        router.push("/upload/status");
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [isComplete, router]);

  // Drag & drop handlers
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      if (file.type === "application/pdf" || file.name.endsWith(".pdf")) {
        setSelectedFile(file);
        setErrorMessage(null);
      } else {
        setErrorMessage("Please select a valid .pdf textbook document.");
      }
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      if (file.type === "application/pdf" || file.name.endsWith(".pdf")) {
        setSelectedFile(file);
        setErrorMessage(null);
      } else {
        setErrorMessage("Please select a valid .pdf textbook document.");
      }
    }
  };

  const startIngestion = async () => {
    if (!selectedFile) {
      setErrorMessage("Please select or drop a PDF file to begin ingestion.");
      return;
    }

    const currentKey = (storage.getAdminKey() || adminKey).trim();
    if (!currentKey) {
      setErrorMessage(
        "Administrator API Key required. Textbook ingestion requires an elevated administrator key. Please configure your Admin Key in Settings before uploading."
      );
      return;
    }

    setErrorMessage(null);
    setIsUploading(true);

    const formData = new FormData();
    formData.append("file", selectedFile);
    formData.append("subject", selectedSubject);
    formData.append("grade", String(selectedGrade));
    formData.append("grade_level", `Class ${selectedGrade}`);
    if (chapterName.trim()) {
      formData.append("chapter_name", chapterName.trim());
    }
    formData.append("target_collection", "class_9_textbooks");

    try {
      // Non-blocking upload: Returns in <500ms with job_id
      const res = await api.uploadTextbook(formData);
      setIsUploading(false);

      // Start real-time SSE telemetry stream
      startJob(res.job_id);
    } catch (err: unknown) {
      setIsUploading(false);
      const msg = getApiErrorMessage(
        err,
        "Failed to initiate textbook upload. Please verify that the FastAPI service is running."
      );
      setErrorMessage(msg);
    }
  };

  const activeError = errorMessage || sseError;
  const isJobActive = isStreaming || (status !== "idle" && status !== "completed" && status !== "failed");

  return (
    <div className="p-6 md:p-8 max-w-4xl mx-auto space-y-6 animate-in fade-in duration-300">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1">
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-foreground">
              Textbook Ingestion Station
            </h1>
            <Badge variant="outline" className="text-xs bg-primary/5 text-primary border-primary/20">
              Admin Ingestion Pipeline
            </Badge>
          </div>
          <p className="text-xs text-muted-foreground">
            Ingest official Punjab Textbook Board Class 9–12 curriculum PDFs directly into the Qdrant hybrid vector store.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {hasAdminKey ? (
            <Badge variant="secondary" className="gap-1.5 text-xs py-1 px-2.5 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30">
              <ShieldCheck className="h-3.5 w-3.5 text-emerald-500" />
              <span>Admin Key Configured</span>
            </Badge>
          ) : (
            <Link href="/settings">
              <Badge variant="outline" className="gap-1.5 text-xs py-1 px-2.5 text-amber-600 dark:text-amber-400 bg-amber-500/10 border border-amber-500/30 hover:bg-amber-500/20 cursor-pointer">
                <AlertCircle className="h-3.5 w-3.5 text-amber-500" />
                <span>Admin Key Required</span>
              </Badge>
            </Link>
          )}
        </div>
      </div>

      {/* Upload Guard Banner when Admin Key is missing */}
      {!hasAdminKey && (
        <Card className="border-amber-500/40 bg-amber-50/60 dark:bg-amber-950/20 shadow-xs animate-in fade-in">
          <CardContent className="p-4 sm:p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-amber-500/10 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5">
                <AlertCircle className="h-5 w-5" />
              </div>
              <div className="space-y-1">
                <h3 className="font-semibold text-sm text-amber-900 dark:text-amber-200">
                  Administrator API Key Required
                </h3>
                <p className="text-xs text-muted-foreground leading-relaxed max-w-2xl">
                  Curriculum textbook ingestion and vector indexing require elevated administrator privileges.
                  Uploads are disabled until an Administrator API Key is configured in your browser settings.
                </p>
              </div>
            </div>
            <Link href="/settings" className="shrink-0 w-full sm:w-auto">
              <Button size="sm" className="w-full sm:w-auto gap-1.5 text-xs bg-amber-600 hover:bg-amber-700 text-white dark:bg-amber-500 dark:hover:bg-amber-600">
                <span>Configure in Settings</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Button>
            </Link>
          </CardContent>
        </Card>
      )}

      {/* Contextual Diagnostic Error Alert (Replaces harsh red banner) */}
      {activeError && (
        <div className="p-4 rounded-xl border border-amber-500/30 bg-amber-50/50 dark:bg-amber-950/20 text-foreground text-xs space-y-3 animate-in fade-in">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-start gap-2.5">
              <AlertCircle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="font-semibold text-amber-800 dark:text-amber-300">
                  Ingestion Notice & Diagnostics
                </p>
                <p className="text-muted-foreground leading-relaxed">
                  {activeError}
                </p>
              </div>
            </div>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => {
                clearJob();
                setErrorMessage(null);
              }}
              className="gap-1.5 text-xs shrink-0 border-amber-500/40 hover:bg-amber-500/10"
            >
              <RotateCcw className="h-3.5 w-3.5" />
              <span>Dismiss</span>
            </Button>
          </div>

          <div className="flex items-center gap-2 pt-1 border-t border-amber-500/20">
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={startIngestion}
              disabled={!selectedFile || isUploading}
              className="text-xs gap-1.5"
            >
              <RotateCcw className="h-3.5 w-3.5" />
              <span>Retry Ingestion</span>
            </Button>
            <Button
              type="button"
              size="sm"
              variant="ghost"
              onClick={() => setShowTerminal(!showTerminal)}
              className="text-xs gap-1.5 text-muted-foreground hover:text-foreground"
            >
              <Terminal className="h-3.5 w-3.5" />
              <span>{showTerminal ? "Hide Execution Logs" : "Inspect Execution Logs"}</span>
            </Button>
          </div>
        </div>
      )}

      {/* Upload Form */}
      <Card className="border-border/80 shadow-2xs">
        <CardHeader className="pb-3 border-b border-border/60">
          <CardTitle className="text-base font-semibold flex items-center gap-2">
            <UploadCloud className="h-4 w-4 text-primary" />
            <span>Upload Curriculum PDF</span>
          </CardTitle>
          <CardDescription className="text-xs">
            Documents are parsed via PyMuPDF, sliced into 800-char semantic chunks, and embedded with FastEmbed dense + BM25 sparse vectors.
          </CardDescription>
        </CardHeader>

        <CardContent className="p-5 space-y-5 text-xs">
          {/* Drag & Drop Area */}
          <div
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            className={`border-2 border-dashed rounded-xl p-8 text-center transition-all cursor-pointer flex flex-col items-center justify-center gap-2.5 ${
              isDragging
                ? "border-primary bg-primary/10"
                : selectedFile
                ? "border-emerald-500/50 bg-emerald-50/20 dark:bg-emerald-950/20"
                : "border-border/80 bg-muted/20 hover:border-primary/40 hover:bg-muted/30"
            }`}
            onClick={() => !isUploading && !isJobActive && document.getElementById("file-upload-input")?.click()}
          >
            <input
              id="file-upload-input"
              type="file"
              accept=".pdf,application/pdf"
              className="hidden"
              onChange={handleFileSelect}
              disabled={isUploading || isJobActive}
            />

            <div
              className={`h-12 w-12 rounded-full flex items-center justify-center ${
                selectedFile
                  ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                  : "bg-primary/10 text-primary"
              }`}
            >
              {selectedFile ? <FileText className="h-6 w-6" /> : <UploadCloud className="h-6 w-6" />}
            </div>

            {selectedFile ? (
              <div className="space-y-1">
                <p className="font-bold text-foreground text-sm flex items-center gap-1.5 justify-center">
                  <span>{selectedFile.name}</span>
                </p>
                <p className="text-[11px] text-muted-foreground font-mono">
                  {(selectedFile.size / (1024 * 1024)).toFixed(2)} MB &bull; PDF Document Ready for Ingestion
                </p>
                <p className="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold">
                  Click or drop another file to replace
                </p>
              </div>
            ) : (
              <div className="space-y-1">
                <p className="font-semibold text-foreground text-sm">
                  Drag and drop textbook PDF here, or click to browse
                </p>
                <p className="text-[11px] text-muted-foreground">
                  Supports official PTB Classes 9–12 .pdf textbooks up to 500MB
                </p>
              </div>
            )}
          </div>

          {/* Metadata Controls */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs flex items-center gap-1.5">
                <BookOpen className="h-3.5 w-3.5 text-primary" />
                <span>Subject Classification</span>
              </Label>
              <div className="relative">
                <select
                  value={selectedSubject}
                  onChange={(e) => setSelectedSubject(e.target.value as SubjectType)}
                  disabled={isUploading || isJobActive}
                  className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
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

            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs flex items-center gap-1.5">
                <ShieldCheck className="h-3.5 w-3.5 text-primary" />
                <span>Academic Class Level</span>
              </Label>
              <div className="relative">
                <select
                  value={selectedGrade}
                  onChange={(e) => setSelectedGrade(Number(e.target.value))}
                  disabled={isUploading || isJobActive}
                  className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <option value={9} className="bg-card text-foreground py-1">Class 9 (SSC-I / Matric Part 1)</option>
                  <option value={10} className="bg-card text-foreground py-1">Class 10 (SSC-II / Matric Part 2)</option>
                  <option value={11} className="bg-card text-foreground py-1">Class 11 (HSSC-I / Intermediate Part 1)</option>
                  <option value={12} className="bg-card text-foreground py-1">Class 12 (HSSC-II / Intermediate Part 2)</option>
                </select>
                <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label className="font-medium text-foreground text-xs">Chapter / Unit Title (Optional)</Label>
              <Input
                type="text"
                placeholder="e.g. Chapter 1: Fundamentals of Chemistry (or leave blank for Full Book)"
                value={chapterName}
                onChange={(e) => setChapterName(e.target.value)}
                disabled={isUploading || isJobActive}
                className="text-xs"
              />
            </div>

            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <Label className="font-medium text-foreground text-xs flex items-center gap-1.5">
                  <Database className="h-3.5 w-3.5 text-primary" />
                  <span>Target Qdrant Collection</span>
                </Label>
                <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-medium flex items-center gap-1">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  Unified Collection (All Classes)
                </span>
              </div>
              <Input
                value="class_9_textbooks"
                disabled
                className="text-xs font-mono bg-muted/40 text-foreground font-semibold"
              />
              <p className="text-[10.5px] text-muted-foreground">
                All academic grades (Class 9–12) are indexed into this unified Qdrant collection.
              </p>
            </div>
          </div>

          {/* Real-time SSE Ingestion Telemetry Card */}
          {(isJobActive || isUploading) && (
            <div className="p-4 rounded-xl border border-primary/30 bg-primary/5 space-y-3 animate-in fade-in">
              <div className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2 font-semibold text-foreground">
                  <Loader2 className="h-4 w-4 text-primary animate-spin" />
                  <span>{stageMessage || "Initializing ingestion pipeline..."}</span>
                </div>
                <div className="flex items-center gap-3">
                  {elapsedSeconds > 0 && (
                    <span className="text-[11px] text-muted-foreground flex items-center gap-1 font-mono">
                      <Clock className="h-3 w-3" />
                      {elapsedSeconds}s
                    </span>
                  )}
                  <span className="font-mono font-bold text-primary">{progressPercent}%</span>
                </div>
              </div>

              {/* Real Progress Bar */}
              <div className="w-full h-2 bg-muted rounded-full overflow-hidden">
                <div
                  className="h-full bg-primary transition-all duration-300 rounded-full"
                  style={{ width: `${Math.max(5, progressPercent)}%` }}
                />
              </div>

              {/* 4 Telemetry Stages */}
              <div className="grid grid-cols-4 gap-2 pt-1 text-[10px] text-center font-mono">
                <div className="p-1.5 rounded-md bg-card/60 border border-border/50">
                  <p className="text-muted-foreground">1. Read PDF</p>
                  <p className="font-semibold text-emerald-600 dark:text-emerald-400">Verified ✓</p>
                </div>
                <div className="p-1.5 rounded-md bg-card/60 border border-border/50">
                  <p className="text-muted-foreground">2. Extraction</p>
                  <p className="font-semibold text-foreground">
                    {totalPages > 0 ? `Page ${currentPage}/${totalPages}` : "Parsing..."}
                  </p>
                </div>
                <div className="p-1.5 rounded-md bg-card/60 border border-border/50">
                  <p className="text-muted-foreground">3. Chunking</p>
                  <p className="font-semibold text-foreground">
                    {chunksIndexed > 0 ? `${chunksIndexed} Chunks` : "800-char overlap"}
                  </p>
                </div>
                <div className="p-1.5 rounded-md bg-card/60 border border-border/50">
                  <p className="text-muted-foreground">4. Qdrant</p>
                  <p className="font-semibold text-primary">Hybrid Dense+BM25</p>
                </div>
              </div>

              {/* Controls below progress */}
              <div className="flex items-center justify-between pt-2">
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowTerminal(!showTerminal)}
                  className="text-[11px] gap-1.5 h-7 text-muted-foreground hover:text-foreground"
                >
                  <Terminal className="h-3.5 w-3.5" />
                  <span>{showTerminal ? "Hide Logs" : `Live Execution Terminal (${logs.length} events)`}</span>
                  {showTerminal ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
                </Button>

                <Link href="/generate">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="text-[11px] gap-1 h-7 text-primary border-primary/30 hover:bg-primary/10"
                  >
                    <span>Run in Background</span>
                    <ExternalLink className="h-3 w-3" />
                  </Button>
                </Link>
              </div>

              {/* Expandable Live Execution Terminal */}
              {showTerminal && (
                <div className="mt-2 p-3 rounded-lg bg-zinc-950 text-zinc-300 font-mono text-[11px] max-h-48 overflow-y-auto space-y-1 border border-zinc-800 animate-in fade-in">
                  <div className="text-[10px] text-zinc-500 pb-1 border-b border-zinc-800 flex items-center justify-between">
                    <span>Server-Sent Ingestion Logs</span>
                    <span>job_id: {job?.job_id || "staging"}</span>
                  </div>
                  {logs.length === 0 ? (
                    <p className="text-zinc-500 italic py-2">Listening for backend stream events...</p>
                  ) : (
                    logs.map((log, idx) => (
                      <div key={idx} className="flex items-start gap-2 leading-tight">
                        <span className="text-zinc-500 shrink-0">[{log.timestamp}]</span>
                        <span
                          className={`font-semibold shrink-0 ${
                            log.level === "ERROR"
                              ? "text-rose-400"
                              : log.level === "SUCCESS"
                              ? "text-emerald-400"
                              : log.level === "WARN"
                              ? "text-amber-400"
                              : "text-blue-400"
                          }`}
                        >
                          {log.level}
                        </span>
                        <span className="text-zinc-300 break-all">{log.message}</span>
                      </div>
                    ))
                  )}
                  <div ref={logsEndRef} />
                </div>
              )}
            </div>
          )}

          {isComplete && (
            <div className="p-4 rounded-xl border border-emerald-500/40 bg-emerald-500/10 text-emerald-700 dark:text-emerald-300 text-xs flex items-center gap-2 animate-in fade-in">
              <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-600 dark:text-emerald-400" />
              <div className="space-y-0.5">
                <p className="font-semibold">Textbook Ingestion Successful!</p>
                <p className="text-[11px]">Indexed into class_9_textbooks. Redirecting to summary report...</p>
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex items-center justify-between pt-3 border-t border-border/60">
            <Link href="/dashboard">
              <Button variant="ghost" size="default" disabled={isUploading || isJobActive} className="text-xs">
                Cancel
              </Button>
            </Link>

            <Button
              size="default"
              onClick={startIngestion}
              disabled={isUploading || isJobActive || !selectedFile || !hasAdminKey}
              className="gap-2 shadow-xs text-xs"
            >
              {isUploading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Dispatching Pipeline...</span>
                </>
              ) : isJobActive ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Ingestion In Progress ({progressPercent}%)</span>
                </>
              ) : (
                <>
                  <span>Start Ingestion Pipeline</span>
                  <ArrowRight className="h-4 w-4" />
                </>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}