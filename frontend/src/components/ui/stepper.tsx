"use client";

import * as React from "react";
import { Minus, Plus, Check, Loader2 } from "lucide-react";
import { Button } from "./button";
import { Badge } from "./badge";
import { cn } from "@/lib/utils";

/**
 * 1. Numeric Stepper for Question Counts
 */
export interface NumberStepperProps {
  value: number;
  min?: number;
  max?: number;
  step?: number;
  marksPerUnit?: number;
  label?: string;
  onChange: (val: number) => void;
  className?: string;
  disabled?: boolean;
}

export function NumberStepper({
  value,
  min = 0,
  max = 20,
  step = 1,
  marksPerUnit,
  label,
  onChange,
  className,
  disabled = false,
}: NumberStepperProps) {
  const handleDecrement = () => {
    if (value - step >= min) {
      onChange(value - step);
    }
  };

  const handleIncrement = () => {
    if (value + step <= max) {
      onChange(value + step);
    }
  };

  const calculatedMarks = marksPerUnit !== undefined ? value * marksPerUnit : null;

  return (
    <div className={cn("flex flex-col space-y-2", className)}>
      {label && (
        <div className="flex items-center justify-between text-sm font-medium">
          <span className="text-foreground">{label}</span>
          {calculatedMarks !== null && (
            <Badge variant="outline" size="sm" className="font-mono text-xs">
              {calculatedMarks} Marks ({marksPerUnit}m each)
            </Badge>
          )}
        </div>
      )}
      <div className="flex items-center gap-2">
        <Button
          type="button"
          variant="outline"
          size="icon-sm"
          onClick={handleDecrement}
          disabled={disabled || value <= min}
          className="h-9 w-9 rounded-lg border-input hover:bg-accent"
          aria-label="Decrease"
        >
          <Minus className="h-4 w-4" />
        </Button>
        <div className="flex flex-1 items-center justify-center rounded-lg border border-input bg-card px-3 py-1.5 text-center font-mono text-base font-semibold text-foreground shadow-xs">
          {value}
        </div>
        <Button
          type="button"
          variant="outline"
          size="icon-sm"
          onClick={handleIncrement}
          disabled={disabled || value >= max}
          className="h-9 w-9 rounded-lg border-input hover:bg-accent"
          aria-label="Increase"
        >
          <Plus className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

/**
 * 2. Visual Multi-Stage Progress Stepper for Generation Pipeline
 */
export interface StepItem {
  step: number;
  title: string;
  subtitle?: string;
  description?: string;
}

export interface StepProgressProps {
  steps: readonly StepItem[] | StepItem[];
  currentStep: number; // 1-indexed
  isComplete?: boolean;
  hasError?: boolean;
  className?: string;
}

export function StepProgress({
  steps,
  currentStep,
  isComplete = false,
  hasError = false,
  className,
}: StepProgressProps) {
  return (
    <div className={cn("space-y-4 py-2", className)}>
      {steps.map((item, index) => {
        const stepNum = index + 1;
        const isDone = isComplete || stepNum < currentStep;
        const isActive = !isComplete && stepNum === currentStep;
        const isPending = stepNum > currentStep;

        return (
          <div key={item.step} className="flex items-start gap-3.5 relative">
            {/* Connecting Vertical Line */}
            {index < steps.length - 1 && (
              <div
                className={cn(
                  "absolute left-4 top-8 -bottom-4 w-0.5 transition-colors duration-300",
                  isDone ? "bg-primary" : "bg-border"
                )}
              />
            )}

            {/* Step Icon Badge */}
            <div
              className={cn(
                "relative z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 text-xs font-bold transition-all duration-300",
                isDone && "border-primary bg-primary text-primary-foreground shadow-sm",
                isActive && !hasError && "border-primary bg-primary/10 text-primary animate-pulse ring-4 ring-primary/20",
                isActive && hasError && "border-destructive bg-destructive/10 text-destructive ring-4 ring-destructive/20",
                isPending && "border-border bg-muted text-muted-foreground"
              )}
            >
              {isDone ? (
                <Check className="h-4 w-4 stroke-[3]" />
              ) : isActive && !hasError ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                stepNum
              )}
            </div>

            {/* Step Content */}
            <div className="flex flex-col pt-0.5">
              <span
                className={cn(
                  "text-sm font-semibold transition-colors",
                  isActive ? "text-primary dark:text-primary font-bold" : isDone ? "text-foreground" : "text-muted-foreground"
                )}
              >
                {item.title}
              </span>
              {(item.subtitle || item.description) && (
                <span className="text-xs text-muted-foreground leading-relaxed mt-0.5">
                  {item.subtitle || item.description}
                </span>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
