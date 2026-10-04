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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  MCQItem,
  ShortQuestionItem,
  LongQuestionItem,
} from "@/types/exam";
import { QuestionSection, QuestionItemUnion } from "@/context/TestDraftContext";
import { Code, CheckCircle2 } from "lucide-react";

interface QuestionEditModalProps {
  isOpen: boolean;
  onClose: () => void;
  section: QuestionSection;
  index: number;
  initialData: MCQItem | ShortQuestionItem | LongQuestionItem | null;
  onSave: (
    section: QuestionSection,
    index: number,
    updated: QuestionItemUnion
  ) => void;
}

export function QuestionEditModal({
  isOpen,
  onClose,
  section,
  index,
  initialData,
  onSave,
}: QuestionEditModalProps) {
  const isMCQ = section === "mcqs";
  const isShort = section === "short_questions";
  const isLong = section === "long_questions";

  // Form State
  const [questionText, setQuestionText] = React.useState("");
  const [marks, setMarks] = React.useState<number>(1);
  const [optionA, setOptionA] = React.useState("");
  const [optionB, setOptionB] = React.useState("");
  const [optionC, setOptionC] = React.useState("");
  const [optionD, setOptionD] = React.useState("");
  const [correctOption, setCorrectOption] = React.useState("A");
  const [explanation, setExplanation] = React.useState("");
  const [expectedAnswer, setExpectedAnswer] = React.useState("");
  const [expectedPoints, setExpectedPoints] = React.useState("");
  const [textbookRef, setTextbookRef] = React.useState("");
  const [referenceTopic, setReferenceTopic] = React.useState("");
  const [referencePage, setReferencePage] = React.useState<number | undefined>(undefined);

  // Sync state when initialData changes or modal opens
  React.useEffect(() => {
    if (!initialData) return;

    setQuestionText(initialData.question || initialData.question_text || "");
    setMarks(
      initialData.marks !== undefined
        ? initialData.marks
        : isMCQ
        ? 1
        : isShort
        ? 2
        : 5
    );
    setTextbookRef(initialData.textbook_reference || initialData.reference_quote || "");
    setReferenceTopic(initialData.reference_topic || "");
    setReferencePage(initialData.reference_page);

    if (isMCQ) {
      const mcq = initialData as MCQItem;
      const opts = mcq.options || [];
      setOptionA(opts[0] ? opts[0].replace(/^[A-D][).:]\s*/i, "") : "");
      setOptionB(opts[1] ? opts[1].replace(/^[A-D][).:]\s*/i, "") : "");
      setOptionC(opts[2] ? opts[2].replace(/^[A-D][).:]\s*/i, "") : "");
      setOptionD(opts[3] ? opts[3].replace(/^[A-D][).:]\s*/i, "") : "");
      setCorrectOption(mcq.correct_option?.trim().toUpperCase() || "A");
      setExplanation(mcq.explanation || "");
    } else if (isShort) {
      const short = initialData as ShortQuestionItem;
      setExpectedAnswer(short.expected_answer || "");
    } else if (isLong) {
      const long = initialData as LongQuestionItem;
      setExpectedPoints(
        long.expected_points ? long.expected_points.join("\n") : ""
      );
    }
  }, [initialData, isMCQ, isShort, isLong, isOpen]);

  const handleInsertTag = (tag: "sub" | "sup") => {
    const opening = `<${tag}>`;
    const closing = `</${tag}>`;
    setQuestionText((prev) => `${prev}${opening}${closing}`);
  };

  const handleSave = () => {
    if (!questionText.trim()) return;

    if (isMCQ) {
      const updatedMCQ: MCQItem = {
        question_number: initialData?.question_number || index + 1,
        question: questionText.trim(),
        options: [
          `A) ${optionA.trim()}`,
          `B) ${optionB.trim()}`,
          `C) ${optionC.trim()}`,
          `D) ${optionD.trim()}`,
        ],
        correct_option: correctOption,
        explanation: explanation.trim() || undefined,
        marks: Number(marks) || 1,
        textbook_reference: textbookRef.trim() || undefined,
        reference_quote: textbookRef.trim() || undefined,
        reference_topic: referenceTopic.trim() || undefined,
        reference_page: referencePage ? Number(referencePage) : undefined,
      };
      onSave(section, index, updatedMCQ);
    } else if (isShort) {
      const updatedShort: ShortQuestionItem = {
        question_number: initialData?.question_number || index + 1,
        question: questionText.trim(),
        marks: Number(marks) || 2,
        expected_answer: expectedAnswer.trim() || undefined,
        textbook_reference: textbookRef.trim() || undefined,
        reference_quote: textbookRef.trim() || undefined,
        reference_topic: referenceTopic.trim() || undefined,
        reference_page: referencePage ? Number(referencePage) : undefined,
      };
      onSave(section, index, updatedShort);
    } else {
      const updatedLong: LongQuestionItem = {
        question_number: initialData?.question_number || index + 1,
        question: questionText.trim(),
        marks: Number(marks) || 5,
        expected_points: expectedPoints
          .split("\n")
          .map((p) => p.trim())
          .filter(Boolean),
        textbook_reference: textbookRef.trim() || undefined,
        reference_quote: textbookRef.trim() || undefined,
        reference_topic: referenceTopic.trim() || undefined,
        reference_page: referencePage ? Number(referencePage) : undefined,
      };
      onSave(section, index, updatedLong);
    }

    onClose();
  };

  if (!isOpen || !initialData) return null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-base font-bold">
            <span>Edit Question {initialData.question_number}</span>
            <span className="text-xs font-normal text-muted-foreground">
              (
              {isMCQ
                ? "Multiple Choice Question"
                : isShort
                ? "Short Question"
                : "Long Question"}
              )
            </span>
          </DialogTitle>
          <DialogDescription>
            Update question prompt, options, marks weighting, and textbook references.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Question Text & Tag Helpers */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <Label htmlFor="question-text" className="text-xs font-semibold">
                Question Statement / Stem *
              </Label>
              <div className="flex items-center gap-1">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="h-6 px-1.5 text-[11px] font-mono gap-1"
                  onClick={() => handleInsertTag("sub")}
                  title="Insert subscript tag (e.g. H2O)"
                >
                  <Code className="h-3 w-3" />
                  <span>&lt;sub&gt;</span>
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="h-6 px-1.5 text-[11px] font-mono gap-1"
                  onClick={() => handleInsertTag("sup")}
                  title="Insert superscript tag (e.g. x2)"
                >
                  <Code className="h-3 w-3" />
                  <span>&lt;sup&gt;</span>
                </Button>
              </div>
            </div>
            <Textarea
              id="question-text"
              rows={3}
              value={questionText}
              onChange={(e) => setQuestionText(e.target.value)}
              placeholder="Enter question text here..."
              className="text-sm font-sans"
            />
          </div>

          {/* Marks & Weighting */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            <div className="space-y-1">
              <Label htmlFor="marks" className="text-xs font-semibold">
                Marks Weighting
              </Label>
              <Input
                id="marks"
                type="number"
                min={1}
                max={20}
                value={marks}
                onChange={(e) => setMarks(Number(e.target.value))}
                className="text-sm"
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="ref-topic" className="text-xs font-semibold">
                Topic Name
              </Label>
              <Input
                id="ref-topic"
                value={referenceTopic}
                onChange={(e) => setReferenceTopic(e.target.value)}
                placeholder="e.g. Atomic Radius"
                className="text-sm"
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="ref-page" className="text-xs font-semibold">
                Textbook Page #
              </Label>
              <Input
                id="ref-page"
                type="number"
                value={referencePage || ""}
                onChange={(e) =>
                  setReferencePage(
                    e.target.value ? Number(e.target.value) : undefined
                  )
                }
                placeholder="e.g. 54"
                className="text-sm"
              />
            </div>
          </div>

          {/* MCQ Specific Fields */}
          {isMCQ && (
            <div className="space-y-3 rounded-xl border border-border/80 bg-muted/20 p-3.5">
              <div className="flex items-center justify-between">
                <Label className="text-xs font-bold text-foreground">
                  Answer Options (A - D) & Correct Key *
                </Label>
                <span className="text-[11px] text-muted-foreground">
                  Select correct option below
                </span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                {/* Option A */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-primary">Option A</span>
                    {correctOption === "A" && (
                      <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-0.5">
                        <CheckCircle2 className="h-3 w-3" /> Correct Key
                      </span>
                    )}
                  </div>
                  <Input
                    value={optionA}
                    onChange={(e) => setOptionA(e.target.value)}
                    placeholder="Choice A..."
                    className="text-xs"
                  />
                </div>

                {/* Option B */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-primary">Option B</span>
                    {correctOption === "B" && (
                      <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-0.5">
                        <CheckCircle2 className="h-3 w-3" /> Correct Key
                      </span>
                    )}
                  </div>
                  <Input
                    value={optionB}
                    onChange={(e) => setOptionB(e.target.value)}
                    placeholder="Choice B..."
                    className="text-xs"
                  />
                </div>

                {/* Option C */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-primary">Option C</span>
                    {correctOption === "C" && (
                      <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-0.5">
                        <CheckCircle2 className="h-3 w-3" /> Correct Key
                      </span>
                    )}
                  </div>
                  <Input
                    value={optionC}
                    onChange={(e) => setOptionC(e.target.value)}
                    placeholder="Choice C..."
                    className="text-xs"
                  />
                </div>

                {/* Option D */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-primary">Option D</span>
                    {correctOption === "D" && (
                      <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-0.5">
                        <CheckCircle2 className="h-3 w-3" /> Correct Key
                      </span>
                    )}
                  </div>
                  <Input
                    value={optionD}
                    onChange={(e) => setOptionD(e.target.value)}
                    placeholder="Choice D..."
                    className="text-xs"
                  />
                </div>
              </div>

              {/* Correct Option Selector */}
              <div className="pt-2 flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-t border-border/40">
                <Label htmlFor="correct-opt-select" className="text-xs font-semibold">
                  Designated Correct Option:
                </Label>
                <div className="w-full sm:w-48">
                  <Select value={correctOption} onValueChange={setCorrectOption}>
                    <SelectTrigger id="correct-opt-select" className="h-8 text-xs">
                      <SelectValue placeholder="Select correct answer" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="A">Option A</SelectItem>
                      <SelectItem value="B">Option B</SelectItem>
                      <SelectItem value="C">Option C</SelectItem>
                      <SelectItem value="D">Option D</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Explanation Field */}
              <div className="space-y-1 pt-1">
                <Label htmlFor="explanation" className="text-xs font-semibold text-muted-foreground">
                  Teacher Explanation / Key Rationale (Optional)
                </Label>
                <Textarea
                  id="explanation"
                  rows={2}
                  value={explanation}
                  onChange={(e) => setExplanation(e.target.value)}
                  placeholder="Explain why this option is correct according to the textbook..."
                  className="text-xs"
                />
              </div>
            </div>
          )}

          {/* Short Question Expected Answer */}
          {isShort && (
            <div className="space-y-1">
              <Label htmlFor="expected-ans" className="text-xs font-semibold">
                Expected Answer / Scoring Points (Optional)
              </Label>
              <Textarea
                id="expected-ans"
                rows={3}
                value={expectedAnswer}
                onChange={(e) => setExpectedAnswer(e.target.value)}
                placeholder="Enter model answer or key concepts expected for full 2 marks..."
                className="text-xs"
              />
            </div>
          )}

          {/* Long Question Expected Points */}
          {isLong && (
            <div className="space-y-1">
              <Label htmlFor="expected-points" className="text-xs font-semibold">
                Marking Scheme Rubric (One item per line)
              </Label>
              <Textarea
                id="expected-points"
                rows={3}
                value={expectedPoints}
                onChange={(e) => setExpectedPoints(e.target.value)}
                placeholder="1. Definition & Formula (1 Mark)&#10;2. Derivation with Graph (3 Marks)&#10;3. Conclusion and SI Units (1 Mark)"
                className="text-xs font-mono"
              />
            </div>
          )}

          {/* Reference Citation */}
          <div className="space-y-1">
            <Label htmlFor="textbook-ref" className="text-xs font-semibold text-muted-foreground">
              Textbook Reference Quote / Citation Note
            </Label>
            <Input
              id="textbook-ref"
              value={textbookRef}
              onChange={(e) => setTextbookRef(e.target.value)}
              placeholder="e.g. As defined in PTB Chapter 3, Page 54: Electronegativity increases across a period."
              className="text-xs"
            />
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" size="sm" onClick={onClose}>
            Cancel
          </Button>
          <Button size="sm" onClick={handleSave} disabled={!questionText.trim()}>
            Save Changes
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
