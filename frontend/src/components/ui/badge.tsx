import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary text-primary-foreground shadow-xs",
        secondary: "border-transparent bg-secondary text-secondary-foreground",
        destructive: "border-transparent bg-destructive text-destructive-foreground",
        outline: "text-foreground border-border",
        success: "border-transparent bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300",
        warning: "border-transparent bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300",
        info: "border-transparent bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-300",
        physics: "border-transparent bg-[#EBF3FF] text-[#005BBF] dark:bg-[#0A1E3B] dark:text-[#ADC7FF]",
        chemistry: "border-transparent bg-[#EAF7EE] text-[#006E2C] dark:bg-[#072410] dark:text-[#86F898]",
        mathematics: "border-transparent bg-[#FFF8EB] text-[#805600] dark:bg-[#2B1D00] dark:text-[#FFBA45]",
        biology: "border-transparent bg-[#F5EFFF] text-[#673AB7] dark:bg-[#220E42] dark:text-[#D1C4E9]",
        "computer-science": "border-transparent bg-[#E0F7FA] text-[#00838F] dark:bg-[#00292E] dark:text-[#80DEEA]",
      },
      size: {
        sm: "px-2 py-0.25 text-[10px]",
        default: "px-2.5 py-0.5 text-xs",
        lg: "px-3.5 py-1 text-sm",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  dot?: boolean;
  pulse?: boolean;
  dotColor?: string;
}

function Badge({ className, variant, size, dot, pulse, dotColor, children, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant, size }), className)} {...props}>
      {dot && (
        <span className="relative flex h-2 w-2">
          {pulse && (
            <span
              className={cn(
                "absolute inline-flex h-full w-full animate-ping rounded-full opacity-75",
                dotColor || "bg-current"
              )}
            />
          )}
          <span
            className={cn("relative inline-flex h-2 w-2 rounded-full", dotColor || "bg-current")}
          />
        </span>
      )}
      {children}
    </div>
  );
}

export { Badge, badgeVariants };
