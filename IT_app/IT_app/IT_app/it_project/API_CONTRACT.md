# Job assignment API contract

These are the shared-backend routes for connecting the admin website to the
supervisor app. They are route contracts only; this Flutter project does not
contain or host the backend, so the routes are not live until the backend
implements them.

## Register and verify an email

The registration screen calls the backend; it does not create a local account
or open the dashboard until email verification succeeds. Configure the API
origin in the Flutter build with `--dart-define=API_BASE_URL=https://api.example.com`.
The app resolves the routes below against that origin.

### Start registration

`POST /api/auth/register`

```json
{
  "fullName": "Example User",
  "email": "user@example.com",
  "password": "sent only during registration",
  "ward": {
    "number": "52",
    "location": "Tongaat"
  }
}
```

Return `202 Accepted` after creating a pending account and sending a
time-limited verification code to the email address. Do not mark the account
verified or issue dashboard access yet. Generate, store, deliver, and validate
the code on the backend through its configured email provider; provider
credentials must never be put in the Flutter app. The app only relays the
user-entered code to the verification route. The ward string displayed in the
app is composed as `Ward 52 - Tongaat`.

### Verify the code

`POST /api/auth/email-verification/verify`

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

Return `200 OK` with `{"verified": true}` only when the code is valid, unexpired,
and belongs to that pending registration. Invalid or expired codes should
return `{"verified": false}` (or a 4xx response with a user-readable `message`).
The app only creates the local signed-in account and opens `HomePage` after
receiving `verified: true`.

### Resend a code

`POST /api/auth/email-verification/resend`

```json
{
  "email": "user@example.com"
}
```

Return `202 Accepted` after sending a replacement code. Apply server-side
rate-limiting and invalidate or safely expire previous codes. For errors, return
a non-2xx status and a JSON body such as `{"message": "A readable error."}`.

These routes are contracts for the backend team; they are not implemented by
this Flutter project. The app currently keeps verified accounts in the
in-memory `AuthStore`, so server-backed login/session persistence still needs
to be integrated separately.

## Assign a report to a supervisor

`PUT /api/reports/{reportId}/assignment`

The admin website sends an authenticated request with:

```json
{
  "supervisorUsername": "supervisor-account",
  "scheduledAt": "2026-10-03T09:00:00+02:00"
}
```

The backend should authorize this operation for admins and persist the
supervisor assignment and schedule date/time on the report group, including all
member reports. Enforce the assigned supervisor's configured issue
responsibility before accepting the assignment. Return the updated group, including its
`assignedSupervisorUsername`, `scheduledAt`, and status.

## List a supervisor's assigned reports

`GET /api/supervisors/{supervisorUsername}/reports`

The backend should authorize the signed-in supervisor to access their own
assignments and return a JSON array of grouped reports. Admin access may be
allowed according to the backend's authorization policy.

Group reports when the normalized issue type, specific issue, and area all
match. Normalize case and surrounding whitespace; reports for different areas
must remain separate. Use the earliest submitted report as the displayed
`reportId`, and include the number of distinct users who reported the issue.
Each returned group should include `reportId`, `reportIds`, `issueType`,
`issue`, `area`, `reporterCount`, `assignedSupervisorUsername`, `scheduledAt`,
and status. The report IDs let the admin or supervisor refer to every original
submission represented by the group.

## Supervisor's daily schedule

`GET /api/supervisors/{supervisorUsername}/schedule?date=YYYY-MM-DD`

Return only the groups allocated to the authenticated supervisor for the
requested local calendar date, including the scheduled time, current status,
and each member report ID. The backend must authorize the supervisor and return
the same group shape described above.

## Update a scheduled job status

`PATCH /api/reports/{reportId}/status`

```json
{
  "status": "On-site"
}
```

The backend should authorize the assigned supervisor, update the status on all
member reports in that group, and make the update immediately visible in the
report submitter's status view. Supported job-flow values are `Assigned`,
`In progress`, `On-site`, and `Completed`.

## Submit a completed job invoice

`POST /api/reports/{reportId}/invoice`

Send the completed invoice fields (`invoiceNumber`, `workerName`, `workerId`,
`jobNumber`, `locationAddress`, `pinLocation`, `startTime`, `stopTime`,
`totalTime`, `managerSignature`, and `workerSignature`). The backend should
authorize the assigned supervisor, save the invoice against the report group,
mark the group `Completed`, and make the invoice available to the admin.
Return the persisted invoice and report status.

The path templates and builders are in
[`lib/Pages/api_paths.dart`](lib/Pages/api_paths.dart). The backend and both
clients must use the same API base URL, report IDs, supervisor usernames, and
authentication scheme. These are route contracts only; this app currently
stores reports locally and does not yet send schedule, status, or invoice
requests to a backend. The supervisor app shows locally saved invoices as
`Pending admin submission` until this API is implemented and connected.
