"use client";

/**
 * src/context/TestDraftContext.tsx
 * ExamCraft AI - Central React Context for Active Test Draft & Question Bank History
 */

import * as React from "react";
import {
  Class9TestSchema,
  MCQItem,
  ShortQuestionItem,
  LongQuestionItem,
  SavedTestRecord,
  SubjectType,
} from "@/types/exam";
import {
  getActiveDraft,
  saveActiveDraft,
  clearActiveDraft,
  getRecentPapers,
  saveRecentPaper,
  deleteRecentPaper,
  toggleFavoritePaper,
} from "@/lib/storage";
import {
  renumberTestQuestions,
} from "@/lib/utils";
import { api } from "@/lib/api";

export type QuestionSection = "mcqs" | "short_questions" | "long_questions";
export type QuestionItemUnion = MCQItem | ShortQuestionItem | LongQuestionItem;

export interface TestDraftContextValue {
  draft: Class9TestSchema | null;
  history: SavedTestRecord[];
  activeGrade: number;
  setActiveGrade: (grade: number) => void;
  isDirty: boolean;
  isRegenerating: boolean;
  lastSavedAt: string | null;

  // Draft Mutations
  setDraft: (draft: Class9TestSchema | null) => void;
  updateDraftMetadata: (
    updates: Partial<
      Pick<Class9TestSchema, "test_title" | "time_allowed" | "instructions" | "chapter_or_topic" | "grade">
    >
  ) => void;
  updateQuestion: (
    section: QuestionSection,
    index: number,
    updatedQuestion: QuestionItemUnion
  ) => void;
  deleteQuestion: (section: QuestionSection, index: number) => void;
  addQuestion: (section: QuestionSection, question: QuestionItemUnion) => void;
  renumberQuestions: () => void;
  regenerateQuestion: (
    section: QuestionSection,
    index: number,
    instruction?: string
  ) => Promise<void>;
  resetDraft: () => void;

  // History & Persistence
  saveCurrentDraftToHistory: () => SavedTestRecord | null;
  loadDraftFromHistory: (id: string) => boolean;
  deleteDraftFromHistory: (id: string) => void;
  toggleFavoriteDraft: (id: string) => void;
  refreshHistory: () => void;
}

const TestDraftContext = React.createContext<TestDraftContextValue | undefined>(undefined);

