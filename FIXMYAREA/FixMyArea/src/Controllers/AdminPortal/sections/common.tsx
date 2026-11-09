import { useState } from "react";
import { Inbox } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/Helpers/utils";
import type { IssueStatus } from "@/Models/municipal";

const STATUS_STYLES: Record<IssueStatus, string> = {
  Reported: "bg-amber-100 text-amber-900 border-amber-300 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800",
  "In Progress": "bg-sky-100 text-sky-900 border-sky-300 dark:bg-sky-950/40 dark:text-sky-300 dark:border-sky-800",
  Fixed: "bg-emerald-100 text-emerald-900 border-emerald-300 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800",
};

export function StatusBadge({ status }: { status: IssueStatus }) {
  return (
    <Badge variant="outline" className={cn("font-semibold whitespace-nowrap", STATUS_STYLES[status])}>
      {status}
    </Badge>
  );
}

export function formatDateTime(iso: string | null | undefined): string {
  return iso ? iso.slice(0, 16).replace("T", " ") : "—";
}

export function formatDate(iso: string | null | undefined): string {
  return iso ? iso.slice(0, 10) : "—";
}

export function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : "Something went wrong. Please try again.";
}

export function EmptyState({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 rounded-lg border border-dashed py-14 text-center">
      <Inbox className="size-8 text-muted-foreground" />
      <p className="font-semibold text-foreground">{title}</p>
      {hint && <p className="max-w-sm text-sm text-muted-foreground">{hint}</p>}
    </div>
  );
}

/** Report photo that quietly disappears if the image can't be loaded. */
export function ReportPhoto({ url, className }: { url: string; className?: string }) {
  const [failed, setFailed] = useState(false);
  if (!url || failed) return null;
  return (
    <img
      src={url}
      alt="Photo submitted with the report"
      loading="lazy"
      onError={() => setFailed(true)}
      className={cn("rounded-md border object-cover", className)}
    />
  );
}

export function PanelHeader({ title, description, children }: { title: string; description?: string; children?: React.ReactNode }) {
  return (
    <div className="mb-4 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h2 className="text-xl font-bold tracking-tight text-foreground">{title}</h2>
        {description && <p className="text-sm text-muted-foreground">{description}</p>}
      </div>
      {children}
    </div>
  );
}
