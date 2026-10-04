"use client";

import * as React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { HtmlRenderer } from "@/components/shared/html-renderer";
import {
  MCQItem,
  ShortQuestionItem,
  LongQuestionItem,
} from "@/types/exam";
import { QuestionSection } from "@/context/TestDraftContext";
import { getApiErrorMessage } from "@/lib/api";
import { Sparkles, Loader2, RefreshCw, AlertCircle } from "lucide-react";

interface QuestionRegenModalProps {
  isOpen: boolean;
  onClose: () => void;
  section: QuestionSection;
  index: number;
  question: MCQItem | ShortQuestionItem | LongQuestionItem | null;
  onRegenerate: (
    section: QuestionSection,
    index: number,
    instruction: string
  ) => Promise<void>;
}

const INSTRUCTION_PRESETS = [
  "Focus on numerical calculation and formula application",
  "Increase cognitive depth & analytical reasoning",
  "Focus on fundamental definition and basic concepts",
  "Ask about laboratory experiments and practical diagrams",
  "Generate a question from another topic in this chapter",
];

export function QuestionRegenModal({
  isOpen,
  onClose,
  section,
  index,
  question,
  onRegenerate,
}: QuestionRegenModalProps) {
  const [instruction, setInstruction] = React.useState("");
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (isOpen) {
      setInstruction("");
      setError(null);
      setLoading(false);
    }
  }, [isOpen]);

  if (!isOpen || !question) return null;

  const qText = question.question || question.question_text || "";

  const handleExecuteRegen = async () => {
    setLoading(true);
    setError(null);
    try {
      await onRegenerate(section, index, instruction.trim());
      onClose();
    } catch (err: unknown) {
      console.error("Single question regeneration failed:", err);
      setError(
        getApiErrorMessage(
          err,
          "Failed to regenerate question. Please check backend connection."
        )
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !loading && onClose()}>
      <DialogContent className="max-w-xl">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <Sparkles className="h-4 w-4" />
            </div>
            <div>
              <DialogTitle className="text-base font-bold">
                AI Question Regeneration
              </DialogTitle>
              <DialogDescription className="text-xs">
                Generate a fresh, curriculum-aligned alternative for Question {question.question_number}
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Current Question Preview Box */}
          <div className="rounded-xl border border-border/70 bg-muted/20 p-3 text-xs space-y-1.5">
            <div className="flex items-center justify-between text-muted-foreground">
              <span className="font-semibold text-foreground">
                Current Question {question.question_number}:
              </span>
              <Badge variant="outline" size="sm" className="text-[10px]">
                {question.marks || 1} {question.marks === 1 ? "Mark" : "Marks"}
              </Badge>
            </div>
            <p className="text-muted-foreground line-clamp-2 italic">
              &ldquo;<HtmlRenderer content={qText} />&rdquo;
            </p>
          </div>

          {/* Preset Prompts Chips */}
          <div className="space-y-1.5">
            <Label className="text-xs font-semibold text-foreground">
              Quick Teacher Directives:
            </Label>
            <div className="flex flex-wrap gap-1.5">
              {INSTRUCTION_PRESETS.map((preset) => (
                <button
                  key={preset}
                  type="button"
                  onClick={() => setInstruction(preset)}
                  className={`rounded-lg border px-2.5 py-1 text-[11px] text-left transition-all ${
                    instruction === preset
                      ? "border-primary bg-primary/10 text-primary font-medium shadow-2xs"
                      : "border-border/60 bg-card hover:bg-muted/50 text-muted-foreground hover:text-foreground"
                  }`}
                >
                  {preset}
                </button>
              ))}
            </div>
          </div>

          {/* Custom Instruction Input */}
          <div className="space-y-1">
            <Label htmlFor="custom-regen-prompt" className="text-xs font-semibold">
              Custom AI Prompt / Specific Guidelines:
            </Label>
            <Textarea
              id="custom-regen-prompt"
              rows={3}
              value={instruction}
              onChange={(e) => setInstruction(e.target.value)}
              placeholder="e.g. Include chemical equation for neutralization or make question require finding molecular mass..."
              className="text-xs"
            />
          </div>

          {/* Error Message if any */}
          {error && (
            <div className="flex items-start gap-2 rounded-lg bg-destructive/10 p-2.5 text-xs text-destructive">
              <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}
        </div>

        <DialogFooter className="gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={onClose}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            size="sm"
            onClick={handleExecuteRegen}
            disabled={loading}
            className="gap-1.5 shadow-xs"
          >
            {loading ? (
              <>
                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                <span>Synthesizing Question...</span>
              </>
            ) : (
              <>
                <RefreshCw className="h-3.5 w-3.5" />
                <span>Regenerate with AI</span>
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
