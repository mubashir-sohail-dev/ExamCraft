/**
 * src/lib/sample-data.ts
 * ExamCraft AI - Realistic Offline Mock Data & Fallback Generators
 */

import { Class9TestSchema, QuestionBankItem } from "@/types/exam";
import {
  HealthResponse,
  SubjectListResponse,
  ChapterListResponse,
  ChapterMetadataResponse,
  TestGenerationRequest,
} from "@/types/api";

export function getMockHealth(): HealthResponse {
  return {
    status: "ok",
    qdrant_connected: true,
    version: "1.0.0",
    environment: "development (offline demo)",
    uptime_seconds: 1250.4,
    timestamp: new Date().toISOString(),
    qdrant_latency_ms: 14.2,
    collection_exists: true,
    llm_available: true,
  };
}

export function getMockSubjects(): SubjectListResponse {
  return {
    subjects: ["Physics", "Chemistry", "Mathematics", "Biology", "Computer Science"],
  };
}

export const MULTI_CLASS_CHAPTERS: Record<number, Record<string, string[]>> = {
  9: {
    Chemistry: [
      "Chapter 1: Fundamentals of Chemistry",
      "Chapter 2: Structure of Atoms",
      "Chapter 3: Periodic Table and Periodicity of Properties",
      "Chapter 4: Structure of Molecules",
      "Chapter 5: Physical States of Matter",
      "Chapter 6: Solutions",
      "Chapter 7: Electrochemistry",
      "Chapter 8: Chemical Reactivity",
    ],
    Physics: [
      "Chapter 1: Physical Quantities & Measurement",
      "Chapter 2: Kinematics",
      "Chapter 3: Dynamics",
      "Chapter 4: Turning Effect of Forces",
      "Chapter 5: Gravitation",
      "Chapter 6: Work and Energy",
      "Chapter 7: Properties of Matter",
      "Chapter 8: Thermal Properties of Matter",
      "Chapter 9: Transfer of Heat",
    ],
    Mathematics: [
      "Chapter 1: Matrices and Determinants",
      "Chapter 2: Real and Complex Numbers",
      "Chapter 3: Logarithms",
      "Chapter 4: Algebraic Expressions and Formulas",
      "Chapter 5: Factorization",
      "Chapter 6: Algebraic Manipulation",
      "Chapter 7: Linear Equations and Inequalities",
      "Chapter 8: Linear Graphs & Their Application",
      "Chapter 9: Introduction to Coordinate Geometry",
    ],
    Biology: [
      "Chapter 1: Introduction to Biology",
      "Chapter 2: Solving a Biological Problem",
      "Chapter 3: Biodiversity",
      "Chapter 4: Cells and Tissues",
      "Chapter 5: Cell Cycle",
      "Chapter 6: Enzymes",
      "Chapter 7: Bioenergetics",
      "Chapter 8: Nutrition",
      "Chapter 9: Transport",
    ],
    "Computer Science": [
      "Chapter 1: Problem Solving",
      "Chapter 2: Binary System",
      "Chapter 3: Networks",
      "Chapter 4: Data and Privacy",
      "Chapter 5: Designing Website (HTML)",
    ],
  },
  10: {
    Chemistry: [
      "Chapter 9: Chemical Equilibrium",
      "Chapter 10: Acids, Bases and Salts",
      "Chapter 11: Organic Chemistry",
      "Chapter 12: Hydrocarbons",
      "Chapter 13: Biochemistry",
      "Chapter 14: The Atmosphere",
      "Chapter 15: Water",
      "Chapter 16: Chemical Industries",
    ],
    Physics: [
      "Chapter 10: Simple Harmonic Motion and Waves",
      "Chapter 11: Sound",
      "Chapter 12: Geometrical Optics",
      "Chapter 13: Electrostatics",
      "Chapter 14: Current Electricity",
      "Chapter 15: Electromagnetism",
      "Chapter 16: Basic Electronics",
      "Chapter 17: Information and Communication Technology",
      "Chapter 18: Atomic and Nuclear Physics",
    ],
    Mathematics: [
      "Chapter 1: Quadratic Equations",
      "Chapter 2: Theory of Quadratic Equations",
      "Chapter 3: Variations",
      "Chapter 4: Partial Fractions",
      "Chapter 5: Sets and Functions",
      "Chapter 6: Basic Statistics",
      "Chapter 7: Introduction to Trigonometry",
      "Chapter 8: Projection of a Side of a Triangle",
      "Chapter 9: Chords of a Circle",
      "Chapter 10: Tangent to a Circle",
      "Chapter 11: Chords and Arcs",
      "Chapter 12: Angle in a Segment of a Circle",
      "Chapter 13: Practical Geometry - Circles",
    ],
    Biology: [
      "Chapter 10: Gaseous Exchange",
      "Chapter 11: Homeostasis",
      "Chapter 12: Coordination and Control",
      "Chapter 13: Support and Movement",
      "Chapter 14: Reproduction",
      "Chapter 15: Inheritance",
      "Chapter 16: Man and His Environment",
      "Chapter 17: Biotechnology",
      "Chapter 18: Pharmacology",
    ],
    "Computer Science": [
      "Chapter 1: Introduction to Programming (C Language)",
      "Chapter 2: User Interface (I/O in C)",
      "Chapter 3: Conditional Logic",
      "Chapter 4: Data Structures (Arrays & Loops)",
      "Chapter 5: Functions and Subprograms",
    ],
  },
  11: {
    Chemistry: [
      "Chapter 1: Basic Concepts",
      "Chapter 2: Experimental Techniques in Chemistry",
      "Chapter 3: Gases",
      "Chapter 4: Liquids and Solids",
      "Chapter 5: Atomic Structure",
      "Chapter 6: Chemical Bonding",
      "Chapter 7: Thermochemistry",
      "Chapter 8: Chemical Equilibrium",
      "Chapter 9: Solutions",
      "Chapter 10: Electrochemistry",
      "Chapter 11: Reaction Kinetics",
    ],
    Physics: [
      "Chapter 1: Measurements",
      "Chapter 2: Vectors and Equilibrium",
      "Chapter 3: Motion and Force",
      "Chapter 4: Work and Energy",
      "Chapter 5: Circular Motion",
      "Chapter 6: Fluid Dynamics",
      "Chapter 7: Oscillations",
      "Chapter 8: Waves",
      "Chapter 9: Physical Optics",
      "Chapter 10: Optical Instruments",
      "Chapter 11: Heat and Thermodynamics",
    ],
    Mathematics: [
      "Chapter 1: Number Systems",
      "Chapter 2: Sets, Functions and Groups",
      "Chapter 3: Matrices and Determinants",
      "Chapter 4: Quadratic Equations",
      "Chapter 5: Partial Fractions",
      "Chapter 6: Sequences and Series",
      "Chapter 7: Permutation, Combination and Probability",
      "Chapter 8: Mathematical Induction and Binomial Theorem",
      "Chapter 9: Fundamentals of Trigonometry",
      "Chapter 10: Trigonometric Identities",
      "Chapter 11: Trigonometric Functions and Their Graphs",
      "Chapter 12: Application of Trigonometry",
      "Chapter 13: Inverse Trigonometric Functions",
      "Chapter 14: Solutions of Trigonometric Equations",
    ],
    Biology: [
      "Chapter 1: Introduction",
      "Chapter 2: Biological Molecules",
      "Chapter 3: Enzymes",
      "Chapter 4: The Cell",
      "Chapter 5: Variety of Life",
      "Chapter 6: Kingdom Prokaryotae (Monera)",
      "Chapter 7: The Kingdom Protista",
      "Chapter 8: Fungi - The Kingdom of Recyclers",
      "Chapter 9: Kingdom Plantae",
      "Chapter 10: Kingdom Animalia",
      "Chapter 11: Bioenergetics",
      "Chapter 12: Nutrition",
      "Chapter 13: Gaseous Exchange",
      "Chapter 14: Transport",
    ],
    "Computer Science": [
      "Chapter 1: Basics of Information Technology",
      "Chapter 2: Information Networks",
      "Chapter 3: Data Communications",
      "Chapter 4: Applications and Uses of Computers",
      "Chapter 5: Computer Architecture",
      "Chapter 6: Security, Copyright and the Law",
      "Chapter 7: Windows Operating System",
      "Chapter 8: Word Processing",
      "Chapter 9: Spreadsheet Software",
      "Chapter 10: Fundamentals of the Internet",
    ],
  },
  12: {
    Chemistry: [
      "Chapter 1: Periodic Classification of Elements and Periodicity",
      "Chapter 2: s-Block Elements",
      "Chapter 3: Group IIIA and Group IVA Elements",
      "Chapter 4: Group VA and Group VIA Elements",
      "Chapter 5: The Halogens and the Noble Gases",
      "Chapter 6: Transition Elements",
      "Chapter 7: Fundamental Principles of Organic Chemistry",
      "Chapter 8: Aliphatic Hydrocarbons",
      "Chapter 9: Aromatic Hydrocarbons",
      "Chapter 10: Alkyl Halides",
      "Chapter 11: Alcohols, Phenols and Ethers",
      "Chapter 12: Aldehydes and Ketones",
      "Chapter 13: Carboxylic Acids",
      "Chapter 14: Macromolecules",
      "Chapter 15: Common Chemical Industries in Pakistan",
      "Chapter 16: Environmental Chemistry",
    ],
    Physics: [
      "Chapter 12: Electrostatics",
      "Chapter 13: Current Electricity",
      "Chapter 14: Electromagnetism",
      "Chapter 15: Electromagnetic Induction",
      "Chapter 16: Alternating Current",
      "Chapter 17: Physics of Solids",
      "Chapter 18: Electronics",
      "Chapter 19: Dawn of Modern Physics",
      "Chapter 20: Atomic Spectra",
      "Chapter 21: Nuclear Physics",
    ],
    Mathematics: [
      "Chapter 1: Functions and Limits",
      "Chapter 2: Differentiation",
      "Chapter 3: Integration",
      "Chapter 4: Introduction to Analytic Geometry",
      "Chapter 5: Linear Inequalities and Linear Programming",
      "Chapter 6: Conic Section",
      "Chapter 7: Vectors",
    ],
    Biology: [
      "Chapter 15: Homeostasis",
      "Chapter 16: Support and Movements",
      "Chapter 17: Coordination and Control",
      "Chapter 18: Reproduction",
      "Chapter 19: Growth and Development",
      "Chapter 20: Chromosomes and DNA",
      "Chapter 21: Cell Cycle",
      "Chapter 22: Variation and Genetics",
      "Chapter 23: Biotechnology",
      "Chapter 24: Evolution",
      "Chapter 25: Ecosystem",
      "Chapter 26: Some Major Ecosystems",
      "Chapter 27: Man and His Environment",
    ],
    "Computer Science": [
      "Chapter 1: Data Basics",
      "Chapter 2: Basic Concepts and Terminology of Databases",
      "Chapter 3: Database Design Process",
      "Chapter 4: Data Integrity and Normalization",
      "Chapter 5: Introduction to Microsoft Access",
      "Chapter 6: Table and Query",
      "Chapter 7: Microsoft Access Forms and Reports",
      "Chapter 8: Getting Started with C",
      "Chapter 9: Elements of C",
      "Chapter 10: Input / Output",
      "Chapter 11: Decision Constructs",
      "Chapter 12: Loop Constructs",
      "Chapter 13: Functions in C",
      "Chapter 14: File Handling in C",
    ],
  },
};

