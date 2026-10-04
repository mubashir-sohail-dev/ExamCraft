/**
 * src/lib/storage.ts
 * ExamCraft AI - Persistent LocalStorage Manager
 */

import { AppSettings } from "@/types/api";
import { Class9TestSchema, SavedTestRecord, QuestionBankItem } from "@/types/exam";
import {
  DEFAULT_API_URL,
  DEFAULT_CLIENT_KEY,
  DEFAULT_ADMIN_KEY,
} from "./constants";

const STORAGE_KEYS = {
  SETTINGS: "examcraft_settings",
  ACTIVE_DRAFT: "examcraft_active_draft",
  RECENT_PAPERS: "examcraft_recent_papers",
  QUESTION_BANK: "examcraft_question_bank",
} as const;

export const DEFAULT_SETTINGS: AppSettings = {
  apiBaseUrl: DEFAULT_API_URL,
  clientApiKey: DEFAULT_CLIENT_KEY,
  adminApiKey: DEFAULT_ADMIN_KEY,
  theme: "system",
  defaultSubject: "Chemistry",
  enableTelemetry: true,
  enableMockFallback: false,
  pollingIntervalMs: 30000,
};

function isClient(): boolean {
  return typeof window !== "undefined" && typeof window.localStorage !== "undefined";
}

export function getSettings(): AppSettings {
  if (!isClient()) return DEFAULT_SETTINGS;
  try {
    const stored = localStorage.getItem(STORAGE_KEYS.SETTINGS);
    if (!stored) return DEFAULT_SETTINGS;
    const parsed = JSON.parse(stored) as Partial<AppSettings>;
    return {
      ...DEFAULT_SETTINGS,
      ...parsed,
      apiBaseUrl: (parsed.apiBaseUrl || DEFAULT_SETTINGS.apiBaseUrl).trim().replace(/\/+$/, ""),
      clientApiKey: (parsed.clientApiKey || DEFAULT_SETTINGS.clientApiKey).trim(),
      adminApiKey: (parsed.adminApiKey || DEFAULT_SETTINGS.adminApiKey).trim(),
    };
  } catch {
    return DEFAULT_SETTINGS;
  }
}

export function saveSettings(updates: Partial<AppSettings>): AppSettings {
  if (!isClient()) return { ...DEFAULT_SETTINGS, ...updates };
  const current = getSettings();
  const next = { ...current, ...updates };
  if (typeof next.apiBaseUrl === "string") {
    next.apiBaseUrl = next.apiBaseUrl.trim().replace(/\/+$/, "");
  }
  if (typeof next.clientApiKey === "string") {
    next.clientApiKey = next.clientApiKey.trim();
  }
  if (typeof next.adminApiKey === "string") {
    next.adminApiKey = next.adminApiKey.trim();
  }
  try {
    localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(next));
  } catch (e) {
    console.error("Failed to save settings:", e);
  }
  return next;
}

export function getActiveDraft(): Class9TestSchema | null {
  if (!isClient()) return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.ACTIVE_DRAFT);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function saveActiveDraft(draft: Class9TestSchema): void {
  if (!isClient()) return;
  try {
    localStorage.setItem(STORAGE_KEYS.ACTIVE_DRAFT, JSON.stringify(draft));
  } catch (e) {
    console.error("Failed to save active draft:", e);
  }
}

export function clearActiveDraft(): void {
  if (!isClient()) return;
  try {
    localStorage.removeItem(STORAGE_KEYS.ACTIVE_DRAFT);
  } catch (e) {
    console.error("Failed to clear active draft:", e);
  }
}

export function getRecentPapers(): SavedTestRecord[] {
  if (!isClient()) return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.RECENT_PAPERS);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

export function saveRecentPaper(test: Class9TestSchema): SavedTestRecord {
  const papers = getRecentPapers();
  const record: SavedTestRecord = {
    id: `paper_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`,
    title: test.test_title,
    subject: test.subject,
    created_at: new Date().toISOString(),
    total_marks: test.total_marks,
    mcq_count: (test.mcqs || []).length,
    short_count: (test.short_questions || []).length,
    long_count: (test.long_questions || []).length,
    question_count:
      (test.mcqs || []).length +
      (test.short_questions || []).length +
      (test.long_questions || []).length,
    is_favorite: false,
    test_data: test,
  };

  const updated = [record, ...papers.filter((p) => p.title !== test.test_title)].slice(0, 50);
  if (isClient()) {
    try {
      localStorage.setItem(STORAGE_KEYS.RECENT_PAPERS, JSON.stringify(updated));
    } catch (e) {
      console.error("Failed to save recent paper:", e);
    }
  }
  return record;
}

