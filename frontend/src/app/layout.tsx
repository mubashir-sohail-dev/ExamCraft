import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { TelemetryProvider } from "@/context/TelemetryContext";
import { TestDraftProvider } from "@/context/TestDraftContext";
import { AppShell } from "@/components/shell/app-shell";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "ExamCraft AI — Secondary & Higher Secondary Assessment Studio",
  description:
    "Zero-hallucination examination paper generator & split-screen crafting studio for Classes 9 to 12 (SSC & HSSC).",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning className={inter.variable}>
      <body className="min-h-screen bg-background text-foreground antialiased font-sans">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <TelemetryProvider>
            <TestDraftProvider>
              <AppShell>{children}</AppShell>
            </TestDraftProvider>
          </TelemetryProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
