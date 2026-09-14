import { redirect } from "next/navigation";
import { ElectivePicker } from "@/components/ElectivePicker";
import { getSession } from "@/lib/auth";
import { uniqueSubjects } from "@/lib/types";
import { loadElectives, loadOfficialTimetable } from "@/lib/timetable-store";

export default async function ElectivesPage() {
  const user = await getSession();
  if (!user) redirect("/login");
  const timetable = await loadOfficialTimetable();
  if (!timetable) redirect("/upload");

  return (
    <main>
      <h1 className="mb-4 text-2xl font-semibold">Your subjects</h1>
      <ElectivePicker
        cores={uniqueSubjects(timetable.sessions, "core")}
        electives={uniqueSubjects(timetable.sessions, "elective")}
        initialSelected={await loadElectives(user.id)}
      />
    </main>
  );
}