export function getMockChapters(subject: string, grade: number = 9): ChapterListResponse {
  const gradeSyllabus = MULTI_CLASS_CHAPTERS[grade] || MULTI_CLASS_CHAPTERS[9];
  const list = gradeSyllabus[subject];

  return {
    subject,
    chapters: list || [
      `Chapter 1: General ${subject}`,
      `Chapter 2: Theoretical Principles`,
      `Chapter 3: Applied Concepts`,
    ],
  };
}

export function getMockChapterMetadata(subject: string, chapter: string): ChapterMetadataResponse {
  if (subject === "Mathematics") {
    return {
      subject,
      chapter,
      exercises: ["Exercise 1.1", "Exercise 1.2", "Exercise 1.3", "Review Exercise 1"],
      sections: ["Section 1.1: Real Numbers", "Section 1.2: Properties of Radicals"],
      topics: ["Radicals and Radicands", "Laws of Exponents", "Complex Numbers"],
    };
  }

  return {
    subject,
    chapter,
    exercises: [],
    sections: ["Section 3.1: Periodic Trends", "Section 3.2: Modern Periodic Table"],
    topics: ["Atomic Radius", "Ionization Energy", "Electron Affinity", "Electronegativity"],
  };
}

export const SAMPLE_CHEMISTRY_TEST: Class9TestSchema = {
  test_title: "Class 9 Chemistry - Chapter 3 Test",
  subject: "Chemistry",
  grade: 9,
  chapter_or_topic: "Periodic Table and Periodicity of Properties",
  total_marks: 16,
  time_allowed: "45 Minutes",
  instructions: [
    "Attempt all questions.",
    "Write neatly and draw diagrams where necessary.",
    "Scientific calculators are allowed.",
  ],
  mcqs: [
    {
      question_number: 1,
      question: "Which element has the highest electronegativity value on the Pauling scale?",
      options: ["A) Chlorine", "B) Oxygen", "C) Fluorine", "D) Nitrogen"],
      correct_option: "C",
      textbook_reference: "Fluorine is the most electronegative element with a value of 4.0 (Page 54).",
      marks: 1,
    },
    {
      question_number: 2,
      question: "The amount of energy released when an electron is added to the valence shell of an isolated gaseous atom is called:",
      options: ["A) Ionization Energy", "B) Electron Affinity", "C) Electronegativity", "D) Shielding Effect"],
      correct_option: "B",
      textbook_reference: "Electron affinity is defined as the energy released when an electron is added (Page 52).",
      marks: 1,
    },
    {
      question_number: 3,
      question: "Along a period from left to right, the atomic radius generally:",
      options: ["A) Increases", "B) Decreases", "C) Remains constant", "D) First decreases then increases"],
      correct_option: "B",
      textbook_reference: "Due to increase in effective nuclear charge, atomic size decreases across a period (Page 49).",
      marks: 1,
    },
    {
      question_number: 4,
      question: "Elements in Group 17 of the modern periodic table are commonly known as:",
      options: ["A) Alkali Metals", "B) Alkaline Earth Metals", "C) Halogens", "D) Noble Gases"],
      correct_option: "C",
      textbook_reference: "Group 17 elements (F, Cl, Br, I) are called halogens (Page 47).",
      marks: 1,
    },
    {
      question_number: 5,
      question: "Which chemical formula correctly represents the water molecule using subscripts?",
      options: ["A) H2O", "B) H<sub>2</sub>O", "C) HO<sub>2</sub>", "D) H<sup>2</sup>O"],
      correct_option: "B",
      textbook_reference: "The chemical formula of water is H<sub>2</sub>O (Page 18).",
      marks: 1,
    },
  ],
  short_questions: [
    {
      question_number: 6,
      question: "Define electron affinity and state its trend across a period in the periodic table.",
      marks: 2,
    },
    {
      question_number: 7,
      question: "Why does the ionization energy decrease from top to bottom within a group?",
      marks: 2,
    },
    {
      question_number: 8,
      question: "State Mendeleev's Periodic Law and explain one major limitation of his periodic table.",
      marks: 2,
    },
  ],
  long_questions: [
    {
      question_number: 9,
      question: "Explain the trends of atomic radius and shielding effect in periods and groups of the periodic table with comprehensive scientific reasons.",
      marks: 5,
    },
  ],
};

