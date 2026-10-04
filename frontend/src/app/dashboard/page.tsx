"use client";

import * as React from "react";
import Link from "next/link";
import {
  Sparkles,
  FileText,
  UploadCloud,
  CheckCircle2,
  Clock,
  ArrowRight,
  Cpu,
  Database,
  Activity,
  Layers,
  Atom,
  FlaskConical,
  Calculator,
  Dna,
  Laptop,
  RefreshCw,
  ExternalLink,
  GraduationCap,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useTelemetry } from "@/context/TelemetryContext";
import { useTestDraft } from "@/context/TestDraftContext";
import { SavedTestRecord } from "@/types/exam";
import { cn, formatDate } from "@/lib/utils";

const SUBJECT_SYLLABI: Record<string, Record<number, string>> = {
  Physics: {
    9: "Kinematics, Dynamics, Gravitation, Work & Energy",
    10: "Simple Harmonic Motion, Waves, Sound, Optics & Nuclear Physics",
    11: "Measurements, Vectors, Force & Motion, Thermodynamics",
    12: "Electrostatics, Current Electricity, Electromagnetism & Modern Physics",
  },
  Chemistry: {
    9: "Atoms, Periodic Table, Chemical Bonding, Physical States",
    10: "Chemical Equilibrium, Acids & Bases, Organic Chemistry & Hydrocarbons",
    11: "Stoichiometry, Atomic Structure, Chemical Bonding & Thermochemistry",
    12: "s-Block & p-Block Elements, Transition Metals, Alkyl Halides & Biomolecules",
  },
  Mathematics: {
    9: "Matrices, Real Numbers, Logarithms, Algebraic Manipulation",
    10: "Quadratic Equations, Variations, Sets & Functions, Coordinate Geometry",
    11: "Number Systems, Matrices & Determinants, Sequences, Trigonometry",
    12: "Functions & Limits, Differentiation, Integration & Analytical Geometry",
  },
  Biology: {
    9: "Cell Biology, Biodiversity, Bioenergetics, Tissues & Transport",
    10: "Gaseous Exchange, Homeostasis, Coordination & Control, Genetics",
    11: "Cell Structure, Biological Molecules, Enzymes, Kingdom Animalia",
    12: "Respiration, Reproduction, Development, Chromosomes & DNA",
  },
  "Computer Science": {
    9: "Computer Hardware, OS, Software Basics, Networks",
    10: "Programming in C, HTML & Web Development, Database Basics",
    11: "Information Technology, Architecture, Operating Systems, Security",
    12: "Object-Oriented Programming, C++ / Python, Data Structures, Algorithms",
  },
};

const SUBJECT_LIST = [
  {
    name: "Physics",
    icon: Atom,
    variant: "physics" as const,
    color: "#005BBF",
    bg: "bg-[#EBF3FF] dark:bg-[#0A1E3B]",
    textColor: "text-[#005BBF] dark:text-[#ADC7FF]",
    description: "Physical Quantities, Kinematics, Dynamics, Gravitation, Work & Energy",
  },
  {
    name: "Chemistry",
    icon: FlaskConical,
    variant: "chemistry" as const,
    color: "#006E2C",
    bg: "bg-[#EAF7EE] dark:bg-[#072410]",
    textColor: "text-[#006E2C] dark:text-[#86F898]",
    description: "Fundamentals of Chemistry, Structure of Atoms, Periodic Table, Bonding",
  },
  {
    name: "Mathematics",
    icon: Calculator,
    variant: "mathematics" as const,
    color: "#805600",
    bg: "bg-[#FFF8EB] dark:bg-[#2B1D00]",
    textColor: "text-[#805600] dark:text-[#FFBA45]",
    description: "Matrices & Determinants, Real Numbers, Logarithms, Algebraic Formulas",
  },
  {
    name: "Biology",
    icon: Dna,
    variant: "biology" as const,
    color: "#673AB7",
    bg: "bg-[#F5EFFF] dark:bg-[#220E42]",
    textColor: "text-[#673AB7] dark:text-[#D1C4E9]",
    description: "Cell Biology, Solving Biological Problems, Biodiversity, Cell Cycle",
  },
  {
    name: "Computer Science",
    icon: Laptop,
    variant: "computer-science" as const,
    color: "#00838F",
    bg: "bg-[#E0F7FA] dark:bg-[#00292E]",
    textColor: "text-[#00838F] dark:text-[#80DEEA]",
    description: "Fundamentals of Computer, Operating Systems, Office Automation",
  },
];

