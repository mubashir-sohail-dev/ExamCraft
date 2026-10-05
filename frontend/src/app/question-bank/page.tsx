"use client";

/**
 * src/app/question-bank/page.tsx
 * ExamCraft AI - Question Bank Explorer & Repository Hub
 */

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  BookOpen,
  Search,
  Filter,
  PlusCircle,
  Copy,
  Trash2,
  CheckCircle2,
  Sparkles,
  RotateCcw,
  SlidersHorizontal,
  ChevronDown,
  Atom,
  FlaskConical,
  Calculator,
  Dna,
  Laptop,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useTestDraft } from "@/context/TestDraftContext";
import {
  getSavedQuestions,
  deleteQuestion,
  resetQuestionBankToDefault,
  clearQuestionBank,
} from "@/lib/storage";
import { QuestionBankItem, QuestionType, DifficultyLevel } from "@/types/exam";
import { cn, formatDate } from "@/lib/utils";
import { HtmlRenderer } from "@/components/shared/html-renderer";

export default function QuestionBankPage() {
  const router = useRouter();
  const { addQuestion, draft } = useTestDraft();

  const [questions, setQuestions] = React.useState<QuestionBankItem[]>([]);
  const [searchQuery, setSearchQuery] = React.useState<string>("");
  const [selectedSubject, setSelectedSubject] = React.useState<string>("all");
  const [selectedType, setSelectedType] = React.useState<string>("all");
  const [selectedDifficulty, setSelectedDifficulty] = React.useState<string>("all");
  const [toastMessage, setToastMessage] = React.useState<{ type: "success" | "error"; text: string } | null>(null);

  const loadQuestions = React.useCallback(() => {
    const items = getSavedQuestions();
    setQuestions(items);
  }, []);

  React.useEffect(() => {
    loadQuestions();
  }, [loadQuestions]);

  const showToast = (type: "success" | "error", text: string) => {
    setToastMessage({ type, text });
    setTimeout(() => setToastMessage(null), 3000);
  };

  const handleCopyQuestion = (text: string) => {
    navigator.clipboard.writeText(text);
    showToast("success", "Question copied to clipboard!");
  };

  const handleAddToDraft = (item: QuestionBankItem) => {
    const qType = item.type.toLowerCase();
    if (qType === "mcq") {
      addQuestion("mcqs", {
        question_number: 1,
        question: item.question,
        options: (item.options as [string, string, string, string]) || ["A", "B", "C", "D"],
        correct_option: item.correct_option || "A",
        textbook_reference: item.textbook_reference,
        marks: item.marks || 1,
      });
    } else if (qType === "short") {
      addQuestion("short_questions", {
        question_number: 1,
        question: item.question,
        marks: item.marks || 2,
        textbook_reference: item.textbook_reference,
      });
    } else {
      addQuestion("long_questions", {
        question_number: 1,
        question: item.question,
        marks: item.marks || 5,
        textbook_reference: item.textbook_reference,
      });
    }
    showToast("success", "Added question to active test draft!");
  };

  const handleDelete = (id: string) => {
    deleteQuestion(id);
    loadQuestions();
    showToast("success", "Question removed from repository.");
  };

  const handleResetDefaults = () => {
    if (confirm("Reset question bank to standard verified textbook samples?")) {
      resetQuestionBankToDefault();
      loadQuestions();
      showToast("success", "Reset question bank to standard syllabus items.");
    }
  };

  // Filter questions
  const filteredQuestions = React.useMemo(() => {
    return questions.filter((q) => {
      const qText = (q.question || q.question_text || "").toLowerCase();
      const qRef = (q.textbook_reference || "").toLowerCase();
      const qChap = (q.chapter || "").toLowerCase();
      const query = searchQuery.toLowerCase().trim();

      const matchesSearch =
        !query ||
        qText.includes(query) ||
        qRef.includes(query) ||
        qChap.includes(query);

      const matchesSubject =
        selectedSubject === "all" ||
        q.subject.toLowerCase() === selectedSubject.toLowerCase();

      const itemType = (q.type || q.question_type || "").toLowerCase();
      const matchesType =
        selectedType === "all" || itemType === selectedType.toLowerCase();

      const matchesDifficulty =
        selectedDifficulty === "all" ||
        (q.difficulty || "").toLowerCase() === selectedDifficulty.toLowerCase();

      return matchesSearch && matchesSubject && matchesType && matchesDifficulty;
    });
  }, [questions, searchQuery, selectedSubject, selectedType, selectedDifficulty]);

  return (
    <div className="max-w-6xl mx-auto space-y-6 py-4 pb-16">
      {/* Toast Alert */}
      {toastMessage && (
        <div
          className={cn(
            "fixed bottom-6 right-6 z-50 flex items-center gap-2.5 px-4 py-2.5 rounded-xl shadow-lg border text-xs font-semibold animate-in fade-in slide-in-from-bottom-3 duration-200",
            toastMessage.type === "success"
              ? "bg-emerald-950 text-emerald-200 border-emerald-800"
              : "bg-rose-950 text-rose-200 border-rose-800"
          )}
        >
          <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-400" />
          <span>{toastMessage.text}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/70">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-foreground">
              Question Bank Explorer
            </h1>
            <Badge variant="outline" className="border-primary/30 bg-primary/10 text-primary text-xs font-bold">
              {questions.length} Items
            </Badge>
          </div>
          <p className="text-xs sm:text-sm text-muted-foreground mt-1">
            Curated repository of syllabus-grounded questions with textbook citations and Bloom taxonomy classifications.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {draft && (
            <Link href="/review">
              <Button size="sm" variant="outline" className="text-xs gap-1.5">
                <Sparkles className="h-3.5 w-3.5 text-primary" />
                <span>Return to Studio</span>
              </Button>
            </Link>
          )}
          <Button
            size="sm"
            variant="ghost"
            onClick={handleResetDefaults}
            className="text-xs gap-1.5 text-muted-foreground hover:text-foreground"
            title="Reset repository to verified curriculum defaults"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Reset Defaults</span>
          </Button>
        </div>
      </div>

      {/* Search and Filters Toolbar */}
      <div className="grid grid-cols-1 sm:grid-cols-12 gap-3">
        <div className="sm:col-span-5 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search questions, citations, chapters..."
            className="pl-9 text-xs h-9 bg-background"
          />
        </div>

        <div className="sm:col-span-3">
          <Select value={selectedSubject} onValueChange={setSelectedSubject}>
            <SelectTrigger className="h-9 text-xs bg-background">
              <SelectValue placeholder="All Subjects" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Subjects</SelectItem>
              <SelectItem value="Physics">Physics</SelectItem>
              <SelectItem value="Chemistry">Chemistry</SelectItem>
              <SelectItem value="Mathematics">Mathematics</SelectItem>
              <SelectItem value="Biology">Biology</SelectItem>
              <SelectItem value="Computer Science">Computer Science</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="sm:col-span-2">
          <Select value={selectedType} onValueChange={setSelectedType}>
            <SelectTrigger className="h-9 text-xs bg-background">
              <SelectValue placeholder="All Types" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Types</SelectItem>
              <SelectItem value="mcq">MCQ</SelectItem>
              <SelectItem value="short">Short Question</SelectItem>
              <SelectItem value="long">Long Question</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="sm:col-span-2">
          <Select value={selectedDifficulty} onValueChange={setSelectedDifficulty}>
            <SelectTrigger className="h-9 text-xs bg-background">
              <SelectValue placeholder="Difficulty" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Difficulties</SelectItem>
              <SelectItem value="easy">Easy</SelectItem>
              <SelectItem value="medium">Medium</SelectItem>
              <SelectItem value="hard">Hard</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Results Header */}
      <div className="flex items-center justify-between text-xs text-muted-foreground px-1">
        <span>
          Showing <strong className="text-foreground">{filteredQuestions.length}</strong> of {questions.length} questions
        </span>
      </div>

      {/* Questions List */}
      {filteredQuestions.length === 0 ? (
        <Card className="border-dashed p-10 text-center">
          <BookOpen className="h-10 w-10 text-muted-foreground/40 mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-foreground">No questions found</h3>
          <p className="text-xs text-muted-foreground mt-1 max-w-sm mx-auto">
            Try adjusting your search criteria or reset the question repository to default curriculum items.
          </p>
          <Button
            variant="outline"
            size="sm"
            onClick={handleResetDefaults}
            className="mt-4 text-xs gap-1.5"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            <span>Reset Default Questions</span>
          </Button>
        </Card>
      ) : (
        <div className="space-y-3">
          {filteredQuestions.map((q) => {
            const qType = (q.type || q.question_type || "mcq").toLowerCase();
            return (
              <Card
                key={q.id}
                className="border-border/80 hover:border-primary/40 transition-colors shadow-2xs"
              >
                <CardContent className="p-4 space-y-3">
                  {/* Item Top Bar */}
                  <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
                    <div className="flex items-center gap-1.5">
                      <Badge
                        variant="secondary"
                        className="font-bold text-[10px] uppercase tracking-wide"
                      >
                        {qType.toUpperCase()}
                      </Badge>
                      <Badge variant="outline" className="text-[10px]">
                        {q.subject}
                      </Badge>
                      <span className="text-muted-foreground text-[11px]">
                        {q.chapter}
                      </span>
                    </div>

                    <div className="flex items-center gap-2">
                      <span className="text-[11px] font-semibold text-muted-foreground">
                        {q.marks || (qType === "mcq" ? 1 : qType === "short" ? 2 : 5)} Mark{q.marks === 1 ? "" : "s"}
                      </span>
                      <Button
                        size="icon-sm"
                        variant="ghost"
                        onClick={() => handleCopyQuestion(q.question || q.question_text || "")}
                        title="Copy question text"
                      >
                        <Copy className="h-3.5 w-3.5 text-muted-foreground" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleAddToDraft(q)}
                        className="gap-1 text-[11px] h-6 px-2"
                        title="Add to active assessment draft"
                      >
                        <PlusCircle className="h-3 w-3 text-primary" />
                        <span>Add to Draft</span>
                      </Button>
                      <Button
                        size="icon-sm"
                        variant="ghost"
                        onClick={() => handleDelete(q.id)}
                        className="text-rose-600 hover:text-rose-700 hover:bg-rose-50 dark:hover:bg-rose-950/40"
                        title="Delete question"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </div>

                  {/* Question Prompt */}
                  <div className="text-xs sm:text-sm text-foreground font-medium leading-relaxed">
                    <HtmlRenderer content={q.question || q.question_text || ""} />
                  </div>

                  {/* MCQ Options Grid */}
                  {qType === "mcq" && q.options && Array.isArray(q.options) && (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5 pt-1">
                      {q.options.map((opt, optIdx) => {
                        const optLetter = ["A", "B", "C", "D"][optIdx] || String(optIdx);
                        const isCorrect = q.correct_option?.toUpperCase().includes(optLetter);
                        return (
                          <div
                            key={optIdx}
                            className={cn(
                              "text-xs px-2.5 py-1.5 rounded border flex items-center justify-between",
                              isCorrect
                                ? "border-emerald-500/50 bg-emerald-50/60 dark:bg-emerald-950/30 text-emerald-800 dark:text-emerald-300 font-semibold"
                                : "border-border/60 bg-muted/20 text-muted-foreground"
                            )}
                          >
                            <span>{opt}</span>
                            {isCorrect && (
                              <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600 dark:text-emerald-400 shrink-0" />
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* Textbook Citation Reference */}
                  {q.textbook_reference && (
                    <div className="pt-1 flex items-center gap-1.5 text-[11px] text-muted-foreground font-mono">
                      <BookOpen className="h-3 w-3 text-primary shrink-0" />
                      <span className="truncate">Reference: {q.textbook_reference}</span>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
