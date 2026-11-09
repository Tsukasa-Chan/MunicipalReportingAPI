# Running FixMyArea (frontend) against MunicipalReportingAPI (backend)

## 1. Backend (one-time setup)
Open a terminal in the folder that contains `MunicipalReportingAPI.csproj`.

```
dotnet user-secrets set "Jwt:Key" "put-a-random-string-of-32-or-more-characters-here"
dotnet user-secrets set "SeedAdmin:Email" "admin@municore.gov"
dotnet user-secrets set "SeedAdmin:Password" "Admin12345"
dotnet user-secrets set "SeedAdmin:FullName" "System Admin"

dotnet tool install --global dotnet-ef
dotnet ef database update
```

If your SQL Server is not `localhost\SQLEXPRESS` with Windows login, also run:
```
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<your connection string>"
```

## 2. Start the backend (every time)
```
dotnet run --launch-profile http
```
Swagger: http://localhost:5250/swagger

## 3. Start the frontend (every time)
```
npm install        # first time only
npm run dev
```
Open http://localhost:5173 and sign in with the SeedAdmin email and password.

## Settings
`.env` in this folder:
- `VITE_API_URL` - backend address (default `http://localhost:5250`)
- `VITE_USE_MOCK=true` - run on built-in demo data without a backend

Restart `npm run dev` after editing `.env`.
