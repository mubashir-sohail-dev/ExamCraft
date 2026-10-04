"use client";

/**
 * src/components/generate/difficulty-selector.tsx
 * ExamCraft AI - Cognitive Difficulty Level Selector (Bloom's Taxonomy)
 */

import * as React from "react";
import { Gauge } from "lucide-react";
import { DifficultyLevel } from "@/types/exam";
import { cn } from "@/lib/utils";

export interface DifficultySelectorProps {
  difficulty: DifficultyLevel;
  onChangeDifficulty: (difficulty: DifficultyLevel) => void;
  disabled?: boolean;
}

interface DifficultyOption {
  level: DifficultyLevel;
  title: string;
  badge: string;
  description: string;
  activeColor: string;
  lightBg: string;
  borderColor: string;
}

const DIFFICULTY_OPTIONS: DifficultyOption[] = [
  {
    level: "easy",
    title: "Easy",
    badge: "Recall & Definitions",
    description: "Fundamental principles, factual recall, and straightforward definitions.",
    activeColor: "text-emerald-700 dark:text-emerald-400",
    lightBg: "bg-emerald-500/10 dark:bg-emerald-500/20",
    borderColor: "border-emerald-500/40 ring-emerald-500/30",
  },
  {
    level: "medium",
    title: "Medium",
    badge: "Conceptual & Application",
    description: "Balanced conceptual understanding, formulas, and standard textbook questions.",
    activeColor: "text-amber-700 dark:text-amber-400",
    lightBg: "bg-amber-500/10 dark:bg-amber-500/20",
    borderColor: "border-amber-500/40 ring-amber-500/30",
  },
  {
    level: "hard",
    title: "Hard",
    badge: "Analytical & Derivations",
    description: "Complex numerical problems, multi-step derivations, and synthesis.",
    activeColor: "text-rose-700 dark:text-rose-400",
    lightBg: "bg-rose-500/10 dark:bg-rose-500/20",
    borderColor: "border-rose-500/40 ring-rose-500/30",
  },
  {
    level: "mixed",
    title: "Mixed",
    badge: "Board Standard Blend",
    description: "Standard Punjab Board distribution (30% Easy, 50% Medium, 20% Hard).",
    activeColor: "text-blue-700 dark:text-blue-400",
    lightBg: "bg-blue-500/10 dark:bg-blue-500/20",
    borderColor: "border-blue-500/40 ring-blue-500/30",
  },
];

export function DifficultySelector({
  difficulty,
  onChangeDifficulty,
  disabled = false,
}: DifficultySelectorProps) {
  const normCurrent = String(difficulty).toLowerCase();

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold text-foreground flex items-center gap-1.5">
          <Gauge className="h-3.5 w-3.5 text-primary" />
          <span>Cognitive Difficulty Level</span>
        </label>
        <span className="text-[10px] text-muted-foreground font-medium">
          Bloom&apos;s Taxonomy Alignment
        </span>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5">
        {DIFFICULTY_OPTIONS.map((opt) => {
          const isSelected = normCurrent === opt.level;

          return (
            <button
              key={opt.level}
              type="button"
              role="radio"
              aria-checked={isSelected}
              disabled={disabled}
              onClick={() => onChangeDifficulty(opt.level)}
              className={cn(
                "p-3 rounded-xl border text-left transition-all duration-150 cursor-pointer flex flex-col justify-between gap-1.5 shadow-2xs select-none disabled:opacity-50 disabled:cursor-not-allowed",
                isSelected
                  ? cn(opt.lightBg, opt.borderColor, "ring-2 border-primary shadow-xs")
                  : "border-border/80 bg-card hover:bg-muted/40 hover:border-border"
              )}
            >
              <div className="flex items-center justify-between w-full">
                <span
                  className={cn(
                    "font-bold text-xs uppercase tracking-wider",
                    isSelected ? opt.activeColor : "text-foreground"
                  )}
                >
                  {opt.title}
                </span>
                {isSelected && (
                  <span className="h-2 w-2 rounded-full bg-primary animate-pulse" />
                )}
              </div>

              <div className="space-y-0.5">
                <span className="text-[10px] font-semibold text-muted-foreground block truncate">
                  {opt.badge}
                </span>
                <p className="text-[10px] text-muted-foreground line-clamp-2 leading-relaxed">
                  {opt.description}
                </p>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}
