"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { SubjectOption } from "@/lib/types";

export function ElectivePicker({
  cores,
  electives,
  initialSelected,
}: {
  cores: SubjectOption[];
  electives: SubjectOption[];
  initialSelected: string[];
}) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set(initialSelected));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function toggle(key: string) {
    setSelected((current) => {
      const next = new Set(current);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }

  async function save() {
    setBusy(true);
    setError(null);
    try {
      const response = await fetch("/api/electives", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ keys: [...selected] }),
      });
      const data = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(data.error ?? "Could not save electives.");
      router.push("/");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not save electives.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <p>Core courses are included for every student. Choose the electives you registered for.</p>
      <section>
        <h2 className="mb-2 text-lg font-semibold">Core</h2>
        <ul className="grid gap-2">
          {cores.map((subject) => (
            <li key={subject.key} className="rounded-xl bg-white px-4 py-3 shadow-sm">
              {subject.courseCode ? `${subject.courseCode} · ${subject.name}` : subject.name}
            </li>
          ))}
        </ul>
      </section>
      <section>
        <h2 className="mb-2 text-lg font-semibold">Electives</h2>
        {electives.length === 0 ? (
          <p>This office file has no elective rows.</p>
        ) : (
          <ul className="grid gap-2">
            {electives.map((subject) => (
              <li key={subject.key} className="rounded-xl bg-white px-4 py-3 shadow-sm">
                <label className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={selected.has(subject.key)}
                    onChange={() => toggle(subject.key)}
                  />
                  {subject.courseCode ? `${subject.courseCode} · ${subject.name}` : subject.name}
                </label>
              </li>
            ))}
          </ul>
        )}
      </section>
      {error ? <p className="text-sm text-red-700">{error}</p> : null}
      <button
        type="button"
        onClick={save}
        disabled={busy}
        className="rounded-xl bg-[#7B1E2C] px-4 py-3 font-medium text-white disabled:opacity-60"
      >
        {busy ? "Saving…" : `Save ${selected.size} elective${selected.size === 1 ? "" : "s"}`}
      </button>
    </div>
  );
}
