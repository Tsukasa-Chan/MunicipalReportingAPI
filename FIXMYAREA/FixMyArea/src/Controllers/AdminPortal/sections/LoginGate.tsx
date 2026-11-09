import { useState } from "react";
import { Eye, EyeOff, LoaderCircle, Lock, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { api, USE_MOCK } from "@/Services/municipal/api";
import { DEMO_ACCOUNTS } from "@/Services/municipal/seed";
import type { PortalUser } from "@/Models/municipal";
import { messageOf } from "./common";

export default function LoginGate({ onSignedIn }: { onSignedIn: (user: PortalUser) => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim() || !password) {
      setError("Enter your email and password.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      onSignedIn(await api.login(email, password));
    } catch (err) {
      setError(messageOf(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="flex min-h-screen items-center justify-center bg-muted/40 px-4 py-10">
      <Card className="w-full max-w-md">
        <CardContent className="space-y-6 p-6 sm:p-8">
          <div className="space-y-2 text-center">
            <div className="mx-auto flex size-12 items-center justify-center rounded-xl bg-primary text-primary-foreground">
              <ShieldCheck className="size-6" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight">FixMyArea Staff Portal</h1>
            <p className="text-sm text-muted-foreground">Sign in as an administrator or supervisor.</p>
          </div>

          <form onSubmit={submit} className="space-y-4" noValidate>
            <div className="space-y-1.5">
              <label htmlFor="login-email" className="text-sm font-medium">Email</label>
              <Input id="login-email" type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="name@municore.gov" />
            </div>
            <div className="space-y-1.5">
              <label htmlFor="login-password" className="text-sm font-medium">Password</label>
              <div className="relative">
                <Input
                  id="login-password"
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  aria-pressed={showPassword}
                  className="absolute inset-y-0 right-0 flex w-10 items-center justify-center text-muted-foreground hover:text-foreground focus-visible:outline-none focus-visible:text-foreground"
                >
                  {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>
            {error && (
              <p role="alert" className="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive">
                {error}
              </p>
            )}
            <Button type="submit" className="w-full" disabled={busy}>
              {busy ? <LoaderCircle className="animate-spin" /> : <Lock />}
              Sign in
            </Button>
          </form>

          {USE_MOCK && (
          <div className="rounded-lg border bg-muted/40 p-3 text-xs text-muted-foreground">
            <p className="mb-2 font-semibold text-foreground">Demo accounts</p>
            <div className="flex flex-wrap gap-2">
              {(
                [
                  ["Admin", DEMO_ACCOUNTS.admin],
                  ["Supervisor", DEMO_ACCOUNTS.supervisor],
                ] as const
              ).map(([label, acc]) => (
                <Button key={label} type="button" size="sm" variant="outline" onClick={() => { setEmail(acc.email); setPassword(acc.password); setError(null); }}>
                  Fill {label}
                </Button>
              ))}
            </div>
          </div>
          )}
        </CardContent>
      </Card>
    </section>
  );
}
