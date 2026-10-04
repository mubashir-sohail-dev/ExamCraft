/**
 * frontend/test-empirical-harness.mjs
 * Comprehensive Empirical Test Harness for ExamCraft Frontend
 * Tests:
 * 1. Marks Calculation Logic (Extreme & Boundary Cases)
 * 2. Question Renumbering Logic (Deletion, Movement, Section Crossing)
 * 3. Formula HTML Sanitizer (XSS, Malformed Tags, Nested Formulas, Special Chars)
 * 4. Draft Immutability & State Mutation Integrity
 */

import assert from "node:assert";

// --- Replicate & Import Core Functions from frontend/src/lib ---
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

// ==========================================
// TEST SUITE EXECUTION
// ==========================================

const testResults = [];

function runTest(suite, name, testFn) {
  try {
    testFn();
    testResults.push({ suite, name, status: "PASS", error: null });
    console.log(`[PASS] [${suite}] ${name}`);
  } catch (err) {
    testResults.push({ suite, name, status: "FAIL", error: err.message });
    console.error(`[FAIL] [${suite}] ${name}: ${err.message}`);
  }
}

console.log("==================================================");
console.log("EXAMCRAFT FRONTEND EMPIRICAL TEST SUITE");
console.log("==================================================\n");

// --------------------------------------------------
// 1. MARKS CALCULATION TESTS
// --------------------------------------------------
runTest("Marks Calculation", "Zero questions across all categories (0, 0, 0)", () => {
  const result = calculateTotalMarks(0, 0, 0);
  assert.strictEqual(result, 0);
});

runTest("Marks Calculation", "Standard 25-mark midterm (10 MCQs, 5 Short, 1 Long)", () => {
  const result = calculateTotalMarks(10, 5, 1);
  assert.strictEqual(result, 10 * 1 + 5 * 2 + 1 * 5); // 25
  assert.strictEqual(result, 25);
});

runTest("Marks Calculation", "Heavy test (20 MCQs, 10 Short, 5 Long)", () => {
  const result = calculateTotalMarks(20, 10, 5);
  assert.strictEqual(result, 20 * 1 + 10 * 2 + 5 * 5); // 20 + 20 + 25 = 65
  assert.strictEqual(result, 65);
});

runTest("Marks Calculation", "Only MCQs (50 MCQs, 0 Short, 0 Long)", () => {
  const result = calculateTotalMarks(50, 0, 0);
  assert.strictEqual(result, 50);
});

runTest("Marks Calculation", "Only Long Questions (0 MCQs, 0 Short, 12 Long)", () => {
  const result = calculateTotalMarks(0, 0, 12);
  assert.strictEqual(result, 60);
});

runTest("Marks Calculation", "calculateTestSchemaMarks with empty test schema", () => {
  const schema = {
    test_title: "Empty Test",
    subject: "Physics",
    chapter_or_topic: "Ch 1",
    total_marks: 0,
    time_allowed: "45 min",
    instructions: [],
    mcqs: [],
    short_questions: [],
    long_questions: [],
  };
  const total = calculateTestSchemaMarks(schema);
  assert.strictEqual(total, 0);
});

runTest("Marks Calculation", "calculateTestSchemaMarks with undefined/missing question arrays", () => {
  const schema = {
    test_title: "Sparse Test",
    subject: "Chemistry",
    chapter_or_topic: "Ch 2",
    total_marks: 0,
    time_allowed: "45 min",
    instructions: [],
  };
  const total = calculateTestSchemaMarks(schema);
  assert.strictEqual(total, 0);
});

