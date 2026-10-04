"use client";

/**
 * src/components/generate/exercise-selector.tsx
 * ExamCraft AI - Dynamic Exercise Selector for Mathematics & Indexed Metadata
 */

import * as React from "react";
import { Calculator, Loader2, Sparkles, ChevronDown } from "lucide-react";
import { api } from "@/lib/api";
import { SubjectType } from "@/types/exam";

export interface ExerciseSelectorProps {
  subject: SubjectType | string;
  chapter: string;
  grade?: number;
  selectedExercise: string | null;
  onSelectExercise: (exercise: string | null) => void;
  disabled?: boolean;
}

// Client-side cache for chapter exercises (0ms instant hits)
const clientExerciseCache = new Map<string, string[]>();

export function ExerciseSelector({
  subject,
  chapter,
  grade,
  selectedExercise,
  onSelectExercise,
  disabled = false,
}: ExerciseSelectorProps) {
  const [exercises, setExercises] = React.useState<string[]>([]);
  const [isLoading, setIsLoading] = React.useState<boolean>(false);

  const isMath = subject === "Mathematics";

  React.useEffect(() => {
    let isMounted = true;
    if (!isMath || !chapter) {
      setExercises([]);
      onSelectExercise(null);
      return;
    }

    const cacheKey = `${subject}_${chapter}_${grade ?? "all"}`;
    if (clientExerciseCache.has(cacheKey)) {
      const cached = clientExerciseCache.get(cacheKey) || [];
      setExercises(cached);
      setIsLoading(false);
      return;
    }

    async function loadMetadata() {
      setIsLoading(true);
      try {
        const meta = await api.getChapterMetadata(subject, chapter, grade);
        if (isMounted) {
          const list = meta.exercises || [];
          clientExerciseCache.set(cacheKey, list);
          setExercises(list);
        }
      } catch {
        if (isMounted) {
          setExercises([]);
        }
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }

    loadMetadata();
    return () => {
      isMounted = false;
    };
  }, [subject, chapter, isMath, onSelectExercise, grade]);

  if (!isMath && exercises.length === 0) {
    return null;
  }

  return (
    <div className="space-y-1.5 animate-in fade-in-50 duration-200">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold text-foreground flex items-center gap-1.5">
          <Calculator className="h-3.5 w-3.5 text-amber-600 dark:text-amber-400" />
          <span>Exercise Focus (Optional)</span>
        </label>
        {isLoading && (
          <span className="flex items-center gap-1 text-[11px] text-muted-foreground">
            <Loader2 className="h-3 w-3 animate-spin text-amber-600 dark:text-amber-400" />
            <span>Scanning exercises...</span>
          </span>
        )}
      </div>

      {isLoading ? (
        <div className="h-9 w-full rounded-lg border border-border/80 bg-muted/40 animate-pulse flex items-center px-3">
          <span className="text-xs text-muted-foreground">Loading exercises...</span>
        </div>
      ) : (
        <div className="relative">
          <select
            value={selectedExercise || "all"}
            disabled={disabled || isLoading}
            onChange={(e) => {
              const val = e.target.value;
              onSelectExercise(val === "all" ? null : val);
            }}
            className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <option value="all" className="bg-card text-foreground py-1">
              Entire Chapter (All Exercises & Review Exercises)
            </option>
            {exercises.map((ex) => (
              <option key={ex} value={ex} className="bg-card text-foreground py-1">
                {ex}
              </option>
            ))}
          </select>
          <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        </div>
      )}
      <p className="text-[10px] text-muted-foreground flex items-center gap-1">
        <Sparkles className="h-3 w-3 text-amber-500 shrink-0" />
        <span>Targeting a specific exercise applies vector payload boosting in Qdrant.</span>
      </p>
    </div>
  );
}
