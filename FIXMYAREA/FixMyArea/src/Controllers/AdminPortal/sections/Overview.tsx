import { useCallback, useEffect, useMemo, useState } from "react";
import { FileText, LayoutDashboard, ListChecks, LoaderCircle, LogOut, RefreshCw, Users, Megaphone } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { cn } from "@/Helpers/utils";
import type { Issue, IssueStatus, PortalUser, Report } from "@/Models/municipal";
import { api } from "@/Services/municipal/api";
import { computeStats, openLoadBySupervisor } from "@/Services/municipal/logic";
import IssueDetailDialog from "./IssueDetailDialog";
import IssuesPanel from "./IssuesPanel";
import LoginGate from "./LoginGate";
import ReportsPanel from "./ReportsPanel";
import StatsPanel from "./StatsPanel";
import UsersPanel from "./UsersPanel";
import NoticesPanel from "./NoticesPanel";
import { messageOf } from "./common";

/**
 * Staff portal shell.
 *
 *   Admin      -> Overview, Issues (assign a supervisor), Reports (read-only), Users (maintain supervisors)
 *   Supervisor -> My Issues (Start work -> Mark fixed)
 */

type TabId = "overview" | "issues" | "reports" | "users" | "my-issues" | "notices";

const ADMIN_TABS: Array<{ id: TabId; label: string; icon: typeof Users }> = [
  { id: "overview", label: "Overview", icon: LayoutDashboard },
  { id: "issues", label: "Issues", icon: ListChecks },
  { id: "reports", label: "Reports", icon: FileText },
  { id: "users", label: "Users", icon: Users },
  { id: "notices", label: "Notices", icon: Megaphone },
];

const SUPERVISOR_TABS: Array<{ id: TabId; label: string; icon: typeof Users }> = [
  { id: "my-issues", label: "My Issues", icon: ListChecks },
];

interface PortalData {
  issues: Issue[];
  reports: Report[];
  users: PortalUser[];
}

interface Notice {
  kind: "success" | "error";
  text: string;
}

function tabFromHash(allowed: TabId[]): TabId {
  const hash = typeof window !== "undefined" ? (window.location.hash.replace("#", "") as TabId) : ("" as TabId);
  return allowed.includes(hash) ? hash : allowed[0];
}

export default function Overview() {
  const [session, setSession] = useState<PortalUser | null>(() => api.getSession());

  if (!session) return <LoginGate onSignedIn={setSession} />;

  return (
    <Portal
      user={session}
      onSignOut={async () => {
        await api.logout();
        setSession(null);
      }}
    />
  );
}

