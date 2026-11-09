import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/Helpers/utils";
import type { IssueStatus, PortalStats } from "@/Models/municipal";
import { ISSUE_STATUSES } from "@/Models/municipal";
import { PanelHeader, StatusBadge } from "./common";

const BAR_COLOR: Record<IssueStatus, string> = {
  Reported: "bg-amber-500",
  "In Progress": "bg-sky-500",
  Fixed: "bg-emerald-500",
};

function Kpi({ label, value, tone }: { label: string; value: number; tone?: "warn" }) {
  return (
    <Card className={cn(tone === "warn" && value > 0 && "border-amber-400")}>
      <CardContent className="p-4">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</p>
        <p className="mt-1 text-3xl font-extrabold text-foreground">{value}</p>
      </CardContent>
    </Card>
  );
}

function Bar({ value, max, className }: { value: number; max: number; className: string }) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0;
  return (
    <div className="h-2 w-full rounded-full bg-muted" role="presentation">
      <div className={cn("h-2 rounded-full", className)} style={{ width: `${pct}%` }} />
    </div>
  );
}

export default function StatsPanel({ stats, onOpenIssue }: { stats: PortalStats; onOpenIssue: (id: string) => void }) {
  const maxStatus = Math.max(1, ...ISSUE_STATUSES.map((s) => stats.byStatus[s]));
  const maxCategory = Math.max(1, ...stats.byCategory.map((c) => c.issues));

  return (
    <div>
      <PanelHeader title="Overview" description="Where municipal issues stand right now." />

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <Kpi label="Issues" value={stats.totalIssues} />
        <Kpi label="Resident reports" value={stats.totalReports} />
        <Kpi label="Awaiting a supervisor" value={stats.unassignedIssues} tone="warn" />
        <Kpi label="In progress" value={stats.byStatus["In Progress"]} />
        <Kpi label="Fixed" value={stats.byStatus.Fixed} />
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader><CardTitle className="text-base">Issues by status</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {ISSUE_STATUSES.map((s) => (
              <div key={s} className="space-y-1">
                <div className="flex items-center justify-between text-sm">
                  <StatusBadge status={s} />
                  <span className="font-semibold">{stats.byStatus[s]}</span>
                </div>
                <Bar value={stats.byStatus[s]} max={maxStatus} className={BAR_COLOR[s]} />
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Issues by category</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {stats.byCategory.length === 0 && <p className="text-sm text-muted-foreground">No issues yet.</p>}
            {stats.byCategory.map((c) => (
              <div key={c.category} className="space-y-1">
                <div className="flex items-center justify-between gap-2 text-sm">
                  <span className="font-medium">{c.category}</span>
                  <span className="text-muted-foreground">
                    <strong className="text-foreground">{c.issues}</strong> issue{c.issues === 1 ? "" : "s"} · {c.reports} report{c.reports === 1 ? "" : "s"}
                  </span>
                </div>
                <Bar value={c.issues} max={maxCategory} className="bg-primary" />
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Most-reported open issues</CardTitle></CardHeader>
          <CardContent>
            {stats.topIssues.length === 0 && <p className="text-sm text-muted-foreground">No open issues.</p>}
            <ul className="divide-y">
              {stats.topIssues.map((i) => (
                <li key={i.id}>
                  <button type="button" onClick={() => onOpenIssue(i.id)} className="flex w-full items-center justify-between gap-3 py-2.5 text-left hover:bg-muted/50">
                    <span className="min-w-0">
                      <span className="block truncate text-sm font-medium">{i.issueType}</span>
                      <span className="block truncate text-xs text-muted-foreground">{i.issueNumber} · {i.location}</span>
                    </span>
                    <span className="shrink-0 rounded-full bg-primary px-2.5 py-0.5 text-xs font-bold text-primary-foreground">
                      {i.reportCount} report{i.reportCount === 1 ? "" : "s"}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Supervisor workload</CardTitle></CardHeader>
          <CardContent>
            {stats.supervisorLoad.length === 0 && <p className="text-sm text-muted-foreground">No supervisors yet. Promote a user on the Users tab.</p>}
            <ul className="divide-y">
              {stats.supervisorLoad.map((s) => (
                <li key={s.supervisorId} className="flex items-center justify-between gap-3 py-2.5 text-sm">
                  <span className="font-medium">{s.name}</span>
                  <span className="text-muted-foreground">
                    <strong className="text-foreground">{s.open}</strong> open · {s.fixed} fixed
                  </span>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
