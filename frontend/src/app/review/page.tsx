"use client";

import * as React from "react";
import Link from "next/link";
import {
  useTestDraft,
  QuestionSection,
  QuestionItemUnion,
} from "@/context/TestDraftContext";
import {
  QuestionCard,
  QuestionEditModal,
  QuestionRegenModal,
  AddQuestionModal,
  TestMetadataModal,
  MarksSummaryBar,
  A4Canvas,
} from "@/components/studio";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { cn, renumberTestQuestions } from "@/lib/utils";
import {
  PlusCircle,
  Columns,
  Eye,
  Edit,
  ArrowRight,
  Layers,
  Sparkles,
  SplitSquareVertical,
} from "lucide-react";
import { Class9TestSchema } from "@/types/exam";

type SplitMode = "50-50" | "60-40" | "editor-only" | "canvas-only";

export default function ReviewPage() {
  const {
    draft,
    setDraft,
    updateQuestion,
    deleteQuestion,
    addQuestion,
    updateDraftMetadata,
    regenerateQuestion,
    saveCurrentDraftToHistory,
    isDirty,
  } = useTestDraft();

  const [isMounted, setIsMounted] = React.useState<boolean>(false);
  React.useEffect(() => {
    setIsMounted(true);
  }, []);

  const activeTest = draft;

  // Split View & Filter State with Persistence (Default 50/50)
  const [splitMode, setSplitMode] = React.useState<SplitMode>("50-50");

  React.useEffect(() => {
    try {
      const saved = localStorage.getItem("examcraft_studio_split_mode");
      if (saved && ["50-50", "60-40", "editor-only", "canvas-only"].includes(saved)) {
        setSplitMode(saved as SplitMode);
      }
    } catch {
      // localStorage may not be accessible
    }
  }, []);

  const handleSetSplitMode = (mode: SplitMode) => {
    setSplitMode(mode);
    try {
      localStorage.setItem("examcraft_studio_split_mode", mode);
    } catch {}
  };

  const [activeFilter, setActiveFilter] = React.useState<string>("all");
  const [mobileTab, setMobileTab] = React.useState<"editor" | "preview">("editor");
  const [savedRecently, setSavedRecently] = React.useState<boolean>(false);

  // Modal States
  const [editModalState, setEditModalState] = React.useState<{
    isOpen: boolean;
    section: QuestionSection;
    index: number;
    data: QuestionItemUnion | null;
  }>({
    isOpen: false,
    section: "mcqs",
    index: 0,
    data: null,
  });

  const [regenModalState, setRegenModalState] = React.useState<{
    isOpen: boolean;
    section: QuestionSection;
    index: number;
    question: QuestionItemUnion | null;
  }>({
    isOpen: false,
    section: "mcqs",
    index: 0,
    question: null,
  });

  const [addModalState, setAddModalState] = React.useState<{
    isOpen: boolean;
    defaultSection: QuestionSection;
  }>({
    isOpen: false,
    defaultSection: "mcqs",
  });

  const [isMetadataModalOpen, setIsMetadataModalOpen] = React.useState<boolean>(false);

  // Handlers for Question Reordering
  const handleMoveQuestion = (
    section: QuestionSection,
    index: number,
    direction: "up" | "down"
  ) => {
    if (!draft) return;
    const currentList = [...(draft[section] || [])];
    const targetIndex = direction === "up" ? index - 1 : index + 1;

    if (targetIndex < 0 || targetIndex >= currentList.length) return;

    // Swap elements
    const temp = currentList[index];
    currentList[index] = currentList[targetIndex];
    currentList[targetIndex] = temp;

    const newDraft: Class9TestSchema = {
      ...draft,
      [section]: currentList,
    };

    setDraft(renumberTestQuestions(newDraft));
  };

  // Handlers for Modals
  const handleOpenEdit = (section: QuestionSection, index: number) => {
    if (!activeTest) return;
    const list = activeTest[section] || [];
    const item = list[index];
    if (item) {
      setEditModalState({
        isOpen: true,
        section,
        index,
        data: item,
      });
    }
  };

  const handleOpenRegen = (section: QuestionSection, index: number) => {
    if (!activeTest) return;
    const list = activeTest[section] || [];
    const item = list[index];
    if (item) {
      setRegenModalState({
        isOpen: true,
        section,
        index,
        question: item,
      });
    }
  };

  const handleOpenAdd = (defaultSection: QuestionSection = "mcqs") => {
    setAddModalState({
      isOpen: true,
      defaultSection,
    });
  };

  const handleSaveToPapers = () => {
    const saved = saveCurrentDraftToHistory();
    if (saved) {
      setSavedRecently(true);
      setTimeout(() => setSavedRecently(false), 3000);
    }
  };

  const handleDirectPrint = () => {
    if (typeof window !== "undefined") {
      window.print();
    }
  };

  if (!isMounted) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  if (!activeTest) {
    return (
      <div className="max-w-xl mx-auto py-16 px-4 text-center space-y-5">
        <div className="h-16 w-16 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto shadow-2xs">
          <SplitSquareVertical className="h-8 w-8" />
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold tracking-tight text-foreground">
            No Examination Paper Generated Yet
          </h2>
          <p className="text-sm text-muted-foreground leading-relaxed">
            The Split-Screen Crafting Studio is accessed after generating an assessment paper.
            Configure syllabus scope and question counts to generate an exam paper.
          </p>
        </div>
        <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
          <Link href="/generate">
            <Button size="default" className="gap-2 shadow-xs">
              <Sparkles className="h-4 w-4" />
              <span>Go to Test Generator</span>
              <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
          <Link href="/recent-papers">
            <Button variant="outline" size="default">
              Open from Recent Papers
            </Button>
          </Link>
        </div>
      </div>
    );
  }

  // Calculate Question counts and marks
  const mcqList = activeTest.mcqs || [];
  const shortList = activeTest.short_questions || [];
  const longList = activeTest.long_questions || [];
  const totalQuestions = mcqList.length + shortList.length + longList.length;

  return (
    <div className="space-y-4 max-w-7xl mx-auto py-2 pb-16">
      {/* Top Marks Summary Bar */}
      <MarksSummaryBar
        test={activeTest}
        isDirty={isDirty}
        onAddQuestion={() => handleOpenAdd("mcqs")}
        onEditMetadata={() => setIsMetadataModalOpen(true)}
        onSavePaper={handleSaveToPapers}
        onPrint={handleDirectPrint}
        savedRecently={savedRecently}
      />

      {/* View Mode Controls & Mobile Tab Switcher */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        {/* Desktop Split Modes */}
        <div className="hidden lg:flex items-center gap-1 bg-card border border-border/80 p-1 rounded-xl shadow-2xs">
          <span className="text-[11px] font-semibold text-muted-foreground px-2">
            View Mode:
          </span>
          <Button
            variant={splitMode === "50-50" ? "secondary" : "ghost"}
            size="sm"
            onClick={() => handleSetSplitMode("50-50")}
            className={cn(
              "h-7 text-xs px-2.5 gap-1.5 transition-all",
              splitMode === "50-50" && "bg-primary/10 text-primary font-semibold border border-primary/25 shadow-2xs"
            )}
            title="Balanced side-by-side workspace"
          >
            <Columns className="h-3 w-3" />
            <span>Split 50 / 50</span>
          </Button>
          <Button
            variant={splitMode === "editor-only" ? "secondary" : "ghost"}
            size="sm"
            onClick={() => handleSetSplitMode("editor-only")}
            className={cn(
              "h-7 text-xs px-2.5 gap-1.5 transition-all",
              splitMode === "editor-only" && "bg-primary/10 text-primary font-semibold border border-primary/25 shadow-2xs"
            )}
            title="Focus exclusively on editing questions"
          >
            <Edit className="h-3 w-3" />
            <span>Focus Editor</span>
          </Button>
          <Button
            variant={splitMode === "canvas-only" ? "secondary" : "ghost"}
            size="sm"
            onClick={() => handleSetSplitMode("canvas-only")}
            className={cn(
              "h-7 text-xs px-2.5 gap-1.5 transition-all",
              splitMode === "canvas-only" && "bg-primary/10 text-primary font-semibold border border-primary/25 shadow-2xs"
            )}
            title="Full-width A4 inspection canvas"
          >
            <Eye className="h-3 w-3" />
            <span>Focus Paper</span>
          </Button>
          <Button
            variant={splitMode === "60-40" ? "secondary" : "ghost"}
            size="sm"
            onClick={() => handleSetSplitMode("60-40")}
            className={cn(
              "h-7 text-xs px-2.5 gap-1.5 transition-all",
              splitMode === "60-40" && "bg-primary/10 text-primary font-semibold border border-primary/25 shadow-2xs"
            )}
            title="Wide editor with compact preview"
          >
            <SplitSquareVertical className="h-3 w-3" />
            <span>Split 60 / 40</span>
          </Button>
        </div>

        {/* Mobile View Switcher */}
        <div className="flex lg:hidden w-full">
          <Tabs
            value={mobileTab}
            onValueChange={(v) => setMobileTab(v as "editor" | "preview")}
            className="w-full"
          >
            <TabsList className="grid grid-cols-2 w-full">
              <TabsTrigger value="editor" className="text-xs gap-1.5">
                <Edit className="h-3.5 w-3.5" />
                <span>Questions Editor ({totalQuestions})</span>
              </TabsTrigger>
              <TabsTrigger value="preview" className="text-xs gap-1.5">
                <Eye className="h-3.5 w-3.5" />
                <span>A4 Paper Preview</span>
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>

        {/* Quick Action: Generator Link */}
        <div className="hidden sm:flex items-center gap-2 text-xs">
          <Link href="/generate">
            <Button variant="outline" size="sm" className="h-7 px-2.5 text-[11px] gap-1.5 shadow-2xs">
              <Sparkles className="h-3 w-3 text-primary" />
              <span>Create Another Paper</span>
            </Button>
          </Link>
        </div>
      </div>

      {/* Main Split-Screen 2-Pane Container */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* LEFT PANE: Interactive Question Crafting Studio */}
        <div
          className={`space-y-4 ${
            splitMode === "60-40"
              ? "lg:col-span-7"
              : splitMode === "50-50"
              ? "lg:col-span-6"
              : splitMode === "editor-only"
              ? "lg:col-span-12"
              : "hidden lg:hidden"
          } ${mobileTab === "preview" ? "hidden lg:block" : "block"}`}
        >
          <Card className="border-border/80 shadow-2xs">
            {/* Editor Filter Bar */}
            <CardHeader className="p-4 pb-3 border-b border-border/60">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
                <div className="flex items-center gap-2">
                  <Layers className="h-4 w-4 text-primary" />
                  <CardTitle className="text-sm font-bold">
                    Question Crafting Studio
                  </CardTitle>
                  <Badge variant="outline" size="sm" className="font-mono text-xs">
                    {totalQuestions} Total
                  </Badge>
                </div>

                {/* Section Tabs */}
                <Tabs value={activeFilter} onValueChange={setActiveFilter}>
                  <TabsList className="h-8 p-0.5">
                    <TabsTrigger value="all" className="text-xs px-2.5 h-7">
                      All ({totalQuestions})
                    </TabsTrigger>
                    <TabsTrigger value="mcqs" className="text-xs px-2.5 h-7">
                      MCQs ({mcqList.length})
                    </TabsTrigger>
                    <TabsTrigger value="short" className="text-xs px-2.5 h-7">
                      Short ({shortList.length})
                    </TabsTrigger>
                    <TabsTrigger value="long" className="text-xs px-2.5 h-7">
                      Long ({longList.length})
                    </TabsTrigger>
                  </TabsList>
                </Tabs>
              </div>
            </CardHeader>

            <CardContent className="p-4 space-y-6">
              {/* SECTION A: MCQs List */}
              {(activeFilter === "all" || activeFilter === "mcqs") && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between bg-muted/40 p-2 px-3 rounded-lg border border-border/50">
                    <div className="flex items-center gap-2">
                      <span className="h-2 w-2 rounded-full bg-primary" />
                      <span className="text-xs font-bold text-foreground uppercase tracking-wide">
                        Section A: Multiple Choice Questions
                      </span>
                      <Badge variant="physics" size="sm">
                        {mcqList.length} Items &bull; {mcqList.length * 1} Marks
                      </Badge>
                    </div>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="h-6 px-2 text-[11px] text-primary gap-1"
                      onClick={() => handleOpenAdd("mcqs")}
                    >
                      <PlusCircle className="h-3 w-3" />
                      <span>Add MCQ</span>
                    </Button>
                  </div>

                  {mcqList.length === 0 ? (
                    <div className="rounded-xl border border-dashed border-border/80 p-6 text-center text-xs text-muted-foreground">
                      No multiple-choice questions in this section.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {mcqList.map((mcq, idx) => (
                        <QuestionCard
                          key={`mcq-${mcq.question_number}-${idx}`}
                          section="mcqs"
                          index={idx}
                          question={mcq}
                          isFirst={idx === 0}
                          isLast={idx === mcqList.length - 1}
                          onEdit={() => handleOpenEdit("mcqs", idx)}
                          onRegenerate={() => handleOpenRegen("mcqs", idx)}
                          onMoveUp={() => handleMoveQuestion("mcqs", idx, "up")}
                          onMoveDown={() => handleMoveQuestion("mcqs", idx, "down")}
                          onDelete={() => deleteQuestion("mcqs", idx)}
                        />
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* SECTION B: Short Questions List */}
              {(activeFilter === "all" || activeFilter === "short") && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between bg-muted/40 p-2 px-3 rounded-lg border border-border/50">
                    <div className="flex items-center gap-2">
                      <span className="h-2 w-2 rounded-full bg-purple-500" />
                      <span className="text-xs font-bold text-foreground uppercase tracking-wide">
                        Section B: Short Questions
                      </span>
                      <Badge variant="biology" size="sm">
                        {shortList.length} Items &bull; {shortList.length * 2} Marks
                      </Badge>
                    </div>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="h-6 px-2 text-[11px] text-purple-600 dark:text-purple-400 gap-1"
                      onClick={() => handleOpenAdd("short_questions")}
                    >
                      <PlusCircle className="h-3 w-3" />
                      <span>Add Short</span>
                    </Button>
                  </div>

                  {shortList.length === 0 ? (
                    <div className="rounded-xl border border-dashed border-border/80 p-6 text-center text-xs text-muted-foreground">
                      No short questions in this section.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {shortList.map((q, idx) => (
                        <QuestionCard
                          key={`short-${q.question_number}-${idx}`}
                          section="short_questions"
                          index={idx}
                          question={q}
                          isFirst={idx === 0}
                          isLast={idx === shortList.length - 1}
                          onEdit={() => handleOpenEdit("short_questions", idx)}
                          onRegenerate={() => handleOpenRegen("short_questions", idx)}
                          onMoveUp={() => handleMoveQuestion("short_questions", idx, "up")}
                          onMoveDown={() =>
                            handleMoveQuestion("short_questions", idx, "down")
                          }
                          onDelete={() => deleteQuestion("short_questions", idx)}
                        />
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* SECTION C: Long Questions List */}
              {(activeFilter === "all" || activeFilter === "long") && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between bg-muted/40 p-2 px-3 rounded-lg border border-border/50">
                    <div className="flex items-center gap-2">
                      <span className="h-2 w-2 rounded-full bg-amber-500" />
                      <span className="text-xs font-bold text-foreground uppercase tracking-wide">
                        Section C: Long Questions
                      </span>
                      <Badge variant="mathematics" size="sm">
                        {longList.length} Items &bull; {longList.length * 5} Marks
                      </Badge>
                    </div>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="h-6 px-2 text-[11px] text-amber-600 dark:text-amber-400 gap-1"
                      onClick={() => handleOpenAdd("long_questions")}
                    >
                      <PlusCircle className="h-3 w-3" />
                      <span>Add Long</span>
                    </Button>
                  </div>

                  {longList.length === 0 ? (
                    <div className="rounded-xl border border-dashed border-border/80 p-6 text-center text-xs text-muted-foreground">
                      No long questions in this section.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {longList.map((q, idx) => (
                        <QuestionCard
                          key={`long-${q.question_number}-${idx}`}
                          section="long_questions"
                          index={idx}
                          question={q}
                          isFirst={idx === 0}
                          isLast={idx === longList.length - 1}
                          onEdit={() => handleOpenEdit("long_questions", idx)}
                          onRegenerate={() => handleOpenRegen("long_questions", idx)}
                          onMoveUp={() => handleMoveQuestion("long_questions", idx, "up")}
                          onMoveDown={() =>
                            handleMoveQuestion("long_questions", idx, "down")
                          }
                          onDelete={() => deleteQuestion("long_questions", idx)}
                        />
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Add Question Footer CTA */}
              <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-4 border-t border-border/60">
                <div className="flex flex-wrap items-center gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    className="text-xs gap-1.5"
                    onClick={() => handleOpenAdd("mcqs")}
                  >
                    <PlusCircle className="h-3.5 w-3.5 text-primary" />
                    <span>+ Add MCQ</span>
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="text-xs gap-1.5"
                    onClick={() => handleOpenAdd("short_questions")}
                  >
                    <PlusCircle className="h-3.5 w-3.5 text-purple-600 dark:text-purple-400" />
                    <span>+ Add Short</span>
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="text-xs gap-1.5"
                    onClick={() => handleOpenAdd("long_questions")}
                  >
                    <PlusCircle className="h-3.5 w-3.5 text-amber-600 dark:text-amber-400" />
                    <span>+ Add Long</span>
                  </Button>
                </div>

                <Link href="/pdf-preview">
                  <Button size="sm" className="text-xs gap-1.5 shadow-xs">
                    <span>Export & Print PDF</span>
                    <ArrowRight className="h-3.5 w-3.5" />
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* RIGHT PANE: Real-Time Synchronized A4 Canvas */}
        <div
          className={`space-y-4 ${
            splitMode === "60-40"
              ? "lg:col-span-5"
              : splitMode === "50-50"
              ? "lg:col-span-6"
              : splitMode === "canvas-only"
              ? "lg:col-span-12"
              : "hidden lg:hidden"
          } ${mobileTab === "editor" ? "hidden lg:block" : "block"}`}
        >
          <div className="sticky top-20">
            <A4Canvas
              test={activeTest}
              onPrint={handleDirectPrint}
            />
          </div>
        </div>
      </div>

      {/* Edit Question Modal */}
      <QuestionEditModal
        isOpen={editModalState.isOpen}
        onClose={() => setEditModalState((prev) => ({ ...prev, isOpen: false }))}
        section={editModalState.section}
        index={editModalState.index}
        initialData={editModalState.data}
        onSave={(sec, idx, updated) => {
          updateQuestion(sec, idx, updated);
        }}
      />

      {/* AI Regenerate Question Modal */}
      <QuestionRegenModal
        isOpen={regenModalState.isOpen}
        onClose={() => setRegenModalState((prev) => ({ ...prev, isOpen: false }))}
        section={regenModalState.section}
        index={regenModalState.index}
        question={regenModalState.question}
        onRegenerate={async (sec, idx, instruction) => {
          await regenerateQuestion(sec, idx, instruction);
        }}
      />

      {/* Add Custom Question Modal */}
      <AddQuestionModal
        isOpen={addModalState.isOpen}
        onClose={() => setAddModalState((prev) => ({ ...prev, isOpen: false }))}
        defaultSection={addModalState.defaultSection}
        onAdd={(sec, newQuestion) => {
          addQuestion(sec, newQuestion);
        }}
      />

      {/* Test Metadata Edit Modal */}
      <TestMetadataModal
        isOpen={isMetadataModalOpen}
        onClose={() => setIsMetadataModalOpen(false)}
        test={activeTest}
        onSave={(metadata) => {
          updateDraftMetadata(metadata);
        }}
      />
    </div>
  );
}
