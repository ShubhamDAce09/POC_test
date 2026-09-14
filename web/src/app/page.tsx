import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import { uniqueSubjects } from "@/lib/types";
import { loadElectives, loadOfficialTimetable } from "@/lib/timetable-store";

export default async function HomePage() {
  const user = await getSession();
  if (!user) redirect("/login");

  let timetable = null;
  try {
    timetable = await loadOfficialTimetable();
  } catch (error) {
    return (
      <main className="mx-auto max-w-xl px-6 py-16">
        <h1 className="text-2xl font-semibold">Database not connected</h1>
        <p className="mt-3 text-stone-700">
          {error instanceof Error ? error.message : "Could not reach Neon."}
        </p>
      </main>
    );
  }

  if (!timetable) redirect("/upload");
  const electives = uniqueSubjects(timetable.sessions, "elective");
  const selected = await loadElectives(user.id);
  if (electives.length > 0 && selected.length === 0) redirect("/electives");
  redirect("/timetable");
}