function Portal({ user, onSignOut }: { user: PortalUser; onSignOut: () => void }) {
  const isAdmin = user.role === "Admin";
  const tabs = isAdmin ? ADMIN_TABS : SUPERVISOR_TABS;
  const allowed = useMemo(() => tabs.map((t) => t.id), [tabs]);

  const [tab, setTab] = useState<TabId>(() => tabFromHash(allowed));
  const [data, setData] = useState<PortalData | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [selectedIssueId, setSelectedIssueId] = useState<string | null>(null);

  // Keep the active tab in sync with the URL hash (back/forward and deep links).
  useEffect(() => {
    const sync = () => setTab(tabFromHash(allowed));
    window.addEventListener("hashchange", sync);
    return () => window.removeEventListener("hashchange", sync);
  }, [allowed]);

  const refresh = useCallback(async (showSpinner: boolean) => {
    if (showSpinner) setLoading(true);
    setLoadError(null);
    try {
      const [issues, reports, users] = await Promise.all([
        api.listIssues(),
        api.listReports(),
        isAdmin ? api.listUsers() : Promise.resolve<PortalUser[]>([]),
      ]);
      setData({ issues, reports, users });
    } catch (e) {
      setLoadError(messageOf(e));
    } finally {
      setLoading(false);
    }
  }, [isAdmin]);

  useEffect(() => {
    void refresh(true);
  }, [refresh]);

  // Auto-dismiss notices.
  useEffect(() => {
    if (!notice) return;
    const t = window.setTimeout(() => setNotice(null), 5000);
    return () => window.clearTimeout(t);
  }, [notice]);

  /** Run a mutation, report the outcome, then reload so every screen stays consistent. */
  async function run(key: string, action: () => Promise<string>) {
    setBusyKey(key);
    try {
      const text = await action();
      setNotice({ kind: "success", text });
      await refresh(false);
    } catch (e) {
      setNotice({ kind: "error", text: messageOf(e) });
    } finally {
      setBusyKey(null);
    }
  }

  const assign = (issueId: string, supervisorId: string) =>
    run(`assign:${issueId}`, async () => {
      const i = await api.assignSupervisor(issueId, supervisorId);
      return `${i.issueNumber} is now assigned to ${i.supervisorName}.`;
    });

  const setStatus = (issueId: string, status: IssueStatus) =>
    run(`status:${issueId}`, async () => {
      const i = await api.setIssueStatus(issueId, status);
      return `${i.issueNumber} marked ${i.status}.`;
    });

  const setRole = (userId: string, role: "Resident" | "Supervisor") =>
    run(`role:${userId}`, async () => {
      const u = await api.setUserRole(userId, role);
      return role === "Supervisor" ? `${u.fullName} is now a supervisor.` : `${u.fullName} is no longer a supervisor.`;
    });

  const setActive = (userId: string, isActive: boolean) =>
    run(`active:${userId}`, async () => {
      const u = await api.setUserActive(userId, isActive);
      return isActive ? `${u.fullName}'s account has been reactivated.` : `${u.fullName}'s account has been deactivated.`;
    });

  const issues = data?.issues ?? [];
  const reports = data?.reports ?? [];
  const users = data?.users ?? [];
  const supervisors = useMemo(() => users.filter((u) => u.role === "Supervisor"), [users]);
  const openLoad = useMemo(() => openLoadBySupervisor(issues), [issues]);
  const stats = useMemo(() => computeStats(issues, reports, users), [issues, reports, users]);
  const selectedIssue = issues.find((i) => i.id === selectedIssueId) ?? null;

  function goTo(next: TabId) {
    window.location.hash = next;
    setTab(next);
  }

  return (
    <div className="flex min-h-[70vh] flex-col bg-background">
      <header className="border-b bg-card">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6">
          <div>
            <p className="text-lg font-extrabold tracking-tight">FixMyArea <span className="font-medium text-muted-foreground">Staff Portal</span></p>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-right leading-tight">
              <p className="text-sm font-semibold">{user.fullName}</p>
              <Badge variant="secondary" className="mt-0.5">{user.role}</Badge>
            </div>
            <Button variant="outline" size="sm" onClick={() => void refresh(false)} disabled={loading} aria-label="Refresh data">
              <RefreshCw className={cn(loading && "animate-spin")} />
            </Button>
            <Button variant="outline" size="sm" onClick={onSignOut}><LogOut />Sign out</Button>
          </div>
        </div>

        {tabs.length > 1 && (
          <nav className="mx-auto flex max-w-7xl gap-1 overflow-x-auto px-4 sm:px-6" aria-label="Portal sections">
            {tabs.map((t) => {
              const Icon = t.icon;
              return (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => goTo(t.id)}
                  aria-current={tab === t.id ? "page" : undefined}
                  className={cn(
                    "inline-flex items-center gap-2 whitespace-nowrap border-b-2 px-3 py-2.5 text-sm font-medium transition-colors",
                    tab === t.id ? "border-primary text-foreground" : "border-transparent text-muted-foreground hover:text-foreground",
                  )}
                >
                  <Icon className="size-4" />
                  {t.label}
                </button>
              );
            })}
          </nav>
        )}
      </header>

      <main className="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:px-6">
        {notice && (
          <div
            role={notice.kind === "error" ? "alert" : "status"}
            className={cn(
              "mb-4 rounded-md border px-4 py-2.5 text-sm font-medium",
              notice.kind === "error" ? "border-destructive/40 bg-destructive/10 text-destructive" : "border-emerald-300 bg-emerald-50 text-emerald-900 dark:bg-emerald-950/40 dark:text-emerald-300",
            )}
          >
            {notice.text}
          </div>
        )}

        {loading && !data ? (
          <div className="flex items-center justify-center gap-2 py-24 text-muted-foreground"><LoaderCircle className="animate-spin" />Loading…</div>
        ) : loadError && !data ? (
          <div className="space-y-3 py-20 text-center">
            <p className="font-semibold text-destructive">{loadError}</p>
            <Button variant="outline" onClick={() => void refresh(true)}>Try again</Button>
          </div>
        ) : (
          <>
            {tab === "overview" && <StatsPanel stats={stats} onOpenIssue={setSelectedIssueId} />}
            {tab === "issues" && <IssuesPanel mode="admin" issues={issues} busyKey={busyKey} onOpenIssue={setSelectedIssueId} />}
            {tab === "reports" && <ReportsPanel reports={reports} issues={issues} onOpenIssue={setSelectedIssueId} />}
            {tab === "notices" && isAdmin && <NoticesPanel />}
            {tab === "users" && <UsersPanel users={users} openLoad={openLoad} busyKey={busyKey} onSetRole={setRole} onSetActive={setActive} currentUserId={user.id} />}
            {tab === "my-issues" && <IssuesPanel mode="supervisor" issues={issues} busyKey={busyKey} onOpenIssue={setSelectedIssueId} onSetStatus={setStatus} />}
          </>
        )}
      </main>

      <IssueDetailDialog
        issue={selectedIssue}
        reports={reports}
        supervisors={supervisors}
        openLoad={openLoad}
        viewer={user}
        busyKey={busyKey}
        onClose={() => setSelectedIssueId(null)}
        onAssign={assign}
        onSetStatus={setStatus}
      />
    </div>
  );
}
