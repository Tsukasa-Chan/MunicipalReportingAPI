import type { Issue, IssueStatus, PortalUser, Report, Role } from "@/Models/municipal";
import type { MunicipalApi } from "./api";
import type { CommunityNotice, SaveCommunityNotice } from "./notices";

/**
 * Real implementation of MunicipalApi that talks to the ASP.NET Core backend
 * (MunicipalReportingAPI). Screens are unchanged: this file only translates between
 * the backend's shapes and the portal's shapes.
 *
 *   backend                          portal
 *   -------------------------------  ---------------------------
 *   Id: 12 (number)                  id: "12" (string)
 *   Status: Resolved / InProgress    status: "Fixed" / "In Progress"
 *   IssueCategory: WaterAndSanitation  category: "Water & Sanitation"
 *   IssueType: BurstPipe             issueType: "Burst pipe"
 *   role "User"                      role "Resident"
 */

const API_URL = ((import.meta.env.VITE_API_URL as string | undefined) ?? "http://localhost:5250").replace(/\/+$/, "");

const ACCESS_KEY = "fixmyarea_access_token";
const REFRESH_KEY = "fixmyarea_refresh_token";
const USER_KEY = "fixmyarea_session_user";

// ---------------------------------------------------------------- storage
const store = {
  get: (k: string) => { try { return window.localStorage.getItem(k); } catch { return null; } },
  set: (k: string, v: string) => { try { window.localStorage.setItem(k, v); } catch { /* blocked */ } },
  del: (k: string) => { try { window.localStorage.removeItem(k); } catch { /* blocked */ } },
};

function clearSession() {
  store.del(ACCESS_KEY);
  store.del(REFRESH_KEY);
  store.del(USER_KEY);
}

// ---------------------------------------------------------------- mapping
const CATEGORY_LABELS: Record<string, string> = {
  WaterAndSanitation: "Water & Sanitation",
  RoadsAndStormwater: "Roads & Stormwater",
  Electricity: "Electricity",
  WasteManagement: "Waste Management",
};

/** "BurstPipe" -> "Burst pipe", "BlockedSewerOrManhole" -> "Blocked sewer or manhole" */
function humanizeType(value: string): string {
  const words = value.replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase();
  return words.charAt(0).toUpperCase() + words.slice(1);
}

const STATUS_FROM_API: Record<string, IssueStatus> = {
  Reported: "Reported",
  InProgress: "In Progress",
  Resolved: "Fixed",
};
const STATUS_TO_API: Record<IssueStatus, string> = {
  Reported: "Reported",
  "In Progress": "InProgress",
  Fixed: "Resolved",
};
const NEXT_STATUS: Partial<Record<IssueStatus, IssueStatus>> = {
  Reported: "In Progress",
  "In Progress": "Fixed",
};

const roleFromApi = (r: string | null | undefined): Role =>
  r === "Admin" ? "Admin" : r === "Supervisor" ? "Supervisor" : "Resident";

/** Uploaded photos are served by the backend, so relative paths need its address. */
const absoluteUrl = (url: string | null | undefined): string =>
  !url ? "" : /^https?:\/\//i.test(url) ? url : `${API_URL}${url.startsWith("/") ? "" : "/"}${url}`;

const issueNumber = (id: number) => `ISS-${String(id).padStart(4, "0")}`;

function mapIssue(d: any): Issue {
  return {
    id: String(d.id),
    issueNumber: issueNumber(d.id),
    category: CATEGORY_LABELS[d.issueCategory] ?? humanizeType(String(d.issueCategory)),
    issueType: humanizeType(String(d.issueType)),
    location: [d.location, d.areaName].filter(Boolean).join(", "),
    latitude: d.latitude,
    longitude: d.longitude,
    status: STATUS_FROM_API[d.status] ?? "Reported",
    supervisorId: d.supervisorId == null ? null : String(d.supervisorId),
    supervisorName: d.supervisorName ?? null,
    reportCount: d.reportCount ?? 0,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt ?? null,
  };
}

function mapReport(d: any): Report {
  return {
    id: String(d.id),
    issueId: String(d.issueId),
    residentId: d.userId == null ? "" : String(d.userId),
    residentName: d.userFullName || "Deleted account",
    description: d.description ?? "",
    photoUrl: absoluteUrl(d.imageUrl),
    location: d.location ?? "",
    submittedAt: d.createdAt,
  };
}

