"use client";

import * as React from "react";
import Link from "next/link";
import {
  FileText,
  Download,
  Printer,
  BookmarkCheck,
  PlusCircle,
  Settings2,
  Atom,
  TestTube2,
  Calculator,
  Dna,
  Laptop,
  Check,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Class9TestSchema } from "@/types/exam";
import { calculateTestSchemaMarks } from "@/lib/utils";

interface MarksSummaryBarProps {
  test: Class9TestSchema;
  isDirty?: boolean;
  onAddQuestion: () => void;
  onEditMetadata: () => void;
  onSavePaper: () => void;
  onPrint?: () => void;
  savedRecently?: boolean;
}

export function MarksSummaryBar({
  test,
  isDirty = false,
  onAddQuestion,
  onEditMetadata,
  onSavePaper,
  onPrint,
  savedRecently = false,
}: MarksSummaryBarProps) {
  const mcqCount = test.mcqs?.length || 0;
  const shortCount = test.short_questions?.length || 0;
  const longCount = test.long_questions?.length || 0;
  const totalQuestions = mcqCount + shortCount + longCount;

  const totalMarks = calculateTestSchemaMarks(test);

  const mcqMarks = (test.mcqs || []).reduce((acc, q) => acc + (q.marks || 1), 0);
  const shortMarks = (test.short_questions || []).reduce(
    (acc, q) => acc + (q.marks || 2),
    0
  );
  const longMarks = (test.long_questions || []).reduce(
    (acc, q) => acc + (q.marks || 5),
    0
  );

  const getSubjectBadgeVariant = (subject: string) => {
    switch (subject?.toLowerCase()) {
      case "physics":
        return "physics";
      case "chemistry":
        return "chemistry";
      case "mathematics":
        return "mathematics";
      case "biology":
        return "biology";
      case "computer science":
        return "computer-science";
      default:
        return "default";
    }
  };

  const getSubjectIcon = (subject: string) => {
    switch (subject?.toLowerCase()) {
      case "physics":
        return <Atom className="h-4 w-4" />;
      case "chemistry":
        return <TestTube2 className="h-4 w-4" />;
      case "mathematics":
        return <Calculator className="h-4 w-4" />;
      case "biology":
        return <Dna className="h-4 w-4" />;
      case "computer science":
        return <Laptop className="h-4 w-4" />;
      default:
        return <FileText className="h-4 w-4" />;
    }
  };

  return (
    <div className="sticky top-16 z-20 rounded-xl border border-border/80 bg-background/95 backdrop-blur-md p-3.5 shadow-sm transition-all">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        {/* Left: Test Title, Subject & Syllabus */}
        <div className="flex items-start sm:items-center gap-3">
          <div className="p-2 rounded-xl bg-primary/10 text-primary shrink-0 hidden sm:flex">
            {getSubjectIcon(test.subject)}
          </div>
          <div className="space-y-1">
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-base sm:text-lg font-bold tracking-tight text-foreground truncate max-w-md">
                {test.test_title}
              </h1>
              <Badge
                variant={getSubjectBadgeVariant(test.subject) as never}
                size="sm"
                className="capitalize font-semibold"
              >
                {test.subject}
              </Badge>
              <Badge variant="outline" size="sm" className="font-bold text-xs bg-muted/40 text-foreground border-border/80">
                Class {test.grade || 9}
              </Badge>
              {isDirty && (
                <span className="flex items-center gap-1 text-[10px] font-medium text-amber-600 dark:text-amber-400 bg-amber-500/10 px-1.5 py-0.5 rounded">
                  <span className="h-1.5 w-1.5 rounded-full bg-amber-500 animate-pulse" />
                  Unsaved changes
                </span>
              )}
            </div>
            <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <span>{test.chapter_or_topic}</span>
              <span>&bull;</span>
              <span>Time: <strong className="text-foreground">{test.time_allowed}</strong></span>
              <span>&bull;</span>
              <span>
                <strong>{totalQuestions}</strong> Questions ({mcqCount} MCQ, {shortCount} Short, {longCount} Long)
              </span>
            </div>
          </div>
        </div>

        {/* Right: Section Breakdown Chips & Action Toolbar */}
        <div className="flex flex-wrap items-center justify-between lg:justify-end gap-2 pt-2 lg:pt-0 border-t lg:border-t-0 border-border/50">
          {/* Section Breakdown Pills */}
          <div className="hidden sm:flex items-center gap-1.5">
            <span className="text-[11px] px-2 py-1 rounded-md border border-primary/30 bg-primary/5 text-primary font-medium">
              Sec A: <strong>{mcqMarks}m</strong>
            </span>
            <span className="text-[11px] px-2 py-1 rounded-md border border-purple-500/30 bg-purple-500/5 text-purple-600 dark:text-purple-400 font-medium">
              Sec B: <strong>{shortMarks}m</strong>
            </span>
            <span className="text-[11px] px-2 py-1 rounded-md border border-amber-500/30 bg-amber-500/5 text-amber-600 dark:text-amber-400 font-medium">
              Sec C: <strong>{longMarks}m</strong>
            </span>
            <div className="px-2.5 py-1 rounded-md border border-border bg-card text-xs font-mono font-bold">
              <span>Total: </span>
              <span className="text-primary font-bold">{totalMarks}m</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap items-center gap-1.5 w-full sm:w-auto">
            {/* Add Question Button */}
            <Button
              size="sm"
              variant="outline"
              onClick={onAddQuestion}
              className="h-8 text-xs gap-1.5"
            >
              <PlusCircle className="h-3.5 w-3.5 text-primary" />
              <span>Add Question</span>
            </Button>

            {/* Edit Metadata */}
            <Button
              size="sm"
              variant="outline"
              onClick={onEditMetadata}
              className="h-8 text-xs gap-1.5"
              title="Edit Title, Chapter, Time, Instructions"
            >
              <Settings2 className="h-3.5 w-3.5 text-muted-foreground" />
              <span className="hidden sm:inline">Details</span>
            </Button>

            {/* Save to Papers */}
            <Button
              size="sm"
              variant="outline"
              onClick={onSavePaper}
              className={`h-8 text-xs gap-1.5 transition-colors ${
                savedRecently
                  ? "border-emerald-500/50 bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300"
                  : ""
              }`}
              title="Save test to Recent Papers history"
            >
              {savedRecently ? (
                <>
                  <Check className="h-3.5 w-3.5 text-emerald-600 dark:text-emerald-400" />
                  <span>Saved</span>
                </>
              ) : (
                <>
                  <BookmarkCheck className="h-3.5 w-3.5 text-muted-foreground" />
                  <span className="hidden sm:inline">Save</span>
                </>
              )}
            </Button>

            {/* Direct Print */}
            {onPrint && (
              <Button
                size="sm"
                variant="outline"
                onClick={onPrint}
                className="h-8 text-xs gap-1.5 hidden md:flex"
                title="Print test directly via browser print"
              >
                <Printer className="h-3.5 w-3.5 text-muted-foreground" />
                <span className="hidden lg:inline">Print</span>
              </Button>
            )}

            {/* Export PDF Button */}
            <Link href="/pdf-preview">
              <Button size="sm" className="h-8 text-xs gap-1.5 shadow-xs">
                <Download className="h-3.5 w-3.5" />
                <span>Export PDF</span>
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