export const SAMPLE_PHYSICS_TEST: Class9TestSchema = {
  test_title: "Class 9 Physics - Chapter 2 Test",
  subject: "Physics",
  grade: 9,
  chapter_or_topic: "Kinematics",
  total_marks: 16,
  time_allowed: "45 Minutes",
  instructions: [
    "Attempt all questions.",
    "Show all calculation steps and include SI units.",
  ],
  mcqs: [
    {
      question_number: 1,
      question: "A body has translatory motion if it moves along a:",
      options: ["A) Straight line only", "B) Circle only", "C) Line without rotation", "D) Curved path only"],
      correct_option: "C",
      textbook_reference: "Translatory motion is motion along a line without any rotation (Page 29).",
      marks: 1,
    },
    {
      question_number: 2,
      question: "The rate of change of displacement with respect to time is known as:",
      options: ["A) Speed", "B) Velocity", "C) Acceleration", "D) Distance"],
      correct_option: "B",
      textbook_reference: "Velocity is the rate of displacement with respect to time (Page 35).",
      marks: 1,
    },
    {
      question_number: 3,
      question: "Which of the following is a vector quantity?",
      options: ["A) Speed", "B) Distance", "C) Displacement", "D) Power"],
      correct_option: "C",
      textbook_reference: "Displacement is a vector possessing both magnitude and direction (Page 34).",
      marks: 1,
    },
    {
      question_number: 4,
      question: "The SI unit of acceleration is:",
      options: ["A) m/s", "B) m·s", "C) m/s<sup>2</sup>", "D) km/h"],
      correct_option: "C",
      textbook_reference: "SI unit of acceleration is meters per second squared, m/s<sup>2</sup> (Page 38).",
      marks: 1,
    },
    {
      question_number: 5,
      question: "The slope of a distance-time graph represents:",
      options: ["A) Speed", "B) Acceleration", "C) Distance", "D) Force"],
      correct_option: "A",
      textbook_reference: "The slope of distance-time graph gives the speed of the body (Page 40).",
      marks: 1,
    },
  ],
  short_questions: [
    {
      question_number: 6,
      question: "Differentiate between scalar and vector quantities with two examples of each.",
      marks: 2,
    },
    {
      question_number: 7,
      question: "Define uniform acceleration and write its mathematical formula.",
      marks: 2,
    },
    {
      question_number: 8,
      question: "Can a body moving with constant speed have an acceleration? Explain briefly with an example.",
      marks: 2,
    },
  ],
  long_questions: [
    {
      question_number: 9,
      question: "Derive the second equation of motion, S = v<sub>i</sub>t + ½at<sup>2</sup>, using a speed-time graph.",
      marks: 5,
    },
  ],
};