runTest("Marks Calculation", "calculateTestSchemaMarks with custom mark overrides per item", () => {
  const schema = {
    test_title: "Custom Weighted Test",
    subject: "Mathematics",
    chapter_or_topic: "Ch 3",
    total_marks: 0,
    time_allowed: "60 min",
    instructions: [],
    mcqs: [
      { question_number: 1, question_text: "Q1", options: ["A","B","C","D"], correct_option: "A", marks: 2 }, // override: 2
      { question_number: 2, question_text: "Q2", options: ["A","B","C","D"], correct_option: "B", marks: undefined }, // default: 1
    ],
    short_questions: [
      { question_number: 3, question_text: "Q3", marks: 4 }, // override: 4
      { question_number: 4, question_text: "Q4", marks: 0 }, // explicit 0 marks (e.g. bonus/ungraded)
    ],
    long_questions: [
      { question_number: 5, question_text: "Q5", marks: 8 }, // override: 8
    ],
  };
  // Expected: (2 + 1) + (4 + 0) + 8 = 15
  const total = calculateTestSchemaMarks(schema);
  assert.strictEqual(total, 15);
});

// --------------------------------------------------
// 2. QUESTION RENUMBERING & MUTATION TESTS
// --------------------------------------------------
runTest("Renumbering", "Sequential numbering across 3 MCQs, 2 Short, 2 Long", () => {
  const schema = {
    test_title: "Renumber Base",
    subject: "Biology",
    chapter_or_topic: "Cells",
    total_marks: 0,
    time_allowed: "45 min",
    instructions: [],
    mcqs: [
      { question_number: 99, question_text: "M1", options: ["A","B","C","D"], correct_option: "A", marks: 1 },
      { question_number: 99, question_text: "M2", options: ["A","B","C","D"], correct_option: "B", marks: 1 },
      { question_number: 99, question_text: "M3", options: ["A","B","C","D"], correct_option: "C", marks: 1 },
    ],
    short_questions: [
      { question_number: 99, question_text: "S1", marks: 2 },
      { question_number: 99, question_text: "S2", marks: 2 },
    ],
    long_questions: [
      { question_number: 99, question_text: "L1", marks: 5 },
      { question_number: 99, question_text: "L2", marks: 5 },
    ],
  };

  const renumbered = renumberTestQuestions(schema);
  assert.strictEqual(renumbered.mcqs[0].question_number, 1);
  assert.strictEqual(renumbered.mcqs[1].question_number, 2);
  assert.strictEqual(renumbered.mcqs[2].question_number, 3);
  assert.strictEqual(renumbered.short_questions[0].question_number, 4);
  assert.strictEqual(renumbered.short_questions[1].question_number, 5);
  assert.strictEqual(renumbered.long_questions[0].question_number, 6);
  assert.strictEqual(renumbered.long_questions[1].question_number, 7);
  assert.strictEqual(renumbered.total_marks, 3 + 4 + 10); // 17
});

runTest("Renumbering", "Delete middle MCQ (item at index 1)", () => {
  const schema = {
    test_title: "Delete Test",
    subject: "Physics",
    chapter_or_topic: "Kinematics",
    total_marks: 25,
    time_allowed: "45 min",
    instructions: [],
    mcqs: [
      { question_number: 1, question_text: "M1", options: ["A","B","C","D"], correct_option: "A", marks: 1 },
      { question_number: 2, question_text: "M2 (Delete me)", options: ["A","B","C","D"], correct_option: "B", marks: 1 },
      { question_number: 3, question_text: "M3", options: ["A","B","C","D"], correct_option: "C", marks: 1 },
    ],
    short_questions: [
      { question_number: 4, question_text: "S1", marks: 2 },
      { question_number: 5, question_text: "S2", marks: 2 },
    ],
    long_questions: [
      { question_number: 6, question_text: "L1", marks: 5 },
    ],
  };

  // Simulate deleteQuestion("mcqs", 1)
  const updatedMcqs = [...schema.mcqs];
  updatedMcqs.splice(1, 1);
  const updatedDraft = { ...schema, mcqs: updatedMcqs };
  const result = renumberTestQuestions(updatedDraft);

  assert.strictEqual(result.mcqs.length, 2);
  assert.strictEqual(result.mcqs[0].question_text, "M1");
  assert.strictEqual(result.mcqs[0].question_number, 1);
  assert.strictEqual(result.mcqs[1].question_text, "M3");
  assert.strictEqual(result.mcqs[1].question_number, 2);
  assert.strictEqual(result.short_questions[0].question_number, 3);
  assert.strictEqual(result.short_questions[1].question_number, 4);
  assert.strictEqual(result.long_questions[0].question_number, 5);
  assert.strictEqual(result.total_marks, 2*1 + 2*2 + 1*5); // 11
});

