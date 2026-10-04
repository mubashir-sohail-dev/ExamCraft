"use client";

/**
 * src/components/generate/marks-calculator-card.tsx
 * ExamCraft AI - Real-time Live Marks Calculator Card with Section Breakdown Chips
 */

import * as React from "react";
import { Calculator, Clock } from "lucide-react";
import { calculateTotalMarks } from "@/lib/utils";
import { SubjectType } from "@/types/exam";

export interface MarksCalculatorCardProps {
  mcqCount: number;
  shortCount: number;
  longCount: number;
  subject?: SubjectType | string;
}

export function MarksCalculatorCard({
  mcqCount,
  shortCount,
  longCount,
  subject: _subject = "Chemistry",
}: MarksCalculatorCardProps) {
  const totalMarks = calculateTotalMarks(mcqCount, shortCount, longCount);
  const totalQuestions = mcqCount + shortCount + longCount;

  // Suggested time estimate
  const suggestedTime =
    totalMarks <= 15
      ? "30 Minutes"
      : totalMarks <= 25
      ? "45 Minutes"
      : totalMarks <= 40
      ? "1 Hour"
      : totalMarks <= 60
      ? "1.5 Hours"
      : "2 - 3 Hours";

  return (
    <div className="p-5 sm:p-6 rounded-xl border border-border bg-card space-y-4 shadow-2xs relative overflow-hidden">
      <div className="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-primary/80 via-primary to-primary/40" />

      {/* Header and Total Marks */}
      <div className="flex items-center justify-between border-b border-border/60 pb-3 pt-0.5">
        <div className="flex items-center gap-2.5">
          <div className="h-8 w-8 rounded-lg bg-primary/10 text-primary border border-primary/20 flex items-center justify-center shadow-2xs">
            <Calculator className="h-4 w-4" />
          </div>
          <div>
            <span className="text-xs font-bold text-foreground block">Live Marks Calculator</span>
            <span className="text-[10px] text-muted-foreground font-mono">
              (MCQs &times; 1) + (Short &times; 2) + (Long &times; 5)
            </span>
          </div>
        </div>

        <div className="text-right flex items-baseline gap-1.5">
          <span className="text-2xl font-black text-primary font-mono tracking-tight leading-none">
            {totalMarks}
          </span>
          <div className="text-left">
            <span className="text-[11px] font-bold text-foreground block uppercase leading-none">Marks</span>
            <span className="text-[9px] text-muted-foreground font-mono leading-none">
              {totalQuestions} Qs
            </span>
          </div>
        </div>
      </div>

      {/* Breakdown Chips */}
      <div className="grid grid-cols-3 gap-2 text-center text-xs">
        <div className="p-2.5 rounded-lg bg-muted/40 border border-border/70 flex flex-col items-center justify-center gap-0.5">
          <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wide">Section A</span>
          <span className="font-bold text-foreground font-mono text-xs">
            {mcqCount} &times; 1m = <span className="text-primary">{mcqCount}m</span>
          </span>
        </div>

        <div className="p-2.5 rounded-lg bg-muted/40 border border-border/70 flex flex-col items-center justify-center gap-0.5">
          <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wide">Section B</span>
          <span className="font-bold text-foreground font-mono text-xs">
            {shortCount} &times; 2m = <span className="text-primary">{shortCount * 2}m</span>
          </span>
        </div>

        <div className="p-2.5 rounded-lg bg-muted/40 border border-border/70 flex flex-col items-center justify-center gap-0.5">
          <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wide">Section C</span>
          <span className="font-bold text-foreground font-mono text-xs">
            {longCount} &times; 5m = <span className="text-primary">{longCount * 5}m</span>
          </span>
        </div>
      </div>

      {/* Recommended Duration Pill */}
      <div className="flex items-center justify-between pt-1 border-t border-border/50 text-xs text-muted-foreground">
        <span className="flex items-center gap-1.5">
          <Clock className="h-3.5 w-3.5 text-primary" />
          <span>Suggested Time Allowed:</span>
        </span>
        <span className="font-semibold text-foreground bg-muted/50 px-2.5 py-0.5 rounded-md border border-border/70 font-mono text-xs">
          {suggestedTime}
        </span>
      </div>
    </div>
  );
}
