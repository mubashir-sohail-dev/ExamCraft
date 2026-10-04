"use client";

import * as React from "react";
import {
  Sparkles,
  Edit3,
  Trash2,
  ArrowUp,
  ArrowDown,
  CheckCircle2,
  BookOpen,
  HelpCircle,
  ListChecks,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { HtmlRenderer } from "@/components/shared/html-renderer";
import {
  MCQItem,
  ShortQuestionItem,
  LongQuestionItem,
} from "@/types/exam";
import { QuestionSection } from "@/context/TestDraftContext";

interface QuestionCardProps {
  section: QuestionSection;
  index: number;
  question: MCQItem | ShortQuestionItem | LongQuestionItem;
  isFirst: boolean;
  isLast: boolean;
  onEdit: () => void;
  onRegenerate: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
  onDelete: () => void;
}

export function QuestionCard({
  section,
  question,
  isFirst,
  isLast,
  onEdit,
  onRegenerate,
  onMoveUp,
  onMoveDown,
  onDelete,
}: QuestionCardProps) {
  const isMCQ = section === "mcqs";
  const isShort = section === "short_questions";
  const isLong = section === "long_questions";

  const mcqData = isMCQ ? (question as MCQItem) : null;
  const shortData = isShort ? (question as ShortQuestionItem) : null;
  const longData = isLong ? (question as LongQuestionItem) : null;

  const marks =
    question.marks !== undefined
      ? question.marks
      : isMCQ
      ? 1
      : isShort
      ? 2
      : 5;

  const qText = question.question || question.question_text || "";

  return (
    <div className="group relative rounded-xl border border-border/80 bg-card p-4 shadow-2xs transition-all duration-200 hover:border-primary/50 hover:shadow-xs">
      {/* Top Header Row */}
      <div className="flex flex-wrap items-center justify-between gap-2 pb-3 border-b border-border/50">
        <div className="flex items-center gap-2">
          {/* Question Number Badge */}
          <span
            className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-lg font-mono text-xs font-bold ${
              isMCQ
                ? "bg-primary/10 text-primary border border-primary/20"
                : isShort
                ? "bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20"
                : "bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20"
            }`}
          >
            Q{question.question_number}
          </span>

          {/* Section & Marks Badge */}
          <Badge
            variant={isMCQ ? "physics" : isShort ? "biology" : "mathematics"}
            size="sm"
            className="font-medium"
          >
            {isMCQ
              ? "Section A: MCQ"
              : isShort
              ? "Section B: Short"
              : "Section C: Long"}
          </Badge>

          <Badge variant="outline" size="sm" className="font-mono text-[11px]">
            {marks} {marks === 1 ? "Mark" : "Marks"}
          </Badge>
        </div>

        {/* Action Buttons Toolbar */}
        <div className="flex items-center gap-1">
          {/* Move Up */}
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-muted-foreground hover:text-foreground disabled:opacity-30"
            onClick={onMoveUp}
            disabled={isFirst}
            title="Move question up"
          >
            <ArrowUp className="h-3.5 w-3.5" />
            <span className="sr-only">Move Up</span>
          </Button>

          {/* Move Down */}
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-muted-foreground hover:text-foreground disabled:opacity-30"
            onClick={onMoveDown}
            disabled={isLast}
            title="Move question down"
          >
            <ArrowDown className="h-3.5 w-3.5" />
            <span className="sr-only">Move Down</span>
          </Button>

          {/* AI Regenerate */}
          <Button
            variant="ghost"
            size="sm"
            className="h-7 px-2 text-xs font-medium text-primary hover:bg-primary/10 hover:text-primary gap-1"
            onClick={onRegenerate}
            title="Regenerate question with AI"
          >
            <Sparkles className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Regen</span>
          </Button>

          {/* Edit Modal */}
          <Button
            variant="ghost"
            size="sm"
            className="h-7 px-2 text-xs font-medium text-foreground hover:bg-muted gap-1"
            onClick={onEdit}
            title="Edit question text and options"
          >
            <Edit3 className="h-3.5 w-3.5 text-muted-foreground" />
            <span className="hidden sm:inline">Edit</span>
          </Button>

          {/* Delete */}
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-muted-foreground hover:text-destructive hover:bg-destructive/10"
            onClick={onDelete}
            title="Delete question"
          >
            <Trash2 className="h-3.5 w-3.5" />
            <span className="sr-only">Delete</span>
          </Button>
        </div>
      </div>

      {/* Question Text with HTML Sub/Sup Support */}
      <div className="pt-3 pb-2 text-sm font-medium text-foreground leading-relaxed">
        <HtmlRenderer content={qText} />
      </div>

      {/* MCQ 2x2 Options Grid */}
      {isMCQ && mcqData && mcqData.options && (
        <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 gap-2">
          {mcqData.options.map((optText, optIdx) => {
            const letter = ["A", "B", "C", "D"][optIdx] || String(optIdx + 1);
            // Clean option text if it starts with A) or A.
            const cleanText = optText.replace(/^[A-D][).:]\s*/i, "");
            const isCorrect =
              mcqData.correct_option?.trim().toUpperCase() === letter;

            return (
              <div
                key={letter}
                className={`flex items-center gap-2.5 rounded-lg border p-2 text-xs transition-colors ${
                  isCorrect
                    ? "border-emerald-500/60 bg-emerald-500/10 text-emerald-900 dark:text-emerald-200 font-semibold"
                    : "border-border/60 bg-muted/20 text-muted-foreground"
                }`}
              >
                <span
                  className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full font-mono text-[11px] font-bold ${
                    isCorrect
                      ? "bg-emerald-500 text-white dark:text-emerald-950"
                      : "bg-muted text-muted-foreground"
                  }`}
                >
                  {letter}
                </span>
                <span className="flex-1">
                  <HtmlRenderer content={cleanText} />
                </span>
                {isCorrect && (
                  <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600 dark:text-emerald-400" />
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Explanation for MCQs (if present) */}
      {isMCQ && mcqData?.explanation && (
        <div className="mt-2.5 flex items-start gap-2 rounded-lg bg-muted/40 p-2 text-xs text-muted-foreground">
          <HelpCircle className="h-3.5 w-3.5 shrink-0 text-primary mt-0.5" />
          <div>
            <span className="font-semibold text-foreground">Explanation: </span>
            <HtmlRenderer content={mcqData.explanation} />
          </div>
        </div>
      )}

      {/* Expected Answer for Short Questions */}
      {isShort && shortData?.expected_answer && (
        <div className="mt-2 flex items-start gap-2 rounded-lg bg-muted/40 p-2 text-xs text-muted-foreground">
          <ListChecks className="h-3.5 w-3.5 shrink-0 text-purple-600 dark:text-purple-400 mt-0.5" />
          <div>
            <span className="font-semibold text-foreground">Key Points: </span>
            <HtmlRenderer content={shortData.expected_answer} />
          </div>
        </div>
      )}

      {/* Expected Points for Long Questions */}
      {isLong && longData?.expected_points && longData.expected_points.length > 0 && (
        <div className="mt-2 rounded-lg bg-muted/40 p-2 text-xs text-muted-foreground space-y-1">
          <div className="flex items-center gap-1.5 font-semibold text-foreground">
            <ListChecks className="h-3.5 w-3.5 text-amber-600 dark:text-amber-400" />
            <span>Marking Scheme / Key Sub-parts:</span>
          </div>
          <ul className="list-disc list-inside space-y-0.5 pl-1 text-[11px]">
            {longData.expected_points.map((point, pIdx) => (
              <li key={pIdx}>
                <HtmlRenderer content={point} />
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Textbook Citation / Reference Quote Footer */}
      {(question.textbook_reference ||
        question.reference_quote ||
        question.reference_topic) && (
        <div className="mt-3 flex flex-wrap items-center gap-2 pt-2 border-t border-border/40 text-[11px] text-muted-foreground">
          <div className="flex items-center gap-1 text-primary">
            <BookOpen className="h-3 w-3" />
            <span className="font-medium">Citation:</span>
          </div>
          <span className="italic truncate max-w-full">
            <HtmlRenderer
              content={
                question.textbook_reference ||
                question.reference_quote ||
                question.reference_topic ||
                ""
              }
            />
          </span>
          {question.reference_page && (
            <Badge variant="outline" size="sm" className="text-[10px] h-4 font-mono">
              Page {question.reference_page}
            </Badge>
          )}
        </div>
      )}
    </div>
  );
}
