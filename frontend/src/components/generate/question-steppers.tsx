"use client";

/**
 * src/components/generate/question-steppers.tsx
 * ExamCraft AI - Question Count Steppers with Marks Weighting & Presets
 */

import * as React from "react";
import { Plus, Minus, ListChecks, HelpCircle, FileText, Zap } from "lucide-react";
import { QUESTION_WEIGHTS } from "@/lib/constants";
import { cn } from "@/lib/utils";

export interface QuestionSteppersProps {
  mcqCount: number;
  onChangeMcqCount: (val: number) => void;
  shortCount: number;
  onChangeShortCount: (val: number) => void;
  longCount: number;
  onChangeLongCount: (val: number) => void;
  disabled?: boolean;
}

export function QuestionSteppers({
  mcqCount,
  onChangeMcqCount,
  shortCount,
  onChangeShortCount,
  longCount,
  onChangeLongCount,
  disabled = false,
}: QuestionSteppersProps) {
  const applyPreset = (mcqs: number, shorts: number, longs: number) => {
    onChangeMcqCount(mcqs);
    onChangeShortCount(shorts);
    onChangeLongCount(longs);
  };

  return (
    <div className="space-y-3">
      {/* 1. MCQs Stepper */}
      <div className="flex items-center justify-between p-3 rounded-xl bg-card border border-border/80 shadow-2xs hover:border-border transition-colors">
        <div className="space-y-0.5 pr-2">
          <div className="flex items-center gap-1.5">
            <ListChecks className="h-4 w-4 text-blue-600 dark:text-blue-400" />
            <span className="font-bold text-xs text-foreground">Section A: Multiple Choice (MCQs)</span>
          </div>
          <p className="text-[11px] text-muted-foreground">
            {QUESTION_WEIGHTS.MCQ} Mark each &bull; 4 choices (A, B, C, D) with textbook citation
          </p>
        </div>

        <div className="flex items-center border border-border rounded-lg bg-card shadow-2xs overflow-hidden shrink-0">
          <button
            type="button"
            disabled={disabled || mcqCount <= 1}
            onClick={() => onChangeMcqCount(Math.max(1, mcqCount - 1))}
            className="h-8 w-8 flex items-center justify-center hover:bg-muted/70 active:bg-muted text-muted-foreground hover:text-foreground transition-colors disabled:opacity-30 disabled:cursor-not-allowed border-r border-border cursor-pointer"
            title="Decrease MCQs"
          >
            <Minus className="h-3.5 w-3.5" />
          </button>

          <span className="font-mono font-bold text-xs w-9 text-center text-foreground select-none">
            {mcqCount}
          </span>

          <button
            type="button"
            disabled={disabled || mcqCount >= 20}
            onClick={() => onChangeMcqCount(Math.min(20, mcqCount + 1))}
            className="h-8 w-8 flex items-center justify-center hover:bg-muted/70 active:bg-muted text-muted-foreground hover:text-foreground transition-colors disabled:opacity-30 disabled:cursor-not-allowed border-l border-border cursor-pointer"
            title="Increase MCQs"
          >
            <Plus className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      {/* 2. Short Questions Stepper */}
      <div className="flex items-center justify-between p-3 rounded-xl bg-card border border-border/80 shadow-2xs hover:border-border transition-colors">
        <div className="space-y-0.5 pr-2">
          <div className="flex items-center gap-1.5">
            <HelpCircle className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
            <span className="font-bold text-xs text-foreground">Section B: Short Answer Questions</span>
          </div>
          <p className="text-[11px] text-muted-foreground">
            {QUESTION_WEIGHTS.SHORT} Marks each &bull; Concise conceptual & numerical problems
          </p>
        </div>

        <div className="flex items-center border border-border rounded-lg bg-card shadow-2xs overflow-hidden shrink-0">
          <button
            type="button"
            disabled={disabled || shortCount <= 0}
            onClick={() => onChangeShortCount(Math.max(0, shortCount - 1))}
            className="h-8 w-8 flex items-center justify-center hover:bg-muted/70 active:bg-muted text-muted-foreground hover:text-foreground transition-colors disabled:opacity-30 disabled:cursor-not-allowed border-r border-border cursor-pointer"
            title="Decrease Short Questions"
          >
            <Minus className="h-3.5 w-3.5" />
          </button>

          <span className="font-mono font-bold text-xs w-9 text-center text-foreground select-none">
            {shortCount}
          </span>

          <button
            type="button"
            disabled={disabled || shortCount >= 10}
            onClick={() => onChangeShortCount(Math.min(10, shortCount + 1))}
            className="h-8 w-8 flex items-center justify-center hover:bg-muted/70 active:bg-muted text-muted-foreground hover:text-foreground transition-colors disabled:opacity-30 disabled:cursor-not-allowed border-l border-border cursor-pointer"
            title="Increase Short Questions"
          >
            <Plus className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      {/* 3. Long Questions Stepper */}
      <div className="flex items-center justify-between p-3 rounded-xl bg-card border border-border/80 shadow-2xs hover:border-border transition-colors">
        <div className="space-y-0.5 pr-2">
          <div className="flex items-center gap-1.5">
            <FileText className="h-4 w-4 text-purple-600 dark:text-purple-400" />
            <span className="font-bold text-xs text-foreground">Section C: Long / Essay Questions</span>
          </div>
          <p className="text-[11px] text-muted-foreground">
            {QUESTION_WEIGHTS.LONG} Marks each &bull; In-depth derivations & multi-part questions
          </p>
        </div>

        <div className="flex items-center border border-border rounded-lg bg-card shadow-2xs overflow-hidden shrink-0">
          <button
            type="button"
            disabled={disabled || longCount <= 0}
            onClick={() => onChangeLongCount(Math.max(0, longCount - 1))}
            className="h-8 w-8 flex items-center justify-center hover:bg-muted/70 active:bg-muted text-muted-foreground hover:text-foreground transition-colors disabled:opacity-30 disabled:cursor-not-allowed border-r border-border cursor-pointer"
            title="Decrease Long Questions"
          >
            <Minus className="h-3.5 w-3.5" />
          </button>

          <span className="font-mono font-bold text-xs w-9 text-center text-foreground select-none">
            {longCount}
          </span>

          <button
            type="button"
            disabled={disabled || longCount >= 5}
            onClick={() => onChangeLongCount(Math.min(5, longCount + 1))}
            className="h-8 w-8 flex items-center justify-center hover:bg-muted/70 active:bg-muted text-muted-foreground hover:text-foreground transition-colors disabled:opacity-30 disabled:cursor-not-allowed border-l border-border cursor-pointer"
            title="Increase Long Questions"
          >
            <Plus className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      {/* Quick Presets */}
      <div className="pt-1 space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-[10px] uppercase tracking-wider font-bold text-muted-foreground flex items-center gap-1.5">
            <Zap className="h-3 w-3 text-amber-500" />
            <span>Quick Distribution Presets</span>
          </span>
        </div>
        <div className="grid grid-cols-3 gap-2">
          <button
            type="button"
            disabled={disabled}
            onClick={() => applyPreset(5, 3, 1)}
            className={cn(
              "p-2 rounded-lg border text-center transition-all cursor-pointer text-xs flex flex-col items-center justify-center gap-0.5 shadow-2xs",
              mcqCount === 5 && shortCount === 3 && longCount === 1
                ? "border-primary bg-primary/10 text-primary font-bold ring-1 ring-primary/30"
                : "border-border/70 bg-card hover:bg-muted/60 text-muted-foreground hover:text-foreground"
            )}
          >
            <span className="font-semibold text-xs">Standard (16m)</span>
            <span className="text-[10px] opacity-75">5 MCQ &bull; 3 Sh &bull; 1 Lg</span>
          </button>

          <button
            type="button"
            disabled={disabled}
            onClick={() => applyPreset(10, 5, 2)}
            className={cn(
              "p-2 rounded-lg border text-center transition-all cursor-pointer text-xs flex flex-col items-center justify-center gap-0.5 shadow-2xs",
              mcqCount === 10 && shortCount === 5 && longCount === 2
                ? "border-primary bg-primary/10 text-primary font-bold ring-1 ring-primary/30"
                : "border-border/70 bg-card hover:bg-muted/60 text-muted-foreground hover:text-foreground"
            )}
          >
            <span className="font-semibold text-xs">Class Test (30m)</span>
            <span className="text-[10px] opacity-75">10 MCQ &bull; 5 Sh &bull; 2 Lg</span>
          </button>

          <button
            type="button"
            disabled={disabled}
            onClick={() => applyPreset(12, 8, 3)}
            className={cn(
              "p-2 rounded-lg border text-center transition-all cursor-pointer text-xs flex flex-col items-center justify-center gap-0.5 shadow-2xs",
              mcqCount === 12 && shortCount === 8 && longCount === 3
                ? "border-primary bg-primary/10 text-primary font-bold ring-1 ring-primary/30"
                : "border-border/70 bg-card hover:bg-muted/60 text-muted-foreground hover:text-foreground"
            )}
          >
            <span className="font-semibold text-xs">Board Mock (43m)</span>
            <span className="text-[10px] opacity-75">12 MCQ &bull; 8 Sh &bull; 3 Lg</span>
          </button>
        </div>
      </div>
    </div>
  );
}
