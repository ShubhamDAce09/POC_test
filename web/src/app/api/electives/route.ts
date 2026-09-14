import { NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { logEvent } from "@/lib/analytics";
import { EVENT_SUBJECT_SELECTION } from "@/lib/constants";
import { saveElectives } from "@/lib/timetable-store";

export async function POST(request: Request) {
  const user = await getSession();
  if (!user) {
    return NextResponse.json({ error: "Sign in required." }, { status: 401 });
  }
  const body = (await request.json()) as { keys?: string[] };
  const keys = Array.isArray(body.keys) ? body.keys.map(String) : [];
  await saveElectives(user.id, keys);
  await logEvent(EVENT_SUBJECT_SELECTION, user.email, { elective_count: keys.length });
  return NextResponse.json({ keys });
}
