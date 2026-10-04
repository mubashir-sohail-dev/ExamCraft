"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { X, GraduationCap } from "lucide-react";
import { cn } from "@/lib/utils";
import { NAV_ITEMS } from "./sidebar";
import { SUBJECTS_CONFIG } from "@/lib/constants";
import { SubjectType } from "@/types/exam";
import { TelemetryBadge } from "./telemetry-badge";
import { ThemeToggle } from "./theme-toggle";
import { useTestDraft } from "@/context/TestDraftContext";

export interface MobileDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export function MobileDrawer({ isOpen, onClose }: MobileDrawerProps) {
  const pathname = usePathname();
  const { activeGrade } = useTestDraft();
  const displayGrade = activeGrade || 9;

  // Close drawer on ESC key
  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  // Prevent background body scrolling when drawer is open
  React.useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex md:hidden" role="dialog" aria-modal="true">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/60 backdrop-blur-xs transition-opacity duration-300 animate-in fade-in"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Drawer Panel */}
      <div className="relative flex w-4/5 max-w-xs flex-1 flex-col bg-card border-r border-border shadow-xl duration-300 animate-in slide-in-from-left">
        {/* Header */}
        <div className="flex h-16 items-center justify-between px-4 border-b border-border">
          <Link
            href="/dashboard"
            onClick={onClose}
            className="flex items-center gap-2.5"
          >
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
              <GraduationCap className="h-4 w-4" />
            </div>
            <div>
              <span className="font-bold text-sm text-foreground">ExamCraft AI</span>
              <span className="ml-1.5 rounded-md bg-primary/10 px-1 py-0.2 text-[9px] font-semibold text-primary">
                Class {displayGrade}
              </span>
            </div>
          </Link>

          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
            aria-label="Close navigation menu"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation Links */}
        <div className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
          <nav className="space-y-1">
            {NAV_ITEMS.map((item) => {
              const Icon = item.icon;
              const isActive =
                item.href === "/dashboard"
                  ? pathname === "/dashboard" || pathname === "/"
                  : pathname === item.href || pathname.startsWith(`${item.href}/`);

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  prefetch={true}
                  onClick={onClose}
                  className={cn(
                    "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                    isActive
                      ? "bg-primary/10 text-primary font-semibold dark:bg-primary/20 dark:text-primary"
                      : "text-muted-foreground hover:bg-muted/70 hover:text-foreground"
                  )}
                >
                  <Icon
                    className={cn(
                      "h-4 w-4 shrink-0",
                      isActive ? "text-primary" : "text-muted-foreground"
                    )}
                  />
                  <span className="flex-1">{item.label}</span>
                  {item.badge && (
                    <span className="rounded-full bg-secondary/15 px-2 py-0.5 text-[10px] font-semibold text-secondary">
                      {item.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* Subjects Section */}
          <div className="pt-4 mt-4 border-t border-border/60">
            <span className="px-3 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Class {displayGrade} Subjects
            </span>
            <div className="mt-2 space-y-1">
              {(Object.keys(SUBJECTS_CONFIG) as SubjectType[]).map((subjectKey) => {
                const sub = SUBJECTS_CONFIG[subjectKey];
                const SubIcon = sub.icon;
                return (
                  <Link
                    key={sub.name}
                    href={`/generate?subject=${encodeURIComponent(sub.name)}`}
                    onClick={onClose}
                    className="flex items-center gap-2.5 rounded-lg px-3 py-2 text-xs transition-colors hover:bg-muted/60"
                  >
                    <div
                      className="flex h-5 w-5 items-center justify-center rounded-md text-xs"
                      style={{ backgroundColor: sub.bgLight, color: sub.lightColor }}
                    >
                      <SubIcon className="h-3 w-3" />
                    </div>
                    <span className="text-muted-foreground hover:text-foreground font-medium">
                      {sub.name}
                    </span>
                  </Link>
                );
              })}
            </div>
          </div>
        </div>

        {/* Footer controls */}
        <div className="p-3 border-t border-border/80 flex items-center justify-between bg-muted/20">
          <TelemetryBadge />
          <ThemeToggle />
        </div>
      </div>
    </div>
  );
}
