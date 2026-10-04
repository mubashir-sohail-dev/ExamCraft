"use client";

/**
 * src/components/shell/class-switcher.tsx
 * ExamCraft AI - Global Class / Grade Level Switcher (Classes 9, 10, 11, 12)
 */

import * as React from "react";
import { GraduationCap, ChevronDown, Check } from "lucide-react";
import { useTestDraft } from "@/context/TestDraftContext";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { AVAILABLE_CLASSES, ClassGrade } from "@/types/exam";
import { cn } from "@/lib/utils";

const CLASS_DETAILS: Record<
  ClassGrade,
  { label: string; subLabel: string; tier: string; badgeColor: string }
> = {
  9: {
    label: "Class 9",
    subLabel: "Matriculation Part I (SSC-I)",
    tier: "SSC-I",
    badgeColor: "bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/30",
  },
  10: {
    label: "Class 10",
    subLabel: "Matriculation Part II (SSC-II)",
    tier: "SSC-II",
    badgeColor: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30",
  },
  11: {
    label: "Class 11",
    subLabel: "Intermediate Part I (HSSC-I / F.Sc)",
    tier: "HSSC-I",
    badgeColor: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30",
  },
  12: {
    label: "Class 12",
    subLabel: "Intermediate Part II (HSSC-II / F.Sc)",
    tier: "HSSC-II",
    badgeColor: "bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/30",
  },
};

export function ClassSwitcher({ className }: { className?: string }) {
  const { activeGrade, setActiveGrade } = useTestDraft();

  const currentGrade = (activeGrade in CLASS_DETAILS
    ? activeGrade
    : 9) as ClassGrade;
  const activeDetails = CLASS_DETAILS[currentGrade] || CLASS_DETAILS[9];

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="outline"
          size="sm"
          className={cn(
            "h-8 gap-1.5 px-2.5 text-xs font-semibold border-border/80 bg-background/80 hover:bg-muted/60 transition-all shadow-2xs cursor-pointer",
            className
          )}
          title="Select Academic Class Level (9 - 12)"
        >
          <GraduationCap className="h-3.5 w-3.5 text-primary" />
          <span className="font-bold text-foreground">{activeDetails.label}</span>
          <span
            className={cn(
              "hidden sm:inline-flex rounded px-1 text-[9px] font-bold uppercase tracking-wider border",
              activeDetails.badgeColor
            )}
          >
            {activeDetails.tier}
          </span>
          <ChevronDown className="h-3 w-3 text-muted-foreground ml-0.5" />
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent align="end" className="w-64 p-1.5 shadow-lg">
        <DropdownMenuLabel className="px-2 py-1 text-[11px] font-bold text-muted-foreground uppercase tracking-wider">
          Select Academic Class
        </DropdownMenuLabel>
        <DropdownMenuSeparator />

        {AVAILABLE_CLASSES.map((grade) => {
          const item = CLASS_DETAILS[grade];
          const isSelected = activeGrade === grade;

          return (
            <DropdownMenuItem
              key={grade}
              onClick={() => setActiveGrade(grade)}
              className={cn(
                "flex items-center justify-between px-2.5 py-2 rounded-lg cursor-pointer transition-colors text-xs",
                isSelected
                  ? "bg-primary/10 text-primary font-semibold dark:bg-primary/20"
                  : "hover:bg-muted/70 text-foreground"
              )}
            >
              <div className="flex flex-col gap-0.5">
                <div className="flex items-center gap-1.5">
                  <span className="font-bold">{item.label}</span>
                  <span
                    className={cn(
                      "rounded px-1 text-[9px] font-bold border",
                      item.badgeColor
                    )}
                  >
                    {item.tier}
                  </span>
                </div>
                <span className="text-[10px] text-muted-foreground">
                  {item.subLabel}
                </span>
              </div>

              {isSelected && <Check className="h-4 w-4 text-primary stroke-[2.5]" />}
            </DropdownMenuItem>
          );
        })}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
