# FixMyArea staff portal (Issue → Reports workflow)

```
Resident creates a Report → backend finds/creates the Issue → Admin sees the Issue
→ Admin assigns a Supervisor → Supervisor: In Progress → Fixed
```

Staff manage **Issues**, not individual Reports. Reports are created only by residents.

## Screens

| Role | Screen | What it does |
|---|---|---|
| Admin | Overview | Issue/report counts, issues by status and category, most-reported open issues, supervisor workload |
| Admin | Issues | All issues (search + status/category/assignment filters). Open one to see category, specific issue, location, status, report count, its reports, and **assign / reassign a supervisor** |
| Admin | Reports | Read-only list of every resident report; click through to its issue |
| Admin | Users | Everyone registered; **Make supervisor** / **Remove** (blocked while that supervisor has open issues) |
| Supervisor | My Issues | Only issues assigned to them. **Start work** (Reported → In Progress), **Mark fixed** (In Progress → Fixed) |

Deliberately absent: creating/editing/deleting/approving reports, admin status changes,
manual grouping, per-report supervisors, deleting duplicates, advanced analytics.

## Demo accounts (password `Password123!`)
`admin@municore.gov` (Admin) · `c.thorne@municore.gov`, `m.torres@municore.gov`, `n.petrov@municore.gov` (Supervisors)

## Where things live
- `src/Models/municipal.ts` – types (`Issue`, `Report`, `PortalUser`, `IssueStatus`…)
- `src/Services/municipal/api.ts` – **the only data layer**; all workflow rules are enforced here
- `src/Services/municipal/logic.ts` – filters + statistics (pure functions)
- `src/Services/municipal/seed.ts` – demo data (9 issues, 28 reports, 10 users)
- `src/Controllers/AdminPortal/sections/` – the screens (`Overview.tsx` is the shell)

## Rules enforced by the API layer
- Only an **Admin** can list users, assign supervisors and change a user's role.
- Only a user with the **Supervisor** role can be assigned; fixed issues can't be reassigned.
- Only the **assigned supervisor** can change status, one step forward only (no skipping, no going back).
- Supervisors only ever receive their own issues and those issues' reports.
- Admin accounts can't be demoted.

## Connecting the real backend
`api.ts` currently runs on an in-browser mock (localStorage). Implement the same `MunicipalApi`
interface with `fetch` and export it as `api`; no screen needs to change. Suggested endpoints:

| `MunicipalApi` method | Suggested endpoint |
|---|---|
| `login` / `logout` | `POST /api/auth/login`, `POST /api/auth/logout` |
| `listIssues` | `GET /api/issues` (Admin: all, Supervisor: own) |
| `listReports` | `GET /api/reports` (same scoping) |
| `listUsers` | `GET /api/users` (Admin) |
| `assignSupervisor` | `PUT /api/issues/{id}/supervisor` `{ supervisorId }` (Admin) |
| `setIssueStatus` | `PUT /api/issues/{id}/status` `{ status }` (assigned Supervisor) |
| `setUserRole` | `PUT /api/users/{id}/role` `{ role }` (Admin) |
| `setUserActive` | `PUT /api/admin/users/{id}/active` `{ isActive }` (Admin) — returns the user incl. `isActive`; login must reject inactive users |

The backend must also create/find the Issue when a resident submits a Report (the grouping is
not done in the UI). The current backend has no `Issue` entity yet.
