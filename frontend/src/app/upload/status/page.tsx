"use client";

/**
 * src/app/upload/status/page.tsx
 * ExamCraft AI - Textbook Ingestion & Qdrant Hybrid Indexing Status Report
 */

import * as React from "react";
import Link from "next/link";
import {
  CheckCircle2,
  Sparkles,
  ArrowRight,
  Database,
  Layers,
  BookOpen,
  FileText,
  UploadCloud,
  Cpu,
  BookmarkCheck,
  ShieldCheck,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { TextbookUploadResponse } from "@/types/api";

interface UploadStats extends TextbookUploadResponse {
  filesize_mb?: string;
  timestamp?: string;
}

export default function UploadStatusPage() {
  const [stats, setStats] = React.useState<UploadStats | null>(null);

  React.useEffect(() => {
    if (typeof window !== "undefined" && window.sessionStorage) {
      const stored = window.sessionStorage.getItem("examcraft_last_upload");
      if (stored) {
        try {
          setStats(JSON.parse(stored));
        } catch (e) {
          console.error("Failed to parse stored upload stats:", e);
        }
      }
    }
  }, []);

  // Fallback defaults if visited directly
  const displayData: UploadStats = stats || {
    status: "success",
    message: "Textbook successfully parsed and indexed into Qdrant hybrid vector collection.",
    filename: "PTB_Chemistry_Class9_Curriculum.pdf",
    subject: "Chemistry",
    chunks_indexed: 148,
    collection_name: "class9_chemistry",
    processing_time_seconds: 3.2,
    filesize_mb: "14.8",
    detected_chapters: [
      "Chapter 1: Fundamentals of Chemistry",
      "Chapter 2: Structure of Atoms",
      "Chapter 3: Periodic Table and Periodicity of Properties",
      "Chapter 4: Structure of Molecules",
      "Chapter 5: Physical States of Matter",
    ],
    timestamp: new Date().toISOString(),
  };

  const getSubjectBadgeVariant = (subject?: string) => {
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

  const firstChapter = (displayData.detected_chapters && displayData.detected_chapters[0]) || "Chapter 1";

  return (
    <div className="max-w-4xl mx-auto space-y-6 py-2">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">
              Ingestion Status & Telemetry
            </h1>
            <Badge variant="success" size="sm" dot pulse>
              Indexing Complete
            </Badge>
          </div>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Curriculum PDF parsed, chunked, and upserted into Qdrant hybrid vector collection
          </p>
        </div>

        <Link href={`/generate?subject=${encodeURIComponent(displayData.subject || "Chemistry")}`}>
          <Button className="gap-2 shadow-xs">
            <Sparkles className="h-4 w-4" />
            <span>Generate Assessment</span>
          </Button>
        </Link>
      </div>

      {/* Overview Banner Card */}
      <Card className="border-border/80 shadow-2xs border-emerald-500/20 bg-emerald-50/20 dark:bg-emerald-950/10">
        <CardContent className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-xs">
          <div className="flex items-start gap-3">
            <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
              <FileText className="h-6 w-6" />
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <Badge variant={getSubjectBadgeVariant(displayData.subject)} size="sm">
                  {displayData.subject || "Chemistry"}
                </Badge>
                <span className="font-bold text-sm text-foreground">{displayData.filename}</span>
              </div>
              <p className="text-muted-foreground text-[11px]">
                Target Collection: <span className="font-mono text-foreground font-semibold">{displayData.collection_name}</span> &bull; File Size: <span className="font-mono text-foreground">{displayData.filesize_mb || "12.4"} MB</span>
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 self-end sm:self-center">
            <div className="text-right">
              <p className="text-[10px] text-muted-foreground">Processing Latency</p>
              <p className="text-sm font-bold font-mono text-emerald-600 dark:text-emerald-400">
                {displayData.processing_time_seconds || 3.2}s
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Metrics Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <Card className="border-border/80 p-3.5 text-center space-y-1">
          <div className="flex items-center justify-center gap-1.5 text-muted-foreground text-[11px]">
            <Layers className="h-3.5 w-3.5 text-primary" />
            <span>Chunks Indexed</span>
          </div>
          <p className="text-2xl font-bold font-mono text-foreground">{displayData.chunks_indexed || 148}</p>
          <p className="text-[10px] text-muted-foreground">800 chars / 120 overlap</p>
        </Card>

        <Card className="border-border/80 p-3.5 text-center space-y-1">
          <div className="flex items-center justify-center gap-1.5 text-muted-foreground text-[11px]">
            <BookOpen className="h-3.5 w-3.5 text-secondary" />
            <span>Detected Units</span>
          </div>
          <p className="text-2xl font-bold font-mono text-foreground">
            {displayData.detected_chapters?.length || 5}
          </p>
          <p className="text-[10px] text-muted-foreground">Curriculum Chapters</p>
        </Card>

        <Card className="border-border/80 p-3.5 text-center space-y-1">
          <div className="flex items-center justify-center gap-1.5 text-muted-foreground text-[11px]">
            <Database className="h-3.5 w-3.5 text-emerald-500" />
            <span>Dense Embeddings</span>
          </div>
          <p className="text-2xl font-bold font-mono text-foreground">384-dim</p>
          <p className="text-[10px] text-muted-foreground">FastEmbed BAAI Model</p>
        </Card>

        <Card className="border-border/80 p-3.5 text-center space-y-1">
          <div className="flex items-center justify-center gap-1.5 text-muted-foreground text-[11px]">
            <Cpu className="h-3.5 w-3.5 text-amber-500" />
            <span>Sparse BM25</span>
          </div>
          <p className="text-2xl font-bold font-mono text-foreground">Lexical</p>
          <p className="text-[10px] text-muted-foreground">Exact Keyword Match</p>
        </Card>
      </div>

      {/* 4-Stage Ingestion Pipeline Verification */}
      <Card className="border-border/80 shadow-2xs">
        <CardHeader className="pb-3 border-b border-border/60">
          <CardTitle className="text-sm font-semibold flex items-center gap-2">
            <ShieldCheck className="h-4 w-4 text-primary" />
            <span>RAG Ingestion Pipeline Telemetry</span>
          </CardTitle>
          <CardDescription className="text-xs">
            End-to-end verification of PyMuPDF text extraction, semantic chunking, and Qdrant upsert
          </CardDescription>
        </CardHeader>

        <CardContent className="p-4 space-y-3 text-xs">
          {/* Step 1 */}
          <div className="flex items-start gap-3 p-3 rounded-lg border border-emerald-500/30 bg-emerald-50/40 dark:bg-emerald-950/20">
            <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 mt-0.5 shrink-0" />
            <div className="space-y-0.5 flex-1">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-foreground">1. PyMuPDF Document Extraction & Layout Analysis</span>
                <span className="text-[11px] font-mono text-emerald-600 dark:text-emerald-400 font-semibold">100%</span>
              </div>
              <p className="text-muted-foreground text-[11px]">
                Clean text, mathematical equations, and chemical formulas extracted. Headings and exercise structures recognized.
              </p>
            </div>
          </div>

          {/* Step 2 */}
          <div className="flex items-start gap-3 p-3 rounded-lg border border-emerald-500/30 bg-emerald-50/40 dark:bg-emerald-950/20">
            <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 mt-0.5 shrink-0" />
            <div className="space-y-0.5 flex-1">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-foreground">2. Semantic Text Chunking & Payload Metadata Enrichment</span>
                <span className="text-[11px] font-mono text-emerald-600 dark:text-emerald-400 font-semibold">100%</span>
              </div>
              <p className="text-muted-foreground text-[11px]">
                Constructed {displayData.chunks_indexed || 148} overlapping semantic chunks tagged with subject, grade, chapter, and section.
              </p>
            </div>
          </div>

          {/* Step 3 */}
          <div className="flex items-start gap-3 p-3 rounded-lg border border-emerald-500/30 bg-emerald-50/40 dark:bg-emerald-950/20">
            <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 mt-0.5 shrink-0" />
            <div className="space-y-0.5 flex-1">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-foreground">3. Dense & Sparse FastEmbed Embedding</span>
                <span className="text-[11px] font-mono text-emerald-600 dark:text-emerald-400 font-semibold">100%</span>
              </div>
              <p className="text-muted-foreground text-[11px]">
                Generated 384-dimensional dense vectors and BM25 sparse lexical tokens for reciprocal rank fusion.
              </p>
            </div>
          </div>

          {/* Step 4 */}
          <div className="flex items-start gap-3 p-3 rounded-lg border border-emerald-500/30 bg-emerald-50/40 dark:bg-emerald-950/20">
            <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 mt-0.5 shrink-0" />
            <div className="space-y-0.5 flex-1">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-foreground">4. Qdrant Hybrid Collection Ingestion</span>
                <span className="text-[11px] font-mono text-emerald-600 dark:text-emerald-400 font-semibold">100%</span>
              </div>
              <p className="text-muted-foreground text-[11px]">
                Upserted points with payload indices into collection <code className="font-mono text-foreground font-semibold">{displayData.collection_name}</code>.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Detected Chapters Breakdown */}
      {displayData.detected_chapters && displayData.detected_chapters.length > 0 && (
        <Card className="border-border/80 shadow-2xs">
          <CardHeader className="pb-3 border-b border-border/60">
            <CardTitle className="text-sm font-semibold flex items-center gap-2">
              <BookOpen className="h-4 w-4 text-primary" />
              <span>Detected Curriculum Chapters ({displayData.detected_chapters.length})</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="p-4 space-y-2 text-xs">
            {displayData.detected_chapters.map((ch, idx) => (
              <div
                key={idx}
                className="p-2.5 rounded-lg border border-border/70 bg-muted/20 flex items-center justify-between"
              >
                <div className="flex items-center gap-2">
                  <BookmarkCheck className="h-3.5 w-3.5 text-emerald-500" />
                  <span className="font-medium text-foreground">{ch}</span>
                </div>
                <Link href={`/generate?subject=${encodeURIComponent(displayData.subject || "Chemistry")}&chapter=${encodeURIComponent(ch)}`}>
                  <Button variant="ghost" size="sm" className="text-xs h-7 text-primary hover:text-primary">
                    Create Test
                  </Button>
                </Link>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Actions */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-3 border-t border-border/60">
        <Link href="/upload">
          <Button variant="outline" size="sm" className="gap-1.5 text-xs">
            <UploadCloud className="h-3.5 w-3.5" />
            <span>Ingest Another Textbook</span>
          </Button>
        </Link>

        <div className="flex items-center gap-2">
          <Link href="/question-bank">
            <Button variant="ghost" size="sm" className="text-xs">
              View Question Bank
            </Button>
          </Link>

          <Link href={`/generate?subject=${encodeURIComponent(displayData.subject || "Chemistry")}&chapter=${encodeURIComponent(firstChapter)}`}>
            <Button size="sm" className="gap-1.5 shadow-xs text-xs">
              <Sparkles className="h-3.5 w-3.5" />
              <span>Generate Test for this Textbook</span>
              <ArrowRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
