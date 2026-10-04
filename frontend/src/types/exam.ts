/**
 * src/types/exam.ts
 * ExamCraft AI - Core Domain Models & Schemas
 */

export type SubjectType =
  | "Physics"
  | "Chemistry"
  | "Mathematics"
  | "Biology"
  | "Computer Science";

export type ClassGrade = 9 | 10 | 11 | 12;
export const AVAILABLE_CLASSES: ClassGrade[] = [9, 10, 11, 12];

export type RetrievalMode = "full_chapter" | "topic";

export type DifficultyLevel = "Easy" | "Medium" | "Hard" | "Mixed" | "easy" | "medium" | "hard" | "mixed";

export type QuestionType = "mcq" | "short" | "long" | "MCQ" | "SHORT" | "LONG";

/**
 * Section A: Multiple Choice Question Item
 * Directly mirrors backend/schemas/exam_schema.py::MCQItem
 */
export interface MCQItem {
  question_number: number;
  question: string;
  question_text?: string; // Optional alias for compatibility
  options: [string, string, string, string] | string[]; // Exactly 4 choices: ["A) ...", "B) ...", "C) ...", "D) ..."]
  correct_option: "A" | "B" | "C" | "D" | string;
  textbook_reference?: string;
  explanation?: string;
  marks?: number; // Default 1 mark
  reference_topic?: string;
  reference_page?: number;
  reference_quote?: string;
}

/**
 * Section B: Short Answer Question Item
 * Directly mirrors backend/schemas/exam_schema.py::ShortQuestionItem
 */
export interface ShortQuestionItem {
  question_number: number;
  question: string;
  question_text?: string; // Optional alias for compatibility
  marks: number; // Default 2 marks
  expected_answer?: string;
  reference_topic?: string;
  reference_page?: number;
  reference_quote?: string;
  textbook_reference?: string;
}

/**
 * Section C: Long / Essay / Numerical Question Item
 * Directly mirrors backend/schemas/exam_schema.py::LongQuestionItem
 */
export interface LongQuestionItem {
  question_number: number;
  question: string;
  question_text?: string; // Optional alias for compatibility
  marks: number; // Default 5 marks
  expected_points?: string[];
  reference_topic?: string;
  reference_page?: number;
  reference_quote?: string;
  textbook_reference?: string;
}

/**
 * Complete Structured Class 9 Examination Paper Schema
 * Directly mirrors backend/schemas/exam_schema.py::Class9TestSchema
 */
export interface Class9TestSchema {
  test_title: string;
  subject: SubjectType | string;
  grade?: ClassGrade | number;
  chapter_or_topic: string;
  total_marks: number;
  time_allowed: string;
  instructions: string[];
  mcqs: MCQItem[];
  short_questions: ShortQuestionItem[];
  long_questions: LongQuestionItem[];
  created_at?: string;
}

/**
 * Persisted Test Record stored in LocalStorage for /recent-papers
 */
export interface SavedTestRecord {
  id: string;
  title: string;
  test_title?: string; // Optional compatibility alias
  subject: SubjectType | string;
  grade?: ClassGrade | number;
  chapter_or_topic?: string; // Optional compatibility alias
  created_at: string; // ISO 8601 UTC
  total_marks: number;
  mcq_count: number;
  short_count: number;
  long_count: number;
  question_count: number;
  is_favorite: boolean;
  test_data: Class9TestSchema;
  notes?: string;
}

/**
 * Legacy alias for SavedTestRecord
 */
export type SavedPaperRecord = SavedTestRecord;

/**
 * Question Repository Entity stored in /question-bank
 */
export interface QuestionBankItem {
  id: string;
  type: QuestionType;
  question_type?: string; // Optional alias
  subject: SubjectType | string;
  chapter: string;
  topic?: string;
  difficulty: DifficultyLevel;
  question: string;
  question_text?: string; // Optional alias
  options?: [string, string, string, string] | string[];
  correct_option?: string;
  textbook_reference?: string;
  reference_quote?: string; // Optional alias
  marks: number;
  created_at: string;
}
