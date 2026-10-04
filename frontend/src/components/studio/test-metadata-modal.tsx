"use client";

import * as React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Class9TestSchema } from "@/types/exam";
import { FileEdit, Plus, Trash2, RotateCcw } from "lucide-react";

interface TestMetadataModalProps {
  isOpen: boolean;
  onClose: () => void;
  test: Class9TestSchema | null;
  onSave: (metadata: {
    test_title: string;
    chapter_or_topic: string;
    time_allowed: string;
    instructions: string[];
  }) => void;
}

const DEFAULT_INSTRUCTIONS = [
  "Attempt all questions in Section A, B, and C.",
  "Write answers clearly with proper question numbering.",
  "Draw neat and labeled diagrams wherever applicable.",
  "Scientific calculators are permitted for calculation parts.",
];

export function TestMetadataModal({
  isOpen,
  onClose,
  test,
  onSave,
}: TestMetadataModalProps) {
  const [title, setTitle] = React.useState("");
  const [chapterOrTopic, setChapterOrTopic] = React.useState("");
  const [timeAllowed, setTimeAllowed] = React.useState("45 Minutes");
  const [instructions, setInstructions] = React.useState<string[]>([]);

  React.useEffect(() => {
    if (test && isOpen) {
      setTitle(test.test_title || "");
      setChapterOrTopic(test.chapter_or_topic || "");
      setTimeAllowed(test.time_allowed || "45 Minutes");
      setInstructions(
        test.instructions && test.instructions.length > 0
          ? [...test.instructions]
          : [...DEFAULT_INSTRUCTIONS]
      );
    }
  }, [test, isOpen]);

  const handleAddInstruction = () => {
    setInstructions((prev) => [...prev, ""]);
  };

  const handleUpdateInstruction = (idx: number, val: string) => {
    setInstructions((prev) => {
      const next = [...prev];
      next[idx] = val;
      return next;
    });
  };

  const handleRemoveInstruction = (idx: number) => {
    setInstructions((prev) => prev.filter((_, i) => i !== idx));
  };

  const handleResetInstructions = () => {
    setInstructions([...DEFAULT_INSTRUCTIONS]);
  };

  const handleSave = () => {
    onSave({
      test_title: title.trim() || test?.test_title || "Examination Paper",
      chapter_or_topic: chapterOrTopic.trim() || (test ? test.chapter_or_topic : "Comprehensive"),
      time_allowed: timeAllowed.trim() || "45 Minutes",
      instructions: instructions.map((i) => i.trim()).filter(Boolean),
    });
    onClose();
  };

  if (!isOpen || !test) return null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <FileEdit className="h-4 w-4" />
            </div>
            <div>
              <DialogTitle className="text-base font-bold">
                Edit Paper Metadata
              </DialogTitle>
              <DialogDescription className="text-xs">
                Update test title, syllabus chapter/topic, allotted time, and printed instructions.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Test Title */}
          <div className="space-y-1">
            <Label htmlFor="meta-title" className="text-xs font-semibold">
              Examination Paper Title *
            </Label>
            <Input
              id="meta-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={`e.g. Class ${test?.grade || 9} Chemistry - Chapter 3 Test`}
              className="text-xs"
            />
          </div>

          {/* Chapter / Topic & Time Allowed */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label htmlFor="meta-chapter" className="text-xs font-semibold">
                Chapter / Topic Name *
              </Label>
              <Input
                id="meta-chapter"
                value={chapterOrTopic}
                onChange={(e) => setChapterOrTopic(e.target.value)}
                placeholder="e.g. Periodic Table & Periodicity"
                className="text-xs"
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="meta-time" className="text-xs font-semibold">
                Time Allowed *
              </Label>
              <Input
                id="meta-time"
                value={timeAllowed}
                onChange={(e) => setTimeAllowed(e.target.value)}
                placeholder="e.g. 45 Minutes or 1 Hour"
                className="text-xs"
              />
            </div>
          </div>

          {/* General Instructions List */}
          <div className="space-y-2 pt-2 border-t border-border/60">
            <div className="flex items-center justify-between">
              <Label className="text-xs font-bold text-foreground">
                General Instructions for Students ({instructions.length})
              </Label>
              <div className="flex items-center gap-1.5">
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={handleResetInstructions}
                  className="h-6 px-1.5 text-[11px] text-muted-foreground gap-1"
                  title="Reset instructions to defaults"
                >
                  <RotateCcw className="h-3 w-3" />
                  <span>Reset Defaults</span>
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleAddInstruction}
                  className="h-6 px-2 text-[11px] gap-1"
                >
                  <Plus className="h-3 w-3" />
                  <span>Add Line</span>
                </Button>
              </div>
            </div>

            <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
              {instructions.map((inst, idx) => (
                <div key={idx} className="flex items-center gap-2">
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-muted font-mono text-[10px] font-bold text-muted-foreground">
                    {idx + 1}
                  </span>
                  <Input
                    value={inst}
                    onChange={(e) => handleUpdateInstruction(idx, e.target.value)}
                    placeholder={`Instruction #${idx + 1}...`}
                    className="h-8 text-xs flex-1"
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    onClick={() => handleRemoveInstruction(idx)}
                    className="h-7 w-7 shrink-0 text-muted-foreground hover:text-destructive"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                </div>
              ))}
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" size="sm" onClick={onClose}>
            Cancel
          </Button>
          <Button size="sm" onClick={handleSave}>
            Apply Changes
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
