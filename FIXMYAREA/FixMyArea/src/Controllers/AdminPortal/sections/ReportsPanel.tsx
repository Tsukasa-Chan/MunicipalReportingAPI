import { useMemo, useState } from "react";
import { Download, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { Issue, Report } from "@/Models/municipal";
import { filterReports } from "@/Services/municipal/logic";
import { downloadReportsCsv } from "@/Services/municipal/exportCsv";
import { EmptyState, PanelHeader, ReportPhoto, formatDateTime } from "./common";

interface Props {
  reports: Report[];
  issues: Issue[];
  onOpenIssue: (id: string) => void;
}

/** Read-only list of every resident report. Staff inspect reports; they never edit or delete them. */
export default function ReportsPanel({ reports, issues, onOpenIssue }: Props) {
  const [search, setSearch] = useState("");
  const [open, setOpen] = useState<Report | null>(null);
  const issueById = useMemo(() => new Map(issues.map((i) => [i.id, i] as const)), [issues]);
  const visible = useMemo(() => filterReports(reports, issues, search), [reports, issues, search]);
  const openIssue = open ? issueById.get(open.issueId) : undefined;

  return (
    <div>
      <PanelHeader title="Reports" description="Individual resident submissions. They are grouped into issues automatically.">
        <Button
          variant="outline"
          size="sm"
          disabled={visible.length === 0}
          title="Download the reports currently shown as a PDF file"
          onClick={() => downloadReportsCsv(visible, issues)}
        >
          <Download className="size-4" /> Download PDF
        </Button>
      </PanelHeader>

      <div className="relative mb-4 max-w-md">
        <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
        <Input aria-label="Search reports" className="pl-9" placeholder="Search resident, description, issue…" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      {reports.length === 0 ? (
        <EmptyState title="No reports yet" hint="Reports appear here as soon as residents submit them." />
      ) : visible.length === 0 ? (
        <EmptyState title="No reports match your search" />
      ) : (
        <div className="rounded-lg border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Report</TableHead>
                <TableHead>Issue</TableHead>
                <TableHead>Resident</TableHead>
                <TableHead>Description</TableHead>
                <TableHead>Submitted</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {visible.map((r) => {
                const issue = issueById.get(r.issueId);
                return (
                  <TableRow key={r.id} className="cursor-pointer" onClick={() => setOpen(r)}>
                    <TableCell className="font-mono text-xs font-semibold">{r.id}</TableCell>
                    <TableCell onClick={(e) => e.stopPropagation()}>
                      {issue ? (
                        <button type="button" className="text-left text-sm font-medium underline-offset-2 hover:underline" onClick={() => onOpenIssue(issue.id)}>
                          <span className="font-mono text-xs">{issue.issueNumber}</span>
                          <span className="block text-xs font-normal text-muted-foreground">{issue.issueType}</span>
                        </button>
                      ) : "—"}
                    </TableCell>
                    <TableCell>{r.residentName}</TableCell>
                    <TableCell className="max-w-md truncate">{r.description}</TableCell>
                    <TableCell className="whitespace-nowrap">{formatDateTime(r.submittedAt)}</TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      )}
      <p className="mt-2 text-xs text-muted-foreground">Showing {visible.length} of {reports.length} report{reports.length === 1 ? "" : "s"}.</p>

      <Dialog open={!!open} onOpenChange={(o) => !o && setOpen(null)}>
        <DialogContent className="max-w-xl">
          {open && (
            <>
              <DialogHeader>
                <DialogTitle>Report <span className="font-mono">{open.id}</span></DialogTitle>
                <DialogDescription>{open.residentName} · {formatDateTime(open.submittedAt)}</DialogDescription>
              </DialogHeader>
              <ReportPhoto url={open.photoUrl} className="max-h-64 w-full" />
              <p className="text-sm">{open.description}</p>
              <p className="text-xs text-muted-foreground">Location: {open.location}</p>
              {openIssue && (
                <button type="button" className="text-left text-sm font-semibold underline underline-offset-2" onClick={() => { setOpen(null); onOpenIssue(openIssue.id); }}>
                  Part of {openIssue.issueNumber} · {openIssue.issueType} ({openIssue.reportCount} report{openIssue.reportCount === 1 ? "" : "s"}) →
                </button>
              )}
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
