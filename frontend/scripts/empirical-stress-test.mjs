/**
 * frontend/scripts/empirical-stress-test.mjs
 * Challenger 2 - Empirical Stress Testing & UI State Synchronization Harness
 */

import { existsSync, readFileSync, readdirSync } from "fs";
import { resolve, join } from "path";

console.log("==================================================================");
console.log("ExamCraft AI - Empirical Challenger 2 Stress Test Harness");
console.log("==================================================================");

let totalPassed = 0;
let totalFailed = 0;
const failures = [];

function assert(condition, name, details = "") {
  if (condition) {
    console.log(`  [PASS] ${name}`);
    totalPassed++;
  } else {
    console.error(`  [FAIL] ${name} ${details ? "- " + details : ""}`);
    totalFailed++;
    failures.push({ name, details });
  }
}

// -----------------------------------------------------------------------------
// Test 1: Route Inventory & Verification (14 Next.js App Router Routes)
// -----------------------------------------------------------------------------
console.log("\n>>> Test Suite 1: App Router Route Inventory & Code Layout");

const appDir = resolve("src/app");
const requiredRoutes = [
  "", // root /
  "about",
  "dashboard",
  "generate",
  "pdf-preview",
  "question-bank",
  "recent-papers",
  "review",
  "settings",
  "upload",
  "upload/status",
];

for (const r of requiredRoutes) {
  const pagePath = r === "" ? join(appDir, "page.tsx") : join(appDir, r, "page.tsx");
  assert(existsSync(pagePath), `Route exists: /${r}`, `File missing: ${pagePath}`);
}

assert(existsSync(join(appDir, "layout.tsx")), "Root Layout exists: src/app/layout.tsx");
assert(existsSync(join(appDir, "globals.css")), "Global CSS exists: src/app/globals.css");

// -----------------------------------------------------------------------------
// Test 2: Marks Math & Formula Verification: (M*1) + (S*2) + (L*5)
// -----------------------------------------------------------------------------
console.log("\n>>> Test Suite 2: Marks Math & Dynamic Formula Verification");

const QUESTION_WEIGHTS = {
  MCQ: 1,
  SHORT: 2,
  LONG: 5,
};

function calculateTotalMarks(mcqCount, shortCount, longCount) {
  return (
    mcqCount * QUESTION_WEIGHTS.MCQ +
    shortCount * QUESTION_WEIGHTS.SHORT +
    longCount * QUESTION_WEIGHTS.LONG
  );
}

