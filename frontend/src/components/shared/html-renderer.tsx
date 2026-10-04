"use client";

import * as React from "react";
import { cn, formatFormulaHtml } from "@/lib/utils";

interface HtmlRendererProps {
  content: string;
  className?: string;
  as?: "span" | "div" | "p";
}

/**
 * Safely renders text with subscript (<sub>) and superscript (<sup>) HTML tags
 * for chemical formulas (e.g. H<sub>2</sub>O) and mathematical exponents (e.g. x<sup>2</sup>).
 */
export function HtmlRenderer({
  content,
  className,
  as: Component = "span",
}: HtmlRendererProps) {
  if (!content) return null;

  // If there are no HTML tags, render clean plain text for performance
  if (!content.includes("<") && !content.includes("&")) {
    return <Component className={className}>{content}</Component>;
  }

  const sanitizedHtml = formatFormulaHtml(content);

  return (
    <Component
      className={cn("inline-formula", className)}
      dangerouslySetInnerHTML={{ __html: sanitizedHtml }}
    />
  );
}