/** The backend does not store phone, ward or registration date for users, so those stay blank. */
function mapUser(d: any): PortalUser {
  const role = roleFromApi(d.role);
  return {
    id: String(d.id),
    fullName: d.fullName,
    email: d.email ?? "",
    phone: "",
    ward: "",
    role,
    registeredDate: "",
    isActive: d.isActive ?? true,
    reportCount: role === "Resident" ? d.reportCount ?? 0 : undefined,
  };
}

// ---------------------------------------------------------------- http
class ApiError extends Error {
  constructor(message: string, public status: number) {
    super(message);
  }
}

/** Backend errors are plain strings, string arrays, or ProblemDetails objects. */
async function readError(res: Response): Promise<string> {
  const text = await res.text().catch(() => "");
  if (!text) return `Request failed (${res.status}).`;
  try {
    const body = JSON.parse(text);
    if (typeof body === "string") return body;
    if (Array.isArray(body)) return body.join(" ");
    if (body?.errors && typeof body.errors === "object") return Object.values(body.errors).flat().join(" ");
    if (body?.message) return String(body.message);
    if (body?.title) return String(body.title);
  } catch {
    /* not JSON - use the raw text */
  }
  return text.replace(/^"|"$/g, "");
}

// Several requests can hit a 401 at once. Share ONE refresh call: the backend rotates
// refresh tokens, so refreshing several times with the same token would sign the user out.
let refreshing: Promise<boolean> | null = null;

function refreshTokens(): Promise<boolean> {
  if (!refreshing) {
    refreshing = (async () => {
      const refreshToken = store.get(REFRESH_KEY);
      if (!refreshToken) return false;
      try {
        const res = await fetch(`${API_URL}/api/auth/refresh`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken }),
        });
        if (!res.ok) return false;
        const data = await res.json();
        store.set(ACCESS_KEY, data.token);
        store.set(REFRESH_KEY, data.refreshToken);
        return true;
      } catch {
        return false;
      }
    })().finally(() => {
      refreshing = null;
    });
  }
  return refreshing;
}

function sessionExpired(): never {
  clearSession();
  // Back to the sign-in screen
  window.setTimeout(() => window.location.reload(), 0);
  throw new Error("Your session has expired. Please sign in again.");
}

