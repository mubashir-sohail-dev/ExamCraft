/**
 * src/lib/subject-colors.ts
 * ExamCraft AI - Subject Color Tokens, Icons & Helpers
 */

import {
  Atom,
  FlaskConical,
  Calculator,
  Dna,
  Laptop,
  type LucideIcon,
} from "lucide-react";

export type SubjectId =
  | "physics"
  | "chemistry"
  | "mathematics"
  | "biology"
  | "computerScience";

export type SubjectApiString =
  | "Physics"
  | "Chemistry"
  | "Mathematics"
  | "Biology"
  | "Computer Science";

export interface SubjectThemeConfig {
  id: SubjectId;
  apiString: SubjectApiString;
  displayName: string;
  lightHex: string;
  darkHex: string;
  hslVar: string;
  bgClass: string;
  textClass: string;
  borderClass: string;
  badgeClass: string;
  activeTileClass: string;
  icon: LucideIcon;
  description: string;
  hasExercises?: boolean; // Mathematics specific
}

export const SUBJECT_CONFIGS: Record<SubjectApiString, SubjectThemeConfig> = {
  Physics: {
    id: "physics",
    apiString: "Physics",
    displayName: "Physics",
    lightHex: "#005BBF",
    darkHex: "#ADC7FF",
    hslVar: "--subject-physics",
    bgClass: "bg-subject-physics",
    textClass: "text-subject-physics",
    borderClass: "border-subject-physics",
    badgeClass: "bg-subject-physics/10 text-subject-physics border-subject-physics/30",
    activeTileClass: "bg-subject-physics/15 border-subject-physics text-subject-physics",
    icon: Atom,
    description: "Classical Mechanics, Electromagnetism, Optics, and Modern Physics",
  },
  Chemistry: {
    id: "chemistry",
    apiString: "Chemistry",
    displayName: "Chemistry",
    lightHex: "#006E2C",
    darkHex: "#86F898",
    hslVar: "--subject-chemistry",
    bgClass: "bg-subject-chemistry",
    textClass: "text-subject-chemistry",
    borderClass: "border-subject-chemistry",
    badgeClass: "bg-subject-chemistry/10 text-subject-chemistry border-subject-chemistry/30",
    activeTileClass: "bg-subject-chemistry/15 border-subject-chemistry text-subject-chemistry",
    icon: FlaskConical,
    description: "Physical Chemistry, Organic, Inorganic, and Chemical Reactions",
  },
  Mathematics: {
    id: "mathematics",
    apiString: "Mathematics",
    displayName: "Mathematics",
    lightHex: "#805600",
    darkHex: "#FFBA45",
    hslVar: "--subject-mathematics",
    bgClass: "bg-subject-mathematics",
    textClass: "text-subject-mathematics",
    borderClass: "border-subject-mathematics",
    badgeClass: "bg-subject-mathematics/10 text-subject-mathematics border-subject-mathematics/30",
    activeTileClass: "bg-subject-mathematics/15 border-subject-mathematics text-subject-mathematics",
    icon: Calculator,
    description: "Algebra, Geometry, Trigonometry, Calculus, and Statistics",
    hasExercises: true,
  },
  Biology: {
    id: "biology",
    apiString: "Biology",
    displayName: "Biology",
    lightHex: "#673AB7",
    darkHex: "#D1C4E9",
    hslVar: "--subject-biology",
    bgClass: "bg-subject-biology",
    textClass: "text-subject-biology",
    borderClass: "border-subject-biology",
    badgeClass: "bg-subject-biology/10 text-subject-biology border-subject-biology/30",
    activeTileClass: "bg-subject-biology/15 border-subject-biology text-subject-biology",
    icon: Dna,
    description: "Cell Biology, Genetics, Physiology, Ecology, and Evolution",
  },
  "Computer Science": {
    id: "computerScience",
    apiString: "Computer Science",
    displayName: "Computer Science",
    lightHex: "#00838F",
    darkHex: "#80DEEA",
    hslVar: "--subject-computer",
    bgClass: "bg-subject-computer",
    textClass: "text-subject-computer",
    borderClass: "border-subject-computer",
    badgeClass: "bg-subject-computer/10 text-subject-computer border-subject-computer/30",
    activeTileClass: "bg-subject-computer/15 border-subject-computer text-subject-computer",
    icon: Laptop,
    description: "Algorithms, Programming, Data Structures, Networks, and Databases",
  },
};

export const ALL_SUBJECTS: SubjectThemeConfig[] = Object.values(SUBJECT_CONFIGS);

export function getSubjectConfig(subjectStr?: string): SubjectThemeConfig {
  if (!subjectStr) return SUBJECT_CONFIGS.Physics;
  const clean = subjectStr.trim().toLowerCase();
  for (const config of ALL_SUBJECTS) {
    if (
      config.apiString.toLowerCase() === clean ||
      config.displayName.toLowerCase() === clean ||
      config.id.toLowerCase() === clean ||
      clean.includes(config.displayName.toLowerCase())
    ) {
      return config;
    }
  }
  return SUBJECT_CONFIGS.Physics;
}

export function isValidSubject(subjectStr: string): boolean {
  const clean = subjectStr.trim().toLowerCase();
  return ALL_SUBJECTS.some(
    (s) =>
      s.apiString.toLowerCase() === clean ||
      s.displayName.toLowerCase() === clean ||
      s.id.toLowerCase() === clean
  );
}
