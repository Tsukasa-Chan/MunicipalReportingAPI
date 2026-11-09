import type { Issue, IssueRecord, IssueStatus, PortalState, PortalUser, Report, Role } from "@/Models/municipal";
import { buildSeed } from "./seed";
import { createHttpApi } from "./httpApi";
import { AREAS } from "./notices";
import type { CommunityNotice, SaveCommunityNotice } from "./notices";

/**
 * Data-access layer for the FixMyArea admin / supervisor portal.
 *
 * Every screen talks to `api` and nothing else, and all workflow rules live here.
 * The implementation below is an in-browser mock (persisted in localStorage) so the
 * portal runs on its own. To use the real backend, provide another object that
 * implements `MunicipalApi` (same method names, same shapes) and export it as `api`.
 */
export interface MunicipalApi {
  getSession(): PortalUser | null;
  /** Admin-only community notice management. */
  listNotices(): Promise<CommunityNotice[]>;
  createNotice(input: SaveCommunityNotice): Promise<CommunityNotice>;
  updateNotice(id: number, input: SaveCommunityNotice): Promise<CommunityNotice>;
  deleteNotice(id: number): Promise<void>;
  login(email: string, password: string): Promise<PortalUser>;
  logout(): Promise<void>;

  /** Admin: every issue. Supervisor: only issues assigned to them. */
  listIssues(): Promise<Issue[]>;
  /** Admin: every report. Supervisor: only reports under their issues. */
  listReports(): Promise<Report[]>;
  /** Admin only. */
  listUsers(): Promise<PortalUser[]>;

  /** Admin only. Assigns (or reassigns) a supervisor to an issue. */
  assignSupervisor(issueId: string, supervisorId: string): Promise<Issue>;
  /** Assigned supervisor only. Reported -> In Progress -> Fixed. */
  setIssueStatus(issueId: string, status: IssueStatus): Promise<Issue>;
  /** Admin only. Promote a resident to supervisor, or return a supervisor to resident. */
  setUserRole(userId: string, role: "Resident" | "Supervisor"): Promise<PortalUser>;
}

export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

const STATE_KEY = "fixmyarea_portal_state_v1";
const SESSION_KEY = "fixmyarea_portal_session_v1";

const NEXT_STATUS: Partial<Record<IssueStatus, IssueStatus>> = {
  Reported: "In Progress",
  "In Progress": "Fixed",
};

function memoryStorage(): StorageLike {
  const data = new Map<string, string>();
  return {
    getItem: (k) => data.get(k) ?? null,
    setItem: (k, v) => void data.set(k, v),
    removeItem: (k) => void data.delete(k),
  };
}

function browserStorage(): StorageLike {
  try {
    if (typeof window !== "undefined" && window.localStorage) {
      const probe = "__fixmyarea_probe__";
      window.localStorage.setItem(probe, "1");
      window.localStorage.removeItem(probe);
      return window.localStorage;
    }
  } catch {
    /* storage blocked (private mode etc.) - fall back to memory */
  }
  return memoryStorage();
}

const stripPassword = (u: PortalUser): PortalUser => {
  const { password: _password, ...rest } = u;
  return rest;
};

