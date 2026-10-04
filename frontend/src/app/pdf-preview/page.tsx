"use client";

/**
 * src/app/pdf-preview/page.tsx
 * ExamCraft AI - Publication-Grade A4 Vector PDF Preview & Export Station
 */

import * as React from "react";
import Link from "next/link";
import {
  FileText,
  Download,
  Printer,
  ZoomIn,
  ZoomOut,
  RotateCcw,
  Sliders,
  Sparkles,
  ArrowLeft,
  ArrowRight,
  RefreshCw,
  Eye,
  Layers,
  Building,
  ShieldCheck,
  AlertCircle,
  FileCode2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { useTestDraft } from "@/context/TestDraftContext";
import { api } from "@/lib/api";
import { downloadBlob, calculateTestSchemaMarks } from "@/lib/utils";
import { A4Canvas } from "@/components/studio/a4-canvas";
import { Class9TestSchema } from "@/types/exam";

type PreviewMode = "pdf-stream" | "a4-canvas" | "split";

export default function PdfPreviewPage() {
  const { draft } = useTestDraft();
  const [isMounted, setIsMounted] = React.useState<boolean>(false);
  const [testData, setTestData] = React.useState<Class9TestSchema | null>(draft);

  React.useEffect(() => {
    setIsMounted(true);
  }, []);

  // Sync with context if draft updates
  React.useEffect(() => {
    if (draft) {
      setTestData(draft);
    }
  }, [draft]);

  // Export & View States
  const [previewMode, setPreviewMode] = React.useState<PreviewMode>("pdf-stream");
  const [zoom, setZoom] = React.useState<number>(100);
  const [includeAnswerKey, setIncludeAnswerKey] = React.useState<boolean>(true);
  const [twoColumnMode, setTwoColumnMode] = React.useState<boolean>(false);
  const [showWatermark, setShowWatermark] = React.useState<boolean>(false);
  
  const testGrade = Number(testData?.grade) || 9;
  const [instituteName, setInstituteName] = React.useState<string>(
    testGrade <= 10
      ? `PUNJAB BOARD SECONDARY SCHOOL EXAMINATION (CLASS ${testGrade}TH)`
      : `PUNJAB BOARD HIGHER SECONDARY EXAMINATION (CLASS ${testGrade}TH)`
  );

  // PDF Rendering States
  const [pdfBlobUrl, setPdfBlobUrl] = React.useState<string | null>(null);
  const [isRendering, setIsRendering] = React.useState<boolean>(false);
  const [renderError, setRenderError] = React.useState<string | null>(null);
  const [downloadSuccess, setDownloadSuccess] = React.useState<boolean>(false);

  // Generate / refresh PDF blob
  const renderPdfBlob = React.useCallback(async () => {
    if (!testData) return;
    setIsRendering(true);
    setRenderError(null);
    try {
      // Create clone with custom title/instructions if modified
      const testToRender: Class9TestSchema = {
        ...testData,
        test_title: instituteName ? `${instituteName} - ${testData.test_title}` : testData.test_title,
      };

      const blob = await api.renderPdf({
        test_data: testToRender,
        include_answer_key: includeAnswerKey,
      });

      const url = URL.createObjectURL(blob);
      setPdfBlobUrl((prevUrl) => {
        if (prevUrl) URL.revokeObjectURL(prevUrl);
        return url;
      });
    } catch (err: unknown) {
      console.error("Failed to render PDF:", err);
      setRenderError(
        err instanceof Error
          ? err.message
          : "Failed to communicate with PDF rendering engine. Please try again."
      );
    } finally {
      setIsRendering(false);
    }
  }, [testData, instituteName, includeAnswerKey]);

  // Initial PDF render on mount or option change
  React.useEffect(() => {
    if (testData) {
      void renderPdfBlob();
    }
    return () => {
      if (pdfBlobUrl) {
        URL.revokeObjectURL(pdfBlobUrl);
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [testData, includeAnswerKey]);

  const handleDownload = async () => {
    if (!testData) return;
    setIsRendering(true);
    try {
      const blob = await api.renderPdf({
        test_data: testData,
        include_answer_key: includeAnswerKey,
      });

      const sanitizedSubject = (testData.subject || "Class9").replace(/[^a-zA-Z0-9]/g, "_");
      const sanitizedChapter = (testData.chapter_or_topic || "Assessment")
        .replace(/[^a-zA-Z0-9]/g, "_")
        .substring(0, 20);

      const filename = `${sanitizedSubject}_Grade${testData.grade || 9}_${sanitizedChapter}_Test.pdf`;
      downloadBlob(blob, filename);

      setDownloadSuccess(true);
      setTimeout(() => setDownloadSuccess(false), 3000);
    } catch (err) {
      console.error("Download failed:", err);
    } finally {
      setIsRendering(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  if (!isMounted) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  if (!draft || !testData) {
    return (
      <div className="max-w-xl mx-auto py-16 px-4 text-center space-y-5">
        <div className="h-16 w-16 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto shadow-2xs">
          <FileText className="h-8 w-8" />
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold tracking-tight text-foreground">
            No Examination Paper Available for Preview
          </h2>
          <p className="text-sm text-muted-foreground leading-relaxed">
            The High-Resolution Vector PDF Preview Station is generated after creating an assessment paper.
            Please configure and generate an exam paper first.
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

  const totalMarks = calculateTestSchemaMarks(testData);
  const mcqCount = (testData.mcqs || []).length;
  const shortCount = (testData.short_questions || []).length;
  const longCount = (testData.long_questions || []).length;
  const totalQuestions = mcqCount + shortCount + longCount;

  const getSubjectBadgeVariant = (subject: string) => {
    switch (subject?.toLowerCase()) {
      case "physics":
        return "physics" as const;
      case "chemistry":
        return "chemistry" as const;
      case "mathematics":
        return "mathematics" as const;
      case "biology":
        return "biology" as const;
      case "computer science":
        return "computer-science" as const;
      default:
        return "outline" as const;
    }
  };

  return (
    <div className="space-y-4 max-w-7xl mx-auto py-2">
      {/* Top Navigation & Action Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-border/80">
        <div className="flex items-center gap-3">
          <Link href="/review">
            <Button variant="ghost" size="icon-sm" title="Back to Crafting Studio">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
          <div className="p-2 rounded-xl bg-primary/10 text-primary">
            <FileText className="h-5 w-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold tracking-tight text-foreground">
                PDF Preview & Export Station
              </h1>
              <Badge variant={getSubjectBadgeVariant(testData.subject)} size="sm">
                {testData.subject}
              </Badge>
              <Badge variant="outline" size="sm" className="font-bold text-xs bg-muted/40 text-foreground border-border/80">
                Class {testGrade}
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground">
              {testData.test_title} &bull; {totalQuestions} Questions &bull; {totalMarks} Total Marks
            </p>
          </div>
        </div>

        {/* Action Controls */}
        <div className="flex flex-wrap items-center gap-2">
          {/* View Mode Switcher */}
          <div className="flex items-center rounded-lg border border-border bg-card p-0.5">
            <button
              type="button"
              onClick={() => setPreviewMode("pdf-stream")}
              className={`px-2.5 py-1 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 ${
                previewMode === "pdf-stream"
                  ? "bg-primary text-primary-foreground font-semibold shadow-2xs"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <FileCode2 className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">Vector PDF Stream</span>
              <span className="sm:hidden">PDF</span>
            </button>
            <button
              type="button"
              onClick={() => setPreviewMode("a4-canvas")}
              className={`px-2.5 py-1 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 ${
                previewMode === "a4-canvas"
                  ? "bg-primary text-primary-foreground font-semibold shadow-2xs"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Eye className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">WYSIWYG A4 Canvas</span>
              <span className="sm:hidden">Canvas</span>
            </button>
            <button
              type="button"
              onClick={() => setPreviewMode("split")}
              className={`px-2.5 py-1 text-xs font-medium rounded-md transition-colors hidden md:flex items-center gap-1.5 ${
                previewMode === "split"
                  ? "bg-primary text-primary-foreground font-semibold shadow-2xs"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Layers className="h-3.5 w-3.5" />
              <span>Split View</span>
            </button>
          </div>

          {/* Zoom controls for canvas view */}
          {previewMode !== "pdf-stream" && (
            <div className="hidden lg:flex items-center rounded-lg border border-border bg-card p-0.5">
              <Button
                variant="ghost"
                size="icon-sm"
                onClick={() => setZoom(Math.max(50, zoom - 15))}
                title="Zoom out"
              >
                <ZoomOut className="h-3.5 w-3.5" />
              </Button>
              <span className="px-2 text-xs font-mono text-muted-foreground w-12 text-center">
                {zoom}%
              </span>
              <Button
                variant="ghost"
                size="icon-sm"
                onClick={() => setZoom(Math.min(160, zoom + 15))}
                title="Zoom in"
              >
                <ZoomIn className="h-3.5 w-3.5" />
              </Button>
              <Button
                variant="ghost"
                size="icon-sm"
                onClick={() => setZoom(100)}
                title="Reset zoom"
              >
                <RotateCcw className="h-3.5 w-3.5" />
              </Button>
            </div>
          )}

          {/* Re-render button */}
          <Button
            variant="outline"
            size="sm"
            onClick={renderPdfBlob}
            disabled={isRendering}
            className="gap-1.5 text-xs"
            title="Re-render PDF with updated export settings"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${isRendering ? "animate-spin" : ""}`} />
            <span className="hidden sm:inline">Refresh</span>
          </Button>

          {/* Direct Print */}
          <Button
            variant="outline"
            size="sm"
            onClick={handlePrint}
            className="gap-1.5 text-xs"
          >
            <Printer className="h-3.5 w-3.5" />
            <span>Print Direct</span>
          </Button>

          {/* Download PDF */}
          <Button
            size="sm"
            onClick={handleDownload}
            disabled={isRendering}
            className={`gap-1.5 shadow-xs text-xs transition-colors ${
              downloadSuccess ? "bg-emerald-600 hover:bg-emerald-700 text-white" : ""
            }`}
          >
            {downloadSuccess ? (
              <>
                <ShieldCheck className="h-3.5 w-3.5" />
                <span>Downloaded!</span>
              </>
            ) : (
              <>
                <Download className="h-3.5 w-3.5" />
                <span>{isRendering ? "Rendering..." : "Download PDF"}</span>
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Main Container: Settings Panel + Preview Area */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Side: Export & Layout Settings (4 cols on lg) */}
        <div className="lg:col-span-4 space-y-4">
          <Card className="border-border/80 shadow-2xs">
            <CardHeader className="p-4 pb-3 border-b border-border/60">
              <CardTitle className="text-sm font-semibold flex items-center gap-2">
                <Sliders className="h-4 w-4 text-primary" />
                <span>Export & Layout Controls</span>
              </CardTitle>
              <CardDescription className="text-xs">
                Customize header typography, answer keys, and page styling
              </CardDescription>
            </CardHeader>

            <CardContent className="p-4 space-y-4 text-xs">
              {/* Institute Name Input */}
              <div className="space-y-1.5">
                <Label htmlFor="institute-name" className="text-xs font-medium flex items-center gap-1.5">
                  <Building className="h-3.5 w-3.5 text-muted-foreground" />
                  <span>Custom School / Institute Header</span>
                </Label>
                <Input
                  id="institute-name"
                  value={instituteName}
                  onChange={(e) => setInstituteName(e.target.value)}
                  placeholder="e.g. ARMY PUBLIC SCHOOL & COLLEGE"
                  className="text-xs"
                />
              </div>

              {/* Answer Key Toggle */}
              <div className="flex items-center justify-between pt-1">
                <div className="space-y-0.5 pr-2">
                  <Label htmlFor="answer-key-toggle" className="text-xs font-medium cursor-pointer">
                    Include Teacher Solution Appendix
                  </Label>
                  <p className="text-[11px] text-muted-foreground">
                    Appends answer key and marking rubric on a separate page
                  </p>
                </div>
                <Switch
                  id="answer-key-toggle"
                  checked={includeAnswerKey}
                  onCheckedChange={setIncludeAnswerKey}
                />
              </div>

              {/* Two Column Mode Toggle */}
              <div className="flex items-center justify-between pt-1">
                <div className="space-y-0.5 pr-2">
                  <Label htmlFor="two-column-toggle" className="text-xs font-medium cursor-pointer">
                    Two-Column Paper Layout
                  </Label>
                  <p className="text-[11px] text-muted-foreground">
                    Compact 2-column formatting for paper conservation
                  </p>
                </div>
                <Switch
                  id="two-column-toggle"
                  checked={twoColumnMode}
                  onCheckedChange={setTwoColumnMode}
                />
              </div>

              {/* Watermark Toggle */}
              <div className="flex items-center justify-between pt-1">
                <div className="space-y-0.5 pr-2">
                  <Label htmlFor="watermark-toggle" className="text-xs font-medium cursor-pointer">
                    Confidential Examination Watermark
                  </Label>
                  <p className="text-[11px] text-muted-foreground">
                    Displays diagonal institutional watermark
                  </p>
                </div>
                <Switch
                  id="watermark-toggle"
                  checked={showWatermark}
                  onCheckedChange={setShowWatermark}
                />
              </div>

              {/* Test Breakdown Stats */}
              <div className="p-3 rounded-lg bg-muted/40 border border-border/70 space-y-2">
                <span className="font-semibold text-foreground text-xs">Test Structure Breakdown</span>
                <div className="grid grid-cols-3 gap-2 text-center">
                  <div className="p-1.5 rounded bg-card border border-border/60">
                    <p className="text-[10px] text-muted-foreground">Section A (MCQ)</p>
                    <p className="text-sm font-bold font-mono text-foreground">{mcqCount} Qs</p>
                  </div>
                  <div className="p-1.5 rounded bg-card border border-border/60">
                    <p className="text-[10px] text-muted-foreground">Section B (Short)</p>
                    <p className="text-sm font-bold font-mono text-foreground">{shortCount} Qs</p>
                  </div>
                  <div className="p-1.5 rounded bg-card border border-border/60">
                    <p className="text-[10px] text-muted-foreground">Section C (Long)</p>
                    <p className="text-sm font-bold font-mono text-foreground">{longCount} Qs</p>
                  </div>
                </div>
              </div>

              {/* Document Specifications */}
              <div className="p-3 rounded-lg bg-muted/20 border border-border/60 space-y-1.5">
                <span className="font-semibold text-foreground">Document Specifications</span>
                <div className="flex justify-between text-muted-foreground text-[11px]">
                  <span>Page Format:</span>
                  <span className="font-mono text-foreground">ISO 216 A4 (210 &times; 297 mm)</span>
                </div>
                <div className="flex justify-between text-muted-foreground text-[11px]">
                  <span>Canvas Dimensions:</span>
                  <span className="font-mono text-foreground">595 &times; 842 pt</span>
                </div>
                <div className="flex justify-between text-muted-foreground text-[11px]">
                  <span>Print Margins:</span>
                  <span className="font-mono text-foreground">0.5 inch (36 pt)</span>
                </div>
                <div className="flex justify-between text-muted-foreground text-[11px]">
                  <span>Rendering Engine:</span>
                  <span className="font-mono text-foreground">ReportLab 4.x Vector PDF</span>
                </div>
              </div>

              {/* Navigation Back */}
              <div className="pt-2 flex flex-col gap-2">
                <Link href="/review">
                  <Button variant="outline" size="sm" className="w-full text-xs gap-1.5">
                    <Sparkles className="h-3.5 w-3.5 text-primary" />
                    <span>Back to Crafting Studio</span>
                  </Button>
                </Link>
                <Link href="/generate">
                  <Button variant="ghost" size="sm" className="w-full text-xs text-muted-foreground">
                    Create Another Assessment
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Side: Viewer (8 cols on lg) */}
        <div className="lg:col-span-8 space-y-4">
          {renderError && (
            <div className="p-4 rounded-xl border border-rose-500/30 bg-rose-500/10 text-rose-700 dark:text-rose-300 text-xs flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{renderError}</span>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={renderPdfBlob}
                className="shrink-0 text-xs h-7 border-rose-500/40"
              >
                Retry
              </Button>
            </div>
          )}

          {/* Mode 1: Vector PDF Stream (Iframe / Object) */}
          {previewMode === "pdf-stream" && (
            <Card className="border-border/80 shadow-md overflow-hidden">
              <div className="p-3 bg-muted/40 border-b border-border/80 flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <FileText className="h-4 w-4 text-primary" />
                  <span className="font-semibold text-foreground">
                    Live ReportLab PDF Stream ({testData.subject})
                  </span>
                </div>
                <Badge variant="outline" className="font-mono text-[10px]">
                  application/pdf
                </Badge>
              </div>

              <div className="relative min-h-[750px] bg-zinc-950 flex items-center justify-center">
                {isRendering ? (
                  <div className="flex flex-col items-center justify-center p-12 text-center space-y-3">
                    <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
                    <p className="text-xs font-semibold text-zinc-300">
                      Compiling Vector PDF Stream...
                    </p>
                    <p className="text-[11px] text-zinc-500">
                      Generating high-resolution Punjab Board formatting with ReportLab
                    </p>
                  </div>
                ) : pdfBlobUrl ? (
                  <iframe
                    src={pdfBlobUrl}
                    className="w-full h-[800px] border-0"
                    title="PDF Examination Preview"
                  />
                ) : (
                  <div className="flex flex-col items-center justify-center p-12 text-center space-y-3">
                    <p className="text-xs text-zinc-400">PDF stream not loaded.</p>
                    <Button size="sm" onClick={renderPdfBlob} className="text-xs">
                      Generate Preview
                    </Button>
                  </div>
                )}
              </div>
            </Card>
          )}

          {/* Mode 2: WYSIWYG A4 Canvas */}
          {previewMode === "a4-canvas" && (
            <div className="flex justify-center overflow-x-auto pb-6">
              <div
                className="transition-transform duration-200 origin-top"
                style={{ transform: `scale(${zoom / 100})` }}
              >
                <A4Canvas
                  test={testData}
                  schoolName={instituteName}
                  showAnswerKeyDefault={includeAnswerKey}
                  twoColumnDefault={twoColumnMode}
                  showWatermarkDefault={showWatermark}
                  onPrint={handlePrint}
                />
              </div>
            </div>
          )}

          {/* Mode 3: Split View (Side-by-Side) */}
          {previewMode === "split" && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
              {/* Left half: PDF Iframe */}
              <div className="rounded-xl border border-border/80 overflow-hidden shadow-xs">
                <div className="p-2 bg-muted/40 border-b border-border/80 text-[11px] font-semibold flex items-center justify-between">
                  <span>Binary PDF Stream</span>
                  <Badge variant="outline" size="sm">ReportLab</Badge>
                </div>
                {pdfBlobUrl ? (
                  <iframe
                    src={pdfBlobUrl}
                    className="w-full h-[700px] border-0 bg-zinc-950"
                    title="PDF Stream Split"
                  />
                ) : (
                  <div className="h-[700px] flex items-center justify-center text-xs text-muted-foreground">
                    Loading PDF...
                  </div>
                )}
              </div>

              {/* Right half: Live A4 Canvas */}
              <div className="rounded-xl border border-border/80 overflow-y-auto max-h-[735px] p-2 bg-muted/20">
                <div className="scale-75 origin-top -mb-40">
                  <A4Canvas
                    test={testData}
                    schoolName={instituteName}
                    showAnswerKeyDefault={includeAnswerKey}
                    twoColumnDefault={twoColumnMode}
                    showWatermarkDefault={showWatermark}
                    onPrint={handlePrint}
                  />
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
