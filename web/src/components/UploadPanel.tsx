"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function UploadPanel() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function upload(file: File) {
    const form = new FormData();
    form.set("file", file);
    const response = await fetch("/api/timetable", { method: "POST", body: form });
    const data = (await response.json()) as { error?: string };
    if (!response.ok) throw new Error(data.error ?? "Upload failed.");
  }

  async function onFile(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    setBusy(true);
    setError(null);
    try {
      await upload(file);
      router.push("/");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed.");
    } finally {
      setBusy(false);
    }
  }

  async function loadSample() {
    setBusy(true);
    setError(null);
    try {
      const response = await fetch("/api/timetable/sample", { method: "POST" });
      const data = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(data.error ?? "Could not load sample.");
      router.push("/");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not load sample.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex max-w-xl flex-col gap-4">
      <p>
        Upload the official Excel file from the PGP/PGPEx office. Expected columns: Day, Start
        Time, End Time, Course Code, Subject, Type (Core or Elective), Faculty, Venue.
      </p>
      <label className="inline-flex cursor-pointer items-center justify-center rounded-xl bg-[#7B1E2C] px-4 py-3 font-medium text-white">
        {busy ? "Working…" : "Upload Excel timetable"}
        <input type="file" accept=".xlsx,.xls" className="hidden" onChange={onFile} disabled={busy} />
      </label>
      <button
        type="button"
        onClick={loadSample}
        disabled={busy}
        className="rounded-xl border border-[#7B1E2C] px-4 py-3 text-[#7B1E2C] disabled:opacity-60"
      >
        Load sample PGPEx timetable
      </button>
      {error ? <p className="text-sm text-red-700">{error}</p> : null}
    </div>
  );
}