export function createMockApi(storage: StorageLike = browserStorage(), now: () => Date = () => new Date()): MunicipalApi {
  function load(): PortalState {
    try {
      const raw = storage.getItem(STATE_KEY);
      if (raw) {
        const s = JSON.parse(raw) as PortalState;
        if (s && s.version === 1 && Array.isArray(s.users) && Array.isArray(s.issues) && Array.isArray(s.reports)) return s;
      }
    } catch {
      /* corrupted - reseed below */
    }
    const seed = buildSeed();
    save(seed);
    return seed;
  }

  function save(state: PortalState): void {
    try {
      storage.setItem(STATE_KEY, JSON.stringify(state));
    } catch {
      /* quota / blocked - the in-flight call still succeeds */
    }
  }

  function session(state: PortalState): PortalUser | null {
    const id = storage.getItem(SESSION_KEY);
    if (!id) return null;
    const user = state.users.find((u) => u.id === id);
    return user && (user.role === "Admin" || user.role === "Supervisor") ? user : null;
  }

  function requireRole(state: PortalState, ...roles: Role[]): PortalUser {
    const user = session(state);
    if (!user) throw new Error("Your session has expired. Please sign in again.");
    if (!roles.includes(user.role)) throw new Error("You don't have permission to do that.");
    return user;
  }

  function toIssue(state: PortalState, r: IssueRecord): Issue {
    return {
      ...r,
      supervisorName: state.users.find((u) => u.id === r.supervisorId)?.fullName ?? null,
      reportCount: state.reports.filter((x) => x.issueId === r.id).length,
    };
  }

  const stamp = () => now().toISOString();
  const NOTICES_KEY = "fixmyarea_mock_notices_v1";
  const getNotices = (): CommunityNotice[] => {
    try { const value = JSON.parse(storage.getItem(NOTICES_KEY) || "[]"); return Array.isArray(value) ? value : []; }
    catch { return []; }
  };
  const putNotices = (items: CommunityNotice[]) => storage.setItem(NOTICES_KEY, JSON.stringify(items));


  return {
    async listNotices() {
      requireRole(load(), "Admin");
      return getNotices().sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    },
    async createNotice(input) {
      const me = requireRole(load(), "Admin");
      const notices = getNotices();
      const item: CommunityNotice = {
        ...input, id: Math.max(0, ...notices.map(n => n.id)) + 1,
        areaName: input.areaId ? AREAS.find(a => a.id === input.areaId)?.name ?? null : null,
        wardName: input.wardId ? `Ward ${input.wardId}` : null,
        createdByUserId: Number(me.id) || null, createdByName: me.fullName,
        createdAt: stamp(), updatedAt: null,
      };
      putNotices([item, ...notices]);
      return item;
    },
    async updateNotice(id, input) {
      requireRole(load(), "Admin");
      const notices = getNotices();
      const index = notices.findIndex(n => n.id === id);
      if (index < 0) throw new Error("Notice not found.");
      const item: CommunityNotice = {
        ...notices[index], ...input,
        areaName: input.areaId ? AREAS.find(a => a.id === input.areaId)?.name ?? null : null,
        wardName: input.wardId ? `Ward ${input.wardId}` : null,
        updatedAt: stamp(),
      };
      notices[index] = item;
      putNotices(notices);
      return item;
    },
    async deleteNotice(id) {
      requireRole(load(), "Admin");
      putNotices(getNotices().filter(n => n.id !== id));
    },
    getSession() {
      const user = session(load());
      return user ? stripPassword(user) : null;
    },

    async login(email, password) {
      const state = load();
      const user = state.users.find((u) => u.email.toLowerCase() === email.trim().toLowerCase());
      if (!user || user.password !== password) throw new Error("Incorrect email or password.");
      if (user.role === "Resident") throw new Error("This portal is for municipal staff only.");
      storage.setItem(SESSION_KEY, user.id);
      return stripPassword(user);
    },

    async logout() {
      storage.removeItem(SESSION_KEY);
    },

    async listIssues() {
      const state = load();
      const me = requireRole(state, "Admin", "Supervisor");
      const records = me.role === "Admin" ? state.issues : state.issues.filter((i) => i.supervisorId === me.id);
      return records.map((r) => toIssue(state, r)).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    },

    async listReports() {
      const state = load();
      const me = requireRole(state, "Admin", "Supervisor");
      const visible = me.role === "Admin" ? null : new Set(state.issues.filter((i) => i.supervisorId === me.id).map((i) => i.id));
      return state.reports
        .filter((r) => !visible || visible.has(r.issueId))
        .sort((a, b) => b.submittedAt.localeCompare(a.submittedAt));
    },

    async listUsers() {
      const state = load();
      requireRole(state, "Admin");
      return state.users.map((u) => ({
        ...stripPassword(u),
        reportCount: u.role === "Resident" ? state.reports.filter((r) => r.residentId === u.id).length : undefined,
      }));
    },

    async assignSupervisor(issueId, supervisorId) {
      const state = load();
      requireRole(state, "Admin");
      const issue = state.issues.find((i) => i.id === issueId);
      if (!issue) throw new Error("Issue not found.");
      const supervisor = state.users.find((u) => u.id === supervisorId);
      if (!supervisor || supervisor.role !== "Supervisor") throw new Error("Choose a user who is a supervisor.");
      if (issue.status === "Fixed") throw new Error("A fixed issue can't be reassigned.");
      if (issue.supervisorId !== supervisorId) {
        issue.supervisorId = supervisorId;
        issue.updatedAt = stamp();
        save(state);
      }
      return toIssue(state, issue);
    },

    async setIssueStatus(issueId, status) {
      const state = load();
      const me = requireRole(state, "Supervisor");
      const issue = state.issues.find((i) => i.id === issueId);
      if (!issue) throw new Error("Issue not found.");
      if (issue.supervisorId !== me.id) throw new Error("Only the assigned supervisor can update this issue.");
      if (NEXT_STATUS[issue.status] !== status) {
        throw new Error(`An issue can't move from "${issue.status}" to "${status}".`);
      }
      issue.status = status;
      issue.updatedAt = stamp();
      save(state);
      return toIssue(state, issue);
    },

    async setUserRole(userId, role) {
      const state = load();
      requireRole(state, "Admin");
      const user = state.users.find((u) => u.id === userId);
      if (!user) throw new Error("User not found.");
      if (user.role === "Admin") throw new Error("Administrator accounts can't be changed here.");
      if (user.role === role) return stripPassword(user);
      if (role === "Resident") {
        const open = state.issues.filter((i) => i.supervisorId === user.id && i.status !== "Fixed").length;
        if (open > 0) {
          throw new Error(`${user.fullName} still has ${open} open issue${open === 1 ? "" : "s"}. Reassign ${open === 1 ? "it" : "them"} first.`);
        }
      }
      user.role = role;
      save(state);
      return stripPassword(user);
    },
  };
}

/**
 * Which data layer the portal uses.
 *   VITE_USE_MOCK=true  -> in-browser demo data (no backend needed)
 *   otherwise           -> the real ASP.NET backend at VITE_API_URL
 */
export const USE_MOCK = import.meta.env.VITE_USE_MOCK === "true";

export const api: MunicipalApi = USE_MOCK ? createMockApi() : createHttpApi();
