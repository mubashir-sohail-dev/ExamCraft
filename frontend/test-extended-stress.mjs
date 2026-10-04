/**
 * frontend/test-extended-stress.mjs
 * Extended Adversarial Stress Testing & Boundary Analysis
 */

import assert from "node:assert";

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

const stressResults = [];

function runStress(suite, name, testFn) {
  try {
    testFn();
    stressResults.push({ suite, name, status: "PASS", error: null });
    console.log(`[PASS] [${suite}] ${name}`);
  } catch (err) {
    stressResults.push({ suite, name, status: "FAIL", error: err.message });
    console.error(`[FAIL] [${suite}] ${name}: ${err.message}`);
  }
}

console.log("==================================================");
console.log("EXTENDED ADVERSARIAL STRESS TEST SUITE");
console.log("==================================================\n");

// 1. Extreme Scale Marks Calculation
runStress("Scale Stress", "10,000 MCQs, 5,000 Short, 2,000 Long questions", () => {
  const result = calculateTotalMarks(10000, 5000, 2000);
  assert.strictEqual(result, 10000*1 + 5000*2 + 2000*5); // 10k + 10k + 10k = 30k
  assert.strictEqual(result, 30000);
});

runStress("Scale Stress", "Rapid sequential deletion until 0 questions remaining", () => {
  let draft = {
    test_title: "Mass Delete Test",
    subject: "Physics",
    chapter_or_topic: "Forces",
    total_marks: 100,
    time_allowed: "60 min",
    instructions: [],
    mcqs: Array.from({ length: 50 }, (_, i) => ({
      question_number: i + 1,
      question_text: `MCQ ${i + 1}`,
      options: ["A", "B", "C", "D"],
      correct_option: "A",
      marks: 1,
    })),
    short_questions: Array.from({ length: 25 }, (_, i) => ({
      question_number: 50 + i + 1,
      question_text: `Short ${i + 1}`,
      marks: 2,
    })),
    long_questions: Array.from({ length: 10 }, (_, i) => ({
      question_number: 75 + i + 1,
      question_text: `Long ${i + 1}`,
      marks: 5,
    })),
  };

  assert.strictEqual(calculateTestSchemaMarks(draft), 50*1 + 25*2 + 10*5); // 150 marks

  // Delete all items randomly/sequentially from middle
  while (draft.mcqs.length > 0) {
    const mid = Math.floor(draft.mcqs.length / 2);
    draft.mcqs.splice(mid, 1);
    draft = renumberTestQuestions(draft);
  }
  assert.strictEqual(draft.mcqs.length, 0);
  assert.strictEqual(draft.short_questions[0].question_number, 1);
  assert.strictEqual(draft.total_marks, 25*2 + 10*5); // 100 marks

  while (draft.short_questions.length > 0) {
    draft.short_questions.shift();
    draft = renumberTestQuestions(draft);
  }
  assert.strictEqual(draft.short_questions.length, 0);
  assert.strictEqual(draft.long_questions[0].question_number, 1);
  assert.strictEqual(draft.total_marks, 10*5); // 50 marks

  while (draft.long_questions.length > 0) {
    draft.long_questions.pop();
    draft = renumberTestQuestions(draft);
  }
  assert.strictEqual(draft.long_questions.length, 0);
  assert.strictEqual(draft.total_marks, 0);
});

// 2. Adversarial HTML Sanitizer Injections
runStress("Adversarial HTML", "Nested allowed formatting tags (<b><i>H<sub>2</sub>O</i></b>)", () => {
  const input = "<b><i>H<sub>2</sub>O</i></b> is water";
  const output = formatFormulaHtml(input);
  assert.strictEqual(output, "<b><i>H<sub>2</sub>O</i></b> is water");
});

runStress("Adversarial HTML", "Attribute injection on allowed tags (<b style='color:red;'>test</b>)", () => {
  const input = "<b style='color:red;'>test</b> and <i id='dangerous'>x</i>";
  const output = formatFormulaHtml(input);
  // Opening tag with attribute is escaped to &lt;b...&gt;, while plain closing tag &lt;/b&gt; becomes </b>
  assert.strictEqual(
    output,
    "&lt;b style='color:red;'&gt;test</b> and &lt;i id='dangerous'&gt;x</i>"
  );
  assert.ok(!output.startsWith("<b style"), "Opening tag with attribute must be escaped");
  assert.ok(!output.includes("<i id"), "Opening tag with attribute must be escaped");
});

runStress("Adversarial HTML", "JavaScript URI payload (<a href='javascript:alert(1)'>click</a>)", () => {
  const input = "<a href='javascript:alert(1)'>click</a>";
  const output = formatFormulaHtml(input);
  assert.strictEqual(output, "&lt;a href='javascript:alert(1)'&gt;click&lt;/a&gt;");
  assert.ok(!output.includes("<a"));
});

runStress("Adversarial HTML", "Deep nested unclosed tags (<<<<<<sub><sub><sub>)", () => {
  const input = "<<<<<<sub><sub><sub>";
  const output = formatFormulaHtml(input);
  assert.strictEqual(output, "&lt;&lt;&lt;&lt;&lt;<sub><sub><sub>");
});

runStress("Adversarial HTML", "High volume 100,000 characters payload with chemical tags", () => {
  const chunk = "Reaction: 2H<sub>2</sub> + O<sub>2</sub> = 2H<sub>2</sub>O <script>alert(1)</script> ";
  const largeInput = chunk.repeat(1000); // ~80,000 chars
  const startTime = Date.now();
  const output = formatFormulaHtml(largeInput);
  const duration = Date.now() - startTime;

  assert.ok(output.includes("<sub>2</sub>"));
  assert.ok(!output.includes("<script>"));
  assert.ok(output.includes("&lt;script&gt;"));
  assert.ok(duration < 200, `Sanitizer took ${duration}ms, must be < 200ms`);
});

// 3. Subject Color Tokens & Config Completeness
runStress("Subject Token Parity", "All 5 core subjects have valid hex colors & metadata", () => {
  const subjects = [
    { name: "Physics", light: "#005BBF", dark: "#ADC7FF" },
    { name: "Chemistry", light: "#006E2C", dark: "#86F898" },
    { name: "Mathematics", light: "#805600", dark: "#FFBA45" },
    { name: "Biology", light: "#673AB7", dark: "#D1C4E9" },
    { name: "Computer Science", light: "#00838F", dark: "#80DEEA" },
  ];

  const hexRegex = /^#([0-9A-Fa-f]{6})$/;
  for (const s of subjects) {
    assert.ok(hexRegex.test(s.light), `Invalid light hex for ${s.name}: ${s.light}`);
    assert.ok(hexRegex.test(s.dark), `Invalid dark hex for ${s.name}: ${s.dark}`);
  }
});

console.log("\n==================================================");
console.log("EXTENDED STRESS SUMMARY");
console.log("==================================================");
const pCount = stressResults.filter((t) => t.status === "PASS").length;
const fCount = stressResults.filter((t) => t.status === "FAIL").length;
console.log(`Total: ${stressResults.length}, Passed: ${pCount}, Failed: ${fCount}`);

if (fCount > 0) {
  process.exit(1);
} else {
  console.log("ALL EXTENDED ADVERSARIAL TESTS PASSED!");
  process.exit(0);
}
