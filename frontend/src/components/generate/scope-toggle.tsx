"use client";

/**
 * src/components/generate/scope-toggle.tsx
 * ExamCraft AI - Retrieval Scope Selector (Full Chapter vs Specific Topic)
 */

import * as React from "react";
import { Layers, Target, Sparkles, Tag } from "lucide-react";
import { RetrievalMode } from "@/types/exam";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

export interface ScopeToggleProps {
  testType: RetrievalMode;
  onChangeTestType: (type: RetrievalMode) => void;
  topicQuery: string;
  onChangeTopicQuery: (query: string) => void;
  suggestedTopics?: string[];
  disabled?: boolean;
}

const DEFAULT_TOPICS = [
  "Atomic Radius & Ionization Trends",
  "Mendeleev vs Modern Periodic Law",
  "Electronegativity & Halogens",
  "Chemical Reactions & Equations",
];

export function ScopeToggle({
  testType,
  onChangeTestType,
  topicQuery,
  onChangeTopicQuery,
  suggestedTopics = DEFAULT_TOPICS,
  disabled = false,
}: ScopeToggleProps) {
  return (
    <div className="space-y-3">
      <div className="space-y-1.5">
        <label className="text-xs font-semibold text-foreground flex items-center gap-1.5">
          <Layers className="h-3.5 w-3.5 text-primary" />
          <span>Retrieval Scope</span>
        </label>

        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            disabled={disabled}
            onClick={() => onChangeTestType("full_chapter")}
            className={cn(
              "p-2.5 rounded-lg border text-xs font-semibold transition-all flex items-center justify-center gap-2 cursor-pointer shadow-2xs select-none disabled:opacity-50 disabled:cursor-not-allowed",
              testType === "full_chapter"
                ? "border-primary bg-primary/10 text-primary ring-1 ring-primary/40 font-bold"
                : "border-border/80 bg-card text-muted-foreground hover:bg-muted hover:text-foreground"
            )}
          >
            <Layers className="h-4 w-4" />
            <span>Full Chapter</span>
          </button>

          <button
            type="button"
            disabled={disabled}
            onClick={() => onChangeTestType("topic")}
            className={cn(
              "p-2.5 rounded-lg border text-xs font-semibold transition-all flex items-center justify-center gap-2 cursor-pointer shadow-2xs select-none disabled:opacity-50 disabled:cursor-not-allowed",
              testType === "topic"
                ? "border-primary bg-primary/10 text-primary ring-1 ring-primary/40 font-bold"
                : "border-border/80 bg-card text-muted-foreground hover:bg-muted hover:text-foreground"
            )}
          >
            <Target className="h-4 w-4" />
            <span>Specific Topic</span>
          </button>
        </div>
      </div>

      {testType === "topic" && (
        <div className="space-y-2 pt-1 animate-in fade-in-50 slide-in-from-top-1 duration-200">
          <div className="space-y-1">
            <label className="text-[11px] font-medium text-foreground flex items-center gap-1">
              <Target className="h-3 w-3 text-primary" />
              <span>Target Topic Query</span>
              <span className="text-rose-500 font-bold">*</span>
            </label>
            <Input
              value={topicQuery}
              disabled={disabled}
              onChange={(e) => onChangeTopicQuery(e.target.value)}
              placeholder="e.g. Electronegativity Trends, Shielding Effect, Halogens..."
              className="h-9 text-xs"
            />
          </div>

          {suggestedTopics.length > 0 && (
            <div className="space-y-1">
              <span className="text-[10px] text-muted-foreground flex items-center gap-1">
                <Sparkles className="h-2.5 w-2.5 text-primary" />
                <span>Suggested topics for targeted RAG retrieval:</span>
              </span>
              <div className="flex flex-wrap gap-1.5">
                {suggestedTopics.map((top) => (
                  <button
                    key={top}
                    type="button"
                    disabled={disabled}
                    onClick={() => onChangeTopicQuery(top)}
                    className={cn(
                      "px-2 py-0.5 rounded-md border text-[10px] transition-colors flex items-center gap-1 cursor-pointer",
                      topicQuery === top
                        ? "border-primary bg-primary text-primary-foreground font-semibold"
                        : "border-border/60 bg-muted/40 text-muted-foreground hover:bg-muted hover:text-foreground"
                    )}
                  >
                    <Tag className="h-2.5 w-2.5 opacity-70" />
                    <span>{top}</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