async function request<T>(path: string, init: { method?: string; body?: unknown; auth?: boolean } = {}): Promise<T> {
  const { method = "GET", body, auth = true } = init;

  const send = () => {
    const headers: Record<string, string> = {};
    if (body !== undefined) headers["Content-Type"] = "application/json";
    const token = store.get(ACCESS_KEY);
    if (auth && token) headers.Authorization = `Bearer ${token}`;
    return fetch(`${API_URL}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  };

  let res: Response;
  try {
    res = await send();
    if (res.status === 401 && auth) {
      if (!(await refreshTokens())) sessionExpired();
      res = await send();
      if (res.status === 401) sessionExpired();
    }
  } catch (e) {
    if (e instanceof ApiError || (e instanceof Error && e.message.startsWith("Your session"))) throw e;
    throw new Error(`Can't reach the server at ${API_URL}. Is the backend running?`);
  }

  if (res.status === 403) throw new Error("You don't have permission to do that.");
  if (!res.ok) throw new ApiError(await readError(res), res.status);

  const text = await res.text();
  if (!text) return undefined as T;
  try {
    return JSON.parse(text) as T;
  } catch {
    return text as unknown as T;
  }
}

// ---------------------------------------------------------------- the api
export function createHttpApi(): MunicipalApi {
  const me = (): PortalUser => {
    const raw = store.get(USER_KEY);
    if (!raw) sessionExpired();
    return JSON.parse(raw as string) as PortalUser;
  };

  return {
    async listNotices() {
      return request<CommunityNotice[]>("/api/CommunityNotices/manage");
    },
    async createNotice(input: SaveCommunityNotice) {
      return request<CommunityNotice>("/api/CommunityNotices", { method: "POST", body: input });
    },
    async updateNotice(id: number, input: SaveCommunityNotice) {
      return request<CommunityNotice>(`/api/CommunityNotices/${id}`, { method: "PUT", body: input });
    },
    async deleteNotice(id: number) {
      return request<void>(`/api/CommunityNotices/${id}`, { method: "DELETE" });
    },
    getSession() {
      const raw = store.get(USER_KEY);
      if (!raw || !store.get(ACCESS_KEY)) return null;
      try {
        return JSON.parse(raw) as PortalUser;
      } catch {
        return null;
      }
    },

    async login(email, password) {
      const tokens = await request<{ token: string; refreshToken: string }>("/api/auth/login", {
        method: "POST",
        body: { email: email.trim(), password },
        auth: false,
      });

      store.set(ACCESS_KEY, tokens.token);
      store.set(REFRESH_KEY, tokens.refreshToken);

      try {
        const profile = await request<any>("/api/auth/me");
        const role = roleFromApi(profile.role);
        if (role === "Resident") {
          // Residents have no business here: end the session we just opened.
          await request("/api/auth/logout", { method: "POST", body: { refreshToken: tokens.refreshToken } }).catch(() => {});
          clearSession();
          throw new Error("This portal is for municipal staff only.");
        }
        const user: PortalUser = {
          id: String(profile.id),
          fullName: profile.fullName,
          email: profile.email,
          phone: "",
          ward: profile.wardName ?? "",
          role,
          registeredDate: "",
        };
        store.set(USER_KEY, JSON.stringify(user));
        return user;
      } catch (e) {
        clearSession();
        throw e;
      }
    },

    async logout() {
      const refreshToken = store.get(REFRESH_KEY);
      try {
        if (store.get(ACCESS_KEY)) {
          await fetch(`${API_URL}/api/auth/logout`, {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${store.get(ACCESS_KEY)}` },
            body: JSON.stringify({ refreshToken: refreshToken ?? "" }),
          });
        }
      } catch {
        /* offline - still sign out locally */
      }
      clearSession();
    },

    async listIssues() {
      const user = me();
      const query = user.role === "Supervisor" ? `?supervisorId=${encodeURIComponent(user.id)}` : "";
      const data = await request<any[]>(`/api/issues${query}`);
      return data.map(mapIssue);
    },

    async listReports() {
      const user = me();
      const data = await request<any[]>("/api/reports");
      // The endpoint returns every report to any staff member; supervisors only see their own issues'.
      const mine = user.role === "Supervisor" ? data.filter((r) => String(r.supervisorId) === user.id) : data;
      return mine.map(mapReport);
    },

    async listUsers() {
      const pageSize = 100;
      const all: any[] = [];
      for (let page = 1; ; page++) {
        const data = await request<{ totalCount: number; items: any[] }>(`/api/admin/users?page=${page}&pageSize=${pageSize}`);
        all.push(...data.items);
        if (all.length >= data.totalCount || data.items.length === 0) break;
      }
      return all.map(mapUser);
    },

    async assignSupervisor(issueId, supervisorId) {
      const current = await request<any>(`/api/issues/${issueId}`);
      if (STATUS_FROM_API[current.status] === "Fixed") throw new Error("A fixed issue can't be reassigned.");
      const updated = await request<any>(`/api/issues/${issueId}/supervisor`, {
        method: "PUT",
        body: { supervisorId: Number(supervisorId) },
      });
      return mapIssue(updated);
    },

    async setIssueStatus(issueId, status) {
      const user = me();
      const current = mapIssue(await request<any>(`/api/issues/${issueId}`));
      if (current.supervisorId !== user.id) throw new Error("Only the assigned supervisor can update this issue.");
      if (NEXT_STATUS[current.status] !== status) {
        throw new Error(`An issue can't move from "${current.status}" to "${status}".`);
      }
      const updated = await request<any>(`/api/issues/${issueId}/status`, {
        method: "PUT",
        body: { status: STATUS_TO_API[status] },
      });
      return mapIssue(updated);
    },

    async setUserRole(userId, role) {
      const updated = await request<any>(`/api/admin/users/${userId}/role`, {
        method: "PUT",
        body: { role: role === "Resident" ? "User" : "Supervisor" },
      });
      return mapUser(updated);
    },

    async setUserActive(userId, isActive) {
      const updated = await request<any>(`/api/admin/users/${userId}/active`, {
        method: "PUT",
        body: { isActive },
      });
      return mapUser(updated);
    },
  };
}
