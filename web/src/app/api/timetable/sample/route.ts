import { readFile } from "node:fs/promises";
import path from "node:path";
import { NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { logEvent } from "@/lib/analytics";
import { EVENT_FILE_UPLOAD } from "@/lib/constants";
import { parseTimetableExcel } from "@/lib/excel";
import { saveOfficialTimetable } from "@/lib/timetable-store";

export async function POST() {
  const user = await getSession();
  if (!user) {
    return NextResponse.json({ error: "Sign in required." }, { status: 401 });
  }

  const filePath = path.join(process.cwd(), "public", "sample_timetable.xlsx");
  const bytes = await readFile(filePath);
  const timetable = parseTimetableExcel(bytes, "sample_timetable.xlsx", user.email);
  await saveOfficialTimetable(timetable);
  await logEvent(EVENT_FILE_UPLOAD, user.email, {
    file_name: "sample_timetable.xlsx",
    session_count: timetable.sessions.length,
    source: "sample",
  });
  return NextResponse.json({ timetable });
}
