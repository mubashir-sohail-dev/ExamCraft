"use client";

/**
 * src/app/recent-papers/page.tsx
 * ExamCraft AI - Archive & History of Generated Assessment Papers
 */

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Clock,
  Sparkles,
  Search,
  Trash2,
  Download,
  Copy,
  Star,
  SlidersHorizontal,
  FileDown,
  Upload,
  CheckCircle2,
  AlertCircle,
  FolderOpen,
  ChevronDown,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { useTestDraft } from "@/context/TestDraftContext";
import {
  getRecentPapers,
  deleteRecentPaper,
  saveRecentPaper,
  toggleFavoritePaper,
  clearRecentPapers,
} from "@/lib/storage";
import { SavedTestRecord } from "@/types/exam";
import { formatDate, downloadJson, cn } from "@/lib/utils";

type SortOption = "newest" | "oldest" | "highest-marks" | "questions";

export default function RecentPapersPage() {
  const router = useRouter();
  const { setDraft } = useTestDraft();

  const [papers, setPapers] = React.useState<SavedTestRecord[]>([]);
  const [searchQuery, setSearchQuery] = React.useState<string>("");
  const [selectedSubject, setSelectedSubject] = React.useState<string>("all");
  const [showFavoritesOnly, setShowFavoritesOnly] = React.useState<boolean>(false);
  const [sortBy, setSortBy] = React.useState<SortOption>("newest");
  const [toastMessage, setToastMessage] = React.useState<{ type: "success" | "error"; text: string } | null>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  const loadPapers = React.useCallback(() => {
    const records = getRecentPapers();
    setPapers(records);
  }, []);

  React.useEffect(() => {
    loadPapers();
  }, [loadPapers]);

  const showToast = (type: "success" | "error", text: string) => {
    setToastMessage({ type, text });
    setTimeout(() => setToastMessage(null), 3000);
  };

  // Actions
  const handleOpenInStudio = (paper: SavedTestRecord) => {
    if (paper.test_data) {
      setDraft(paper.test_data);
      router.push("/review");
    }
  };

  const handleExportPdf = (paper: SavedTestRecord) => {
    if (paper.test_data) {
      setDraft(paper.test_data);
      router.push("/pdf-preview");
    }
  };

  const handleDuplicate = (paper: SavedTestRecord) => {
    if (!paper.test_data) return;
    const clonedData = {
      ...paper.test_data,
      test_title: `${paper.test_data.test_title || paper.title} (Copy)`,
    };
    saveRecentPaper(clonedData);
    loadPapers();
    showToast("success", "Paper duplicated successfully!");
  };

  const handleDelete = (id: string, title: string) => {
    if (confirm(`Delete "${title}" from history?`)) {
      deleteRecentPaper(id);
      loadPapers();
      showToast("success", "Paper deleted from archive.");
    }
  };

  const handleToggleFavorite = (id: string) => {
    toggleFavoritePaper(id);
    loadPapers();
  };

  const handleClearAll = () => {
    if (papers.length === 0) return;
    if (confirm("Are you sure you want to clear all archived assessment papers? This action cannot be undone.")) {
      clearRecentPapers();
      loadPapers();
      showToast("success", "Recent papers archive cleared.");
    }
  };

  const handleExportArchiveJson = () => {
    if (papers.length === 0) {
      showToast("error", "No papers in archive to export.");
      return;
    }
    downloadJson(papers, `examcraft_papers_archive_${new Date().toISOString().slice(0, 10)}.json`);
    showToast("success", `Exported ${papers.length} papers to JSON.`);
  };

  const handleImportArchiveJson = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const parsed = JSON.parse(event.target?.result as string);
        if (Array.isArray(parsed) && parsed.length > 0) {
          let count = 0;
          for (const item of parsed) {
            if (item.test_data && item.title) {
              saveRecentPaper(item.test_data);
              count++;
            }
          }
          loadPapers();
          showToast("success", `Imported ${count} papers into archive!`);
        } else {
          showToast("error", "Invalid JSON format: expected array of paper records.");
        }
      } catch (err) {
        console.error("Failed to import papers JSON:", err);
        showToast("error", "Failed to parse JSON file.");
      }
    };
    reader.readAsText(file);
    e.target.value = "";
  };

  // Filter & Sort
  const filteredAndSortedPapers = React.useMemo(() => {
    const filtered = papers.filter((p) => {
      const title = (p.title || p.test_title || p.test_data?.test_title || "").toLowerCase();
      const subject = (p.subject || "").toLowerCase();
      const chapter = (p.chapter_or_topic || p.test_data?.chapter_or_topic || "").toLowerCase();
      const q = searchQuery.toLowerCase();

      const matchesQuery = !q || title.includes(q) || subject.includes(q) || chapter.includes(q);
      const matchesSubject =
        selectedSubject === "all" || subject === selectedSubject.toLowerCase();
      const matchesFavorite = !showFavoritesOnly || p.is_favorite;

      return matchesQuery && matchesSubject && matchesFavorite;
    });

    // Sort
    return filtered.sort((a, b) => {
      if (sortBy === "newest") {
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      }
      if (sortBy === "oldest") {
        return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
      }
      if (sortBy === "highest-marks") {
        return (b.total_marks || 0) - (a.total_marks || 0);
      }
      if (sortBy === "questions") {
        return (b.question_count || 0) - (a.question_count || 0);
      }
      return 0;
    });
  }, [papers, searchQuery, selectedSubject, showFavoritesOnly, sortBy]);

  const getSubjectBadgeVariant = (subject: string) => {
    switch (subject?.toLowerCase()) {
      case "physics":
        return "physics" as const;
      case "chemistry":
        return "chemistry" as const;
      case "mathematics":
        return "mathematics" as const;
      case "biology":
        return "biology" as const;
      case "computer science":
        return "computer-science" as const;
      default:
        return "outline" as const;
    }
  };

  return (
    <div className="space-y-6 max-w-6xl mx-auto py-2">
      {/* Toast Notification */}
      {toastMessage && (
        <div
          className={`fixed bottom-6 right-6 z-50 p-4 rounded-xl shadow-lg border text-xs font-medium flex items-center gap-2 transition-all animate-in fade-in slide-in-from-bottom-2 ${
            toastMessage.type === "success"
              ? "bg-emerald-950/90 border-emerald-500/40 text-emerald-200"
              : "bg-rose-950/90 border-rose-500/40 text-rose-200"
          }`}
        >
          {toastMessage.type === "success" ? (
            <CheckCircle2 className="h-4 w-4 text-emerald-400" />
          ) : (
            <AlertCircle className="h-4 w-4 text-rose-400" />
          )}
          <span>{toastMessage.text}</span>
        </div>
      )}

      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">
              Recent Papers Archive
            </h1>
            <Badge variant="outline" className="text-primary border-primary/30 bg-primary/10 text-xs">
              Saved Papers ({papers.length})
            </Badge>
          </div>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Manage, duplicate, edit in Studio, and export previously generated Punjab Board assessments
          </p>
        </div>

        {/* Global Toolbar Actions */}
        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportArchiveJson}
            disabled={papers.length === 0}
            className="gap-1.5 text-xs"
            title="Export all papers to JSON"
          >
            <FileDown className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Export History</span>
          </Button>

          <input
            type="file"
            ref={fileInputRef}
            accept=".json"
            className="hidden"
            onChange={handleImportArchiveJson}
          />
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => fileInputRef.current?.click()}
            className="gap-1.5 text-xs"
          >
            <Upload className="h-3.5 w-3.5" />
            <span className="hidden sm:inline">Import Archive</span>
          </Button>

          {papers.length > 0 && (
            <Button
              variant="ghost"
              size="sm"
              onClick={handleClearAll}
              className="text-xs text-muted-foreground hover:text-destructive"
              title="Clear all saved papers"
            >
              <Trash2 className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">Clear Archive</span>
            </Button>
          )}

          <Link href="/generate">
            <Button size="sm" className="gap-1.5 shadow-xs text-xs">
              <Sparkles className="h-3.5 w-3.5" />
              <span>Create New Test</span>
            </Button>
          </Link>
        </div>
      </div>

      {/* Filter & Search Bar */}
      <Card className="border-border/80 shadow-2xs">
        <CardContent className="p-4 space-y-3">
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
            {/* Search Input */}
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                type="text"
                placeholder="Filter saved papers by title, subject, or chapter..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 text-xs"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery("")}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-muted-foreground hover:text-foreground"
                >
                  Clear
                </button>
              )}
            </div>

            {/* Sort Dropdown */}
            <div className="flex items-center gap-2 shrink-0">
              <SlidersHorizontal className="h-3.5 w-3.5 text-muted-foreground" />
              <div className="relative">
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as SortOption)}
                  className="appearance-none rounded-lg border border-border bg-card px-2.5 py-1.5 pr-7 text-xs text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary shadow-2xs transition-all cursor-pointer"
                >
                  <option value="newest" className="bg-card text-foreground">Sort: Newest First</option>
                  <option value="oldest" className="bg-card text-foreground">Sort: Oldest First</option>
                  <option value="highest-marks" className="bg-card text-foreground">Sort: Highest Marks</option>
                  <option value="questions" className="bg-card text-foreground">Sort: Question Count</option>
                </select>
                <ChevronDown className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
              </div>
            </div>
          </div>

          {/* Subject Pills & Favorites Toggle */}
          <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-xs font-semibold text-muted-foreground mr-1">Subject:</span>
              {["all", "Chemistry", "Physics", "Mathematics", "Biology", "Computer Science"].map((subj) => (
                <button
                  key={subj}
                  type="button"
                  onClick={() => setSelectedSubject(subj)}
                  className={cn(
                    "px-2.5 py-1 rounded-md text-xs font-medium transition-colors border",
                    selectedSubject === subj
                      ? "bg-primary text-primary-foreground border-primary font-semibold shadow-2xs"
                      : "bg-card text-muted-foreground border-border hover:bg-muted"
                  )}
                >
                  {subj === "all" ? "All Subjects" : subj}
                </button>
              ))}
            </div>

            {/* Favorites Filter */}
            <button
              type="button"
              onClick={() => setShowFavoritesOnly(!showFavoritesOnly)}
              className={cn(
                "px-2.5 py-1 rounded-md text-xs font-medium transition-colors border flex items-center gap-1",
                showFavoritesOnly
                  ? "bg-amber-500/20 text-amber-700 dark:text-amber-300 border-amber-500/40 font-semibold"
                  : "bg-card text-muted-foreground border-border hover:bg-muted"
              )}
            >
              <Star className={`h-3 w-3 ${showFavoritesOnly ? "fill-amber-500 text-amber-500" : ""}`} />
              <span>Favorites Only</span>
            </button>
          </div>
        </CardContent>
      </Card>

      {/* Papers Grid / List */}
      <div className="space-y-3">
        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <span>Showing {filteredAndSortedPapers.length} of {papers.length} Saved Papers</span>
          <span>Punjab & Federal Curriculum Standard (Classes 9–12)</span>
        </div>

        {filteredAndSortedPapers.length > 0 ? (
          <div className="space-y-3">
            {filteredAndSortedPapers.map((paper) => {
              const test = paper.test_data;
              const mcqCount = paper.mcq_count ?? (test?.mcqs || []).length;
              const shortCount = paper.short_count ?? (test?.short_questions || []).length;
              const longCount = paper.long_count ?? (test?.long_questions || []).length;
              const totalQ = paper.question_count ?? (mcqCount + shortCount + longCount);

              return (
                <Card
                  key={paper.id}
                  className="border-border/80 shadow-2xs hover:border-primary/40 transition-colors"
                >
                  <CardContent className="p-4 sm:p-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
                    {/* Left: Metadata */}
                    <div className="space-y-2 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge variant={getSubjectBadgeVariant(paper.subject)} size="sm">
                          {paper.subject}
                        </Badge>
                        <Badge variant="outline" size="sm" className="text-[10px] font-bold bg-muted/40">
                          Class {paper.grade || test?.grade || 9}
                        </Badge>
                        <h3 className="font-bold text-sm text-foreground">
                          {paper.title || paper.test_title || test?.test_title || "Examination Paper"}
                        </h3>
                        <button
                          type="button"
                          onClick={() => handleToggleFavorite(paper.id)}
                          className="text-muted-foreground hover:text-amber-500 transition-colors p-0.5"
                          title={paper.is_favorite ? "Remove from favorites" : "Add to favorites"}
                        >
                          <Star
                            className={`h-4 w-4 ${
                              paper.is_favorite
                                ? "fill-amber-500 text-amber-500"
                                : "text-muted-foreground/60"
                            }`}
                          />
                        </button>
                      </div>

                      {/* Chapter / Topic & Stats */}
                      <p className="text-xs text-muted-foreground flex flex-wrap items-center gap-2">
                        <span className="font-medium text-foreground">
                          {test?.chapter_or_topic || paper.chapter_or_topic || "Curriculum Chapter"}
                        </span>
                        <span>&bull;</span>
                        <span className="font-mono font-semibold text-foreground">
                          {paper.total_marks || test?.total_marks || 25} Total Marks
                        </span>
                        <span>&bull;</span>
                        <span>{test?.time_allowed || "45 Minutes"}</span>
                      </p>

                      {/* Breakdown Pills */}
                      <div className="flex flex-wrap items-center gap-1.5 text-[11px] font-mono">
                        <span className="px-2 py-0.5 rounded bg-muted text-muted-foreground">
                          {mcqCount} MCQs
                        </span>
                        <span className="px-2 py-0.5 rounded bg-muted text-muted-foreground">
                          {shortCount} Short Qs
                        </span>
                        <span className="px-2 py-0.5 rounded bg-muted text-muted-foreground">
                          {longCount} Long Qs
                        </span>
                        <span className="px-2 py-0.5 rounded bg-primary/10 text-primary font-semibold">
                          {totalQ} Total Questions
                        </span>
                        <span className="text-muted-foreground font-sans pl-1">
                          &bull; Generated: {formatDate(paper.created_at)}
                        </span>
                      </div>
                    </div>

                    {/* Right: Actions */}
                    <div className="flex flex-wrap items-center gap-2 shrink-0 self-start md:self-center">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleOpenInStudio(paper)}
                        className="text-xs h-8 gap-1.5"
                        title="Open paper in Split-Screen Crafting Studio"
                      >
                        <FolderOpen className="h-3.5 w-3.5 text-primary" />
                        <span>Studio</span>
                      </Button>

                      <Button
                        size="sm"
                        onClick={() => handleExportPdf(paper)}
                        className="text-xs h-8 gap-1.5 shadow-xs"
                        title="Preview & Export Vector PDF"
                      >
                        <Download className="h-3.5 w-3.5" />
                        <span>PDF</span>
                      </Button>

                      <Button
                        variant="ghost"
                        size="icon-sm"
                        onClick={() => handleDuplicate(paper)}
                        className="h-8 w-8 text-muted-foreground hover:text-foreground"
                        title="Duplicate paper"
                      >
                        <Copy className="h-3.5 w-3.5" />
                      </Button>

                      <Button
                        variant="ghost"
                        size="icon-sm"
                        onClick={() => handleDelete(paper.id, paper.title || "Paper")}
                        className="h-8 w-8 text-muted-foreground hover:text-destructive"
                        title="Delete paper"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        ) : (
          <Card className="border-border/80 p-8 text-center space-y-3">
            <div className="h-12 w-12 rounded-full bg-muted flex items-center justify-center mx-auto text-muted-foreground">
              <Clock className="h-6 w-6" />
            </div>
            <div>
              <p className="text-sm font-semibold text-foreground">
                {papers.length === 0 ? "No recent papers recorded" : "No papers match current filters"}
              </p>
              <p className="text-xs text-muted-foreground max-w-sm mx-auto">
                {papers.length === 0
                  ? "Generate your first assessment paper in Studio to start building your persistent history archive."
                  : "Try resetting your search query or subject filters to view all archived papers."}
              </p>
            </div>
            {papers.length === 0 ? (
              <Link href="/generate">
                <Button size="sm" className="gap-1.5 shadow-xs">
                  <Sparkles className="h-3.5 w-3.5" />
                  <span>Create Assessment Paper</span>
                </Button>
              </Link>
            ) : (
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setSearchQuery("");
                  setSelectedSubject("all");
                  setShowFavoritesOnly(false);
                }}
                className="text-xs"
              >
                Reset Filters
              </Button>
            )}
          </Card>
        )}
      </div>
    </div>
  );
}