export const SAMPLE_QUESTIONS_BANK: QuestionBankItem[] = [
  // --- CHEMISTRY ---
  {
    id: "qb_chem_1",
    type: "mcq",
    subject: "Chemistry",
    chapter: "Chapter 3: Periodic Table and Periodicity",
    topic: "Electronegativity Trends",
    difficulty: "Medium",
    question: "Which element has the highest electronegativity value on the Pauling scale?",
    options: ["A) Chlorine", "B) Oxygen", "C) Fluorine", "D) Nitrogen"],
    correct_option: "C",
    textbook_reference: "PTB Chemistry Class 9, Chapter 3, Page 54: Electronegativity increases across a period and fluorine has maximum value (4.0).",
    marks: 1,
    created_at: "2026-08-15T10:00:00.000Z",
  },
  {
    id: "qb_chem_2",
    type: "mcq",
    subject: "Chemistry",
    chapter: "Chapter 1: Fundamentals of Chemistry",
    topic: "Molar Mass & Empirical Formulas",
    difficulty: "Easy",
    question: "What is the molecular mass of nitric acid (HNO<sub>3</sub>)? (Atomic masses: H = 1, N = 14, O = 16)",
    options: ["A) 63 amu", "B) 60 amu", "C) 56 amu", "D) 48 amu"],
    correct_option: "A",
    textbook_reference: "PTB Chemistry Class 9, Chapter 1, Page 16: Molecular mass = 1 + 14 + (3 × 16) = 63 amu.",
    marks: 1,
    created_at: "2026-08-15T10:05:00.000Z",
  },
  {
    id: "qb_chem_3",
    type: "short",
    subject: "Chemistry",
    chapter: "Chapter 4: Structure of Molecules",
    topic: "Ionic vs Covalent Bonding",
    difficulty: "Medium",
    question: "Explain why ionic compounds like NaCl conduct electricity in molten state or aqueous solution but not in solid state.",
    marks: 2,
    textbook_reference: "PTB Chemistry Class 9, Chapter 4, Page 68: Solid ionic lattices lock ions in place, whereas molten/solution states liberate free mobile ions to conduct electrical charge.",
    created_at: "2026-08-15T10:10:00.000Z",
  },
  {
    id: "qb_chem_4",
    type: "long",
    subject: "Chemistry",
    chapter: "Chapter 2: Structure of Atoms",
    topic: "Rutherford Atomic Model",
    difficulty: "Hard",
    question: "Describe Rutherford&apos;s Alpha Particle Scattering Experiment with an illustrative diagram, summarize its observations, and explain why it was revised by Bohr&apos;s atomic theory.",
    marks: 5,
    textbook_reference: "PTB Chemistry Class 9, Chapter 2, Pages 31-33: Gold foil experiment, nuclear discovery, and classical electrodynamics defect.",
    created_at: "2026-08-15T10:15:00.000Z",
  },

  // --- PHYSICS ---
  {
    id: "qb_phy_1",
    type: "mcq",
    subject: "Physics",
    chapter: "Chapter 2: Kinematics",
    topic: "Equations of Motion",
    difficulty: "Medium",
    question: "A car accelerates uniformly from rest at 2 m/s<sup>2</sup> for 5 seconds. What is the final velocity attained?",
    options: ["A) 5 m/s", "B) 10 m/s", "C) 20 m/s", "D) 25 m/s"],
    correct_option: "B",
    textbook_reference: "PTB Physics Class 9, Chapter 2, Page 44: Using v<sub>f</sub> = v<sub>i</sub> + at = 0 + (2 × 5) = 10 m/s.",
    marks: 1,
    created_at: "2026-08-16T11:00:00.000Z",
  },
  {
    id: "qb_phy_2",
    type: "mcq",
    subject: "Physics",
    chapter: "Chapter 3: Dynamics",
    topic: "Newton's Laws of Motion",
    difficulty: "Easy",
    question: "The property of a body due to which it resists any change in its state of rest or uniform motion is called:",
    options: ["A) Momentum", "B) Torque", "C) Inertia", "D) Friction"],
    correct_option: "C",
    textbook_reference: "PTB Physics Class 9, Chapter 3, Page 58: Mass of a body is a quantitative measure of its inertia.",
    marks: 1,
    created_at: "2026-08-16T11:05:00.000Z",
  },
  {
    id: "qb_phy_3",
    type: "short",
    subject: "Physics",
    chapter: "Chapter 5: Gravitation",
    topic: "Newton's Law of Universal Gravitation",
    difficulty: "Medium",
    question: "State Newton&apos;s Law of Universal Gravitation and write its mathematical equation with SI units of gravitational constant G.",
    marks: 2,
    textbook_reference: "PTB Physics Class 9, Chapter 5, Page 107: F = G(m<sub>1</sub>m<sub>2</sub>)/r<sup>2</sup>, where G = 6.673 × 10<sup>-11</sup> N·m<sup>2</sup>/kg<sup>2</sup>.",
    created_at: "2026-08-16T11:10:00.000Z",
  },
  {
    id: "qb_phy_4",
    type: "long",
    subject: "Physics",
    chapter: "Chapter 2: Kinematics",
    topic: "Derivation of Third Equation of Motion",
    difficulty: "Hard",
    question: "Derive the third equation of motion (2as = v<sub>f</sub><sup>2</sup> - v<sub>i</sub><sup>2</sup>) using a speed-time graph for a body moving with uniform acceleration.",
    marks: 5,
    textbook_reference: "PTB Physics Class 9, Chapter 2, Page 45: Trapezium area calculation S = (v<sub>i</sub> + v<sub>f</sub>)/2 × t substituted with t = (v<sub>f</sub> - v<sub>i</sub>)/a.",
    created_at: "2026-08-16T11:15:00.000Z",
  },

  // --- MATHEMATICS ---
  {
    id: "qb_math_1",
    type: "mcq",
    subject: "Mathematics",
    chapter: "Chapter 1: Matrices and Determinants",
    topic: "Order and Singular Matrices",
    difficulty: "Easy",
    question: "If matrix A = [[2, 4], [1, 2]], the determinant |A| is equal to:",
    options: ["A) 0 (Singular)", "B) 2", "C) 4", "D) -2 (Non-singular)"],
    correct_option: "A",
    textbook_reference: "PTB Mathematics Class 9, Chapter 1, Page 14: |A| = (2)(2) - (4)(1) = 4 - 4 = 0.",
    marks: 1,
    created_at: "2026-08-17T09:00:00.000Z",
  },
  {
    id: "qb_math_2",
    type: "short",
    subject: "Mathematics",
    chapter: "Chapter 2: Real and Complex Numbers",
    topic: "Complex Number Simplification",
    difficulty: "Medium",
    question: "Evaluate and express in standard a + bi form: (2 - 3i)(3 + 2i).",
    marks: 2,
    textbook_reference: "PTB Mathematics Class 9, Chapter 2, Page 47: 6 + 4i - 9i - 6i<sup>2</sup> = 6 - 5i - 6(-1) = 12 - 5i.",
    created_at: "2026-08-17T09:05:00.000Z",
  },
  {
    id: "qb_math_3",
    type: "long",
    subject: "Mathematics",
    chapter: "Chapter 1: Matrices and Determinants",
    topic: "Cramer's Rule",
    difficulty: "Hard",
    question: "Solve the following system of linear equations using Cramer&apos;s Rule: 2x - 2y = 4 and 3x + 2y = 6.",
    marks: 5,
    textbook_reference: "PTB Mathematics Class 9, Chapter 1, Page 25: Matrix equation AX = B, determinant |A| = 10, |A<sub>x</sub>| = 20, |A<sub>y</sub>| = 0 => x = 2, y = 0.",
    created_at: "2026-08-17T09:10:00.000Z",
  },

  // --- BIOLOGY ---
  {
    id: "qb_bio_1",
    type: "mcq",
    subject: "Biology",
    chapter: "Chapter 4: Cells and Tissues",
    topic: "Organelle Functions",
    difficulty: "Easy",
    question: "Which cellular organelle is designated as the powerhouse of the cell due to ATP synthesis?",
    options: ["A) Ribosome", "B) Mitochondria", "C) Golgi Apparatus", "D) Endoplasmic Reticulum"],
    correct_option: "B",
    textbook_reference: "PTB Biology Class 9, Chapter 4, Page 61: Mitochondria are the sites of cellular respiration and ATP generation.",
    marks: 1,
    created_at: "2026-08-18T14:00:00.000Z",
  },
  {
    id: "qb_bio_2",
    type: "short",
    subject: "Biology",
    chapter: "Chapter 7: Bioenergetics",
    topic: "Photosynthesis Light Reactions",
    difficulty: "Medium",
    question: "State the balanced chemical equation representing photosynthesis and explain the role of chlorophyll.",
    marks: 2,
    textbook_reference: "PTB Biology Class 9, Chapter 7, Page 120: 6CO<sub>2</sub> + 12H<sub>2</sub>O + Light → C<sub>6</sub>H<sub>12</sub>O<sub>6</sub> + 6O<sub>2</sub> + 6H<sub>2</sub>O.",
    created_at: "2026-08-18T14:05:00.000Z",
  },
  {
    id: "qb_bio_3",
    type: "long",
    subject: "Biology",
    chapter: "Chapter 5: Cell Cycle",
    topic: "Mitosis Stages",
    difficulty: "Hard",
    question: "Explain the four continuous phases of Karyokinesis in Mitosis (Prophase, Metaphase, Anaphase, Telophase) with labeled schematic diagrams.",
    marks: 5,
    textbook_reference: "PTB Biology Class 9, Chapter 5, Pages 89-92: Chromosome condensation, metaphase plate alignment, sister chromatid separation, and nuclear envelope reformation.",
    created_at: "2026-08-18T14:10:00.000Z",
  },

  // --- COMPUTER SCIENCE ---
  {
    id: "qb_cs_1",
    type: "mcq",
    subject: "Computer Science",
    chapter: "Chapter 1: Fundamentals of Computer",
    topic: "Memory Hierarchy",
    difficulty: "Medium",
    question: "Which type of computer memory is volatile and loses its contents when power is turned off?",
    options: ["A) ROM", "B) Hard Disk Drive", "C) RAM", "D) Flash Memory"],
    correct_option: "C",
    textbook_reference: "PTB Computer Science Class 9, Chapter 1, Page 18: Random Access Memory (RAM) is primary volatile storage.",
    marks: 1,
    created_at: "2026-08-19T16:00:00.000Z",
  },
  {
    id: "qb_cs_2",
    type: "short",
    subject: "Computer Science",
    chapter: "Chapter 4: Data Communication",
    topic: "Transmission Media",
    difficulty: "Easy",
    question: "Differentiate between Guided Transmission Media (e.g. Fiber Optics) and Unguided Transmission Media (e.g. Radio Waves).",
    marks: 2,
    textbook_reference: "PTB Computer Science Class 9, Chapter 4, Page 78: Guided media confine signals along physical cables; unguided media broadcast electromagnetic waves through atmospheric space.",
    created_at: "2026-08-19T16:05:00.000Z",
  },
  {
    id: "qb_cs_3",
    type: "long",
    subject: "Computer Science",
    chapter: "Chapter 2: Fundamentals of Operating System",
    topic: "OS Functions & Memory Management",
    difficulty: "Hard",
    question: "Describe five major functions of an Operating System, including Process Management, Memory Management, File System Management, and Device I/O Handling.",
    marks: 5,
    textbook_reference: "PTB Computer Science Class 9, Chapter 2, Pages 35-38: Resource allocation, multitasking scheduling, virtual memory paging, and security enforcement.",
    created_at: "2026-08-19T16:10:00.000Z",
  },
];

