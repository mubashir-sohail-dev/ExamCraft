/**
 * src/lib/constants.ts
 * ExamCraft AI - System Constants, Color Tokens & Subject Metadata
 */

import { SubjectType } from "@/types/exam";
import { Atom, FlaskConical, Calculator, Dna, Laptop, LucideIcon } from "lucide-react";

export const DEFAULT_API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
export const DEFAULT_CLIENT_KEY = process.env.NEXT_PUBLIC_CLIENT_KEY || "examcraft-secret-key-2026";
export const DEFAULT_ADMIN_KEY = process.env.NEXT_PUBLIC_ADMIN_KEY || "examcraft-admin-key-2026";

export const QUESTION_WEIGHTS = {
  MCQ: 1,
  SHORT: 2,
  LONG: 5,
} as const;

export const DEFAULT_TIME_ALLOWED = "45 Minutes";

export const DEFAULT_INSTRUCTIONS = [
  "Attempt all questions.",
  "Write neatly and draw diagrams where necessary.",
  "Scientific calculators are allowed for numerical questions.",
];

export interface SubjectConfig {
  id: SubjectType;
  name: string;
  slug: string;
  icon: LucideIcon;
  lightColor: string;
  darkColor: string;
  tokenVar: string;
  bgLight: string;
  bgDark: string;
  borderColorLight: string;
  borderColorDark: string;
  description: string;
  defaultTime: string;
  sampleChapters: string[];
}

export const SUBJECTS_CONFIG: Record<SubjectType, SubjectConfig> = {
  Physics: {
    id: "Physics",
    name: "Physics",
    slug: "physics",
    icon: Atom,
    lightColor: "#005BBF",
    darkColor: "#ADC7FF",
    tokenVar: "var(--physics-color)",
    bgLight: "#EBF3FF",
    bgDark: "#0A1E3B",
    borderColorLight: "#B8D5FF",
    borderColorDark: "#1E3E6E",
    description: "Physical Quantities, Kinematics, Dynamics, Gravitation, Work & Energy",
    defaultTime: "45 Minutes",
    sampleChapters: [
      "Chapter 1: Physical Quantities and Measurement",
      "Chapter 2: Kinematics",
      "Chapter 3: Dynamics",
      "Chapter 4: Turning Effect of Forces",
      "Chapter 5: Gravitation",
    ],
  },
  Chemistry: {
    id: "Chemistry",
    name: "Chemistry",
    slug: "chemistry",
    icon: FlaskConical,
    lightColor: "#006E2C",
    darkColor: "#86F898",
    tokenVar: "var(--chemistry-color)",
    bgLight: "#EAF7EE",
    bgDark: "#072410",
    borderColorLight: "#A3E8B5",
    borderColorDark: "#144D26",
    description: "Fundamentals of Chemistry, Structure of Atoms, Periodic Table, Chemical Bonding",
    defaultTime: "45 Minutes",
    sampleChapters: [
      "Chapter 1: Fundamentals of Chemistry",
      "Chapter 2: Structure of Atoms",
      "Chapter 3: Periodic Table and Periodicity of Properties",
      "Chapter 4: Structure of Molecules",
      "Chapter 5: Physical States of Matter",
    ],
  },
  Mathematics: {
    id: "Mathematics",
    name: "Mathematics",
    slug: "mathematics",
    icon: Calculator,
    lightColor: "#805600",
    darkColor: "#FFBA45",
    tokenVar: "var(--math-color)",
    bgLight: "#FFF8EB",
    bgDark: "#2B1D00",
    borderColorLight: "#F3D594",
    borderColorDark: "#5E3F00",
    description: "Matrices & Determinants, Real & Complex Numbers, Logarithms, Algebraic Expressions",
    defaultTime: "60 Minutes",
    sampleChapters: [
      "Chapter 1: Matrices and Determinants",
      "Chapter 2: Real and Complex Numbers",
      "Chapter 3: Logarithms",
      "Chapter 4: Algebraic Expressions and Algebraic Formulas",
      "Chapter 5: Factorization",
    ],
  },
  Biology: {
    id: "Biology",
    name: "Biology",
    slug: "biology",
    icon: Dna,
    lightColor: "#673AB7",
    darkColor: "#D1C4E9",
    tokenVar: "var(--biology-color)",
    bgLight: "#F5EFFF",
    bgDark: "#220E42",
    borderColorLight: "#D9C2FF",
    borderColorDark: "#4A2B7B",
    description: "Introduction to Biology, Solving a Biological Problem, Biodiversity, Cell Structure",
    defaultTime: "45 Minutes",
    sampleChapters: [
      "Chapter 1: Introduction to Biology",
      "Chapter 2: Solving a Biological Problem",
      "Chapter 3: Biodiversity",
      "Chapter 4: Cells and Tissues",
      "Chapter 5: Cell Cycle",
    ],
  },
  "Computer Science": {
    id: "Computer Science",
    name: "Computer Science",
    slug: "computer-science",
    icon: Laptop,
    lightColor: "#00838F",
    darkColor: "#80DEEA",
    tokenVar: "var(--cs-color)",
    bgLight: "#E0F7FA",
    bgDark: "#00292E",
    borderColorLight: "#8CE4EE",
    borderColorDark: "#00535C",
    description: "Fundamentals of Computer, Computer Security & Ethics, Office Automation",
    defaultTime: "45 Minutes",
    sampleChapters: [
      "Chapter 1: Fundamentals of Computer",
      "Chapter 2: Fundamentals of Operating System",
      "Chapter 3: Office Automation",
      "Chapter 4: Data Communication",
      "Chapter 5: Computer Networks",
    ],
  },
};

export const SUBJECTS_METADATA = SUBJECTS_CONFIG;

export const GENERATION_PIPELINE_STEPS = [
  {
    step: 1,
    title: "Searching Knowledge Base",
    subtitle: "Querying Qdrant hybrid vector index for verified textbook chunks",
    description: "Retrieving official textbook chunks from Qdrant vector database...",
    durationMs: 1200,
  },
  {
    step: 2,
    title: "Context Extraction & Alignment",
    subtitle: "Filtering syllabus constraints and aligning Bloom's Taxonomy levels",
    description: "Aligning Bloom's taxonomy & syllabus bounds for Class 9...",
    durationMs: 1500,
  },
  {
    step: 3,
    title: "Synthesizing AI Questions",
    subtitle: "Gemini generating structured MCQs, Short & Long questions with citations",
    description: "Generating zero-hallucination MCQs, Short & Long questions with citations...",
    durationMs: 2500,
  },
  {
    step: 4,
    title: "Assembly & Answer Key Generation",
    subtitle: "Formatting examination layout & calculating total marks",
    description: "Formatting examination layout & calculating total marks...",
    durationMs: 1000,
  },
] as const;

export const PIPELINE_STEPS = GENERATION_PIPELINE_STEPS;
