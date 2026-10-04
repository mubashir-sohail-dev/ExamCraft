"use client";

/**
 * src/components/generate/subject-selector.tsx
 * ExamCraft AI - Subject Card Selector Grid with Token Accents & Icons
 */

import * as React from "react";
import { Check } from "lucide-react";
import { ALL_SUBJECTS, SubjectThemeConfig } from "@/lib/subject-colors";
import { SubjectType } from "@/types/exam";
import { cn } from "@/lib/utils";

export interface SubjectSelectorProps {
  selectedSubject: SubjectType;
  onSelectSubject: (subject: SubjectType) => void;
  disabled?: boolean;
}

export function SubjectSelector({
  selectedSubject,
  onSelectSubject,
  disabled = false,
}: SubjectSelectorProps) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground">
          Step 1: Select Subject
        </label>
        <span className="text-[11px] text-muted-foreground font-medium">
          5 Curriculum Subjects Available
        </span>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
        {ALL_SUBJECTS.map((config: SubjectThemeConfig ) => {
          const Icon = config.icon;
          const isSelected = selectedSubject === config.apiString;

          return (
            <button
              key={config.id}
              type="button"
              role="radio"
              aria-checked={isSelected}
              disabled={disabled}
              onClick={() => onSelectSubject(config.apiString as SubjectType)}
              className={cn(
                "group relative p-3.5 rounded-xl border text-left transition-all duration-200 cursor-pointer flex flex-col justify-between gap-3 shadow-2xs select-none disabled:opacity-50 disabled:cursor-not-allowed",
                isSelected
                  ? "border-primary bg-primary/5 ring-2 ring-primary/40 shadow-xs"
                  : "border-border/80 bg-card hover:border-border hover:bg-muted/40"
              )}
            >
              {/* Top Row: Icon and Selection Badge */}
              <div className="flex items-center justify-between w-full">
                <div
                  className="h-9 w-9 rounded-lg flex items-center justify-center transition-transform group-hover:scale-105"
                  style={{
                    backgroundColor: `color-mix(in srgb, ${config.lightHex} 15%, transparent)`,
                    color: config.lightHex,
                  }}
                >
                  <Icon className="h-5 w-5" />
                </div>

                {isSelected ? (
                  <span className="h-5 w-5 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xs shadow-xs animate-in zoom-in-50 duration-150">
                    <Check className="h-3 w-3 stroke-[3]" />
                  </span>
                ) : (
                  <span className="h-4 w-4 rounded-full border border-border/80 group-hover:border-primary/50 transition-colors" />
                )}
              </div>

              {/* Bottom Row: Text details */}
              <div className="space-y-1">
                <h3 className="font-bold text-xs sm:text-sm text-foreground tracking-tight flex items-center gap-1.5">
                  {config.displayName}
                </h3>
                <p className="text-[10px] text-muted-foreground line-clamp-2 leading-relaxed">
                  {config.description}
                </p>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}
