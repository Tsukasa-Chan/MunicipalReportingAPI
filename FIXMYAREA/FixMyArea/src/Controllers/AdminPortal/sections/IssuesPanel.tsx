import { useMemo, useState } from "react";
import { Download, Play, CircleCheck, Search, UserX } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { Issue, IssueStatus } from "@/Models/municipal";
import { ISSUE_STATUSES } from "@/Models/municipal";
import { EMPTY_ISSUE_FILTERS, filterIssues, type IssueFilters } from "@/Services/municipal/logic";
import { downloadIssuesCsv } from "@/Services/municipal/exportCsv";
import { EmptyState, PanelHeader, StatusBadge, formatDate } from "./common";

interface Props {
  /** "admin" = everything, read-only status. "supervisor" = own issues with status actions. */
  mode: "admin" | "supervisor";
  issues: Issue[];
  busyKey: string | null;
  onOpenIssue: (id: string) => void;
  onSetStatus?: (issueId: string, status: IssueStatus) => void;
}

export default function IssuesPanel({ mode, issues, busyKey, onOpenIssue, onSetStatus }: Props) {
  const [filters, setFilters] = useState<IssueFilters>(EMPTY_ISSUE_FILTERS);
  const isAdmin = mode === "admin";

  const categories = useMemo(() => [...new Set(issues.map((i) => i.category))].sort(), [issues]);
  const visible = useMemo(() => filterIssues(issues, filters), [issues, filters]);
  const set = (patch: Partial<IssueFilters>) => setFilters((f) => ({ ...f, ...patch }));
  const filtering = JSON.stringify(filters) !== JSON.stringify(EMPTY_ISSUE_FILTERS);

  return (
    <div>
      <PanelHeader
        title={isAdmin ? "Issues" : "My Issues"}
        description={
          isAdmin
            ? "Each issue groups every resident report about the same problem. Assign a supervisor to get it fixed."
            : "Issues assigned to you. Start work when you begin, and mark an issue fixed when it is done."
        }
      >
        <Button
          variant="outline"
          size="sm"
          disabled={visible.length === 0}
          title="Download the issues currently shown as a PDF file"
          onClick={() => downloadIssuesCsv(visible)}
        >
          <Download className="size-4" /> Download PDF
        </Button>
      </PanelHeader>

      <div className="mb-4 flex flex-wrap gap-2">
        <div className="relative min-w-52 flex-1">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input aria-label="Search issues" className="pl-9" placeholder="Search issue, category, location…" value={filters.search} onChange={(e) => set({ search: e.target.value })} />
        </div>

        <Select value={filters.status} onValueChange={(v) => set({ status: v as IssueFilters["status"] })}>
          <SelectTrigger aria-label="Filter by status" className="w-40"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All statuses</SelectItem>
            {ISSUE_STATUSES.map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}
          </SelectContent>
        </Select>

        <Select value={filters.category} onValueChange={(v) => set({ category: v })}>
          <SelectTrigger aria-label="Filter by category" className="w-52"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All categories</SelectItem>
            {categories.map((c) => <SelectItem key={c} value={c}>{c}</SelectItem>)}
          </SelectContent>
        </Select>

        {isAdmin && (
          <Select value={filters.assignment} onValueChange={(v) => set({ assignment: v as IssueFilters["assignment"] })}>
            <SelectTrigger aria-label="Filter by assignment" className="w-44"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Any assignment</SelectItem>
              <SelectItem value="unassigned">Unassigned</SelectItem>
              <SelectItem value="assigned">Assigned</SelectItem>
            </SelectContent>
          </Select>
        )}

        {filtering && <Button variant="ghost" onClick={() => setFilters(EMPTY_ISSUE_FILTERS)}>Clear</Button>}
      </div>

      {issues.length === 0 ? (
        <EmptyState
          title={isAdmin ? "No issues yet" : "Nothing assigned to you yet"}
          hint={isAdmin ? "Issues appear automatically when residents submit reports." : "When an administrator assigns you an issue it will show up here."}
        />
      ) : visible.length === 0 ? (
        <EmptyState title="No issues match your filters" hint="Try clearing a filter or searching for something else." />
      ) : (
        <div className="rounded-lg border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Issue</TableHead>
                <TableHead>Category / specific issue</TableHead>
                <TableHead>Location</TableHead>
                <TableHead className="text-center">Reports</TableHead>
                <TableHead>Status</TableHead>
                {isAdmin && <TableHead>Supervisor</TableHead>}
                <TableHead className="text-right">{isAdmin ? "" : "Action"}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {visible.map((i) => {
                const busy = busyKey === `status:${i.id}`;
                return (
                  <TableRow key={i.id} className="cursor-pointer" onClick={() => onOpenIssue(i.id)}>
                    <TableCell>
                      <span className="font-mono text-xs font-semibold">{i.issueNumber}</span>
                      <span className="block text-xs text-muted-foreground">{formatDate(i.createdAt)}</span>
                    </TableCell>
                    <TableCell>
                      <span className="block text-xs text-muted-foreground">{i.category}</span>
                      <span className="font-medium">{i.issueType}</span>
                    </TableCell>
                    <TableCell className="max-w-56 whitespace-normal">{i.location}</TableCell>
                    <TableCell className="text-center">
                      <span className="inline-flex min-w-7 justify-center rounded-full bg-muted px-2 py-0.5 text-xs font-bold">{i.reportCount}</span>
                    </TableCell>
                    <TableCell><StatusBadge status={i.status} /></TableCell>
                    {isAdmin && (
                      <TableCell>
                        {i.supervisorName ? (
                          <span className="text-sm">{i.supervisorName}</span>
                        ) : i.status === "Fixed" ? (
                          <span className="text-sm text-muted-foreground">—</span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-sm font-medium text-amber-700 dark:text-amber-400"><UserX className="size-3.5" />Unassigned</span>
                        )}
                      </TableCell>
                    )}
                    <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                      {isAdmin ? (
                        <Button size="sm" variant="outline" onClick={() => onOpenIssue(i.id)}>
                          {i.status !== "Fixed" && !i.supervisorId ? "Assign" : "View"}
                        </Button>
                      ) : i.status === "Reported" ? (
                        <Button size="sm" disabled={busy} onClick={() => onSetStatus?.(i.id, "In Progress")}><Play />Start work</Button>
                      ) : i.status === "In Progress" ? (
                        <Button size="sm" disabled={busy} onClick={() => onSetStatus?.(i.id, "Fixed")}><CircleCheck />Mark fixed</Button>
                      ) : (
                        <span className="text-sm text-muted-foreground">Done</span>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      )}
      <p className="mt-2 text-xs text-muted-foreground">Showing {visible.length} of {issues.length} issue{issues.length === 1 ? "" : "s"}.</p>
    </div>
  );
}
