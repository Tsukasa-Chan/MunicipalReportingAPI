import { useCallback, useEffect, useMemo, useState } from "react";
import { AlertTriangle, LoaderCircle, Megaphone, Pencil, Plus, RefreshCw, Trash2, X } from "lucide-react";
import { api, USE_MOCK } from "@/Services/municipal/api";
import { AREAS, WARDS } from "@/Services/municipal/notices";
import type { CommunityNotice, NoticeAudience, NoticeCategory, SaveCommunityNotice } from "@/Services/municipal/notices";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { PanelHeader, messageOf } from "./common";

const blank = (): SaveCommunityNotice => ({
  title: "", description: "", category: "General", audience: "All",
  wardId: null, areaId: null, expiresAt: null, isActive: true,
});

function toLocalInput(iso: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const shifted = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
  return shifted.toISOString().slice(0, 16);
}
function niceDate(iso: string | null): string {
  if (!iso) return "No expiry";
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? "Unknown date" : date.toLocaleString();
}
function audienceLabel(n: CommunityNotice): string {
  return n.audience === "All" ? "All communities" :
    n.audience === "Ward" ? (n.wardName || `Ward ${n.wardId}`) :
    (n.areaName || AREAS.find(a => a.id === n.areaId)?.name || `Area ${n.areaId}`);
}
const fieldClass = "w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring";