export function TestDraftProvider({ children }: { children: React.ReactNode }) {
  const [draft, setDraftState] = React.useState<Class9TestSchema | null>(null);
  const [history, setHistory] = React.useState<SavedTestRecord[]>([]);
  const [activeGrade, setActiveGradeState] = React.useState<number>(9);
  const [isDirty, setIsDirty] = React.useState<boolean>(false);
  const [isRegenerating, setIsRegenerating] = React.useState<boolean>(false);
  const [lastSavedAt, setLastSavedAt] = React.useState<string | null>(null);

  // Initial client hydration from LocalStorage
  React.useEffect(() => {
    try {
      const active = getActiveDraft();
      if (active) {
        setDraftState(active);
        if (active.grade) {
          setActiveGradeState(Number(active.grade));
        }
      }
      const savedGrade = localStorage.getItem("examcraft_active_grade");
      if (savedGrade && [9, 10, 11, 12].includes(Number(savedGrade))) {
        setActiveGradeState(Number(savedGrade));
      }
      const savedPapers = getRecentPapers();
      setHistory(savedPapers);
    } catch (e) {
      console.error("Failed to hydrate TestDraftContext from storage:", e);
    }
  }, []);

  const setActiveGrade = React.useCallback((grade: number) => {
    setActiveGradeState(grade);
    try {
      localStorage.setItem("examcraft_active_grade", String(grade));
    } catch (e) {
      console.error("Failed to persist active grade:", e);
    }
  }, []);

  const refreshHistory = React.useCallback(() => {
    const papers = getRecentPapers();
    setHistory(papers);
  }, []);

  // Internal helper to update draft, recalculate marks, renumber questions, and persist
  const setDraftInternal = React.useCallback(
    (newDraft: Class9TestSchema | null, markDirty = true) => {
      if (!newDraft) {
        setDraftState(null);
        clearActiveDraft();
        setIsDirty(false);
        setLastSavedAt(null);
        return;
      }

      // Automatically renumber and calculate total marks
      const preparedDraft = renumberTestQuestions(newDraft);
      setDraftState(preparedDraft);
      saveActiveDraft(preparedDraft);
      if (markDirty) {
        setIsDirty(true);
      }
      setLastSavedAt(new Date().toISOString());
    },
    []
  );

  const setDraft = React.useCallback(
    (newDraft: Class9TestSchema | null) => {
      setDraftInternal(newDraft, true);
    },
    [setDraftInternal]
  );

  const updateDraftMetadata = React.useCallback(
    (
      updates: Partial<
        Pick<Class9TestSchema, "test_title" | "time_allowed" | "instructions" | "chapter_or_topic">
      >
    ) => {
      setDraftState((prev) => {
        if (!prev) return prev;
        const next: Class9TestSchema = {
          ...prev,
          ...updates,
        };
        const prepared = renumberTestQuestions(next);
        saveActiveDraft(prepared);
        setIsDirty(true);
        setLastSavedAt(new Date().toISOString());
        return prepared;
      });
    },
    []
  );

  const updateQuestion = React.useCallback(
    (
      section: QuestionSection,
      index: number,
      updatedQuestion: QuestionItemUnion
    ) => {
      setDraftState((prev) => {
        if (!prev) return prev;
        const sectionList = [...(prev[section] || [])];
        if (index < 0 || index >= sectionList.length) return prev;

        sectionList[index] = updatedQuestion as never;
        const newDraft: Class9TestSchema = {
          ...prev,
          [section]: sectionList,
        };
        const prepared = renumberTestQuestions(newDraft);
        saveActiveDraft(prepared);
        setIsDirty(true);
        setLastSavedAt(new Date().toISOString());
        return prepared;
      });
    },
    []
  );

  const deleteQuestion = React.useCallback(
    (section: QuestionSection, index: number) => {
      setDraftState((prev) => {
        if (!prev) return prev;
        const sectionList = [...(prev[section] || [])];
        if (index < 0 || index >= sectionList.length) return prev;

        sectionList.splice(index, 1);
        const newDraft: Class9TestSchema = {
          ...prev,
          [section]: sectionList,
        };
        const prepared = renumberTestQuestions(newDraft);
        saveActiveDraft(prepared);
        setIsDirty(true);
        setLastSavedAt(new Date().toISOString());
        return prepared;
      });
    },
    []
  );

  const addQuestion = React.useCallback(
    (section: QuestionSection, question: QuestionItemUnion) => {
      setDraftState((prev) => {
        if (!prev) return prev;
        const sectionList = [...(prev[section] || []), question];
        const newDraft: Class9TestSchema = {
          ...prev,
          [section]: sectionList,
        };
        const prepared = renumberTestQuestions(newDraft);
        saveActiveDraft(prepared);
        setIsDirty(true);
        setLastSavedAt(new Date().toISOString());
        return prepared;
      });
    },
    []
  );

  const renumberQuestions = React.useCallback(() => {
    setDraftState((prev) => {
      if (!prev) return prev;
      const prepared = renumberTestQuestions(prev);
      saveActiveDraft(prepared);
      setLastSavedAt(new Date().toISOString());
      return prepared;
    });
  }, []);

  const regenerateQuestion = React.useCallback(
    async (
      section: QuestionSection,
      index: number,
      instruction?: string
    ): Promise<void> => {
      if (!draft) return;
      const currentList = draft[section] || [];
      if (index < 0 || index >= currentList.length) return;

      setIsRegenerating(true);
      try {
        const res = await api.generateDraft({
          subject: draft.subject as SubjectType,
          chapter_name: draft.chapter_or_topic || "Chapter 1",
          test_type: "topic",
          topic_query: draft.chapter_or_topic,
          grade: draft.grade || activeGrade || 9,
          mcq_count: section === "mcqs" ? 1 : 0,
          short_count: section === "short_questions" ? 1 : 0,
          long_count: section === "long_questions" ? 1 : 0,
          generation_instruction:
            instruction || `Regenerate a high-quality alternative question for Class ${draft.grade || activeGrade || 9}.`,
        });

        const generatedList = res[section] || [];
        if (generatedList.length > 0) {
          const replacement = generatedList[0];
          updateQuestion(section, index, replacement);
        }
      } catch (err) {
        console.error("Failed to regenerate question:", err);
        throw err;
      } finally {
        setIsRegenerating(false);
      }
    },
    [draft, updateQuestion, activeGrade]
  );

  const resetDraft = React.useCallback(() => {
    setDraftInternal(null, false);
  }, [setDraftInternal]);

  const saveCurrentDraftToHistory = React.useCallback((): SavedTestRecord | null => {
    if (!draft) return null;
    try {
      const record = saveRecentPaper(draft);
      refreshHistory();
      setIsDirty(false);
      return record;
    } catch (e) {
      console.error("Failed to save draft to history:", e);
      return null;
    }
  }, [draft, refreshHistory]);

  const loadDraftFromHistory = React.useCallback(
    (id: string): boolean => {
      const papers = getRecentPapers();
      const match = papers.find((p) => p.id === id);
      if (match && match.test_data) {
        setDraftInternal(match.test_data, false);
        return true;
      }
      return false;
    },
    [setDraftInternal]
  );

  const deleteDraftFromHistory = React.useCallback(
    (id: string) => {
      deleteRecentPaper(id);
      refreshHistory();
    },
    [refreshHistory]
  );

  const toggleFavoriteDraft = React.useCallback(
    (id: string) => {
      toggleFavoritePaper(id);
      refreshHistory();
    },
    [refreshHistory]
  );

  const value = React.useMemo<TestDraftContextValue>(
    () => ({
      draft,
      history,
      activeGrade,
      setActiveGrade,
      isDirty,
      isRegenerating,
      lastSavedAt,
      setDraft,
      updateDraftMetadata,
      updateQuestion,
      deleteQuestion,
      addQuestion,
      renumberQuestions,
      regenerateQuestion,
      resetDraft,
      saveCurrentDraftToHistory,
      loadDraftFromHistory,
      deleteDraftFromHistory,
      toggleFavoriteDraft,
      refreshHistory,
    }),
    [
      draft,
      history,
      activeGrade,
      setActiveGrade,
      isDirty,
      isRegenerating,
      lastSavedAt,
      setDraft,
      updateDraftMetadata,
      updateQuestion,
      deleteQuestion,
      addQuestion,
      renumberQuestions,
      regenerateQuestion,
      resetDraft,
      saveCurrentDraftToHistory,
      loadDraftFromHistory,
      deleteDraftFromHistory,
      toggleFavoriteDraft,
      refreshHistory,
    ]
  );

  return (
    <TestDraftContext.Provider value={value}>
      {children}
    </TestDraftContext.Provider>
  );
}

export function useTestDraft(): TestDraftContextValue {
  const context = React.useContext(TestDraftContext);
  if (!context) {
    throw new Error("useTestDraft must be used within a TestDraftProvider");
  }
  return context;
}
