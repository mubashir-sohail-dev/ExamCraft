"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Sparkles,
  Clock,
  UploadCloud,
  Settings,
  Info,
  ChevronLeft,
  ChevronRight,
  GraduationCap,
  Atom,
  FlaskConical,
  Calculator,
  Dna,
  Laptop,
  BookOpen,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useTestDraft } from "@/context/TestDraftContext";

export interface NavItem {
  label: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
}

export const NAV_ITEMS: NavItem[] = [
  {
    label: "Dashboard",
    href: "/dashboard",
    icon: LayoutDashboard,
  },
  {
    label: "Generate",
    href: "/generate",
    icon: Sparkles,
  },
  {
    label: "Question Bank",
    href: "/question-bank",
    icon: BookOpen,
  },
  {
    label: "Recent Papers",
    href: "/recent-papers",
    icon: Clock,
  },
  {
    label: "Upload Textbook",
    href: "/upload",
    icon: UploadCloud,
  },
  {
    label: "Settings",
    href: "/settings",
    icon: Settings,
  },
  {
    label: "About",
    href: "/about",
    icon: Info,
  },
];

const SUBJECT_QUICK_LINKS = [
  { name: "Physics", icon: Atom, colorClass: "text-[#005BBF] dark:text-[#ADC7FF]", bgClass: "bg-[#EBF3FF] dark:bg-[#0A1E3B]" },
  { name: "Chemistry", icon: FlaskConical, colorClass: "text-[#006E2C] dark:text-[#86F898]", bgClass: "bg-[#EAF7EE] dark:bg-[#072410]" },
  { name: "Mathematics", icon: Calculator, colorClass: "text-[#805600] dark:text-[#FFBA45]", bgClass: "bg-[#FFF8EB] dark:bg-[#2B1D00]" },
  { name: "Biology", icon: Dna, colorClass: "text-[#673AB7] dark:text-[#D1C4E9]", bgClass: "bg-[#F5EFFF] dark:bg-[#220E42]" },
  { name: "Computer Science", icon: Laptop, colorClass: "text-[#00838F] dark:text-[#80DEEA]", bgClass: "bg-[#E0F7FA] dark:bg-[#00292E]" },
];

export interface SidebarProps {
  className?: string;
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
}

export function Sidebar({ className, isCollapsed = false, onToggleCollapse }: SidebarProps) {
  const pathname = usePathname();
  const { activeGrade } = useTestDraft();
  const displayGrade = activeGrade || 9;

  return (
    <aside
      className={cn(
        "relative flex flex-col border-r border-border/80 bg-card transition-all duration-300 ease-in-out select-none",
        isCollapsed ? "w-[72px]" : "w-64",
        className
      )}
    >
      {/* Brand Header */}
      <div className="flex h-16 items-center justify-between px-3.5 border-b border-border/80">
        <Link
          href="/dashboard"
          className={cn(
            "flex items-center gap-2.5 overflow-hidden transition-all",
            isCollapsed && "justify-center w-full"
          )}
          title="ExamCraft AI Studio"
        >
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-xs">
            <GraduationCap className="h-5 w-5" />
          </div>

          {!isCollapsed && (
            <div className="flex flex-col truncate">
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-sm tracking-tight text-foreground">
                  ExamCraft AI
                </span>
                <span className="rounded-md bg-primary/10 px-1.5 py-0.25 text-[10px] font-semibold text-primary">
                  Class {displayGrade}
                </span>
              </div>
              <span className="text-[11px] text-muted-foreground truncate">
                Assessment Studio
              </span>
            </div>
          )}
        </Link>
      </div>

      {/* Primary Navigation Links */}
      <div className="flex-1 overflow-y-auto px-2.5 py-3 space-y-1">
        <nav className="space-y-1" aria-label="Main Navigation">
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
                className={cn(
                  "group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors relative",
                  isActive
                    ? "bg-primary/10 text-primary font-semibold dark:bg-primary/20 dark:text-primary"
                    : "text-muted-foreground hover:bg-muted/70 hover:text-foreground",
                  isCollapsed && "justify-center px-2 py-2.5"
                )}
                title={isCollapsed ? item.label : undefined}
              >
                <Icon
                  className={cn(
                    "h-4 w-4 shrink-0 transition-transform group-hover:scale-110",
                    isActive ? "text-primary" : "text-muted-foreground group-hover:text-foreground"
                  )}
                />

                {!isCollapsed && (
                  <span className="truncate flex-1 text-[13px]">{item.label}</span>
                )}

                {!isCollapsed && item.badge && (
                  <span className="rounded-full bg-secondary/15 px-2 py-0.5 text-[10px] font-semibold text-secondary">
                    {item.badge}
                  </span>
                )}

                {isActive && (
                  <span
                    className={cn(
                      "absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 rounded-r-full bg-primary",
                      isCollapsed && "left-0.5"
                    )}
                  />
                )}
              </Link>
            );
          })}
        </nav>

        {/* Quick Subject Shortcuts */}
        <div className="pt-4 mt-4 border-t border-border/60">
          {!isCollapsed ? (
            <div className="px-2 pb-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                Class {displayGrade} Subjects
              </span>
            </div>
          ) : null}

          <div className={cn("space-y-1", isCollapsed && "flex flex-col items-center gap-1")}>
            {SUBJECT_QUICK_LINKS.map((sub) => {
              const SubIcon = sub.icon;
              return (
                <Link
                  key={sub.name}
                  href={`/generate?subject=${encodeURIComponent(sub.name)}`}
                  prefetch={true}
                  className={cn(
                    "group flex items-center gap-2.5 rounded-lg px-2.5 py-1.5 text-xs transition-colors hover:bg-muted/60",
                    isCollapsed && "justify-center p-2"
                  )}
                  title={`Generate ${sub.name} Test`}
                >
                  <div
                    className={cn(
                      "flex h-6 w-6 shrink-0 items-center justify-center rounded-md transition-transform group-hover:scale-105",
                      sub.bgClass,
                      sub.colorClass
                    )}
                  >
                    <SubIcon className="h-3.5 w-3.5" />
                  </div>
                  {!isCollapsed && (
                    <span className="truncate text-muted-foreground group-hover:text-foreground font-medium text-[12px]">
                      {sub.name}
                    </span>
                  )}
                </Link>
              );
            })}
          </div>
        </div>
      </div>

      {/* Collapse Toggle Footer */}
      {onToggleCollapse && (
        <div className="p-2 border-t border-border/80 flex items-center justify-center">
          <Button
            variant="ghost"
            size="sm"
            onClick={onToggleCollapse}
            className={cn(
              "w-full flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground",
              isCollapsed && "justify-center px-0 h-9 w-9"
            )}
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
            title={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {isCollapsed ? (
              <ChevronRight className="h-4 w-4" />
            ) : (
              <>
                <ChevronLeft className="h-4 w-4" />
                <span>Collapse Navigation</span>
              </>
            )}
          </Button>
        </div>
      )}
    </aside>
  );
}
