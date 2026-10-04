"use client";

import * as React from "react";
import {
  Sparkles,
  Database,
  Server,
  Activity,
  RefreshCw,
  Code2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useTelemetry } from "@/context/TelemetryContext";
import { cn } from "@/lib/utils";

export default function AboutPage() {
  const { status, latencyMs, healthData, refreshHealth, backendUrl, lastChecked } = useTelemetry();
  const [isRefreshing, setIsRefreshing] = React.useState(false);

  const handleManualPing = async () => {
    setIsRefreshing(true);
    try {
      await refreshHealth();
    } finally {
      setIsRefreshing(false);
    }
  };

  return (
    <div className="max-w-5xl mx-auto space-y-8 py-4">
      {/* Title & Mission */}
      <div className="space-y-3">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-primary/30 bg-primary/10 text-primary text-xs font-semibold">
          <Sparkles className="h-3.5 w-3.5" />
          <span>ExamCraft AI Architecture & Technical Specifications</span>
        </div>

        <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-foreground">
          Zero-Hallucination Assessment Engine
        </h1>

        <p className="text-muted-foreground text-sm sm:text-base leading-relaxed max-w-3xl">
          ExamCraft AI is a specialized assessment generation and split-screen crafting studio built specifically
          for secondary and intermediate education (Classes 9, 10, 11, and 12). Designed to eliminate AI hallucinations entirely, ExamCraft
          employs hybrid dense/sparse vector retrieval directly from verified textbook corpora.
        </p>
      </div>

      {/* Live System Diagnostics Card */}
      <Card className="border-border/80 shadow-2xs">
        <CardHeader className="pb-3 flex flex-row items-center justify-between">
          <div className="space-y-1">
            <CardTitle className="text-base font-semibold flex items-center gap-2">
              <Activity className="h-4 w-4 text-emerald-500" />
              <span>Live System Diagnostics</span>
            </CardTitle>
            <CardDescription className="text-xs">
              Direct telemetry connection to the ExamCraft FastAPI backend
            </CardDescription>
          </div>

          <Button
            size="sm"
            variant="outline"
            onClick={handleManualPing}
            disabled={isRefreshing}
            className="gap-1.5 text-xs"
          >
            <RefreshCw className={cn("h-3.5 w-3.5", isRefreshing && "animate-spin")} />
            <span>{isRefreshing ? "Pinging..." : "Run Health Check"}</span>
          </Button>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
            <div className="p-3 rounded-lg border border-border/70 bg-card space-y-1">
              <span className="text-muted-foreground">Service Status</span>
              <div className="flex items-center gap-1.5 font-semibold text-sm">
                <Badge
                  variant={status === "connected" ? "success" : status === "degraded" ? "warning" : "destructive"}
                  size="sm"
                  dot
                  pulse={status === "connected"}
                >
                  {status === "connected" ? "Operational" : status === "degraded" ? "Degraded" : "Offline"}
                </Badge>
              </div>
            </div>

            <div className="p-3 rounded-lg border border-border/70 bg-card space-y-1">
              <span className="text-muted-foreground">Roundtrip Latency</span>
              <p className="font-mono text-sm font-bold text-foreground">
                {latencyMs !== null ? `${latencyMs} ms` : "N/A"}
              </p>
            </div>

            <div className="p-3 rounded-lg border border-border/70 bg-card space-y-1">
              <span className="text-muted-foreground">Qdrant Vector DB</span>
              <p className="font-semibold text-sm text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                <Database className="h-3.5 w-3.5" />
                {healthData?.qdrant_connected ? "Connected" : status === "offline" ? "Unreachable" : "Disconnected"}
              </p>
            </div>

            <div className="p-3 rounded-lg border border-border/70 bg-card space-y-1">
              <span className="text-muted-foreground">Backend Uptime</span>
              <p className="font-mono text-sm font-semibold text-foreground">
                {healthData?.uptime_seconds ? `${Math.floor(healthData.uptime_seconds / 60)} mins` : "N/A"}
              </p>
            </div>
          </div>

          <div className="p-3 rounded-lg bg-muted/30 border border-border/60 flex flex-col sm:flex-row sm:items-center justify-between text-xs gap-2">
            <div className="flex items-center gap-2 text-muted-foreground">
              <Server className="h-3.5 w-3.5" />
              <span>Target Endpoint:</span>
              <span className="font-mono font-medium text-foreground">{backendUrl}</span>
            </div>

            <div className="text-muted-foreground text-[11px]">
              Last verified: {lastChecked ? lastChecked.toLocaleTimeString() : "Pending"}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* RAG Pipeline Architecture */}
      <div className="space-y-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-foreground">
            5-Stage Grounded RAG Pipeline
          </h2>
          <p className="text-xs text-muted-foreground">
            How ExamCraft converts raw textbooks into verifiable examination papers
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card className="border-border/80 shadow-2xs">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="h-7 w-7 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-xs font-bold">
                  1
                </div>
                <CardTitle className="text-sm font-semibold">
                  PyMuPDF Text Ingestion & Parsing
                </CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Official Punjab Curriculum and Textbook Board (PCTB) PDF files are parsed using PyMuPDF.
                Text is chunked into logical units containing chapter headers, section titles, and exercise numbers.
              </p>
            </CardContent>
          </Card>

          <Card className="border-border/80 shadow-2xs">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="h-7 w-7 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center text-xs font-bold">
                  2
                </div>
                <CardTitle className="text-sm font-semibold">
                  FastEmbed Dense & Sparse Embeddings
                </CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Chunks are embedded using FastEmbed <code className="text-[11px] bg-muted px-1 rounded">BAAI/bge-small-en-v1.5</code> (dense 384d vectors)
                paired with BM25 sparse vectors for hybrid semantic and keyword lexical retrieval.
              </p>
            </CardContent>
          </Card>

          <Card className="border-border/80 shadow-2xs">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="h-7 w-7 rounded-lg bg-violet-500/10 text-violet-600 dark:text-violet-400 flex items-center justify-center text-xs font-bold">
                  3
                </div>
                <CardTitle className="text-sm font-semibold">
                  Qdrant Vector Database
                </CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Stored in high-performance Qdrant collections. Hybrid search utilizes Reciprocal Rank Fusion (RRF)
                to rank the most syllabus-accurate text chunks for assessment generation.
              </p>
            </CardContent>
          </Card>

          <Card className="border-border/80 shadow-2xs">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="h-7 w-7 rounded-lg bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center text-xs font-bold">
                  4
                </div>
                <CardTitle className="text-sm font-semibold">
                  Google Gemini 3.8 Flash Synthesis
                </CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Gemini LLM receives retrieved textbook chunks along with strict curriculum prompt constraints (Classes 9–12).
                It produces structured Pydantic schemas with MCQs, short questions, and long questions.
              </p>
            </CardContent>
          </Card>

          <Card className="border-border/80 shadow-2xs md:col-span-2">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="h-7 w-7 rounded-lg bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center text-xs font-bold">
                  5
                </div>
                <CardTitle className="text-sm font-semibold">
                  ReportLab Vector PDF Typesetting
                </CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-muted-foreground leading-relaxed">
                The approved examination JSON is compiled directly into a publication-ready vector A4 PDF using ReportLab.
                Includes custom institution headers, student roll number blocks, 2-column MCQ tables, and full solution appendix.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Tech Stack Badges */}
      <Card className="border-border/80 bg-muted/20">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Code2 className="h-4 w-4 text-primary" />
            <span>Technology Stack</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2 text-xs">
            <Badge variant="outline" className="bg-card">Next.js 15 (App Router)</Badge>
            <Badge variant="outline" className="bg-card">React 19</Badge>
            <Badge variant="outline" className="bg-card">TypeScript 5</Badge>
            <Badge variant="outline" className="bg-card">Tailwind CSS</Badge>
            <Badge variant="outline" className="bg-card">FastAPI (Python 3.12)</Badge>
            <Badge variant="outline" className="bg-card">Qdrant Vector DB</Badge>
            <Badge variant="outline" className="bg-card">FastEmbed</Badge>
            <Badge variant="outline" className="bg-card">Google Gemini 3.8 Flash</Badge>
            <Badge variant="outline" className="bg-card">ReportLab PDF Engine</Badge>
            <Badge variant="outline" className="bg-card">Flutter Mobile Parity</Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
