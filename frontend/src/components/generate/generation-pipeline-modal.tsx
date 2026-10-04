"use client";

/**
 * src/components/generate/generation-pipeline-modal.tsx
 * ExamCraft AI - Animated 4-Step Generation Pipeline Modal with Resilient Error Diagnostics
 */

import * as React from "react";
import { useRouter } from "next/navigation";
import {
  Sparkles,
  Search,
  BookOpen,
  Brain,
  ClipboardCheck,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  ArrowRight,
  Loader2,
  Clock,
  Info,
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { api, ApiError, getApiErrorMessage } from "@/lib/api";
import { TestGenerationRequest } from "@/types/api";
import { Class9TestSchema } from "@/types/exam";
import { cn } from "@/lib/utils";

export interface GenerationPipelineModalProps {
  isOpen: boolean;
  onClose: () => void;
  payload: TestGenerationRequest | null;
  onSuccess: (generatedDraft: Class9TestSchema) => void;
}

interface StepDefinition {
  stepNumber: number;
  percent: number;
  title: string;
  subtitle: string;
  icon: React.ComponentType<{ className?: string }>;
}

const PIPELINE_STEPS: StepDefinition[] = [
  {
    stepNumber: 1,
    percent: 25,
    title: "Searching Knowledge Base",
    subtitle: "Retrieving relevant textbook material & syllabus context via Qdrant",
    icon: Search,
  },
  {
    stepNumber: 2,
    percent: 50,
    title: "Context Extraction & Alignment",
    subtitle: "Aligning extracted textbook material with Bloom's taxonomy",
    icon: BookOpen,
  },
  {
    stepNumber: 3,
    percent: 75,
    title: "Synthesizing AI Questions",
    subtitle: "Synthesizing MCQs, Short & Long questions with answer keys",
    icon: Brain,
  },
  {
    stepNumber: 4,
    percent: 100,
    title: "Test Paper Assembly & Answer Key",
    subtitle: "Formatting layout, calculating marks & constructing answer key",
    icon: ClipboardCheck,
  },
];

export function GenerationPipelineModal({
  isOpen,
  onClose,
  payload,
  onSuccess,
}: GenerationPipelineModalProps) {
  const router = useRouter();
  const [currentStepIndex, setCurrentStepIndex] = React.useState<number>(0);
  const [elapsedSeconds, setElapsedSeconds] = React.useState<number>(0);
  const [isCompleted, setIsCompleted] = React.useState<boolean>(false);
  const [apiError, setApiError] = React.useState<ApiError | null>(null);
  const [isRetrying, setIsRetrying] = React.useState<boolean>(false);

  // Timer interval while generating
  React.useEffect(() => {
    if (!isOpen || isCompleted || apiError) return;

    const timer = setInterval(() => {
      setElapsedSeconds((prev) => prev + 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [isOpen, isCompleted, apiError]);

  // Main generation execution
  const executeGeneration = React.useCallback(async () => {
    if (!payload) return;

    setCurrentStepIndex(0);
    setIsCompleted(false);
    setApiError(null);
    setElapsedSeconds(0);

    // Progressive step animation timers
    const t1 = setTimeout(() => {
      setCurrentStepIndex((prev) => Math.max(prev, 1));
    }, 900);

    const t2 = setTimeout(() => {
      setCurrentStepIndex((prev) => Math.max(prev, 2));
    }, 1900);

    try {
      const draft = await api.generateDraft(payload);

      // Step 4: Final assembly
      setCurrentStepIndex(3);

      setTimeout(() => {
        setIsCompleted(true);
        onSuccess(draft);
      }, 500);
    } catch (err: unknown) {
      console.error("Generation failed:", err);
      if (err instanceof ApiError) {
        setApiError(err);
      } else {
        const message = getApiErrorMessage(err, "Generation failed. Check backend connection.");
        setApiError(
          new ApiError(message, {
            statusCode: 500,
            errorType: "SynthesisError",
          })
        );
      }
    } finally {
      clearTimeout(t1);
      clearTimeout(t2);
    }
  }, [payload, onSuccess]);

  React.useEffect(() => {
    if (isOpen && payload && !isCompleted && !apiError && !isRetrying) {
      executeGeneration();
    }
  }, [isOpen, payload, isCompleted, apiError, isRetrying, executeGeneration]);

  const handleRetry = () => {
    setIsRetrying(true);
    executeGeneration().finally(() => setIsRetrying(false));
  };

  const handleOpenStudio = () => {
    onClose();
    router.push("/review");
  };

  const currentStep = PIPELINE_STEPS[currentStepIndex] || PIPELINE_STEPS[0];
  const progressPercent = isCompleted ? 100 : currentStep.percent;

  const formatTimer = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}s`;
  };

  // Helper diagnostics for error categorization and remediation advice
  const getErrorDiagnostics = (error: ApiError) => {
    const status = error.statusCode;
    const isTimeout = error.isTimeout || status === 408;
    const isNetwork = error.isNetworkError || status === 503;

    if (status === 404 || error.errorType === "ContextNotFound") {
      return {
        badgeText: "Missing Textbook (404)",
        title: "Textbook Material Not Found",
        remediation:
          "No indexed curriculum material was found in Qdrant for this chapter/topic. Ensure the textbook PDF is uploaded in the Admin Ingestion panel, or select another indexed chapter.",
      };
    }

    if (isTimeout) {
      return {
        badgeText: "Generation Timeout (408)",
        title: "AI Synthesis Timed Out (120s Limit)",
        remediation:
          "The generation request exceeded the 120-second timeout. This may occur under heavy concurrent load or large question requests. Click 'Retry Generation' or try reducing question counts.",
      };
    }

    if (isNetwork) {
      return {
        badgeText: "Connection Error (503)",
        title: "Backend Server Unreachable",
        remediation:
          "Cannot connect to the ExamCraft FastAPI backend. Verify that the backend service is running on http://localhost:8000 and Qdrant is operational.",
      };
    }

    if (status === 400 || status === 422 || error.errorType === "ValidationError") {
      return {
        badgeText: `Validation Error (${status || 422})`,
        title: "Invalid Request Parameters",
        remediation:
          "The generation parameters failed schema validation. Please review question counts, subject name, and custom instructions.",
      };
    }

    return {
      badgeText: `Synthesis Error (${status || 500})`,
      title: "AI Question Synthesis Error",
      remediation:
        "An unexpected error occurred during structured question synthesis. Click 'Retry Generation' to retry, or check backend logs.",
    };
  };

  const errorDiagnostics = apiError ? getErrorDiagnostics(apiError) : null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isCompleted && onClose()}>
      <DialogContent className="sm:max-w-md md:max-w-lg p-6 border-border/90 shadow-2xl bg-card">
        <DialogHeader className="space-y-1 text-center sm:text-center pb-2">
          <DialogTitle className="text-lg sm:text-xl font-bold flex items-center justify-center gap-2">
            <Sparkles className="h-5 w-5 text-primary animate-pulse" />
            <span>
              {isCompleted
                ? "Assessment Generated Successfully!"
                : apiError
                ? "Generation Encountered An Error"
                : "AI Assessment Paper Synthesis"}
            </span>
          </DialogTitle>
          <DialogDescription className="text-xs text-muted-foreground">
            {payload?.subject} &bull; {payload?.chapter_name}
          </DialogDescription>
        </DialogHeader>

        {/* Central Orbital Progress Animation */}
        <div className="flex flex-col items-center justify-center py-3 space-y-3">
          <div className="relative h-24 w-24 flex items-center justify-center">
            {/* Outer spinning ring when active */}
            {!isCompleted && !apiError && (
              <div className="absolute inset-0 rounded-full border-4 border-primary/20 border-t-primary animate-spin duration-1000" />
            )}

            {/* Completed state ring */}
            {isCompleted && (
              <div className="absolute inset-0 rounded-full border-4 border-emerald-500 bg-emerald-500/10 animate-in zoom-in-75 duration-300" />
            )}

            {/* Error ring */}
            {apiError && (
              <div className="absolute inset-0 rounded-full border-4 border-rose-500 bg-rose-500/10" />
            )}

            {/* Center icon */}
            <div className="h-14 w-14 rounded-full bg-background border border-border flex items-center justify-center shadow-xs">
              {isCompleted ? (
                <CheckCircle2 className="h-8 w-8 text-emerald-600 dark:text-emerald-400 animate-in zoom-in duration-200" />
              ) : apiError ? (
                <AlertCircle className="h-8 w-8 text-rose-600 dark:text-rose-400" />
              ) : (
                <Sparkles className="h-7 w-7 text-primary animate-pulse" />
              )}
            </div>
          </div>

          {/* Progress Bar & Readout */}
          <div className="w-full space-y-1.5">
            <div className="flex items-center justify-between text-xs font-semibold">
              <span className="text-foreground">
                {isCompleted
                  ? "Ready for Review Studio"
                  : apiError
                  ? "Pipeline Halted"
                  : currentStep.title}
              </span>
              <span className="font-mono text-primary font-bold">
                {progressPercent}%
              </span>
            </div>

            <div className="h-2 w-full rounded-full bg-muted overflow-hidden">
              <div
                className={cn(
                  "h-full transition-all duration-500 rounded-full",
                  isCompleted
                    ? "bg-emerald-500"
                    : apiError
                    ? "bg-rose-500"
                    : "bg-primary"
                )}
                style={{ width: `${progressPercent}%` }}
              />
            </div>

            <div className="flex items-center justify-between text-[11px] text-muted-foreground pt-0.5">
              <span className="flex items-center gap-1 font-mono">
                <Clock className="h-3 w-3" />
                <span>Elapsed: {formatTimer(elapsedSeconds)}</span>
              </span>
              <span>Class {payload?.grade || 9} Grounded RAG</span>
            </div>
          </div>
        </div>

        {/* 4 Pipeline Steps Timeline (hidden on error to focus on diagnostics) */}
        {!apiError && (
          <div className="space-y-2 py-1 border-t border-b border-border/60 my-1">
            {PIPELINE_STEPS.map((step, idx) => {
              const isDone = isCompleted || currentStepIndex > idx;
              const isCurrent = !isCompleted && !apiError && currentStepIndex === idx;

              return (
                <div
                  key={step.stepNumber}
                  className={cn(
                    "flex items-start gap-3 p-2 rounded-lg transition-colors text-xs",
                    isCurrent
                      ? "bg-primary/10 border border-primary/30"
                      : isDone
                      ? "bg-muted/30"
                      : "opacity-60"
                  )}
                >
                  <div className="mt-0.5 shrink-0">
                    {isDone ? (
                      <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                    ) : isCurrent ? (
                      <Loader2 className="h-4 w-4 text-primary animate-spin" />
                    ) : (
                      <span className="h-4 w-4 rounded-full border border-muted-foreground/60 flex items-center justify-center text-[9px] font-mono">
                        {step.stepNumber}
                      </span>
                    )}
                  </div>

                  <div className="space-y-0.5 min-w-0">
                    <div className="flex items-center gap-2">
                      <span
                        className={cn(
                          "font-bold text-xs",
                          isCurrent
                            ? "text-primary"
                            : isDone
                            ? "text-foreground"
                            : "text-muted-foreground"
                        )}
                      >
                        Step {step.stepNumber}: {step.title}
                      </span>
                    </div>
                    <p className="text-[11px] text-muted-foreground line-clamp-1">
                      {step.subtitle}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Categorized Error Diagnostics & Remediation Container */}
        {apiError && errorDiagnostics && (
          <div className="p-3.5 rounded-xl bg-destructive/10 border border-destructive/30 text-xs space-y-2.5 animate-in fade-in-50 duration-200">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1.5 font-bold text-destructive">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{errorDiagnostics.title}</span>
              </div>
              <Badge variant="outline" className="text-[10px] font-mono border-destructive/40 text-destructive bg-destructive/5 shrink-0">
                {errorDiagnostics.badgeText}
              </Badge>
            </div>

            {/* Verbatim Server Error Message */}
            <div className="space-y-1">
              <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                Verbatim Server Message:
              </span>
              <p className="text-[11px] font-mono bg-background/80 p-2 rounded-md border border-border/60 text-foreground leading-relaxed break-words">
                {apiError.message}
              </p>
            </div>

            {/* Clear Remediation Advice */}
            <div className="flex items-start gap-1.5 text-[11px] text-muted-foreground bg-background/50 p-2 rounded-md border border-border/50">
              <Info className="h-3.5 w-3.5 text-primary shrink-0 mt-0.5" />
              <div>
                <span className="font-semibold text-foreground">Remediation Advice: </span>
                <span>{errorDiagnostics.remediation}</span>
              </div>
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="pt-2 flex items-center justify-end gap-2">
          {apiError ? (
            <>
              <Button
                type="button"
                variant="outline"
                onClick={onClose}
                disabled={isRetrying}
                className="text-xs"
              >
                Dismiss & Keep Settings
              </Button>
              <Button
                type="button"
                onClick={handleRetry}
                disabled={isRetrying}
                className="gap-2 text-xs font-semibold shadow-sm"
              >
                <RefreshCw className={cn("h-4 w-4", isRetrying && "animate-spin")} />
                <span>{isRetrying ? "Retrying Synthesis..." : "Retry Generation"}</span>
              </Button>
            </>
          ) : isCompleted ? (
            <Button
              type="button"
              size="lg"
              onClick={handleOpenStudio}
              className="w-full gap-2 shadow-md text-sm font-bold bg-primary hover:bg-primary/90 text-primary-foreground"
            >
              <span>View Draft in Studio</span>
              <ArrowRight className="h-4 w-4" />
            </Button>
          ) : (
            <div className="w-full flex items-center justify-center text-xs text-muted-foreground py-1">
              <span className="flex items-center gap-2">
                <Loader2 className="h-3.5 w-3.5 animate-spin text-primary" />
                <span>Zero-hallucination vector retrieval in progress...</span>
              </span>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