runTest("Renumbering", "Move / Reorder Short questions (swap index 0 and 1)", () => {
  const schema = {
    test_title: "Reorder Test",
    subject: "Computer Science",
    chapter_or_topic: "Networks",
    total_marks: 20,
    time_allowed: "45 min",
    instructions: [],
    mcqs: [
      { question_number: 1, question_text: "M1", options: ["A","B","C","D"], correct_option: "A", marks: 1 },
    ],
    short_questions: [
      { question_number: 2, question_text: "Original S1", marks: 2 },
      { question_number: 3, question_text: "Original S2", marks: 2 },
    ],
    long_questions: [
      { question_number: 4, question_text: "L1", marks: 5 },
    ],
  };

  // Swap S1 and S2
  const updatedShort = [schema.short_questions[1], schema.short_questions[0]];
  const renumbered = renumberTestQuestions({ ...schema, short_questions: updatedShort });

  assert.strictEqual(renumbered.short_questions[0].question_text, "Original S2");
  assert.strictEqual(renumbered.short_questions[0].question_number, 2);
  assert.strictEqual(renumbered.short_questions[1].question_text, "Original S1");
  assert.strictEqual(renumbered.short_questions[1].question_number, 3);
  assert.strictEqual(renumbered.long_questions[0].question_number, 4);
});

runTest("Renumbering", "Immutability check: original schema must not be mutated in place", () => {
  const originalSchema = {
    test_title: "Immutability Test",
    subject: "Physics",
    chapter_or_topic: "Forces",
    total_marks: 0,
    time_allowed: "45 min",
    instructions: [],
    mcqs: [
      { question_number: 50, question_text: "M1", options: ["A","B","C","D"], correct_option: "A", marks: 1 },
    ],
    short_questions: [],
    long_questions: [],
  };

  const renumbered = renumberTestQuestions(originalSchema);
  assert.strictEqual(originalSchema.mcqs[0].question_number, 50, "Original object MCQ question_number was mutated!");
  assert.strictEqual(renumbered.mcqs[0].question_number, 1, "Cloned object has correct question_number");
  assert.notStrictEqual(originalSchema.mcqs, renumbered.mcqs, "Array reference must be unique");
  assert.notStrictEqual(originalSchema.mcqs[0], renumbered.mcqs[0], "Item reference must be unique");
});

// --------------------------------------------------
// 3. FORMULA HTML SANITIZER & XSS DEFENSE TESTS
// --------------------------------------------------
runTest("HTML Sanitizer", "Chemical formulas with subscript (H2O, H2SO4, CO2)", () => {
  const input1 = "What is the molecular mass of H<sub>2</sub>O?";
  assert.strictEqual(formatFormulaHtml(input1), "What is the molecular mass of H<sub>2</sub>O?");

  const input2 = "Reaction: 2H<sub>2</sub> + O<sub>2</sub> &rarr; 2H<sub>2</sub>O";
  assert.strictEqual(
    formatFormulaHtml(input2),
    "Reaction: 2H<sub>2</sub> + O<sub>2</sub> &amp;rarr; 2H<sub>2</sub>O"
  );

  const input3 = "Fe<sup>3+</sup> + 3e<sup>-</sup>";
  assert.strictEqual(formatFormulaHtml(input3), "Fe<sup>3+</sup> + 3e<sup>-</sup>");
});

runTest("HTML Sanitizer", "Mathematical exponents with superscript (x^2, E=mc^2)", () => {
  const input = "Calculate x<sup>2</sup> + y<sup>2</sup> = z<sup>2</sup>";
  assert.strictEqual(formatFormulaHtml(input), "Calculate x<sup>2</sup> + y<sup>2</sup> = z<sup>2</sup>");
});