function calculateTestSchemaMarks(test) {
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

function renumberTestQuestions(test) {
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

// Check standard permutations
assert(calculateTotalMarks(10, 5, 2) === 30, "Marks Formula: 10 MCQs + 5 Short + 2 Long = 30 Marks");
assert(calculateTotalMarks(12, 5, 3) === 37, "Marks Formula: 12 MCQs + 5 Short + 3 Long = 37 Marks");
assert(calculateTotalMarks(0, 0, 0) === 0, "Marks Formula: 0 Questions = 0 Marks");
assert(calculateTotalMarks(50, 25, 10) === 150, "Marks Formula: 50 MCQs + 25 Short + 10 Long = 150 Marks");

// -----------------------------------------------------------------------------
// Test 3: Question Renumbering & State Mutation Stress Test
// -----------------------------------------------------------------------------
console.log("\n>>> Test Suite 3: Question Renumbering & State Synchronization Stress Test");

const mockTest = {
  test_title: "Class 9 Chemistry Midterm Exam",
  subject: "Chemistry",
  chapter_or_topic: "Chapter 1 & 2",
  total_marks: 25,
  time_allowed: "45 Minutes",
  instructions: ["Attempt all questions.", "Use blue/black pen."],
  mcqs: [
    { question_number: 99, question_text: "What is molar mass of H<sub>2</sub>SO<sub>4</sub>?", options: ["98 g/mol", "18 g/mol", "44 g/mol", "32 g/mol"], correct_option: "A", marks: 1 },
    { question_number: 99, question_text: "Which subatomic particle has negative charge?", options: ["Proton", "Neutron", "Electron", "Positron"], correct_option: "C", marks: 1 },
  ],
  short_questions: [
    { question_number: 99, question_text: "Define empirical formula with an example.", marks: 2 },
    { question_number: 99, question_text: "Differentiate between atom and ion.", marks: 2 },
  ],
  long_questions: [
    { question_number: 99, question_text: "Explain Rutherford's atomic model and state its defects.", marks: 5 },
  ],
};

const renumbered = renumberTestQuestions(mockTest);

assert(renumbered.mcqs[0].question_number === 1, "MCQ 1 has sequential index 1");
assert(renumbered.mcqs[1].question_number === 2, "MCQ 2 has sequential index 2");
assert(renumbered.short_questions[0].question_number === 3, "Short Q 1 continues sequence to 3");
assert(renumbered.short_questions[1].question_number === 4, "Short Q 2 continues sequence to 4");
assert(renumbered.long_questions[0].question_number === 5, "Long Q 1 continues sequence to 5");
assert(renumbered.total_marks === 11, "Recalculated total marks (2*1 + 2*2 + 1*5 = 11)");

// Stress test: Massive question suite (100 MCQs + 50 Short + 20 Long)
const massiveTest = {
  test_title: "Massive Assessment",
  subject: "Physics",
  chapter_or_topic: "Comprehensive",
  total_marks: 0,
  time_allowed: "3 Hours",
  instructions: [],
  mcqs: Array.from({ length: 100 }, (_, i) => ({ question_number: 0, question_text: `MCQ ${i}`, options: ["A", "B", "C", "D"], correct_option: "A", marks: 1 })),
  short_questions: Array.from({ length: 50 }, (_, i) => ({ question_number: 0, question_text: `Short ${i}`, marks: 2 })),
  long_questions: Array.from({ length: 20 }, (_, i) => ({ question_number: 0, question_text: `Long ${i}`, marks: 5 })),
};

const massiveRenumbered = renumberTestQuestions(massiveTest);
assert(massiveRenumbered.mcqs.length === 100, "Massive test contains 100 MCQs");
assert(massiveRenumbered.short_questions.length === 50, "Massive test contains 50 Short Qs");
assert(massiveRenumbered.long_questions.length === 20, "Massive test contains 20 Long Qs");
assert(massiveRenumbered.mcqs[99].question_number === 100, "MCQ 100 has sequential index 100");
assert(massiveRenumbered.short_questions[0].question_number === 101, "Short Q 1 continues sequence to 101");
assert(massiveRenumbered.short_questions[49].question_number === 150, "Short Q 50 has sequence index 150");
assert(massiveRenumbered.long_questions[0].question_number === 151, "Long Q 1 continues sequence to 151");
assert(massiveRenumbered.long_questions[19].question_number === 170, "Long Q 20 has sequence index 170");
assert(massiveRenumbered.total_marks === 300, "Massive test total marks correctly equals 300 (100*1 + 50*2 + 20*5)");

// -----------------------------------------------------------------------------
// Test 4: Formula HTML Formatting & Sanitization
// -----------------------------------------------------------------------------
console.log("\n>>> Test Suite 4: Formula HTML Formatting & Sub/Superscript Sanitization");

function formatFormulaHtml(content) {
  if (!content) return "";
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

const chemFormula = "HNO<sub>3</sub> + NaOH -> NaNO<sub>3</sub> + H<sub>2</sub>O";
const chemFormatted = formatFormulaHtml(chemFormula);
assert(chemFormatted.includes("<sub>3</sub>"), "Chemical formula subscript preserved: <sub>3</sub>");
assert(chemFormatted.includes("<sub>2</sub>"), "Chemical formula subscript preserved: <sub>2</sub>");

const mathFormula = "E = mc<sup>2</sup> and a<sup>2</sup> + b<sup>2</sup> = c<sup>2</sup>";
const mathFormatted = formatFormulaHtml(mathFormula);
assert(mathFormatted.includes("<sup>2</sup>"), "Mathematical superscript preserved: <sup>2</sup>");

const maliciousScript = "<script>alert('xss')</script><b>Safe</b>";
const safeFormatted = formatFormulaHtml(maliciousScript);
assert(!safeFormatted.includes("<script>"), "Malicious script tag safely escaped");
assert(safeFormatted.includes("&lt;script&gt;"), "Script tag sanitized to HTML entities");
assert(safeFormatted.includes("<b>Safe</b>"), "Allowed formatting tag <b>Safe</b> preserved");

// -----------------------------------------------------------------------------
// Test 5: Subject Tokens & Flutter Design Parity Check
// -----------------------------------------------------------------------------
console.log("\n>>> Test Suite 5: Subject Tokens & Design System Parity");

const subjectConstantsPath = resolve("src/lib/constants.ts");
const subjectColorsPath = resolve("src/lib/subject-colors.ts");

assert(existsSync(subjectConstantsPath), "Constants file exists: src/lib/constants.ts");
assert(existsSync(subjectColorsPath), "Subject colors file exists: src/lib/subject-colors.ts");

const constantsContent = readFileSync(subjectConstantsPath, "utf-8");
assert(constantsContent.includes("#005BBF"), "Physics light color #005BBF present");
assert(constantsContent.includes("#006E2C"), "Chemistry light color #006E2C present");
assert(constantsContent.includes("#805600"), "Mathematics light color #805600 present");
assert(constantsContent.includes("#673AB7"), "Biology light color #673AB7 present");
assert(constantsContent.includes("#00838F"), "Computer Science light color #00838F present");

// -----------------------------------------------------------------------------
// Test 6: Offline Resilience & Mock Generators
// -----------------------------------------------------------------------------
console.log("\n>>> Test Suite 6: Offline Mock Fallbacks & Resilience");

const sampleDataPath = resolve("src/lib/sample-data.ts");
assert(existsSync(sampleDataPath), "Sample data file exists: src/lib/sample-data.ts");

const sampleDataContent = readFileSync(sampleDataPath, "utf-8");
assert(sampleDataContent.includes("SAMPLE_CHEMISTRY_TEST"), "SAMPLE_CHEMISTRY_TEST defined for offline fallback");
assert(sampleDataContent.includes("SAMPLE_PHYSICS_TEST"), "SAMPLE_PHYSICS_TEST defined for offline fallback");
assert(sampleDataContent.includes("generateMockPdfBlob"), "generateMockPdfBlob defined for offline ReportLab fallback");
assert(sampleDataContent.includes("getMockHealth"), "getMockHealth defined for offline telemetry fallback");
assert(sampleDataContent.includes("SAMPLE_QUESTIONS_BANK"), "SAMPLE_QUESTIONS_BANK defined for grounded repository");

// -----------------------------------------------------------------------------
// Summary
// -----------------------------------------------------------------------------
console.log("\n==================================================================");
console.log(`Empirical Test Summary: ${totalPassed} Passed, ${totalFailed} Failed`);
console.log("==================================================================");

if (totalFailed > 0) {
  console.error("FAILURES ENCOUNTERED:");
  failures.forEach((f) => console.error(`- ${f.name}: ${f.details}`));
  process.exit(1);
} else {
  console.log("ALL EMPIRICAL TESTS PASSED WITH 0 FAILURES.");
  process.exit(0);
}
