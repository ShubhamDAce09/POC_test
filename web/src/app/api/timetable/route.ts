import { NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { logEvent } from "@/lib/analytics";
import { EVENT_FILE_UPLOAD } from "@/lib/constants";
import { ExcelParseError, parseTimetableExcel } from "@/lib/excel";
import { saveOfficialTimetable } from "@/lib/timetable-store";

export async function POST(request: Request) {
  const user = await getSession();
  if (!user) {
    return NextResponse.json({ error: "Sign in required." }, { status: 401 });
  }

  try {
    const form = await request.formData();
    const file = form.get("file");
    if (!(file instanceof File)) {
      return NextResponse.json({ error: "Choose an Excel file." }, { status: 400 });
    }

    const bytes = Buffer.from(await file.arrayBuffer());
    const timetable = parseTimetableExcel(bytes, file.name, user.email);
    await saveOfficialTimetable(timetable);
    await logEvent(EVENT_FILE_UPLOAD, user.email, {
      file_name: file.name,
      session_count: timetable.sessions.length,
    });
    return NextResponse.json({ timetable });
  } catch (error) {
    const message =
      error instanceof ExcelParseError ? error.message : "Could not parse that Excel file.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
