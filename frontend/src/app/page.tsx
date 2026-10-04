"use client";

import * as React from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Sparkles,
  ArrowRight,
  ShieldCheck,
  Cpu,
  Atom,
  FlaskConical,
  Calculator,
  Dna,
  Laptop,
  FileText,
  Sliders,
} from "lucide-react";
import { useTestDraft } from "@/context/TestDraftContext";

const GRADE_INFO: Record<number, { level: string; badge: string; sub: string }> = {
  9: {
    level: "Secondary School Examination Engine",
    badge: "SSC-I",
    sub: "Matric Part 1",
  },
  10: {
    level: "Secondary School Examination Engine",
    badge: "SSC-II",
    sub: "Matric Part 2",
  },
  11: {
    level: "Higher Secondary Examination Engine",
    badge: "HSSC-I",
    sub: "Intermediate Part 1",
  },
  12: {
    level: "Higher Secondary Examination Engine",
    badge: "HSSC-II",
    sub: "Intermediate Part 2",
  },
};

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

export default function HomePage() {
  const { activeGrade } = useTestDraft();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const displayGrade = (mounted && activeGrade) ? activeGrade : 9;
  const gradeMeta = GRADE_INFO[displayGrade] || GRADE_INFO[9];

  return (
    <div className="max-w-5xl mx-auto space-y-8 py-4">
      {/* Welcome Banner */}
      <div className="relative overflow-hidden rounded-2xl border border-border/80 bg-gradient-to-br from-primary/10 via-background to-secondary/10 p-6 sm:p-8">
        <div className="space-y-4 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-primary/30 bg-primary/10 text-primary text-xs font-semibold">
            <Sparkles className="h-3.5 w-3.5" />
            <span>Class {displayGrade} {gradeMeta.level} ({gradeMeta.badge})</span>
          </div>

          <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-foreground">
            Zero-Hallucination <span className="text-primary">Exam Generator</span>
          </h1>

          <p className="text-muted-foreground text-sm sm:text-base leading-relaxed">
            Generate rigorous Class {displayGrade} ({gradeMeta.badge}) assessment papers with grounded textbook citations, live marks calculation,
            and split-screen real-time A4 editing.
          </p>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <Link href="/generate" prefetch={true}>
              <Button size="default" className="gap-2 shadow-xs">
                <Sparkles className="h-4 w-4" />
                <span>Create New Assessment</span>
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
            <Link href="/dashboard" prefetch={true}>
              <Button variant="outline" size="default">
                View Dashboard
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Feature Highlights Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="border-border/80 shadow-2xs hover:border-primary/40 transition-colors">
          <CardHeader className="pb-2">
            <div className="h-9 w-9 rounded-lg bg-emerald-100 dark:bg-emerald-950/60 flex items-center justify-center text-emerald-600 dark:text-emerald-400 mb-1">
              <ShieldCheck className="h-5 w-5" />
            </div>
            <CardTitle className="text-base">100% Grounded RAG</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="text-xs leading-relaxed">
              Every question is extracted directly from verified Class {displayGrade} textbook chapters with exact section and topic references.
            </CardDescription>
          </CardContent>
        </Card>

        <Card className="border-border/80 shadow-2xs hover:border-primary/40 transition-colors">
          <CardHeader className="pb-2">
            <div className="h-9 w-9 rounded-lg bg-blue-100 dark:bg-blue-950/60 flex items-center justify-center text-primary mb-1">
              <Cpu className="h-5 w-5" />
            </div>
            <CardTitle className="text-base">Split-Screen Studio</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="text-xs leading-relaxed">
              Edit questions, regenerate single items with AI, and watch the live A4 examination sheet update synchronously.
            </CardDescription>
          </CardContent>
        </Card>

        <Card className="border-border/80 shadow-2xs hover:border-primary/40 transition-colors">
          <CardHeader className="pb-2">
            <div className="h-9 w-9 rounded-lg bg-amber-100 dark:bg-amber-950/60 flex items-center justify-center text-amber-600 dark:text-amber-400 mb-1">
              <FileText className="h-5 w-5" />
            </div>
            <CardTitle className="text-base">ReportLab PDF Export</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="text-xs leading-relaxed">
              Export pixel-perfect publication-ready A4 PDF papers complete with school headers, student fields, and answer keys.
            </CardDescription>
          </CardContent>
        </Card>
      </div>

      {/* 5 Subjects Cards */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-bold tracking-tight text-foreground">
              Core Class {displayGrade} Subjects ({gradeMeta.badge})
            </h2>
            <p className="text-xs text-muted-foreground">
              Select a subject to start generating custom exam papers from official Class {displayGrade} textbooks
            </p>
          </div>
          <Link href="/generate" className="text-xs text-primary font-medium hover:underline flex items-center gap-1">
            <span>All Subjects</span>
            <ArrowRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
          <Link href="/generate?subject=Physics" className="group">
            <Card className="border-border/80 hover:border-[#005BBF] hover:shadow-xs transition-all h-full">
              <CardContent className="p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="p-2 rounded-lg bg-[#EBF3FF] dark:bg-[#0A1E3B] text-[#005BBF] dark:text-[#ADC7FF]">
                    <Atom className="h-4 w-4" />
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm group-hover:text-[#005BBF] transition-colors">Physics</h3>
                  <p className="text-[11px] text-muted-foreground line-clamp-2">
                    {SUBJECT_SYLLABI["Physics"][displayGrade] || SUBJECT_SYLLABI["Physics"][9]}
                  </p>
                </div>
              </CardContent>
            </Card>
          </Link>

          <Link href="/generate?subject=Chemistry" className="group">
            <Card className="border-border/80 hover:border-[#006E2C] hover:shadow-xs transition-all h-full">
              <CardContent className="p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="p-2 rounded-lg bg-[#EAF7EE] dark:bg-[#072410] text-[#006E2C] dark:text-[#86F898]">
                    <FlaskConical className="h-4 w-4" />
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm group-hover:text-[#006E2C] transition-colors">Chemistry</h3>
                  <p className="text-[11px] text-muted-foreground line-clamp-2">
                    {SUBJECT_SYLLABI["Chemistry"][displayGrade] || SUBJECT_SYLLABI["Chemistry"][9]}
                  </p>
                </div>
              </CardContent>
            </Card>
          </Link>

          <Link href="/generate?subject=Mathematics" className="group">
            <Card className="border-border/80 hover:border-[#805600] hover:shadow-xs transition-all h-full">
              <CardContent className="p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="p-2 rounded-lg bg-[#FFF8EB] dark:bg-[#2B1D00] text-[#805600] dark:text-[#FFBA45]">
                    <Calculator className="h-4 w-4" />
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm group-hover:text-[#805600] transition-colors">Mathematics</h3>
                  <p className="text-[11px] text-muted-foreground line-clamp-2">
                    {SUBJECT_SYLLABI["Mathematics"][displayGrade] || SUBJECT_SYLLABI["Mathematics"][9]}
                  </p>
                </div>
              </CardContent>
            </Card>
          </Link>

          <Link href="/generate?subject=Biology" className="group">
            <Card className="border-border/80 hover:border-[#673AB7] hover:shadow-xs transition-all h-full">
              <CardContent className="p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="p-2 rounded-lg bg-[#F5EFFF] dark:bg-[#220E42] text-[#673AB7] dark:text-[#D1C4E9]">
                    <Dna className="h-4 w-4" />
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm group-hover:text-[#673AB7] transition-colors">Biology</h3>
                  <p className="text-[11px] text-muted-foreground line-clamp-2">
                    {SUBJECT_SYLLABI["Biology"][displayGrade] || SUBJECT_SYLLABI["Biology"][9]}
                  </p>
                </div>
              </CardContent>
            </Card>
          </Link>

          <Link href="/generate?subject=Computer%20Science" className="group">
            <Card className="border-border/80 hover:border-[#00838F] hover:shadow-xs transition-all h-full">
              <CardContent className="p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="p-2 rounded-lg bg-[#E0F7FA] dark:bg-[#00292E] text-[#00838F] dark:text-[#80DEEA]">
                    <Laptop className="h-4 w-4" />
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm group-hover:text-[#00838F] transition-colors">Computer Science</h3>
                  <p className="text-[11px] text-muted-foreground line-clamp-2">
                    {SUBJECT_SYLLABI["Computer Science"][displayGrade] || SUBJECT_SYLLABI["Computer Science"][9]}
                  </p>
                </div>
              </CardContent>
            </Card>
          </Link>
        </div>
      </div>

      {/* Workflow Steps Preview */}
      <Card className="border-border/80 bg-muted/20">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Sliders className="h-4 w-4 text-primary" />
            <span>4-Step Assessment Pipeline</span>
          </CardTitle>
          <CardDescription className="text-xs">
            From textbook indexing to final print examination
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs">
            <div className="flex items-start gap-2.5 p-2.5 rounded-lg border border-border/60 bg-card">
              <div className="h-6 w-6 rounded-full bg-primary/10 text-primary font-bold flex items-center justify-center shrink-0">
                1
              </div>
              <div className="space-y-0.5">
                <p className="font-semibold">Configure Scope</p>
                <p className="text-muted-foreground text-[11px]">Select subject, chapter, question mix & marks</p>
              </div>
            </div>

            <div className="flex items-start gap-2.5 p-2.5 rounded-lg border border-border/60 bg-card">
              <div className="h-6 w-6 rounded-full bg-primary/10 text-primary font-bold flex items-center justify-center shrink-0">
                2
              </div>
              <div className="space-y-0.5">
                <p className="font-semibold">Qdrant Hybrid Search</p>
                <p className="text-muted-foreground text-[11px]">Vector retrieval of official textbook chunks</p>
              </div>
            </div>

            <div className="flex items-start gap-2.5 p-2.5 rounded-lg border border-border/60 bg-card">
              <div className="h-6 w-6 rounded-full bg-primary/10 text-primary font-bold flex items-center justify-center shrink-0">
                3
              </div>
              <div className="space-y-0.5">
                <p className="font-semibold">Studio Review</p>
                <p className="text-muted-foreground text-[11px]">Interactive question editing & live A4 sync</p>
              </div>
            </div>

            <div className="flex items-start gap-2.5 p-2.5 rounded-lg border border-border/60 bg-card">
              <div className="h-6 w-6 rounded-full bg-primary/10 text-primary font-bold flex items-center justify-center shrink-0">
                4
              </div>
              <div className="space-y-0.5">
                <p className="font-semibold">PDF Export</p>
                <p className="text-muted-foreground text-[11px]">Generate high-res printable PDF with answer key</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
