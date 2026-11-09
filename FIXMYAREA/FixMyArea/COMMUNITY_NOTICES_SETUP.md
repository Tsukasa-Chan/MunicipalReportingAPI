# Community Notices — Admin Website

This is the complete original FixMyArea React/TypeScript website with an additional **Notices** tab for administrators. Other portal features remain in place.

## Run

1. Apply the separate `CommunityNotices_Backend_Step1.zip` changes to MunicipalReportingAPI and run its EF Core `Add-Migration AddCommunityNotices`, then `Update-Database`.
2. Start the ASP.NET API using its HTTP launch profile (port 5250 by default).
3. In this folder, run `npm ci` followed by `npm run dev`.
4. Log in as an existing **Admin** account, then open the **Notices** tab.

The existing `.env` remains `VITE_API_URL=http://localhost:5250` and `VITE_USE_MOCK=false`. If your API uses a different port, set `VITE_API_URL` accordingly. Only the already configured Admin role can publish notices; supervisors will not see the Notices tab.

## Notices behavior

- Create, edit, activate/deactivate, and permanently delete notices.
- Target all communities, a whole ward (58/61/62), or one of the 35 seeded areas.
- Optional future expiry date/time; the UI converts it to UTC for the API.
- Filter the management list by published, inactive/expired, or all.
- Form and data map to the C# `SaveCommunityNoticeDTO` and `CommunityNoticeResponseDTO`.
- Uses the existing authenticated API client, token refresh, error handling and login.
- Demo mode (`VITE_USE_MOCK=true`) stores notices in local browser storage only and will **not** publish them to Flutter users.

**Important:** This ZIP is the website, not a replacement for the backend ZIP. Database migration and a running backend are required for actual persistence. The Flutter Community Notices page has not been added yet.

## Build validation

The uploaded original website contains an incomplete `src/components/ui/form.tsx` ending without a closing function brace. A single closing brace was added so that this file parses; this does not modify its existing form behavior. The environment could not complete package installation, so a full `npm run build` could not be verified here. All other original files remain unchanged except for the notice integration described above.
