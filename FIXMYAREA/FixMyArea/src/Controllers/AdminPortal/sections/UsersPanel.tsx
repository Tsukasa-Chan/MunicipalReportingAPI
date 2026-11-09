import { useMemo, useState } from "react";
import { Search, UserMinus, UserPlus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { cn } from "@/Helpers/utils";
import type { PortalUser, Role } from "@/Models/municipal";
import { EmptyState, PanelHeader, formatDate } from "./common";

type RoleFilter = "all" | Role;

const FILTERS: Array<{ id: RoleFilter; label: string }> = [
  { id: "all", label: "Everyone" },
  { id: "Resident", label: "Residents" },
  { id: "Supervisor", label: "Supervisors" },
  { id: "Admin", label: "Admins" },
];

const ROLE_STYLE: Record<Role, string> = {
  Admin: "bg-primary text-primary-foreground",
  Supervisor: "bg-sky-100 text-sky-900 border-sky-300 dark:bg-sky-950/40 dark:text-sky-300",
  Resident: "bg-muted text-muted-foreground",
};

interface Props {
  users: PortalUser[];
  openLoad: Record<string, number>;
  busyKey: string | null;
  onSetRole: (userId: string, role: "Resident" | "Supervisor") => void;
}

/** Simple user directory. Admins can see everyone and decide who is a supervisor. */
export default function UsersPanel({ users, openLoad, busyKey, onSetRole }: Props) {
  const [filter, setFilter] = useState<RoleFilter>("all");
  const [search, setSearch] = useState("");

  const counts = useMemo(() => {
    const c: Record<RoleFilter, number> = { all: users.length, Resident: 0, Supervisor: 0, Admin: 0 };
    for (const u of users) c[u.role] += 1;
    return c;
  }, [users]);

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    return users.filter((u) => (filter === "all" || u.role === filter) && (!q || [u.fullName, u.email, u.ward, u.phone].join(" ").toLowerCase().includes(q)));
  }, [users, filter, search]);

  return (
    <div>
      <PanelHeader title="Users" description="See who is registered and decide who acts as a supervisor." />

      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="inline-flex rounded-lg border p-1" role="tablist" aria-label="Filter users by role">
          {FILTERS.map((f) => (
            <button
              key={f.id}
              type="button"
              role="tab"
              aria-selected={filter === f.id}
              onClick={() => setFilter(f.id)}
              className={cn("rounded-md px-3 py-1.5 text-sm font-medium transition-colors", filter === f.id ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground")}
            >
              {f.label} <span className="opacity-70">({counts[f.id]})</span>
            </button>
          ))}
        </div>
        <div className="relative min-w-52 flex-1 sm:max-w-xs">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input aria-label="Search users" className="pl-9" placeholder="Search name, email, ward…" value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
      </div>

      {visible.length === 0 ? (
        <EmptyState title="No users match" hint="Try a different role or search term." />
      ) : (
        <div className="rounded-lg border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Contact</TableHead>
                <TableHead>Ward</TableHead>
                <TableHead>Role</TableHead>
                <TableHead className="text-center">Activity</TableHead>
                <TableHead>Registered</TableHead>
                <TableHead className="text-right">Supervisor access</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {visible.map((u) => {
                const open = openLoad[u.id] ?? 0;
                const busy = busyKey === `role:${u.id}`;
                return (
                  <TableRow key={u.id}>
                    <TableCell className="font-medium">{u.fullName}</TableCell>
                    <TableCell>
                      <span className="block text-sm">{u.email}</span>
                      <span className="block text-xs text-muted-foreground">{u.phone}</span>
                    </TableCell>
                    <TableCell>{u.ward}</TableCell>
                    <TableCell><Badge variant="outline" className={ROLE_STYLE[u.role]}>{u.role}</Badge></TableCell>
                    <TableCell className="text-center text-sm">
                      {u.role === "Resident" && <span>{u.reportCount ?? 0} report{(u.reportCount ?? 0) === 1 ? "" : "s"}</span>}
                      {u.role === "Supervisor" && <span>{open} open issue{open === 1 ? "" : "s"}</span>}
                      {u.role === "Admin" && <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="whitespace-nowrap">{formatDate(u.registeredDate)}</TableCell>
                    <TableCell className="text-right">
                      {u.role === "Resident" && (
                        <Button size="sm" variant="outline" disabled={busy} onClick={() => onSetRole(u.id, "Supervisor")}><UserPlus />Make supervisor</Button>
                      )}
                      {u.role === "Supervisor" && (
                        <Button size="sm" variant="outline" disabled={busy || open > 0} title={open > 0 ? "Reassign this supervisor's open issues first" : undefined} onClick={() => onSetRole(u.id, "Resident")}><UserMinus />Remove</Button>
                      )}
                      {u.role === "Admin" && <span className="text-sm text-muted-foreground">—</span>}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
