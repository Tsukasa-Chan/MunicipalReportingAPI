/**
 * FixMyArea municipal domain model (Issue -> Reports workflow).
 *
 *  Resident creates a Report
 *    -> backend finds or creates the Issue that Report belongs to
 *    -> Admin sees the Issue and assigns a Supervisor
 *    -> Supervisor moves the Issue "In Progress" and then "Fixed"
 *
 * Reports are only ever created by residents and are never edited by staff.
 * Staff manage Issues, not individual Reports.
 */

export type Role = "Resident" | "Supervisor" | "Admin";

export interface PortalUser {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  ward: string;
  role: Role;
  registeredDate: string;
  /** Number of reports the user has submitted (derived, residents only). */
  reportCount?: number;
  /** Mock-only. Never present on objects returned by the API layer. */
  password?: string;
}

export type IssueStatus = "Reported" | "In Progress" | "Fixed";

export const ISSUE_STATUSES: IssueStatus[] = ["Reported", "In Progress", "Fixed"];

export interface Issue {
  id: string;
  issueNumber: string;
  /** Broad category, e.g. "Water & Sanitation". */
  category: string;
  /** Specific issue within the category, e.g. "Burst pipe". */
  issueType: string;
  location: string;
  latitude: number;
  longitude: number;
  status: IssueStatus;
  supervisorId: string | null;
  /** Derived from supervisorId. */
  supervisorName: string | null;
  /** Derived: how many resident reports are grouped under this issue. */
  reportCount: number;
  createdAt: string;
  updatedAt: string | null;
}

export interface Report {
  id: string;
  issueId: string;
  residentId: string;
  residentName: string;
  description: string;
  photoUrl: string;
  location: string;
  submittedAt: string;
}

/** Shape persisted by the mock API (derived Issue fields are not stored). */
export type IssueRecord = Omit<Issue, "reportCount" | "supervisorName">;

export interface PortalState {
  version: 1;
  users: PortalUser[];
  issues: IssueRecord[];
  reports: Report[];
}

export interface PortalStats {
  totalIssues: number;
  totalReports: number;
  unassignedIssues: number;
  byStatus: Record<IssueStatus, number>;
  byCategory: Array<{ category: string; issues: number; reports: number }>;
  topIssues: Issue[];
  supervisorLoad: Array<{ supervisorId: string; name: string; open: number; fixed: number }>;
}
