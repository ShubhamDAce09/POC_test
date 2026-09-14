export type SubjectKind = "core" | "elective";

export type ClassSession = {
  id: string;
  subjectName: string;
  courseCode: string;
  kind: SubjectKind;
  day: number;
  startMinutes: number;
  endMinutes: number;
  faculty: string;
  venue: string;
};

export type OfficialTimetable = {
  fileName: string;
  uploadedBy: string;
  uploadedAt: string;
  sessions: ClassSession[];
};

export type SubjectOption = {
  key: string;
  name: string;
  courseCode: string;
  kind: SubjectKind;
};

export function subjectKey(session: Pick<ClassSession, "courseCode" | "subjectName">) {
  return (session.courseCode || session.subjectName).trim().toLowerCase();
}

export function weekdayName(day: number) {
  return [
    "",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ][day] ?? "Unknown";
}

export function formatMinutes(minutes: number) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  const period = h >= 12 ? "PM" : "AM";
  const hour12 = h % 12 === 0 ? 12 : h % 12;
  return `${hour12}:${String(m).padStart(2, "0")} ${period}`;
}

export function uniqueSubjects(sessions: ClassSession[], kind: SubjectKind): SubjectOption[] {
  const seen = new Set<string>();
  const result: SubjectOption[] = [];
  for (const session of sessions) {
    if (session.kind !== kind) continue;
    const key = subjectKey(session);
    if (seen.has(key)) continue;
    seen.add(key);
    result.push({
      key,
      name: session.subjectName,
      courseCode: session.courseCode,
      kind: session.kind,
    });
  }
  return result.sort((a, b) => a.name.localeCompare(b.name));
}

export function personalizedSessions(
  sessions: ClassSession[],
  selectedElectiveKeys: string[],
) {
  const selected = new Set(selectedElectiveKeys);
  return sessions
    .filter((session) => session.kind === "core" || selected.has(subjectKey(session)))
    .sort((a, b) => a.day - b.day || a.startMinutes - b.startMinutes);
}
