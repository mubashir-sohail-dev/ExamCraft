import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: {
          DEFAULT: "hsl(var(--border))",
          subtle: "hsl(var(--border-subtle))",
        },
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
          container: "hsl(var(--primary-container))",
          "container-foreground": "hsl(var(--primary-container-foreground))",
          fixed: "hsl(var(--primary-fixed))",
          "fixed-dim": "hsl(var(--primary-fixed-dim))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
          container: "hsl(var(--secondary-container))",
          "container-foreground": "hsl(var(--secondary-container-foreground))",
        },
        tertiary: {
          DEFAULT: "hsl(var(--tertiary))",
          foreground: "hsl(var(--tertiary-foreground))",
          container: "hsl(var(--tertiary-container))",
          "container-foreground": "hsl(var(--tertiary-container-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
          container: "hsl(var(--error-container))",
          "container-foreground": "hsl(var(--on-error-container))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        surface: {
          lowest: "hsl(var(--surface-lowest))",
          low: "hsl(var(--surface-low))",
          container: "hsl(var(--surface-container))",
          high: "hsl(var(--surface-high))",
          highest: "hsl(var(--surface-highest))",
        },
        // Direct subject aliases
        physics: {
          DEFAULT: "var(--physics-color)",
          bg: "var(--physics-bg)",
          border: "var(--physics-border)",
        },
        chemistry: {
          DEFAULT: "var(--chemistry-color)",
          bg: "var(--chemistry-bg)",
          border: "var(--chemistry-border)",
        },
        mathematics: {
          DEFAULT: "var(--math-color)",
          bg: "var(--math-bg)",
          border: "var(--math-border)",
        },
        math: {
          DEFAULT: "var(--math-color)",
          bg: "var(--math-bg)",
          border: "var(--math-border)",
        },
        biology: {
          DEFAULT: "var(--biology-color)",
          bg: "var(--biology-bg)",
          border: "var(--biology-border)",
        },
        computerscience: {
          DEFAULT: "var(--cs-color)",
          bg: "var(--cs-bg)",
          border: "var(--cs-border)",
        },
        cs: {
          DEFAULT: "var(--cs-color)",
          bg: "var(--cs-bg)",
          border: "var(--cs-border)",
        },
        // Subject nested object for subject-physics etc.
        subject: {
          physics: {
            DEFAULT: "hsl(var(--subject-physics))",
          },
          chemistry: {
            DEFAULT: "hsl(var(--subject-chemistry))",
          },
          mathematics: {
            DEFAULT: "hsl(var(--subject-mathematics))",
          },
          biology: {
            DEFAULT: "hsl(var(--subject-biology))",
          },
          computer: {
            DEFAULT: "hsl(var(--subject-computer))",
          },
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        xl: "calc(var(--radius) + 4px)",
        "2xl": "calc(var(--radius) + 8px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "pulse-glow": {
          "0%, 100%": { opacity: "1", transform: "scale(1)" },
          "50%": { opacity: "0.7", transform: "scale(1.05)" },
        },
        "spin-slow": {
          from: { transform: "rotate(0deg)" },
          to: { transform: "rotate(360deg)" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "pulse-glow": "pulse-glow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        "spin-slow": "spin-slow 8s linear infinite",
      },
    },
  },
  plugins: [tailwindcssAnimate],
};

export default config;