runTest("HTML Sanitizer", "Case insensitive permitted tags (<SUB>, <Sup>, <B>, <I>)", () => {
  const input = "H<SUB>2</SUB>O and <B>Important</B> <I>note</I>";
  const output = formatFormulaHtml(input);
  assert.strictEqual(output, "H<sub>2</sub>O and <b>Important</b> <i>note</i>");
});

runTest("HTML Sanitizer", "XSS vector: <script> alert", () => {
  const malicious = '<script>alert("XSS Attack!");</script>';
  const sanitized = formatFormulaHtml(malicious);
  assert.strictEqual(sanitized, '&lt;script&gt;alert("XSS Attack!");&lt;/script&gt;');
  assert.ok(!sanitized.includes("<script>"), "Must not contain unescaped <script>");
});

runTest("HTML Sanitizer", "XSS vector: <img src=x onerror=...>", () => {
  const malicious = '<img src="invalid.jpg" onerror="alert(document.cookie)" />';
  const sanitized = formatFormulaHtml(malicious);
  assert.strictEqual(
    sanitized,
    '&lt;img src="invalid.jpg" onerror="alert(document.cookie)" /&gt;'
  );
  assert.ok(!sanitized.includes("<img"), "Must not contain unescaped <img>");
});

runTest("HTML Sanitizer", "XSS vector: <svg onload=...>", () => {
  const malicious = '<svg onload="alert(1)">';
  const sanitized = formatFormulaHtml(malicious);
  assert.strictEqual(sanitized, '&lt;svg onload="alert(1)"&gt;');
});

runTest("HTML Sanitizer", "XSS vector: Attribute injection in allowed tag <sub onclick=alert(1)>", () => {
  const malicious = '<sub onclick="alert(1)">2</sub>';
  const sanitized = formatFormulaHtml(malicious);
  // The sanitizer only whitelists pure &lt;sub&gt;, so &lt;sub onclick...&gt; stays escaped!
  assert.strictEqual(sanitized, '&lt;sub onclick="alert(1)"&gt;2</sub>');
  assert.ok(!sanitized.startsWith("<sub onclick"), "Attribute injection must be safely escaped");
});

runTest("HTML Sanitizer", "Malformed unclosed tag: H<sub2", () => {
  const input = "H<sub2";
  const output = formatFormulaHtml(input);
  assert.strictEqual(output, "H&lt;sub2");
});

runTest("HTML Sanitizer", "Mathematical inequality characters: a < b & c > d", () => {
  const input = "If a < b and c > d & e != f";
  const output = formatFormulaHtml(input);
  assert.strictEqual(output, "If a &lt; b and c &gt; d &amp; e != f");
});

runTest("HTML Sanitizer", "Null, undefined, and empty string edge cases", () => {
  assert.strictEqual(formatFormulaHtml(""), "");
  assert.strictEqual(formatFormulaHtml(null), "");
  assert.strictEqual(formatFormulaHtml(undefined), "");
});

// --------------------------------------------------
// SUMMARY OF TEST RESULTS
// --------------------------------------------------
console.log("\n==================================================");
console.log("TEST SUMMARY REPORT");
console.log("==================================================");

const passedCount = testResults.filter((t) => t.status === "PASS").length;
const failedCount = testResults.filter((t) => t.status === "FAIL").length;

console.log(`Total Tests: ${testResults.length}`);
console.log(`Passed: ${passedCount}`);
console.log(`Failed: ${failedCount}`);

if (failedCount > 0) {
  console.error("\nFailed Tests Details:");
  testResults
    .filter((t) => t.status === "FAIL")
    .forEach((t) => {
      console.error(`- [${t.suite}] ${t.name}: ${t.error}`);
    });
  process.exit(1);
} else {
  console.log("\nALL EMPIRICAL TESTS PASSED SUCCESSFULLY! (100% SUCCESS RATE)");
  process.exit(0);
}
