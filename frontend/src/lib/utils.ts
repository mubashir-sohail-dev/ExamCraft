/**
 * src/lib/utils.ts
 * ExamCraft AI - General Utilities, Marks Math & Question Renumbering
 */

import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import { Class9TestSchema } from "@/types/exam";
import { QUESTION_WEIGHTS } from "./constants";

/**
 * Standard Tailwind merge + clsx utility
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/**
 * Calculate total test marks based on question counts
 */
export function calculateTotalMarks(
  mcqCount: number,
  shortCount: number,
  longCount: number
): number {
  return (
    mcqCount * QUESTION_WEIGHTS.MCQ +
    shortCount * QUESTION_WEIGHTS.SHORT +
    longCount * QUESTION_WEIGHTS.LONG
  );
}

/**
 * Dynamically compute actual total marks from a live Class9TestSchema instance
 */
export function calculateTestSchemaMarks(test: Class9TestSchema): number {
  const mcqTotal = (test.mcqs || []).reduce(
    (sum, item) => sum + (item.marks !== undefined ? item.marks : QUESTION_WEIGHTS.MCQ),
    0
  );
  const shortTotal = (test.short_questions || []).reduce(
    (sum, item) => sum + (item.marks !== undefined ? item.marks : QUESTION_WEIGHTS.SHORT),
    0
  );
  const longTotal = (test.long_questions || []).reduce(
    (sum, item) => sum + (item.marks !== undefined ? item.marks : QUESTION_WEIGHTS.LONG),
    0
  );
  return mcqTotal + shortTotal + longTotal;
}

/**
 * Renumbers questions sequentially across all sections (MCQs 1..N, Short N+1..M, Long M+1..K)
 * Returns a cloned, immutable copy of the updated test schema.
 */
export function renumberTestQuestions(test: Class9TestSchema): Class9TestSchema {
  let counter = 1;

  const newMcqs = (test.mcqs || []).map((item) => ({
    ...item,
    question_number: counter++,
  }));

  const newShort = (test.short_questions || []).map((item) => ({
    ...item,
    question_number: counter++,
  }));

  const newLong = (test.long_questions || []).map((item) => ({
    ...item,
    question_number: counter++,
  }));

  const updatedTotal = calculateTestSchemaMarks({
    ...test,
    mcqs: newMcqs,
    short_questions: newShort,
    long_questions: newLong,
  });

  return {
    ...test,
    total_marks: updatedTotal,
    mcqs: newMcqs,
    short_questions: newShort,
    long_questions: newLong,
  };
}

/**
 * Converts subscript/superscript HTML safely or formats special characters
 */
export function formatFormulaHtml(content: string): string {
  if (!content) return "";
  // Sanitize simple tags: only allow <sub>, </sub>, <sup>, </sup>, <b>, </b>, <i>, </i>
  return content
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/&lt;sub&gt;/gi, "<sub>")
    .replace(/&lt;\/sub&gt;/gi, "</sub>")
    .replace(/&lt;sup&gt;/gi, "<sup>")
    .replace(/&lt;\/sup&gt;/gi, "</sup>")
    .replace(/&lt;b&gt;/gi, "<b>")
    .replace(/&lt;\/b&gt;/gi, "</b>")
    .replace(/&lt;i&gt;/gi, "<i>")
    .replace(/&lt;\/i&gt;/gi, "</i>");
}

/**
 * Trigger in-browser file download from a Blob
 */
export function downloadBlob(blob: Blob, filename: string): void {
  if (typeof window === "undefined") return;
  const url = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  window.URL.revokeObjectURL(url);
}

/**
 * Trigger in-browser JSON file download
 */
export function downloadJson(data: unknown, filename: string): void {
  if (typeof window === "undefined") return;
  const jsonStr = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonStr], { type: "application/json" });
  downloadBlob(blob, filename);
}

/**
 * Safely copy text to clipboard with fallback
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  if (typeof window === "undefined") return false;
  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return true;
    }
    const textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-999999px";
    textArea.style.top = "-999999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    const successful = document.execCommand("copy");
    document.body.removeChild(textArea);
    return successful;
  } catch (err) {
    console.error("Clipboard copy failed:", err);
    return false;
  }
}

/**
 * Format date string into human-readable format
 */
export function formatDate(dateString: string): string {
  try {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(date);
  } catch {
    return dateString;
  }
}