export default function DashboardPage() {
  const { status, latencyMs, healthData, refreshHealth } = useTelemetry();
  const { activeGrade, setDraft, history, refreshHistory } = useTestDraft();
  const [isRefreshing, setIsRefreshing] = React.useState(false);
  const displayGrade = activeGrade || 9;

  React.useEffect(() => {
    refreshHistory();
  }, [refreshHistory]);

  const handleManualRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refreshHealth();
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleOpenTestInStudio = (testRecord: SavedTestRecord) => {
    if (testRecord.test_data) {
      setDraft(testRecord.test_data);
    }
  };

  const getSubjectBadgeVariant = (subject: string) => {
    switch (subject.toLowerCase()) {
      case "physics":
        return "physics" as const;
      case "chemistry":
        return "chemistry" as const;
      case "mathematics":
      case "math":
        return "mathematics" as const;
      case "biology":
        return "biology" as const;
      case "computer science":
      case "computer":
        return "computer-science" as const;
      default:
        return "outline" as const;
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">
            Assessment Dashboard
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Class {activeGrade || 9} Assessment Studio & Grounded Examination Workspace
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link href="/generate">
            <Button className="gap-2 shadow-xs">
              <Sparkles className="h-4 w-4" />
              <span>Generate New Test</span>
            </Button>
          </Link>
        </div>
      </div>

      {/* Quick Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
        <Card className="border-border/80 shadow-2xs">
          <CardContent className="p-4 sm:p-5 flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-xs font-medium text-muted-foreground">Generated Papers</p>
              <p className="text-2xl font-bold text-foreground">
                {history.length}
              </p>
              <p className="text-[11px] font-medium flex items-center gap-1">
                {history.length > 0 ? (
                  <span className="text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                    <CheckCircle2 className="h-3 w-3" /> Ready for Print
                  </span>
                ) : (
                  <span className="text-muted-foreground">None generated yet</span>
                )}
              </p>
            </div>
            <div className="h-11 w-11 rounded-xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
              <FileText className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-border/80 shadow-2xs">
          <CardContent className="p-4 sm:p-5 flex items-center justify-between">
            <div className="space-y-1.5">
              <p className="text-xs font-medium text-muted-foreground">Curriculum Classes</p>
              <div className="flex items-center gap-1.5">
                {[9, 10, 11, 12].map((g) => (
                  <span
                    key={g}
                    className={`inline-flex items-center justify-center text-xs font-bold px-2 py-0.5 rounded-md border transition-colors ${
                      displayGrade === g
                        ? "bg-primary text-primary-foreground border-primary shadow-xs"
                        : "bg-muted/50 text-muted-foreground border-border/70"
                    }`}
                  >
                    {g}th
                  </span>
                ))}
              </div>
              <p className="text-[11px] text-muted-foreground">SSC &amp; HSSC Board Syllabi</p>
            </div>
            <div className="h-11 w-11 rounded-xl bg-secondary/10 text-secondary flex items-center justify-center shrink-0">
              <GraduationCap className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-border/80 shadow-2xs">
          <CardContent className="p-4 sm:p-5 flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-xs font-medium text-muted-foreground">Subjects Indexed</p>
              <p className="text-2xl font-bold text-foreground">5 / 5</p>
              <p className="text-[11px] text-muted-foreground">Class {displayGrade} Curriculum</p>
            </div>
            <div className="h-11 w-11 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0">
              <Layers className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 5 Subjects Cards Grid */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-bold tracking-tight text-foreground">
              Class {displayGrade} Subject Syllabi
            </h2>
            <p className="text-xs text-muted-foreground">
              Direct access to chapter-level assessment generators from official Class {displayGrade} textbooks
            </p>
          </div>
          <Link
            href="/generate"
            className="text-xs text-primary font-medium hover:underline flex items-center gap-1"
          >
            <span>Open Generator</span>
            <ArrowRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-3.5">
          {SUBJECT_LIST.map((subj) => {
            const Icon = subj.icon;
            const syllabusDesc = SUBJECT_SYLLABI[subj.name]?.[displayGrade] || subj.description;
            return (
              <Card
                key={subj.name}
                className="border-border/80 shadow-2xs hover:shadow-xs transition-all hover:border-primary/50 group flex flex-col justify-between"
              >
                <CardHeader className="p-4 pb-2">
                  <div className="flex items-center justify-between mb-2">
                    <div
                      className={cn(
                        "h-8 w-8 rounded-lg flex items-center justify-center",
                        subj.bg,
                        subj.textColor
                      )}
                    >
                      <Icon className="h-4 w-4" />
                    </div>
                  </div>
                  <CardTitle className="text-base group-hover:text-primary transition-colors">
                    {subj.name}
                  </CardTitle>
                  <CardDescription className="text-[11px] line-clamp-2 leading-relaxed">
                    {syllabusDesc}
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-4 pt-2">
                  <Link href={`/generate?subject=${encodeURIComponent(subj.name)}`}>
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full text-xs gap-1.5 group-hover:bg-primary group-hover:text-primary-foreground group-hover:border-primary transition-all"
                    >
                      <span>Create Test</span>
                      <ArrowRight className="h-3 w-3" />
                    </Button>
                  </Link>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Lower Row: Recent Papers + Live Backend Diagnostics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Generated Papers (2 cols) */}
        <Card className="lg:col-span-2 border-border/80 shadow-2xs flex flex-col">
          <CardHeader className="p-4 sm:p-5 pb-3 border-b border-border/60 flex flex-row items-center justify-between">
            <div>
              <CardTitle className="text-base font-semibold flex items-center gap-2">
                <Clock className="h-4 w-4 text-primary" />
                <span>Recent Exam Papers</span>
              </CardTitle>
              <CardDescription className="text-xs">
                Previously generated &amp; crafted examination papers
              </CardDescription>
            </div>
            {history.length > 0 && (
              <Link href="/recent-papers">
                <Button variant="ghost" size="sm" className="text-xs gap-1">
                  <span>View All</span>
                  <ArrowRight className="h-3 w-3" />
                </Button>
              </Link>
            )}
          </CardHeader>

          <CardContent className="p-4 sm:p-5 flex-1 space-y-3">
            {history.length > 0 ? (
              <div className="space-y-2.5">
                {history.slice(0, 4).map((test) => (
                  <div
                    key={test.id}
                    className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-3 rounded-lg border border-border/70 bg-card hover:bg-muted/40 transition-colors"
                  >
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <Badge variant={getSubjectBadgeVariant(test.subject)} size="sm">
                          {test.subject}
                        </Badge>
                        <span className="font-semibold text-xs text-foreground line-clamp-1">
                          {test.title || test.test_title || `Class ${displayGrade} Examination`}
                        </span>
                      </div>
                      <p className="text-[11px] text-muted-foreground">
                        {test.test_data?.chapter_or_topic || test.chapter_or_topic || "Chapter Assessment"} &bull; {test.total_marks} Marks &bull; {formatDate(test.created_at)}
                      </p>
                    </div>

                    <div className="flex items-center gap-2 self-end sm:self-center shrink-0">
                      <Link href="/review" onClick={() => handleOpenTestInStudio(test)}>
                        <Button variant="outline" size="sm" className="text-xs h-7 px-2.5">
                          Studio
                        </Button>
                      </Link>
                      <Link href="/pdf-preview" onClick={() => handleOpenTestInStudio(test)}>
                        <Button size="sm" className="text-xs h-7 px-2.5">
                          PDF
                        </Button>
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-8 text-center space-y-3">
                <div className="h-10 w-10 rounded-full bg-muted/60 flex items-center justify-center mx-auto text-muted-foreground">
                  <FileText className="h-5 w-5" />
                </div>
                <div className="space-y-1">
                  <p className="text-sm font-semibold text-foreground">No Generated Papers Yet</p>
                  <p className="text-xs text-muted-foreground max-w-sm mx-auto">
                    You have not generated any Class {displayGrade} assessment papers yet. Use the test generator to configure and create your first exam.
                  </p>
                </div>
                <div className="pt-1">
                  <Link href="/generate">
                    <Button size="sm" className="gap-1.5 text-xs shadow-xs">
                      <Sparkles className="h-3.5 w-3.5" />
                      <span>Generate First Assessment</span>
                    </Button>
                  </Link>
                </div>
              </div>
            )}

            {history.length > 0 && (
              <div className="pt-2 flex justify-center">
                <Link href="/generate">
                  <Button variant="ghost" size="sm" className="text-xs text-primary gap-1">
                    <Sparkles className="h-3.5 w-3.5" />
                    <span>Configure a new Class {displayGrade} assessment</span>
                  </Button>
                </Link>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Live Backend Telemetry & Diagnostic Card (1 col) */}
        <Card className="border-border/80 shadow-2xs flex flex-col justify-between">
          <CardHeader className="p-4 sm:p-5 pb-3 border-b border-border/60 flex flex-row items-center justify-between">
            <div>
              <CardTitle className="text-base font-semibold flex items-center gap-2">
                <Activity className="h-4 w-4 text-emerald-500" />
                <span>Backend Telemetry</span>
              </CardTitle>
              <CardDescription className="text-xs">
                Real-time API & RAG status
              </CardDescription>
            </div>

            <Button
              variant="ghost"
              size="icon-sm"
              onClick={handleManualRefresh}
              disabled={isRefreshing}
              title="Ping Backend"
            >
              <RefreshCw className={cn("h-3.5 w-3.5", isRefreshing && "animate-spin")} />
            </Button>
          </CardHeader>

          <CardContent className="p-4 sm:p-5 space-y-3.5 text-xs">
            {/* Status overview */}
            <div className="p-3 rounded-lg border border-border/70 bg-muted/20 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Status:</span>
                <Badge
                  variant={status === "connected" ? "success" : status === "degraded" ? "warning" : "destructive"}
                  size="sm"
                  dot
                  pulse={status === "connected"}
                >
                  {status === "connected" ? "Connected" : status === "degraded" ? "Degraded" : "Offline"}
                </Badge>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Ping Latency:</span>
                <span className="font-mono font-semibold text-foreground">
                  {latencyMs !== null ? `${latencyMs} ms` : "N/A"}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Qdrant Vector DB:</span>
                <span className="font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                  <Database className="h-3.5 w-3.5" />
                  {healthData?.qdrant_connected ? "Connected" : status === "offline" ? "Unreachable" : "Disconnected"}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">AI Generation Model:</span>
                <span className="font-mono font-medium text-foreground flex items-center gap-1">
                  <Cpu className="h-3 w-3 text-primary" />
                  Gemini 3.8 Flash
                </span>
              </div>
            </div>

            {/* Quick action links */}
            <div className="space-y-1.5 pt-1">
              <Link
                href="/upload"
                className="flex items-center justify-between p-2 rounded-md hover:bg-muted/60 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <UploadCloud className="h-3.5 w-3.5 text-muted-foreground" />
                  <span className="font-medium text-muted-foreground hover:text-foreground">
                    Upload Textbook PDF
                  </span>
                </div>
                <ArrowRight className="h-3 w-3 text-muted-foreground" />
              </Link>

              <Link
                href="/about"
                className="flex items-center justify-between p-2 rounded-md hover:bg-muted/60 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <ExternalLink className="h-3.5 w-3.5 text-muted-foreground" />
                  <span className="font-medium text-muted-foreground hover:text-foreground">
                    System Specs & Architecture
                  </span>
                </div>
                <ArrowRight className="h-3 w-3 text-muted-foreground" />
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
