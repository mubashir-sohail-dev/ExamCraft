"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Menu, Sparkles, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { TelemetryBadge } from "./telemetry-badge";
import { ThemeToggle } from "./theme-toggle";
import { ClassSwitcher } from "./class-switcher";
import { cn } from "@/lib/utils";

export interface HeaderProps {
  className?: string;
  onOpenMobileMenu?: () => void;
}

const ROUTE_TITLES: Record<string, { title: string; subtitle?: string; parent?: string }> = {
  "/": { title: "Dashboard", subtitle: "Overview & Assessment Metrics" },
  "/dashboard": { title: "Dashboard", subtitle: "Assessment Overview & Metrics" },
  "/generate": { title: "Test Generator", subtitle: "Configure & Generate Assessment Papers" },
  "/review": { title: "Split-Screen Studio", subtitle: "Interactive Question Editor & Live A4 Canvas" },
  "/pdf-preview": { title: "PDF Preview & Export", subtitle: "High-Resolution Examination Viewer" },
  "/recent-papers": { title: "Recent Papers", subtitle: "Saved & Exported Assessment Archive" },
  "/question-bank": { title: "Question Bank", subtitle: "Syllabus Question Explorer & Repository" },
  "/upload": { title: "Textbook Ingestion", subtitle: "Upload Official Curriculum PDF" },
  "/upload/status": { title: "Ingestion Status", subtitle: "Real-time Vector Processing Timeline", parent: "Upload" },
  "/settings": { title: "Settings", subtitle: "Backend Endpoint & Preference Controls" },
  "/about": { title: "About ExamCraft AI", subtitle: "Architecture, RAG Pipeline & Specifications" },
};

export function Header({ className, onOpenMobileMenu }: HeaderProps) {
  const pathname = usePathname();

  // Look up current route title
  const currentRouteInfo = ROUTE_TITLES[pathname] || {
    title: pathname.split("/")[1] ? pathname.split("/")[1].charAt(0).toUpperCase() + pathname.split("/")[1].slice(1) : "ExamCraft",
    subtitle: "Curriculum Assessment Studio",
  };

  return (
    <header
      className={cn(
        "sticky top-0 z-30 flex h-16 w-full shrink-0 items-center justify-between border-b border-border/80 bg-background/95 px-4 backdrop-blur-md transition-all sm:px-6",
        className
      )}
    >
      {/* Left section: Hamburger button & Breadcrumb / Title */}
      <div className="flex items-center gap-3">
        {onOpenMobileMenu && (
          <Button
            variant="ghost"
            size="icon-sm"
            onClick={onOpenMobileMenu}
            className="md:hidden text-muted-foreground hover:text-foreground"
            aria-label="Open mobile navigation"
          >
            <Menu className="h-5 w-5" />
          </Button>
        )}

        <div className="flex flex-col">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground font-medium">
            <span>ExamCraft</span>
            {currentRouteInfo.parent && (
              <>
                <ChevronRight className="h-3 w-3 text-muted-foreground/60" />
                <span>{currentRouteInfo.parent}</span>
              </>
            )}
            <ChevronRight className="h-3 w-3 text-muted-foreground/60" />
            <span className="text-foreground font-semibold">
              {currentRouteInfo.title}
            </span>
          </div>

          <h1 className="text-sm font-bold tracking-tight text-foreground sm:text-base line-clamp-1">
            {currentRouteInfo.title}
          </h1>
        </div>
      </div>

      {/* Right section: Quick action, Class Switcher, Telemetry badge & Theme toggle */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Global Academic Class Switcher */}
        <ClassSwitcher />

        {pathname !== "/generate" && (
          <Link href="/generate" className="hidden sm:inline-flex">
            <Button size="sm" className="gap-1.5 shadow-2xs h-8 text-xs px-3">
              <Sparkles className="h-3.5 w-3.5" />
              <span>Create Paper</span>
            </Button>
          </Link>
        )}

        {/* Live Telemetry Health Badge */}
        <TelemetryBadge />

        <div className="h-4 w-px bg-border/80 hidden sm:block" />

        {/* Theme mode switcher */}
        <ThemeToggle />
      </div>
    </header>
  );
}