export function deleteRecentPaper(id: string): void {
  if (!isClient()) return;
  try {
    const papers = getRecentPapers().filter((p) => p.id !== id);
    localStorage.setItem(STORAGE_KEYS.RECENT_PAPERS, JSON.stringify(papers));
  } catch (e) {
    console.error("Failed to delete recent paper:", e);
  }
}

export function toggleFavoritePaper(id: string): void {
  if (!isClient()) return;
  try {
    const papers = getRecentPapers().map((p) =>
      p.id === id ? { ...p, is_favorite: !p.is_favorite } : p
    );
    localStorage.setItem(STORAGE_KEYS.RECENT_PAPERS, JSON.stringify(papers));
  } catch (e) {
    console.error("Failed to toggle favorite paper:", e);
  }
}

import { SAMPLE_QUESTIONS_BANK } from "./sample-data";

export function getSavedQuestions(): QuestionBankItem[] {
  if (!isClient()) return SAMPLE_QUESTIONS_BANK;
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.QUESTION_BANK);
    if (!raw) {
      try {
        localStorage.setItem(STORAGE_KEYS.QUESTION_BANK, JSON.stringify(SAMPLE_QUESTIONS_BANK));
      } catch {}
      return SAMPLE_QUESTIONS_BANK;
    }
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.length > 0 ? parsed : SAMPLE_QUESTIONS_BANK;
  } catch {
    return SAMPLE_QUESTIONS_BANK;
  }
}

export function saveQuestion(item: QuestionBankItem): void {
  if (!isClient()) return;
  try {
    const items = getSavedQuestions();
    const updated = [item, ...items.filter((q) => q.id !== item.id)];
    localStorage.setItem(STORAGE_KEYS.QUESTION_BANK, JSON.stringify(updated));
  } catch (e) {
    console.error("Failed to save question:", e);
  }
}

export function saveQuestionBank(items: QuestionBankItem[]): void {
  if (!isClient()) return;
  try {
    localStorage.setItem(STORAGE_KEYS.QUESTION_BANK, JSON.stringify(items));
  } catch (e) {
    console.error("Failed to save question bank:", e);
  }
}

export function deleteQuestion(id: string): void {
  if (!isClient()) return;
  try {
    const items = getSavedQuestions().filter((q) => q.id !== id);
    localStorage.setItem(STORAGE_KEYS.QUESTION_BANK, JSON.stringify(items));
  } catch (e) {
    console.error("Failed to delete question:", e);
  }
}

export function resetQuestionBankToDefault(): QuestionBankItem[] {
  if (isClient()) {
    try {
      localStorage.setItem(STORAGE_KEYS.QUESTION_BANK, JSON.stringify(SAMPLE_QUESTIONS_BANK));
    } catch (e) {
      console.error("Failed to reset question bank:", e);
    }
  }
  return SAMPLE_QUESTIONS_BANK;
}

export function clearQuestionBank(): void {
  if (!isClient()) return;
  try {
    localStorage.removeItem(STORAGE_KEYS.QUESTION_BANK);
  } catch (e) {
    console.error("Failed to clear question bank:", e);
  }
}

export function clearRecentPapers(): void {
  if (!isClient()) return;
  try {
    localStorage.removeItem(STORAGE_KEYS.RECENT_PAPERS);
  } catch (e) {
    console.error("Failed to clear recent papers:", e);
  }
}

export function clearAllCache(): void {
  if (!isClient()) return;
  try {
    localStorage.removeItem(STORAGE_KEYS.ACTIVE_DRAFT);
    localStorage.removeItem(STORAGE_KEYS.RECENT_PAPERS);
    localStorage.removeItem(STORAGE_KEYS.QUESTION_BANK);
  } catch (e) {
    console.error("Failed to clear cache:", e);
  }
}

// Aliases for convenient imports
export const getRecentTests = getRecentPapers;
export const deleteSavedTest = deleteRecentPaper;
export const getQuestionBank = getSavedQuestions;
export const clearAllStorage = clearAllCache;

export const storage = {
  getSettings,
  saveSettings,
  getActiveDraft,
  saveActiveDraft,
  clearActiveDraft,
  getRecentPapers,
  getRecentTests,
  saveRecentPaper,
  savePaperToHistory: saveRecentPaper,
  deleteRecentPaper,
  deleteSavedTest,
  deletePaperFromHistory: deleteRecentPaper,
  toggleFavoritePaper,
  getSavedQuestions,
  getQuestionBank,
  saveQuestion,
  saveQuestionBank,
  deleteQuestion,
  resetQuestionBankToDefault,
  clearQuestionBank,
  clearRecentPapers,
  clearAllCache,
  clearAllStorage,
};

