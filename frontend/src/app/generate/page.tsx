"use client";

/**
 * src/app/generate/page.tsx
 * ExamCraft AI - Assessment Paper Configurator & Generator
 */

import * as React from "react";
import {
  Sparkles,
  FileText,
  Clock,
  KeyRound,
  MessageSquare,
  AlertCircle,
  Sliders,
  GraduationCap,
  ChevronDown,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { useTestDraft } from "@/context/TestDraftContext";
import { SubjectType, DifficultyLevel, RetrievalMode, Class9TestSchema } from "@/types/exam";
import { TestGenerationRequest } from "@/types/api";
import { calculateTotalMarks, cn } from "@/lib/utils";
import { getSubjectConfig } from "@/lib/subject-colors";
import {
  SubjectSelector,
  ChapterSelector,
  ExerciseSelector,
  ScopeToggle,
  QuestionSteppers,
  MarksCalculatorCard,
  DifficultySelector,
  GenerationPipelineModal,
  prefetchCurriculumChapters,
} from "@/components/generate";

const TIME_OPTIONS = [
  "30 Minutes",
  "45 Minutes",
  "1 Hour",
  "1.5 Hours",
  "2 Hours",
  "3 Hours",
];

export default function GeneratePage() {
  const { setDraft, activeGrade, setActiveGrade } = useTestDraft();

  // Configuration State
  const [selectedSubject, setSelectedSubject] = React.useState<SubjectType>("Chemistry");
  const [selectedChapter, setSelectedChapter] = React.useState<string>("");
  const [selectedExercise, setSelectedExercise] = React.useState<string | null>(null);
  const [testType, setTestType] = React.useState<RetrievalMode>("full_chapter");
  const [topicQuery, setTopicQuery] = React.useState<string>("");

  // Reset selected chapter and trigger instant background prefetch for active grade
  React.useEffect(() => {
    setSelectedChapter("");
    setSelectedExercise(null);
    setTopicQuery("");
    prefetchCurriculumChapters(activeGrade);
  }, [activeGrade]);

  // Question Counts
  const [mcqCount, setMcqCount] = React.useState<number>(10);
  const [shortCount, setShortCount] = React.useState<number>(5);
  const [longCount, setLongCount] = React.useState<number>(2);

  // Difficulty & Exam Params
  const [difficulty, setDifficulty] = React.useState<DifficultyLevel>("medium");
  const [timeAllowed, setTimeAllowed] = React.useState<string>("1 Hour");
  const [includeAnswerKey, setIncludeAnswerKey] = React.useState<boolean>(true);
  const [customInstruction, setCustomInstruction] = React.useState<string>("");

  // Pipeline Modal State
  const [isPipelineOpen, setIsPipelineOpen] = React.useState<boolean>(false);
  const [generationPayload, setGenerationPayload] = React.useState<TestGenerationRequest | null>(null);

  // Calculations & Configs
  const totalMarks = calculateTotalMarks(mcqCount, shortCount, longCount);
  const totalQuestions = mcqCount + shortCount + longCount;
  const subjectConfig = getSubjectConfig(selectedSubject);

  // Validation
  const isTopicMode = testType === "topic";
  const isTopicValid = !isTopicMode || topicQuery.trim().length >= 2;
  const isFormValid = totalQuestions > 0 && Boolean(selectedChapter) && isTopicValid;

  const handleStartGeneration = () => {
    if (!isFormValid) return;

    const payload: TestGenerationRequest = {
      subject: selectedSubject,
      grade: activeGrade,
      chapter_name: selectedChapter,
      test_type: testType,
      topic_query: isTopicMode ? topicQuery.trim() : undefined,
      exercise: selectedSubject === "Mathematics" && selectedExercise ? selectedExercise : undefined,
      mcq_count: mcqCount,
      short_count: shortCount,
      long_count: longCount,
      difficulty: difficulty,
      include_answer_key: includeAnswerKey,
      generation_instruction: customInstruction.trim() || undefined,
    };

    setGenerationPayload(payload);
    setIsPipelineOpen(true);
  };

  const handlePipelineSuccess = (draft: Class9TestSchema) => {
    // Override time allowed with user choice if provided, and attach selected grade
    const finalDraft: Class9TestSchema = {
      ...draft,
      grade: activeGrade,
      time_allowed: timeAllowed || draft.time_allowed,
    };
    setDraft(finalDraft);
  };

  return (
    <div className="max-w-5xl mx-auto space-y-6 py-2 pb-16">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-3 border-b border-border/60">
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-foreground">
              Assessment Configurator
            </h1>
            <Badge variant="outline" className="text-primary border-primary/30 bg-primary/10 text-xs font-bold">
              Class {activeGrade} Curriculum
            </Badge>
          </div>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Generate academically rigorous, zero-hallucination exam papers grounded in official textbooks.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-lg border border-primary/30 bg-primary/10 flex items-center gap-2 text-xs">
            <span className="text-muted-foreground">Target Marks:</span>
            <span className="font-bold text-primary text-sm font-mono">{totalMarks}</span>
          </div>
        </div>
      </div>

      {/* Class Level Selector Bar */}
      <div className="space-y-2 p-3.5 rounded-xl border border-border bg-card shadow-2xs">
        <div className="flex items-center justify-between">
          <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
            <GraduationCap className="h-4 w-4 text-primary" />
            <span>Target Academic Class Level</span>
          </label>
          <span className="text-[11px] font-semibold text-primary">
            Class {activeGrade} Active
          </span>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
          {[
            { grade: 9, label: "Class 9", sub: "SSC-I (Matric 1)" },
            { grade: 10, label: "Class 10", sub: "SSC-II (Matric 2)" },
            { grade: 11, label: "Class 11", sub: "HSSC-I (Inter 1)" },
            { grade: 12, label: "Class 12", sub: "HSSC-II (Inter 2)" },
          ].map((item) => (
            <button
              key={item.grade}
              type="button"
              onClick={() => setActiveGrade(item.grade)}
              className={cn(
                "px-3 py-2.5 rounded-lg border text-left transition-all cursor-pointer flex flex-col justify-center gap-0.5",
                activeGrade === item.grade
                  ? "border-primary bg-primary/10 text-primary font-bold ring-2 ring-primary/30 shadow-2xs"
                  : "border-border/80 hover:bg-muted/50 text-foreground"
              )}
            >
              <span className="text-xs font-bold">{item.label}</span>
              <span className="text-[10px] text-muted-foreground font-normal">{item.sub}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Step 1: Subject Selection */}
      <SubjectSelector
        selectedSubject={selectedSubject}
        onSelectSubject={(subj) => {
          setSelectedSubject(subj);
          setSelectedChapter("");
          setSelectedExercise(null);
          setTopicQuery("");
        }}
      />

      {/* Two-Column Main Configuration Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Syllabus & Question Settings (7 cols) */}
        <div className="lg:col-span-7 space-y-5">
          {/* Step 2: Syllabus Scope */}
          <div className="p-5 sm:p-6 rounded-xl border border-border bg-card space-y-4 shadow-2xs">
            <div className="flex items-center justify-between pb-2 border-b border-border/60">
              <h2 className="text-sm font-bold text-foreground flex items-center gap-2">
                <Sliders className="h-4 w-4 text-primary" />
                <span>Step 2: Syllabus & Scope</span>
              </h2>
              <div className="flex items-center gap-2">
                <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-primary/10 text-primary border border-primary/25 shadow-2xs">
                  Class {activeGrade} Syllabus
                </span>
                <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-muted/60 text-muted-foreground border border-border/80 shadow-2xs">
                  <span className="h-1.5 w-1.5 rounded-full shrink-0" style={{ backgroundColor: subjectConfig.lightHex }} />
                  {subjectConfig.displayName}
                </span>
              </div>
            </div>

            {/* Chapter Dropdown */}
            <ChapterSelector
              subject={selectedSubject}
              grade={activeGrade}
              selectedChapter={selectedChapter}
              onSelectChapter={setSelectedChapter}
            />

            {/* Exercise Selector (Mathematics only) */}
            <ExerciseSelector
              subject={selectedSubject}
              chapter={selectedChapter}
              grade={activeGrade}
              selectedExercise={selectedExercise}
              onSelectExercise={setSelectedExercise}
            />

            {/* Scope Toggle (Full Chapter vs Specific Topic) */}
            <ScopeToggle
              testType={testType}
              onChangeTestType={setTestType}
              topicQuery={topicQuery}
              onChangeTopicQuery={setTopicQuery}
            />
          </div>

          {/* Step 3: Question Distribution */}
          <div className="p-5 sm:p-6 rounded-xl border border-border bg-card space-y-4 shadow-2xs">
            <div className="flex items-center justify-between pb-2 border-b border-border/60">
              <h2 className="text-sm font-bold text-foreground flex items-center gap-2">
                <FileText className="h-4 w-4 text-primary" />
                <span>Step 3: Question Sections & Counts</span>
              </h2>
              <span className="text-[11px] font-mono text-muted-foreground">
                {totalQuestions} questions
              </span>
            </div>

            <QuestionSteppers
              mcqCount={mcqCount}
              onChangeMcqCount={setMcqCount}
              shortCount={shortCount}
              onChangeShortCount={setShortCount}
              longCount={longCount}
              onChangeLongCount={setLongCount}
            />
          </div>

          {/* Step 4: Cognitive Difficulty */}
          <div className="p-5 sm:p-6 rounded-xl border border-border bg-card space-y-3 shadow-2xs">
            <DifficultySelector
              difficulty={difficulty}
              onChangeDifficulty={setDifficulty}
            />
          </div>
        </div>

        {/* Right Column: Marks Card, Instructions & Generate CTA (5 cols) */}
        <div className="lg:col-span-5 space-y-5">
          {/* Live Marks Calculator */}
          <MarksCalculatorCard
            mcqCount={mcqCount}
            shortCount={shortCount}
            longCount={longCount}
            subject={selectedSubject}
          />

          {/* Exam Paper Format & Teacher Custom Instructions */}
          <div className="p-5 sm:p-6 rounded-xl border border-border bg-card space-y-4 shadow-2xs">
            <h2 className="text-sm font-bold text-foreground pb-2 border-b border-border/60 flex items-center gap-2">
              <Clock className="h-4 w-4 text-primary" />
              <span>Paper Format & Output Options</span>
            </h2>

            {/* Time Allowed Selector */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="text-xs font-semibold text-foreground">Time Allowed (Duration)</label>
                <span className="text-[10px] text-muted-foreground">Printed on Paper Header</span>
              </div>
              <div className="relative">
                <select
                  value={timeAllowed}
                  onChange={(e) => setTimeAllowed(e.target.value)}
                  className="w-full appearance-none rounded-lg border border-border bg-card px-3 py-2 pr-9 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer"
                >
                  {TIME_OPTIONS.map((t) => (
                    <option key={t} value={t} className="bg-card text-foreground py-1">
                      {t}
                    </option>
                  ))}
                </select>
                <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              </div>
            </div>

            {/* Answer Key Toggle */}
            <div className="flex items-center justify-between p-3 rounded-lg bg-muted/40 border border-border/70 shadow-2xs">
              <div className="space-y-0.5 pr-2">
                <div className="flex items-center gap-1.5">
                  <KeyRound className="h-3.5 w-3.5 text-primary" />
                  <span className="text-xs font-semibold text-foreground">
                    Auto-Generate Answer Key
                  </span>
                </div>
                <p className="text-[10px] text-muted-foreground">
                  Appends MCQ solutions, short answer rubrics & marking scheme
                </p>
              </div>
              <Switch
                checked={includeAnswerKey}
                onCheckedChange={setIncludeAnswerKey}
              />
            </div>

            {/* Teacher Custom Instructions */}
            <div className="space-y-2 pt-2 border-t border-border/60">
              <div className="flex items-center justify-between">
                <label className="text-xs font-semibold text-foreground flex items-center gap-1.5">
                  <MessageSquare className="h-3.5 w-3.5 text-primary" />
                  <span>Teacher Prompt & Instructions</span>
                  <span className="text-[10px] text-muted-foreground font-normal">(Optional)</span>
                </label>
                <span className="text-[10px] font-mono text-muted-foreground">
                  {customInstruction.length} / 2000
                </span>
              </div>
              <Textarea
                value={customInstruction}
                onChange={(e) => setCustomInstruction(e.target.value.slice(0, 2000))}
                placeholder="e.g. Include at least one numerical problem for Molar Mass. Avoid extremely rare isotopes..."
                rows={3}
                className="text-xs resize-none bg-card/60 focus:bg-card"
              />
            </div>
          </div>

          {/* Generation CTA */}
          <div className="space-y-2">
            <Button
              type="button"
              size="lg"
              disabled={!isFormValid}
              onClick={handleStartGeneration}
              className="w-full h-12 text-sm font-bold gap-2 shadow-md bg-primary hover:bg-primary/90 text-primary-foreground cursor-pointer disabled:opacity-50"
            >
              <Sparkles className="h-4 w-4" />
              <span>Generate {subjectConfig.displayName} Paper</span>
              <span className="px-2 py-0.5 rounded bg-primary-foreground/20 text-primary-foreground text-[11px] font-mono">
                {totalMarks} Marks
              </span>
            </Button>

            {!isFormValid && (
              <p className="text-[11px] text-amber-600 dark:text-amber-400 flex items-center gap-1 justify-center">
                <AlertCircle className="h-3.5 w-3.5" />
                <span>
                  {!isTopicValid
                    ? "Please enter a target topic query (at least 2 chars)"
                    : "Please select at least one question to generate"}
                </span>
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Generation Pipeline Modal */}
      <GenerationPipelineModal
        isOpen={isPipelineOpen}
        onClose={() => setIsPipelineOpen(false)}
        payload={generationPayload}
        onSuccess={handlePipelineSuccess}
      />
    </div>
  );
}