export default function NoticesPanel() {
  const [notices, setNotices] = useState<CommunityNotice[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [editing, setEditing] = useState<number | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<SaveCommunityNotice>(blank);
  const [expiresLocal, setExpiresLocal] = useState("");
  const [filter, setFilter] = useState<"all" | "active" | "inactive">("all");

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try { setNotices(await api.listNotices()); }
    catch (e) { setError(messageOf(e)); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { void reload(); }, [reload]);

  const visible = useMemo(() => notices.filter(n => {
    const active = n.isActive && (!n.expiresAt || new Date(n.expiresAt).getTime() > Date.now());
    return filter === "all" || (filter === "active" ? active : !active);
  }), [notices, filter]);

  const patch = (values: Partial<SaveCommunityNotice>) => setForm(prev => ({...prev, ...values}));
  const newNotice = () => {
    setEditing(null); setForm(blank()); setExpiresLocal(""); setError(null); setSuccess(null); setShowForm(true);
  };
  const editNotice = (notice: CommunityNotice) => {
    setEditing(notice.id);
    setForm({
      title: notice.title, description: notice.description, category: notice.category,
      audience: notice.audience, areaId: notice.areaId, wardId: notice.wardId,
      expiresAt: notice.expiresAt, isActive: notice.isActive,
    });
    setExpiresLocal(toLocalInput(notice.expiresAt));
    setError(null); setSuccess(null); setShowForm(true);
  };
  const submit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const title = form.title.trim();
    const description = form.description.trim();
    if (title.length < 3 || title.length > 150) { setError("Title must contain 3–150 characters."); return; }
    if (description.length < 5 || description.length > 3000) { setError("Description must contain 5–3000 characters."); return; }
    if (form.audience === "Ward" && !form.wardId) { setError("Choose a ward."); return; }
    if (form.audience === "Area" && !form.areaId) { setError("Choose an area."); return; }
    const expiry = expiresLocal ? new Date(expiresLocal) : null;
    if (expiry && (Number.isNaN(expiry.getTime()) || expiry.getTime() <= Date.now())) {
      setError("Expiry must be a future date and time."); return;
    }
    const payload: SaveCommunityNotice = {
      ...form, title, description,
      areaId: form.audience === "Area" ? form.areaId : null,
      wardId: form.audience === "Ward" ? form.wardId : null,
      expiresAt: expiry?.toISOString() || null,
    };
    setBusy(true); setError(null); setSuccess(null);
    try {
      if (editing === null) await api.createNotice(payload);
      else await api.updateNotice(editing, payload);
      setSuccess(editing === null ? "Notice created successfully." : "Notice updated successfully.");
      setShowForm(false); setEditing(null);
      await reload();
    } catch (err) { setError(messageOf(err)); }
    finally { setBusy(false); }
  };
  const toggleActive = async (notice: CommunityNotice) => {
    setBusy(true); setError(null); setSuccess(null);
    try {
      await api.updateNotice(notice.id, {
        title: notice.title, description: notice.description,
        category: notice.category, audience: notice.audience,
        areaId: notice.areaId, wardId: notice.wardId,
        expiresAt: notice.expiresAt, isActive: !notice.isActive,
      });
      setSuccess(notice.isActive ? "Notice deactivated." : "Notice activated.");
      await reload();
    } catch (err) { setError(messageOf(err)); }
    finally { setBusy(false); }
  };
  const remove = async (notice: CommunityNotice) => {
    if (!window.confirm(`Permanently delete “${notice.title}”? This cannot be undone.`)) return;
    setBusy(true); setError(null); setSuccess(null);
    try { await api.deleteNotice(notice.id); setSuccess("Notice deleted."); await reload(); }
    catch (err) { setError(messageOf(err)); }
    finally { setBusy(false); }
  };

  return (
    <section className="space-y-5">
      <PanelHeader title="Community Notices" description="Publish important announcements to all residents, a ward, or one community area.">
        <Button variant="outline" onClick={() => void reload()} disabled={loading || busy}><RefreshCw className={loading ? "animate-spin" : ""}/> Refresh</Button>
        <Button onClick={newNotice} disabled={busy}><Plus /> New notice</Button>
      </PanelHeader>
      {USE_MOCK && <p className="rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-950">Demo mode is enabled. Notices are saved only in this browser, not in SQL Server. Set VITE_USE_MOCK=false to publish real notices.</p>}
      {error && <p role="alert" className="rounded-md border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">{error}</p>}
      {success && <p role="status" className="rounded-md border border-emerald-300 bg-emerald-50 p-3 text-sm text-emerald-900">{success}</p>}

      {showForm && (
        <form onSubmit={e => void submit(e)} className="space-y-4 rounded-xl border bg-card p-5 shadow-sm">
          <div className="flex items-center justify-between gap-2">
            <h3 className="text-lg font-semibold">{editing === null ? "Create notice" : "Edit notice"}</h3>
            <Button type="button" size="sm" variant="ghost" onClick={() => setShowForm(false)} disabled={busy}><X/> Close</Button>
          </div>
          <div><label htmlFor="notice-title" className="mb-1 block text-sm font-medium">Title</label>
            <input id="notice-title" className={fieldClass} maxLength={150} minLength={3} required value={form.title} onChange={e => patch({title:e.target.value})} placeholder="e.g. Scheduled water maintenance"/></div>
          <div><label htmlFor="notice-description" className="mb-1 block text-sm font-medium">Description</label>
            <textarea id="notice-description" className={fieldClass} maxLength={3000} minLength={5} required rows={5} value={form.description} onChange={e => patch({description:e.target.value})} placeholder="Explain what residents need to know…"/>
            <p className="text-right text-xs text-muted-foreground">{form.description.length}/3000</p></div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div><label htmlFor="notice-category" className="mb-1 block text-sm font-medium">Category</label>
              <select id="notice-category" className={fieldClass} value={form.category} onChange={e => patch({category:e.target.value as NoticeCategory})}>
                <option value="General">General announcement</option><option value="Maintenance">Maintenance</option><option value="Emergency">Emergency</option>
              </select></div>
            <div><label htmlFor="notice-audience" className="mb-1 block text-sm font-medium">Who should see this?</label>
              <select id="notice-audience" className={fieldClass} value={form.audience} onChange={e => patch({audience:e.target.value as NoticeAudience,areaId:null,wardId:null})}>
                <option value="All">All communities</option><option value="Ward">Entire ward</option><option value="Area">Specific area</option>
              </select></div>
            {form.audience === "Ward" && <div><label htmlFor="notice-ward" className="mb-1 block text-sm font-medium">Ward</label>
              <select id="notice-ward" required className={fieldClass} value={form.wardId ?? ""} onChange={e => patch({wardId:e.target.value ? Number(e.target.value) : null})}>
                <option value="">Select ward</option>{WARDS.map(id => <option key={id} value={id}>Ward {id}</option>)}
              </select></div>}
            {form.audience === "Area" && <div><label htmlFor="notice-area" className="mb-1 block text-sm font-medium">Community area</label>
              <select id="notice-area" required className={fieldClass} value={form.areaId ?? ""} onChange={e => patch({areaId:e.target.value ? Number(e.target.value) : null})}>
                <option value="">Select area</option>{WARDS.map(ward => <optgroup key={ward} label={`Ward ${ward}`}>
                  {AREAS.filter(a => a.wardId === ward).map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
                </optgroup>)}
              </select></div>}
            <div><label htmlFor="notice-expiry" className="mb-1 block text-sm font-medium">Expiry date and time (optional)</label>
              <input id="notice-expiry" type="datetime-local" className={fieldClass} value={expiresLocal} onChange={e => setExpiresLocal(e.target.value)}/>
              <p className="mt-1 text-xs text-muted-foreground">Leave blank to keep this notice until deactivated or deleted.</p></div>
          </div>
          <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.isActive} onChange={e => patch({isActive:e.target.checked})}/> Published / visible to residents</label>
          <div className="flex flex-wrap gap-2"><Button disabled={busy} type="submit">{busy && <LoaderCircle className="animate-spin"/>}{editing === null ? "Create notice" : "Save changes"}</Button>
            <Button type="button" variant="outline" disabled={busy} onClick={() => setShowForm(false)}>Cancel</Button></div>
        </form>
      )}
      <div className="flex flex-wrap gap-2" aria-label="Filter notices">
        {(["all", "active", "inactive"] as const).map(value => <Button type="button" size="sm" key={value} variant={filter === value ? "default" : "outline"} onClick={() => setFilter(value)}>
          {value === "all" ? "All notices" : value === "active" ? "Published" : "Inactive / expired"}
        </Button>)}
      </div>
      {loading ? <div className="flex items-center gap-2 py-10 text-muted-foreground"><LoaderCircle className="animate-spin"/> Loading notices…</div> :
        visible.length === 0 ? <div className="rounded-xl border border-dashed px-4 py-14 text-center text-muted-foreground"><Megaphone className="mx-auto mb-3 size-9"/>No notices match this filter.</div> :
        <div className="grid gap-3">
          {visible.map(notice => {
            const expired = !!notice.expiresAt && new Date(notice.expiresAt).getTime() <= Date.now();
            return <article key={notice.id} className="rounded-xl border bg-card p-4 shadow-sm sm:p-5">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0 flex-1 space-y-2">
                  <div className="flex flex-wrap items-center gap-2"><h3 className="text-lg font-semibold">{notice.title}</h3>
                    <Badge variant="outline">{notice.category}</Badge>
                    <Badge variant={notice.isActive && !expired ? "default" : "secondary"}>{!notice.isActive ? "Inactive" : expired ? "Expired" : "Published"}</Badge>
                  </div>
                  <p className="whitespace-pre-wrap break-words text-sm leading-relaxed text-foreground">{notice.description}</p>
                  <p className="text-xs text-muted-foreground">Audience: {audienceLabel(notice)} · Created: {niceDate(notice.createdAt)} · Expires: {niceDate(notice.expiresAt)}</p>
                  <p className="text-xs text-muted-foreground">Published by {notice.createdByName || "Administrator"}</p>
                </div>
                <div className="flex flex-wrap gap-2">
                  <Button size="sm" variant="outline" disabled={busy} onClick={() => editNotice(notice)}><Pencil/> Edit</Button>
                  <Button size="sm" variant="outline" disabled={busy || expired && !notice.isActive} onClick={() => void toggleActive(notice)}>{notice.isActive ? "Deactivate" : "Activate"}</Button>
                  <Button size="sm" variant="destructive" disabled={busy} onClick={() => void remove(notice)}><Trash2/> Delete</Button>
                </div>
              </div>
            </article>;
          })}
        </div>}
      <p className="flex items-center gap-2 text-xs text-muted-foreground"><AlertTriangle className="size-4"/> Emergency notices are announcements, not emergency-service dispatches.</p>
    </section>
  );
}
