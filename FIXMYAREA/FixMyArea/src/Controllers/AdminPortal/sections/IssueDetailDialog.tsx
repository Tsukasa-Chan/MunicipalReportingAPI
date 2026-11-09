import { useEffect, useState } from "react";
import { LoaderCircle, MapPin, Play, CircleCheck, UserCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { Issue, IssueStatus, PortalUser, Report } from "@/Models/municipal";
import { ReportPhoto, StatusBadge, formatDateTime } from "./common";

interface Props {
  issue: Issue | null;
  reports: Report[];
  supervisors: PortalUser[];
  openLoad: Record<string, number>;
  viewer: PortalUser;
  busyKey: string | null;
  onClose: () => void;
  onAssign: (issueId: string, supervisorId: string) => void;
  onSetStatus: (issueId: string, status: IssueStatus) => void;
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</dt>
      <dd className="mt-0.5 text-sm font-medium text-foreground">{children}</dd>
    </div>
  );
}

export default function IssueDetailDialog({ issue, reports, supervisors, openLoad, viewer, busyKey, onClose, onAssign, onSetStatus }: Props) {
  const [choice, setChoice] = useState("");

  // Reset the picker whenever a different issue is opened or its assignment changes.
  useEffect(() => {
    setChoice(issue?.supervisorId ?? "");
  }, [issue?.id, issue?.supervisorId]);

  if (!issue) return <Dialog open={false} onOpenChange={() => onClose()} />;

  const isAdmin = viewer.role === "Admin";
  const mine = viewer.role === "Supervisor" && issue.supervisorId === viewer.id;
  const issueReports = reports.filter((r) => r.issueId === issue.id).sort((a, b) => a.submittedAt.localeCompare(b.submittedAt));
  const assigning = busyKey === `assign:${issue.id}`;
  const updating = busyKey === `status:${issue.id}`;
  const canAssign = isAdmin && issue.status !== "Fixed";

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[90vh] max-w-3xl overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex flex-wrap items-center gap-2">
            <span className="font-mono text-sm text-muted-foreground">{issue.issueNumber}</span>
            {issue.issueType}
            <StatusBadge status={issue.status} />
          </DialogTitle>
          <DialogDescription className="flex items-center gap-1.5"><MapPin className="size-3.5" />{issue.location}</DialogDescription>
        </DialogHeader>

        <dl className="grid grid-cols-2 gap-4 rounded-lg border bg-muted/30 p-4 sm:grid-cols-3">
          <Field label="Category">{issue.category}</Field>
          <Field label="Specific issue">{issue.issueType}</Field>
          <Field label="Status">{issue.status}</Field>
          <Field label="Resident reports">{issue.reportCount}</Field>
          <Field label="First reported">{formatDateTime(issue.createdAt)}</Field>
          <Field label="Last updated">{formatDateTime(issue.updatedAt)}</Field>
          <Field label="Coordinates"><span className="font-mono text-xs">{issue.latitude.toFixed(4)}, {issue.longitude.toFixed(4)}</span></Field>
          <Field label="Supervisor">{issue.supervisorName ?? <span className="text-amber-700 dark:text-amber-400">Unassigned</span>}</Field>
        </dl>

        {isAdmin && (
          <section className="space-y-2 rounded-lg border p-4" aria-label="Assign supervisor">
            <h3 className="flex items-center gap-2 text-sm font-semibold"><UserCheck className="size-4" />Supervisor</h3>
            {issue.status === "Fixed" ? (
              <p className="text-sm text-muted-foreground">This issue is fixed{issue.supervisorName ? ` by ${issue.supervisorName}` : ""}. Nothing more to assign.</p>
            ) : supervisors.length === 0 ? (
              <p className="text-sm text-muted-foreground">There are no supervisors yet. Promote a user to supervisor on the Users tab first.</p>
            ) : (
              <>
                <div className="flex flex-wrap gap-2">
                  <Select value={choice} onValueChange={setChoice}>
                    <SelectTrigger aria-label="Choose a supervisor" className="w-72"><SelectValue placeholder="Choose a supervisor…" /></SelectTrigger>
                    <SelectContent>
                      {supervisors.map((s) => (
                        <SelectItem key={s.id} value={s.id}>{s.fullName} ({openLoad[s.id] ?? 0} open)</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Button disabled={!canAssign || !choice || choice === issue.supervisorId || assigning} onClick={() => onAssign(issue.id, choice)}>
                    {assigning && <LoaderCircle className="animate-spin" />}
                    {issue.supervisorId ? "Reassign" : "Assign supervisor"}
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground">The supervisor moves the issue to In Progress and Fixed. Admins don't change status.</p>
              </>
            )}
          </section>
        )}

        {mine && (
          <section className="space-y-2 rounded-lg border p-4" aria-label="Update status">
            <h3 className="text-sm font-semibold">Your update</h3>
            {issue.status === "Reported" && (
              <Button disabled={updating} onClick={() => onSetStatus(issue.id, "In Progress")}>{updating ? <LoaderCircle className="animate-spin" /> : <Play />}Start work</Button>
            )}
            {issue.status === "In Progress" && (
              <Button disabled={updating} onClick={() => onSetStatus(issue.id, "Fixed")}>{updating ? <LoaderCircle className="animate-spin" /> : <CircleCheck />}Mark as fixed</Button>
            )}
            {issue.status === "Fixed" && <p className="text-sm text-muted-foreground">You marked this issue as fixed. Thank you.</p>}
          </section>
        )}

        <section aria-label="Resident reports" className="space-y-3">
          <h3 className="text-sm font-semibold">Resident reports ({issueReports.length})</h3>
          {issueReports.length === 0 && <p className="text-sm text-muted-foreground">No reports to show.</p>}
          <ul className="space-y-3">
            {issueReports.map((r) => (
              <li key={r.id} className="flex gap-3 rounded-lg border p-3">
                <ReportPhoto url={r.photoUrl} className="size-20 shrink-0" />
                <div className="min-w-0 space-y-1">
                  <p className="text-xs text-muted-foreground">
                    <span className="font-semibold text-foreground">{r.residentName}</span> · {formatDateTime(r.submittedAt)} · <span className="font-mono">{r.id}</span>
                  </p>
                  <p className="text-sm">{r.description}</p>
                </div>
              </li>
            ))}
          </ul>
        </section>
      </DialogContent>
    </Dialog>
  );
}
