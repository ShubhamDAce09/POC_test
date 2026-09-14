import { redirect } from "next/navigation";
import { ClassReminders } from "@/components/ClassReminders";
import { getSession } from "@/lib/auth";
import {
  formatMinutes,
  personalizedSessions,
  weekdayName,
} from "@/lib/types";
import { loadElectives, loadOfficialTimetable } from "@/lib/timetable-store";

export default async function TimetablePage() {
  const user = await getSession();
  if (!user) redirect("/login");
  const timetable = await loadOfficialTimetable();
  if (!timetable) redirect("/upload");
  const selected = await loadElectives(user.id);
  const sessions = personalizedSessions(timetable.sessions, selected);
  const days = [...new Set(sessions.map((session) => session.day))];

  return (
    <main>
      <ClassReminders sessions={sessions} />
      <h1 className="mb-2 text-2xl font-semibold">My timetable</h1>
      <p className="mb-6 text-sm text-stone-600">
        {timetable.fileName} · uploaded by {timetable.uploadedBy}
      </p>
      {days.length === 0 ? (
        <p>No classes for the current selection.</p>
      ) : (
        days.map((day) => (
          <section key={day} className="mb-6">
            <h2 className="mb-2 text-lg font-semibold">{weekdayName(day)}</h2>
            <ul className="grid gap-2">
              {sessions
                .filter((session) => session.day === day)
                .map((session) => (
                  <li key={session.id} className="rounded-xl bg-white px-4 py-3 shadow-sm">
                    <div className="flex flex-wrap items-baseline justify-between gap-2">
                      <strong>
                        {session.courseCode
                          ? `${session.courseCode} · ${session.subjectName}`
                          : session.subjectName}
                      </strong>
                      <span className="text-sm uppercase tracking-wide text-[#7B1E2C]">
                        {session.kind}
                      </span>
                    </div>
                    <p className="text-sm text-stone-600">
                      {formatMinutes(session.startMinutes)} – {formatMinutes(session.endMinutes)}
                      {session.venue ? ` · ${session.venue}` : ""}
                      {session.faculty ? ` · ${session.faculty}` : ""}
                    </p>
                  </li>
                ))}
            </ul>
          </section>
        ))
      )}
    </main>
  );
}