export function generateMockDraft(req: TestGenerationRequest): Class9TestSchema {
  const mcqCount = req.mcq_count || 5;
  const shortCount = req.short_count || 3;
  const longCount = req.long_count || 1;
  const subjectStr = String(req.subject);
  const chapterStr = req.chapter_name || "Chapter 1";
  const gradeNum = req.grade || 9;

  if (subjectStr === "Chemistry" && mcqCount === 5 && shortCount === 3 && longCount === 1) {
    return { ...SAMPLE_CHEMISTRY_TEST, grade: gradeNum, test_title: `Class ${gradeNum} Chemistry - ${chapterStr} Test` };
  }

  if (subjectStr === "Physics" && mcqCount === 5 && shortCount === 3 && longCount === 1) {
    return { ...SAMPLE_PHYSICS_TEST, grade: gradeNum, test_title: `Class ${gradeNum} Physics - ${chapterStr} Test` };
  }

  return {
    test_title: `Class ${gradeNum} ${subjectStr} - ${chapterStr} Test`,
    subject: subjectStr,
    grade: gradeNum,
    chapter_or_topic: req.topic_query || chapterStr,
    total_marks: mcqCount * 1 + shortCount * 2 + longCount * 5,
    time_allowed: "45 Minutes",
    instructions: [
      "Attempt all questions.",
      "Write clearly and show all relevant calculation steps.",
    ],
    mcqs: Array.from({ length: mcqCount }, (_, i) => ({
      question_number: i + 1,
      question: `Sample MCQ #${i + 1} regarding ${req.topic_query || chapterStr} with relevant formulas and concepts.`,
      options: [
        `A) Choice Alpha for item ${i + 1}`,
        `B) Choice Beta for item ${i + 1}`,
        `C) Choice Gamma for item ${i + 1}`,
        `D) Choice Delta for item ${i + 1}`,
      ],
      correct_option: ["A", "B", "C", "D"][i % 4],
      textbook_reference: `Verified textbook reference citation for question ${i + 1} (Page ${40 + i}).`,
      marks: 1,
    })),
    short_questions: Array.from({ length: shortCount }, (_, i) => ({
      question_number: mcqCount + i + 1,
      question: `Briefly define and explain the core principle #${i + 1} of ${req.topic_query || chapterStr}.`,
      marks: 2,
    })),
    long_questions: Array.from({ length: longCount }, (_, i) => ({
      question_number: mcqCount + shortCount + i + 1,
      question: `Provide a detailed analytical derivation and comprehensive explanation for ${req.topic_query || chapterStr} with relevant illustrations.`,
      marks: 5,
    })),
  };
}

export function generateMockPdfBlob(_test: Class9TestSchema): Blob {
  const pdfString = `%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n3 0 obj<</Type/Page/MediaBox[0 0 595 842]/Parent 2 0 R/Resources<<>>>>endobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000052 00000 n \n0000000102 00000 n \ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n178\n%%EOF`;
  return new Blob([pdfString], { type: "application/pdf" });
}
