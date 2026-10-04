"use client";

import * as React from "react";
import {
  ZoomIn,
  ZoomOut,
  Maximize2,
  Printer,
  Eye,
  Columns,
  Sparkles,
  FileCheck,
  Expand,
  X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { HtmlRenderer } from "@/components/shared/html-renderer";
import { Class9TestSchema } from "@/types/exam";
import { cn, calculateTestSchemaMarks } from "@/lib/utils";

interface A4CanvasProps {
  test: Class9TestSchema;
  schoolName?: string;
  showAnswerKeyDefault?: boolean;
  twoColumnDefault?: boolean;
  showWatermarkDefault?: boolean;
  onPrint?: () => void;
}

export function A4Canvas({
  test,
  schoolName,
  showAnswerKeyDefault = false,
  twoColumnDefault = false,
  showWatermarkDefault = false,
  onPrint,
}: A4CanvasProps) {
  const testGrade = Number(test.grade) || 9;
  const resolvedSchoolName =
    schoolName ||
    (testGrade <= 10
      ? `SECONDARY SCHOOL CERTIFICATE (CLASS ${testGrade === 9 ? "IX" : "X"}) EXAMINATION`
      : `HIGHER SECONDARY SCHOOL CERTIFICATE (CLASS ${testGrade === 11 ? "XI" : "XII"}) EXAMINATION`);

  const containerRef = React.useRef<HTMLDivElement>(null);
  const [containerWidth, setContainerWidth] = React.useState<number>(0);
  const [isAutoFit, setIsAutoFit] = React.useState<boolean>(true);
  const [zoomLevel, setZoomLevel] = React.useState<number>(85);
  const [isFullscreenOpen, setIsFullscreenOpen] = React.useState<boolean>(false);
  const [fullscreenZoom, setFullscreenZoom] = React.useState<number>(100);

  const [showAnswerKey, setShowAnswerKey] = React.useState<boolean>(showAnswerKeyDefault);
  const [twoColumnMode, setTwoColumnMode] = React.useState<boolean>(twoColumnDefault);
  const [showWatermark, setShowWatermark] = React.useState<boolean>(showWatermarkDefault);

  // Load preferences from localStorage on mount
  React.useEffect(() => {
    try {
      const savedAutoFit = localStorage.getItem("examcraft_canvas_autofit");
      if (savedAutoFit !== null) {
        setIsAutoFit(savedAutoFit === "true");
      }
      const savedZoom = localStorage.getItem("examcraft_canvas_zoom");
      if (savedZoom) {
        const parsed = Number(savedZoom);
        if (!isNaN(parsed) && parsed >= 40 && parsed <= 175) {
          setZoomLevel(parsed);
        }
      }
    } catch {
      // localStorage may not be available
    }
  }, []);

  // Monitor container width for precise Auto-Fit
  React.useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const updateWidth = () => {
      if (el.clientWidth > 0) {
        setContainerWidth(el.clientWidth);
      }
    };

    updateWidth();

    const observer = new ResizeObserver((entries) => {
      for (const entry of entries) {
        if (entry.contentRect.width > 0) {
          setContainerWidth(entry.contentRect.width);
        }
      }
    });

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  // Calculate dynamic auto-fit percentage: (containerWidth - padding) / 794px
  const PADDING = 40; // 20px padding each side
  const availableWidth = Math.max(260, (containerWidth || 794) - PADDING);
  const calculatedAutoFit = Math.min(115, Math.max(35, Math.floor((availableWidth / 794) * 100)));

  const effectiveZoom = isAutoFit ? calculatedAutoFit : zoomLevel;

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

  const handleZoomIn = () => {
    setIsAutoFit(false);
    setZoomLevel((prev) => {
      const next = Math.min(prev + 15, 175);
      try {
        localStorage.setItem("examcraft_canvas_zoom", String(next));
        localStorage.setItem("examcraft_canvas_autofit", "false");
      } catch {}
      return next;
    });
  };

  const handleZoomOut = () => {
    setIsAutoFit(false);
    setZoomLevel((prev) => {
      const next = Math.max(prev - 15, 40);
      try {
        localStorage.setItem("examcraft_canvas_zoom", String(next));
        localStorage.setItem("examcraft_canvas_autofit", "false");
      } catch {}
      return next;
    });
  };

  const handleToggleAutoFit = () => {
    setIsAutoFit((prev) => {
      const next = !prev;
      try {
        localStorage.setItem("examcraft_canvas_autofit", String(next));
      } catch {}
      return next;
    });
  };

  const handleResetZoom = () => {
    setIsAutoFit(false);
    setZoomLevel(100);
    try {
      localStorage.setItem("examcraft_canvas_zoom", "100");
      localStorage.setItem("examcraft_canvas_autofit", "false");
    } catch {}
  };

  const handleTriggerPrint = () => {
    if (onPrint) {
      onPrint();
    } else if (typeof window !== "undefined") {
      window.print();
    }
  };

  return (
    <div className="flex flex-col space-y-3">
      {/* Canvas Top Control Bar */}
      <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-border/80 bg-card p-2 px-3 text-xs shadow-2xs">
        {/* Left: View Toggles */}
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex items-center space-x-1.5">
            <Switch
              id="show-answer-key"
              checked={showAnswerKey}
              onCheckedChange={setShowAnswerKey}
            />
            <Label
              htmlFor="show-answer-key"
              className="text-[11px] font-medium cursor-pointer flex items-center gap-1"
            >
              <Eye className="h-3 w-3 text-primary" />
              <span>Answer Key</span>
            </Label>
          </div>

          <div className="flex items-center space-x-1.5">
            <Switch
              id="two-column-mode"
              checked={twoColumnMode}
              onCheckedChange={setTwoColumnMode}
            />
            <Label
              htmlFor="two-column-mode"
              className="text-[11px] font-medium cursor-pointer flex items-center gap-1"
            >
              <Columns className="h-3 w-3 text-primary" />
              <span>2-Column</span>
            </Label>
          </div>

          <div className="flex items-center space-x-1.5">
            <Switch
              id="watermark-mode"
              checked={showWatermark}
              onCheckedChange={setShowWatermark}
            />
            <Label
              htmlFor="watermark-mode"
              className="text-[11px] font-medium cursor-pointer flex items-center gap-1"
            >
              <Sparkles className="h-3 w-3 text-primary" />
              <span>Watermark</span>
            </Label>
          </div>
        </div>

        {/* Right: Zoom, Auto-Fit, Maximize & Print Controls */}
        <div className="flex items-center gap-1.5">
          <div className="flex items-center border border-border/70 rounded-lg overflow-hidden bg-background">
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7 rounded-none text-muted-foreground hover:text-foreground"
              onClick={handleZoomOut}
              disabled={effectiveZoom <= 40}
              title="Zoom out (-15%)"
            >
              <ZoomOut className="h-3.5 w-3.5" />
            </Button>
            <span
              onClick={handleResetZoom}
              className="px-2 font-mono text-[11px] font-semibold cursor-pointer hover:text-primary transition-colors select-none"
              title="Click to reset zoom to 100%"
            >
              {effectiveZoom}%
            </span>
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7 rounded-none text-muted-foreground hover:text-foreground"
              onClick={handleZoomIn}
              disabled={effectiveZoom >= 175}
              title="Zoom in (+15%)"
            >
              <ZoomIn className="h-3.5 w-3.5" />
            </Button>
          </div>

          <Button
            variant={isAutoFit ? "secondary" : "outline"}
            size="sm"
            className={cn(
              "h-7 px-2 text-[11px] gap-1 transition-colors",
              isAutoFit && "border-primary/40 font-semibold text-primary"
            )}
            onClick={handleToggleAutoFit}
            title={isAutoFit ? "Auto-Fit active (Click to lock zoom)" : "Fit A4 sheet to container width"}
          >
            <Maximize2 className="h-3 w-3" />
            <span>{isAutoFit ? "Fit (Auto)" : "Fit Width"}</span>
          </Button>

          <Button
            variant="outline"
            size="sm"
            className="h-7 px-2 text-[11px] gap-1 hover:text-primary transition-colors"
            onClick={() => setIsFullscreenOpen(true)}
            title="Inspect paper in Fullscreen Proofing Mode"
          >
            <Expand className="h-3 w-3" />
            <span className="hidden sm:inline">Maximize</span>
          </Button>

          <Button
            variant="outline"
            size="sm"
            className="h-7 px-2 text-[11px] gap-1"
            onClick={handleTriggerPrint}
            title="Print Paper"
          >
            <Printer className="h-3 w-3" />
            <span className="hidden sm:inline">Print</span>
          </Button>
        </div>
      </div>

      {/* A4 Canvas Scroll Container with Independent Scrolling & Anti-Clipping */}
      <div
        ref={containerRef}
        className="w-full overflow-auto rounded-xl border border-border/70 bg-slate-900/5 dark:bg-slate-950/60 p-3 sm:p-5 shadow-inner max-h-[calc(100vh-185px)] min-h-[550px] transition-all"
      >
        {/* Anti-clipping wrapper: Centered when sheet fits, starts at 0 with scroll when sheet is wider */}
        <div className="min-w-full w-fit mx-auto flex justify-center items-start">
          {/* Scalable Paper Wrapper with calculated bounding box */}
          <div
            style={{
              width: `${Math.round(794 * (effectiveZoom / 100))}px`,
              minHeight: `${Math.round(1123 * (effectiveZoom / 100))}px`,
              position: "relative",
              transition: "width 0.15s ease-out, min-height 0.15s ease-out",
            }}
            className="shrink-0 mb-8"
          >
            {/* Authentic A4 Paper Sheet (210mm x 297mm standard ratio: ~794px width) */}
            <div
              id="printable-a4-canvas"
              style={{
                transform: `scale(${effectiveZoom / 100})`,
                transformOrigin: "top left",
                position: "absolute",
                top: 0,
                left: 0,
                fontFamily: 'Charter, Cambria, "Times New Roman", Times, serif',
              }}
              className="w-[794px] min-h-[1123px] bg-white text-[#0f172a] shadow-2xl ring-1 ring-black/15 rounded-xs p-[48px] font-serif text-[13px] leading-relaxed flex flex-col justify-between select-text"
            >
            {/* Optional Watermark */}
            {showWatermark && (
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center opacity-5 select-none rotate-[-30deg]">
                <span className="text-7xl font-bold uppercase tracking-widest font-sans">
                  EXAMCRAFT AI
                </span>
              </div>
            )}

            <div>
              {/* Board Exam Header Section */}
              <div className="text-center pb-3 border-b-2 border-black space-y-1">
                <h1 className="text-[17px] font-bold uppercase tracking-wider font-sans">
                  {resolvedSchoolName}
                </h1>
                <p className="text-[14px] font-semibold text-black">
                  Subject: <span className="font-bold underline">{test.subject}</span> (Class {testGrade}th) &bull;{" "}
                  <span>{test.chapter_or_topic}</span>
                </p>
                <div className="flex items-center justify-between text-[12px] font-sans font-semibold pt-1 px-1 border-t border-black/30 mt-1.5">
                  <span>Time Allowed: {test.time_allowed}</span>
                  <span className="text-[11px] uppercase tracking-wider text-black/80 font-normal">
                    {testGrade <= 10 ? "Secondary School Certificate" : "Higher Secondary Certificate"}
                  </span>
                  <span>Total Marks: {totalMarks}</span>
                </div>
              </div>

              {/* Student Details Fields */}
              <div className="grid grid-cols-2 gap-y-2 gap-x-6 py-2.5 border-b border-black/40 text-[12px] font-sans">
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Student Name:</span>
                  <span className="flex-1 border-b border-dotted border-black/80" />
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Roll Number:</span>
                  <span className="flex-1 border-b border-dotted border-black/80" />
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Section / Class:</span>
                  <span className="flex-1 border-b border-dotted border-black/80" />
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Date:</span>
                  <span className="flex-1 border-b border-dotted border-black/80" />
                </div>
              </div>

              {/* General Instructions Box */}
              {test.instructions && test.instructions.length > 0 && (
                <div className="my-3 rounded border border-black/60 bg-black/[0.02] p-2 px-3 text-[11px] font-sans space-y-0.5">
                  <div className="font-bold uppercase tracking-wide text-[10px]">
                    General Instructions:
                  </div>
                  <ol className="list-decimal list-inside space-y-0.5 text-black/90">
                    {test.instructions.map((inst, i) => (
                      <li key={i}>{inst}</li>
                    ))}
                  </ol>
                </div>
              )}

              {/* Examination Questions Body */}
              <div className={twoColumnMode ? "grid grid-cols-2 gap-6 pt-2" : "space-y-4 pt-2"}>
                {/* SECTION A: MCQs */}
                {test.mcqs && test.mcqs.length > 0 && (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between border-b border-black bg-black/[0.04] p-1 px-2 font-sans font-bold text-[12px] uppercase">
                      <span>Section A — Multiple Choice Questions</span>
                      <span className="font-mono">
                        ({test.mcqs.length} &times; 1 = {mcqMarks} Marks)
                      </span>
                    </div>
                    <p className="text-[11px] italic font-sans text-black/80 pl-1">
                      Q.1: Select the correct option for each question. Each MCQ carries 1 mark.
                    </p>

                    <div className="space-y-2.5 pt-1 pl-1">
                      {test.mcqs.map((mcq) => (
                        <div key={mcq.question_number} className="space-y-1">
                          <p className="text-[12.5px] font-medium leading-tight">
                            <span className="font-bold font-sans pr-1">
                              ({mcq.question_number})
                            </span>
                            <HtmlRenderer content={mcq.question || mcq.question_text || ""} />
                          </p>

                          {/* 2x2 Option Grid Layout (Matching ReportLab PDF colWidths=[250, 250]) */}
                          <div className="grid grid-cols-2 gap-x-4 gap-y-0.5 text-[11.5px] pl-5 font-sans">
                            {mcq.options.map((opt, optI) => {
                              const label = ["A", "B", "C", "D"][optI];
                              const cleanOpt = opt.replace(/^[A-D][).:]\s*/i, "");
                              return (
                                <div key={label} className="flex items-baseline gap-1">
                                  <span className="font-bold">({label})</span>
                                  <span>
                                    <HtmlRenderer content={cleanOpt} />
                                  </span>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* SECTION B: Short Questions */}
                {test.short_questions && test.short_questions.length > 0 && (
                  <div className="space-y-2 pt-2">
                    <div className="flex items-center justify-between border-b border-black bg-black/[0.04] p-1 px-2 font-sans font-bold text-[12px] uppercase">
                      <span>Section B — Short Answer Questions</span>
                      <span className="font-mono">
                        ({test.short_questions.length} &times; 2 = {shortMarks} Marks)
                      </span>
                    </div>
                    <p className="text-[11px] italic font-sans text-black/80 pl-1">
                      Q.2: Give brief and accurate answers to the following questions.
                    </p>

                    <div className="space-y-2 pt-1 pl-1">
                      {test.short_questions.map((q) => (
                        <div
                          key={q.question_number}
                          className="flex items-start justify-between gap-3 text-[12.5px] font-medium leading-snug"
                        >
                          <p className="flex-1">
                            <span className="font-bold font-sans pr-1">
                              ({q.question_number})
                            </span>
                            <HtmlRenderer content={q.question || q.question_text || ""} />
                          </p>
                          <span className="font-sans font-bold text-[11px] shrink-0 text-black/80">
                            [{q.marks || 2}]
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* SECTION C: Long Questions */}
                {test.long_questions && test.long_questions.length > 0 && (
                  <div className="space-y-2 pt-2">
                    <div className="flex items-center justify-between border-b border-black bg-black/[0.04] p-1 px-2 font-sans font-bold text-[12px] uppercase">
                      <span>Section C — Long / Detailed Questions</span>
                      <span className="font-mono">
                        ({test.long_questions.length} &times; 5 = {longMarks} Marks)
                      </span>
                    </div>
                    <p className="text-[11px] italic font-sans text-black/80 pl-1">
                      Q.3: Answer the following questions in detail with diagrams and derivations where necessary.
                    </p>

                    <div className="space-y-2.5 pt-1 pl-1">
                      {test.long_questions.map((q) => (
                        <div
                          key={q.question_number}
                          className="flex items-start justify-between gap-3 text-[12.5px] font-medium leading-snug"
                        >
                          <p className="flex-1">
                            <span className="font-bold font-sans pr-1">
                              ({q.question_number})
                            </span>
                            <HtmlRenderer content={q.question || q.question_text || ""} />
                          </p>
                          <span className="font-sans font-bold text-[11px] shrink-0 text-black/80">
                            [{q.marks || 5}]
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Teacher Answer Key & Textbook Citation Appendix (Toggleable) */}
              {showAnswerKey && (
                <div className="mt-6 pt-4 border-t-2 border-dashed border-black/60 space-y-2.5 font-sans">
                  <div className="flex items-center justify-between bg-black/10 p-1.5 px-2 rounded">
                    <div className="flex items-center gap-1.5 text-xs font-bold uppercase">
                      <FileCheck className="h-4 w-4" />
                      <span>Confidential — Teacher Marking Key & Textbook Citations</span>
                    </div>
                    <Badge variant="outline" size="sm" className="text-[10px] bg-white text-black border-black/40">
                      Master Key
                    </Badge>
                  </div>

                  {/* MCQ Keys Table */}
                  {test.mcqs && test.mcqs.length > 0 && (
                    <div className="space-y-1">
                      <span className="text-[11px] font-bold uppercase">Section A Keys:</span>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-1.5 text-[11px]">
                        {test.mcqs.map((mcq) => (
                          <div
                            key={mcq.question_number}
                            className="p-1 rounded border border-black/20 bg-black/[0.02] flex items-center justify-between px-1.5"
                          >
                            <span>Q{mcq.question_number}:</span>
                            <span className="font-bold text-black underline">
                              Option ({mcq.correct_option})
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Textbook Citations Table */}
                  <div className="space-y-1 pt-1">
                    <span className="text-[11px] font-bold uppercase">Curriculum Citations & Quotes:</span>
                    <div className="space-y-1 text-[10.5px]">
                      {test.mcqs?.map((m) =>
                        m.textbook_reference || m.reference_quote ? (
                          <div key={m.question_number} className="flex items-start gap-1.5 text-black/80">
                            <span className="font-bold shrink-0">Q{m.question_number}:</span>
                            <span className="italic">
                              <HtmlRenderer content={m.textbook_reference || m.reference_quote || ""} />
                            </span>
                          </div>
                        ) : null
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Bottom Page Footer */}
            <div className="mt-8 pt-3 border-t border-black/30 flex items-center justify-between text-[10.5px] font-sans text-black/70">
              <span>ExamCraft AI &bull; Punjab Curriculum Aligned Paper</span>
              <span className="font-semibold">*** END OF PAPER ***</span>
              <span>Page 1 of 1</span>
            </div>
          </div>
        </div>
      </div>
    </div>

      {/* Fullscreen A4 Inspection Modal */}
      <Dialog open={isFullscreenOpen} onOpenChange={setIsFullscreenOpen}>
        <DialogContent className="max-w-[96vw] w-[96vw] h-[94vh] max-h-[94vh] p-0 flex flex-col bg-slate-950/95 border-border/70 backdrop-blur-md text-foreground overflow-hidden shadow-2xl">
          <DialogTitle className="sr-only">Fullscreen Paper Inspection</DialogTitle>
          {/* Top Inspection Toolbar */}
          <div className="flex items-center justify-between px-5 py-3 border-b border-border/70 bg-card/80 shrink-0">
            <div className="flex items-center gap-3">
              <Badge variant="outline" className="font-mono text-xs text-primary border-primary/30">
                Class {testGrade} &bull; {test.subject}
              </Badge>
              <h2 className="text-sm font-bold truncate max-w-[360px]">{test.test_title || "Examination Paper"}</h2>
              <span className="text-xs text-muted-foreground hidden md:inline">
                ({totalMarks} Marks &bull; {test.time_allowed})
              </span>
            </div>

            <div className="flex items-center gap-2">
              <div className="flex items-center border border-border/70 rounded-lg overflow-hidden bg-background">
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-7 w-7 rounded-none"
                  onClick={() => setFullscreenZoom((prev) => Math.max(prev - 15, 50))}
                  title="Zoom out"
                >
                  <ZoomOut className="h-3.5 w-3.5" />
                </Button>
                <span className="px-2 font-mono text-[11px] font-semibold select-none">
                  {fullscreenZoom}%
                </span>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-7 w-7 rounded-none"
                  onClick={() => setFullscreenZoom((prev) => Math.min(prev + 15, 150))}
                  title="Zoom in"
                >
                  <ZoomIn className="h-3.5 w-3.5" />
                </Button>
              </div>

              <Button
                variant={fullscreenZoom === 100 ? "secondary" : "outline"}
                size="sm"
                className="h-7 px-2.5 text-xs"
                onClick={() => setFullscreenZoom(100)}
                title="Reset to 100% true print size"
              >
                100%
              </Button>

              <Button
                size="sm"
                className="h-7 px-3 text-xs gap-1.5 shadow-xs"
                onClick={handleTriggerPrint}
              >
                <Printer className="h-3.5 w-3.5" />
                <span>Print Paper</span>
              </Button>

              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7 rounded-lg text-muted-foreground hover:text-foreground"
                onClick={() => setIsFullscreenOpen(false)}
                title="Close inspection"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>

          {/* Fullscreen Paper Canvas Viewport */}
          <div className="flex-1 overflow-auto p-6 sm:p-10 flex justify-center items-start bg-slate-900/80">
            <div className="min-w-full w-fit mx-auto flex justify-center items-start">
              <div
                style={{
                  width: `${Math.round(794 * (fullscreenZoom / 100))}px`,
                  minHeight: `${Math.round(1123 * (fullscreenZoom / 100))}px`,
                  position: "relative",
                  transition: "width 0.15s ease-out, min-height 0.15s ease-out",
                }}
                className="shrink-0 mb-12"
              >
                <div
                  style={{
                    transform: `scale(${fullscreenZoom / 100})`,
                    transformOrigin: "top left",
                    position: "absolute",
                    top: 0,
                    left: 0,
                    fontFamily: 'Charter, Cambria, "Times New Roman", Times, serif',
                  }}
                  className="w-[794px] min-h-[1123px] bg-white text-[#0f172a] shadow-2xl ring-1 ring-black/15 rounded-xs p-[48px] font-serif text-[13px] leading-relaxed flex flex-col justify-between select-text"
                >
                  {/* Optional Watermark */}
                  {showWatermark && (
                    <div className="pointer-events-none absolute inset-0 flex items-center justify-center opacity-5 select-none rotate-[-30deg]">
                      <span className="text-7xl font-bold uppercase tracking-widest font-sans">
                        EXAMCRAFT AI
                      </span>
                    </div>
                  )}

                  <div>
                    {/* Board Exam Header Section */}
                    <div className="text-center pb-3 border-b-2 border-black space-y-1">
                      <h1 className="text-[17px] font-bold uppercase tracking-wider font-sans">
                        {resolvedSchoolName}
                      </h1>
                      <p className="text-[14px] font-semibold text-black">
                        Subject: <span className="font-bold underline">{test.subject}</span> (Class {testGrade}th) &bull;{" "}
                        <span>{test.chapter_or_topic}</span>
                      </p>
                      <div className="flex items-center justify-between text-[12px] font-sans font-semibold pt-1 px-1 border-t border-black/30 mt-1.5">
                        <span>Time Allowed: {test.time_allowed}</span>
                        <span className="text-[11px] uppercase tracking-wider text-black/80 font-normal">
                          {testGrade <= 10 ? "Secondary School Certificate" : "Higher Secondary Certificate"}
                        </span>
                        <span>Total Marks: {totalMarks}</span>
                      </div>
                    </div>

                    {/* Student Details Fields */}
                    <div className="grid grid-cols-2 gap-y-2 gap-x-6 py-2.5 border-b border-black/40 text-[12px] font-sans">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold">Student Name:</span>
                        <span className="flex-1 border-b border-dotted border-black/80" />
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold">Roll Number:</span>
                        <span className="flex-1 border-b border-dotted border-black/80" />
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold">Section / Class:</span>
                        <span className="flex-1 border-b border-dotted border-black/80" />
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold">Date:</span>
                        <span className="flex-1 border-b border-dotted border-black/80" />
                      </div>
                    </div>

                    {/* General Instructions Box */}
                    {test.instructions && test.instructions.length > 0 && (
                      <div className="my-3 rounded border border-black/60 bg-black/[0.02] p-2 px-3 text-[11px] font-sans space-y-0.5">
                        <div className="font-bold uppercase tracking-wide text-[10px]">
                          General Instructions:
                        </div>
                        <ol className="list-decimal list-inside space-y-0.5 text-black/90">
                          {test.instructions.map((inst, i) => (
                            <li key={i}>{inst}</li>
                          ))}
                        </ol>
                      </div>
                    )}

                    {/* Examination Questions Body */}
                    <div className={twoColumnMode ? "grid grid-cols-2 gap-6 pt-2" : "space-y-4 pt-2"}>
                      {/* SECTION A: MCQs */}
                      {test.mcqs && test.mcqs.length > 0 && (
                        <div className="space-y-2">
                          <div className="flex items-center justify-between border-b border-black bg-black/[0.04] p-1 px-2 font-sans font-bold text-[12px] uppercase">
                            <span>Section A — Multiple Choice Questions</span>
                            <span className="font-mono">
                              ({test.mcqs.length} &times; 1 = {mcqMarks} Marks)
                            </span>
                          </div>
                          <p className="text-[11px] italic font-sans text-black/80 pl-1">
                            Q.1: Select the correct option for each question. Each MCQ carries 1 mark.
                          </p>

                          <div className="space-y-2.5 pt-1 pl-1">
                            {test.mcqs.map((mcq) => (
                              <div key={mcq.question_number} className="space-y-1">
                                <p className="text-[12.5px] font-medium leading-tight">
                                  <span className="font-bold font-sans pr-1">
                                    ({mcq.question_number})
                                  </span>
                                  <HtmlRenderer content={mcq.question || mcq.question_text || ""} />
                                </p>

                                <div className="grid grid-cols-2 gap-x-4 gap-y-0.5 text-[11.5px] pl-5 font-sans">
                                  {mcq.options.map((opt, optI) => {
                                    const label = ["A", "B", "C", "D"][optI];
                                    const cleanOpt = opt.replace(/^[A-D][).:]\s*/i, "");
                                    return (
                                      <div key={label} className="flex items-baseline gap-1">
                                        <span className="font-bold">({label})</span>
                                        <span>
                                          <HtmlRenderer content={cleanOpt} />
                                        </span>
                                      </div>
                                    );
                                  })}
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* SECTION B: Short Questions */}
                      {test.short_questions && test.short_questions.length > 0 && (
                        <div className="space-y-2 pt-2">
                          <div className="flex items-center justify-between border-b border-black bg-black/[0.04] p-1 px-2 font-sans font-bold text-[12px] uppercase">
                            <span>Section B — Short Answer Questions</span>
                            <span className="font-mono">
                              ({test.short_questions.length} &times; 2 = {shortMarks} Marks)
                            </span>
                          </div>
                          <p className="text-[11px] italic font-sans text-black/80 pl-1">
                            Q.2: Give brief and accurate answers to the following questions.
                          </p>

                          <div className="space-y-2 pt-1 pl-1">
                            {test.short_questions.map((q) => (
                              <div
                                key={q.question_number}
                                className="flex items-start justify-between gap-3 text-[12.5px] font-medium leading-snug"
                              >
                                <p className="flex-1">
                                  <span className="font-bold font-sans pr-1">
                                    ({q.question_number})
                                  </span>
                                  <HtmlRenderer content={q.question || q.question_text || ""} />
                                </p>
                                <span className="font-sans font-bold text-[11px] shrink-0 text-black/80">
                                  [{q.marks || 2}]
                                </span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* SECTION C: Long Questions */}
                      {test.long_questions && test.long_questions.length > 0 && (
                        <div className="space-y-2 pt-2">
                          <div className="flex items-center justify-between border-b border-black bg-black/[0.04] p-1 px-2 font-sans font-bold text-[12px] uppercase">
                            <span>Section C — Long / Detailed Questions</span>
                            <span className="font-mono">
                              ({test.long_questions.length} &times; 5 = {longMarks} Marks)
                            </span>
                          </div>
                          <p className="text-[11px] italic font-sans text-black/80 pl-1">
                            Q.3: Answer the following questions in detail with diagrams and derivations where necessary.
                          </p>

                          <div className="space-y-2.5 pt-1 pl-1">
                            {test.long_questions.map((q) => (
                              <div
                                key={q.question_number}
                                className="flex items-start justify-between gap-3 text-[12.5px] font-medium leading-snug"
                              >
                                <p className="flex-1">
                                  <span className="font-bold font-sans pr-1">
                                    ({q.question_number})
                                  </span>
                                  <HtmlRenderer content={q.question || q.question_text || ""} />
                                </p>
                                <span className="font-sans font-bold text-[11px] shrink-0 text-black/80">
                                  [{q.marks || 5}]
                                </span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Teacher Answer Key & Textbook Citation Appendix */}
                    {showAnswerKey && (
                      <div className="mt-6 pt-4 border-t-2 border-dashed border-black/60 space-y-2.5 font-sans">
                        <div className="flex items-center justify-between bg-black/10 p-1.5 px-2 rounded">
                          <div className="flex items-center gap-1.5 text-xs font-bold uppercase">
                            <FileCheck className="h-4 w-4" />
                            <span>Confidential — Teacher Marking Key &amp; Textbook Citations</span>
                          </div>
                          <Badge variant="outline" size="sm" className="text-[10px] bg-white text-black border-black/40">
                            Master Key
                          </Badge>
                        </div>

                        {/* MCQ Keys Table */}
                        {test.mcqs && test.mcqs.length > 0 && (
                          <div className="space-y-1">
                            <span className="text-[11px] font-bold uppercase">Section A Keys:</span>
                            <div className="grid grid-cols-2 sm:grid-cols-4 gap-1.5 text-[11px]">
                              {test.mcqs.map((mcq) => (
                                <div
                                  key={mcq.question_number}
                                  className="p-1 rounded border border-black/20 bg-black/[0.02] flex items-center justify-between px-1.5"
                                >
                                  <span>Q{mcq.question_number}:</span>
                                  <span className="font-bold text-black underline">
                                    Option ({mcq.correct_option})
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        {/* Textbook Citations Table */}
                        <div className="space-y-1 pt-1">
                          <span className="text-[11px] font-bold uppercase">Curriculum Citations &amp; Quotes:</span>
                          <div className="space-y-1 text-[10.5px]">
                            {test.mcqs?.map((m) =>
                              m.textbook_reference || m.reference_quote ? (
                                <div key={m.question_number} className="flex items-start gap-1.5 text-black/80">
                                  <span className="font-bold shrink-0">Q{m.question_number}:</span>
                                  <span className="italic">
                                    <HtmlRenderer content={m.textbook_reference || m.reference_quote || ""} />
                                  </span>
                                </div>
                              ) : null
                            )}
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Bottom Page Footer */}
                  <div className="mt-8 pt-3 border-t border-black/30 flex items-center justify-between text-[10.5px] font-sans text-black/70">
                    <span>ExamCraft AI &bull; Punjab Curriculum Aligned Paper</span>
                    <span className="font-semibold">*** END OF PAPER ***</span>
                    <span>Page 1 of 1</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
