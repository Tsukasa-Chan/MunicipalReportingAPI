import type { Issue, IssueStatus, PortalStats, PortalUser, Report } from "@/Models/municipal";

export interface IssueFilters {
  search: string;
  status: IssueStatus | "all";
  category: string | "all";
  assignment: "all" | "assigned" | "unassigned";
}

export const EMPTY_ISSUE_FILTERS: IssueFilters = {
  search: "",
  status: "all",
  category: "all",
  assignment: "all",
};

/** An issue is "open" until a supervisor marks it Fixed. */
export const isOpen = (issue: Issue): boolean => issue.status !== "Fixed";

export function filterIssues(issues: Issue[], f: IssueFilters): Issue[] {
  const q = f.search.trim().toLowerCase();
  return issues.filter((i) => {
    if (f.status !== "all" && i.status !== f.status) return false;
    if (f.category !== "all" && i.category !== f.category) return false;
    if (f.assignment === "assigned" && !i.supervisorId) return false;
    if (f.assignment === "unassigned" && i.supervisorId) return false;
    if (!q) return true;
    return [i.issueNumber, i.category, i.issueType, i.location, i.supervisorName ?? ""]
      .join(" ")
      .toLowerCase()
      .includes(q);
  });
}

export function filterReports(reports: Report[], issues: Issue[], search: string): Report[] {
  const q = search.trim().toLowerCase();
  if (!q) return reports;
  const byId = new Map(issues.map((i) => [i.id, i] as const));
  return reports.filter((r) => {
    const issue = byId.get(r.issueId);
    return [r.id, r.residentName, r.description, r.location, issue?.issueNumber ?? "", issue?.issueType ?? "", issue?.category ?? ""]
      .join(" ")
      .toLowerCase()
      .includes(q);
  });
}

/** Number of open (not yet Fixed) issues currently assigned to each supervisor. */
export function openLoadBySupervisor(issues: Issue[]): Record<string, number> {
  const load: Record<string, number> = {};
  for (const i of issues) {
    if (i.supervisorId && isOpen(i)) load[i.supervisorId] = (load[i.supervisorId] ?? 0) + 1;
  }
  return load;
}

/** Deliberately simple statistics for the admin overview. */
export function computeStats(issues: Issue[], reports: Report[], users: PortalUser[]): PortalStats {
  const byStatus: Record<IssueStatus, number> = { Reported: 0, "In Progress": 0, Fixed: 0 };
  const categories = new Map<string, { issues: number; reports: number }>();

  for (const i of issues) {
    byStatus[i.status] += 1;
    const c = categories.get(i.category) ?? { issues: 0, reports: 0 };
    c.issues += 1;
    c.reports += i.reportCount;
    categories.set(i.category, c);
  }

  const supervisorLoad = users
    .filter((u) => u.role === "Supervisor")
    .map((s) => ({
      supervisorId: s.id,
      name: s.fullName,
      open: issues.filter((i) => i.supervisorId === s.id && isOpen(i)).length,
      fixed: issues.filter((i) => i.supervisorId === s.id && i.status === "Fixed").length,
    }));

  return {
    totalIssues: issues.length,
    totalReports: reports.length,
    unassignedIssues: issues.filter((i) => !i.supervisorId && isOpen(i)).length,
    byStatus,
    byCategory: [...categories.entries()]
      .map(([category, v]) => ({ category, ...v }))
      .sort((a, b) => b.issues - a.issues || a.category.localeCompare(b.category)),
    topIssues: [...issues]
      .filter(isOpen)
      .sort((a, b) => b.reportCount - a.reportCount || a.issueNumber.localeCompare(b.issueNumber))
      .slice(0, 5),
    supervisorLoad,
  };
}
