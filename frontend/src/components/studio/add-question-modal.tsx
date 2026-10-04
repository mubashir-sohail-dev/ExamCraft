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
import { PlusCircle, Code, CheckCircle2 } from "lucide-react";
import {
  MCQItem,
  ShortQuestionItem,
  LongQuestionItem,
} from "@/types/exam";
import { QuestionSection, QuestionItemUnion } from "@/context/TestDraftContext";

interface AddQuestionModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultSection?: QuestionSection;
  onAdd: (section: QuestionSection, question: QuestionItemUnion) => void;
}

export function AddQuestionModal({
  isOpen,
  onClose,
  defaultSection = "mcqs",
  onAdd,
}: AddQuestionModalProps) {
  const [section, setSection] = React.useState<QuestionSection>(defaultSection);
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

  // Sync defaultSection on open
  React.useEffect(() => {
    if (isOpen) {
      setSection(defaultSection);
      setQuestionText("");
      setOptionA("");
      setOptionB("");
      setOptionC("");
      setOptionD("");
      setCorrectOption("A");
      setExplanation("");
      setExpectedAnswer("");
      setExpectedPoints("");
      setTextbookRef("");
      setReferenceTopic("");
      setReferencePage(undefined);
      setMarks(defaultSection === "mcqs" ? 1 : defaultSection === "short_questions" ? 2 : 5);
    }
  }, [isOpen, defaultSection]);

  const handleSectionChange = (val: QuestionSection) => {
    setSection(val);
    if (val === "mcqs") setMarks(1);
    else if (val === "short_questions") setMarks(2);
    else setMarks(5);
  };

  const handleInsertTag = (tag: "sub" | "sup") => {
    const opening = `<${tag}>`;
    const closing = `</${tag}>`;
    setQuestionText((prev) => `${prev}${opening}${closing}`);
  };

  const handleAddQuestion = () => {
    if (!questionText.trim()) return;

    if (section === "mcqs") {
      const newMCQ: MCQItem = {
        question_number: 1, // Will be renumbered automatically by context
        question: questionText.trim(),
        options: [
          `A) ${optionA.trim() || "Option A"}`,
          `B) ${optionB.trim() || "Option B"}`,
          `C) ${optionC.trim() || "Option C"}`,
          `D) ${optionD.trim() || "Option D"}`,
        ],
        correct_option: correctOption,
        explanation: explanation.trim() || undefined,
        marks: Number(marks) || 1,
        textbook_reference: textbookRef.trim() || undefined,
        reference_quote: textbookRef.trim() || undefined,
        reference_topic: referenceTopic.trim() || undefined,
        reference_page: referencePage ? Number(referencePage) : undefined,
      };
      onAdd("mcqs", newMCQ);
    } else if (section === "short_questions") {
      const newShort: ShortQuestionItem = {
        question_number: 1,
        question: questionText.trim(),
        marks: Number(marks) || 2,
        expected_answer: expectedAnswer.trim() || undefined,
        textbook_reference: textbookRef.trim() || undefined,
        reference_quote: textbookRef.trim() || undefined,
        reference_topic: referenceTopic.trim() || undefined,
        reference_page: referencePage ? Number(referencePage) : undefined,
      };
      onAdd("short_questions", newShort);
    } else {
      const newLong: LongQuestionItem = {
        question_number: 1,
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
      onAdd("long_questions", newLong);
    }

    onClose();
  };

  if (!isOpen) return null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <PlusCircle className="h-4 w-4" />
            </div>
            <div>
              <DialogTitle className="text-base font-bold">
                Add New Question
              </DialogTitle>
              <DialogDescription className="text-xs">
                Create and append a custom examination question to the active test draft.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Target Section Selector */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label className="text-xs font-semibold">Target Exam Section *</Label>
              <Select
                value={section}
                onValueChange={(v) => handleSectionChange(v as QuestionSection)}
              >
                <SelectTrigger className="h-9 text-xs">
                  <SelectValue placeholder="Select section" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="mcqs">Section A: Multiple Choice (1m)</SelectItem>
                  <SelectItem value="short_questions">Section B: Short Question (2m)</SelectItem>
                  <SelectItem value="long_questions">Section C: Long / Essay Question (5m)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1">
              <Label htmlFor="add-marks" className="text-xs font-semibold">
                Marks Weighting
              </Label>
              <Input
                id="add-marks"
                type="number"
                min={1}
                max={20}
                value={marks}
                onChange={(e) => setMarks(Number(e.target.value))}
                className="h-9 text-xs"
              />
            </div>
          </div>

          {/* Question Text */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <Label htmlFor="add-question-text" className="text-xs font-semibold">
                Question Statement / Stem *
              </Label>
              <div className="flex items-center gap-1">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="h-6 px-1.5 text-[11px] font-mono gap-1"
                  onClick={() => handleInsertTag("sub")}
                  title="Insert subscript tag"
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
                  title="Insert superscript tag"
                >
                  <Code className="h-3 w-3" />
                  <span>&lt;sup&gt;</span>
                </Button>
              </div>
            </div>
            <Textarea
              id="add-question-text"
              rows={3}
              value={questionText}
              onChange={(e) => setQuestionText(e.target.value)}
              placeholder="Enter your custom question statement here..."
              className="text-sm font-sans"
            />
          </div>

          {/* MCQ Options Fields */}
          {section === "mcqs" && (
            <div className="space-y-3 rounded-xl border border-border/80 bg-muted/20 p-3.5">
              <div className="flex items-center justify-between">
                <Label className="text-xs font-bold text-foreground">
                  MCQ Options (A to D) *
                </Label>
                <span className="text-[11px] text-muted-foreground">
                  Specify 4 distinct options
                </span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                <div className="space-y-1">
                  <span className="text-xs font-bold text-primary">Option A</span>
                  <Input
                    value={optionA}
                    onChange={(e) => setOptionA(e.target.value)}
                    placeholder="Choice Alpha"
                    className="text-xs"
                  />
                </div>
                <div className="space-y-1">
                  <span className="text-xs font-bold text-primary">Option B</span>
                  <Input
                    value={optionB}
                    onChange={(e) => setOptionB(e.target.value)}
                    placeholder="Choice Beta"
                    className="text-xs"
                  />
                </div>
                <div className="space-y-1">
                  <span className="text-xs font-bold text-primary">Option C</span>
                  <Input
                    value={optionC}
                    onChange={(e) => setOptionC(e.target.value)}
                    placeholder="Choice Gamma"
                    className="text-xs"
                  />
                </div>
                <div className="space-y-1">
                  <span className="text-xs font-bold text-primary">Option D</span>
                  <Input
                    value={optionD}
                    onChange={(e) => setOptionD(e.target.value)}
                    placeholder="Choice Delta"
                    className="text-xs"
                  />
                </div>
              </div>

              {/* Correct Option Selector */}
              <div className="pt-2 flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-t border-border/40">
                <div className="flex items-center gap-1.5 text-xs font-semibold">
                  <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                  <span>Correct Key Answer:</span>
                </div>
                <div className="w-full sm:w-48">
                  <Select value={correctOption} onValueChange={setCorrectOption}>
                    <SelectTrigger className="h-8 text-xs">
                      <SelectValue placeholder="Correct option" />
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

              {/* Optional Explanation */}
              <div className="space-y-1 pt-1">
                <Label htmlFor="add-mcq-exp" className="text-xs font-semibold text-muted-foreground">
                  Explanation / Textbook Justification (Optional)
                </Label>
                <Textarea
                  id="add-mcq-exp"
                  rows={2}
                  value={explanation}
                  onChange={(e) => setExplanation(e.target.value)}
                  placeholder="Explain why this option is correct..."
                  className="text-xs"
                />
              </div>
            </div>
          )}

          {/* Short Question Answer */}
          {section === "short_questions" && (
            <div className="space-y-1">
              <Label htmlFor="add-short-ans" className="text-xs font-semibold">
                Model Expected Answer (Optional)
              </Label>
              <Textarea
                id="add-short-ans"
                rows={3}
                value={expectedAnswer}
                onChange={(e) => setExpectedAnswer(e.target.value)}
                placeholder="Key concepts or concise answer required for full marks..."
                className="text-xs"
              />
            </div>
          )}

          {/* Long Question Points */}
          {section === "long_questions" && (
            <div className="space-y-1">
              <Label htmlFor="add-long-points" className="text-xs font-semibold">
                Marking Rubric Steps (One per line)
              </Label>
              <Textarea
                id="add-long-points"
                rows={3}
                value={expectedPoints}
                onChange={(e) => setExpectedPoints(e.target.value)}
                placeholder="1. Definition & Formula (1 Mark)&#10;2. Graphical Analysis (2 Marks)&#10;3. Derivation steps (2 Marks)"
                className="text-xs font-mono"
              />
            </div>
          )}

          {/* Textbook Reference & Topic */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label htmlFor="add-topic" className="text-xs font-semibold">
                Topic / Unit Reference
              </Label>
              <Input
                id="add-topic"
                value={referenceTopic}
                onChange={(e) => setReferenceTopic(e.target.value)}
                placeholder="e.g. Periodic Law"
                className="text-xs"
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="add-page" className="text-xs font-semibold">
                Textbook Page #
              </Label>
              <Input
                id="add-page"
                type="number"
                value={referencePage || ""}
                onChange={(e) =>
                  setReferencePage(e.target.value ? Number(e.target.value) : undefined)
                }
                placeholder="e.g. 52"
                className="text-xs"
              />
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" size="sm" onClick={onClose}>
            Cancel
          </Button>
          <Button
            size="sm"
            onClick={handleAddQuestion}
            disabled={!questionText.trim()}
            className="gap-1.5"
          >
            <PlusCircle className="h-3.5 w-3.5" />
            <span>Add Question to Exam</span>
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
