import { NextResponse } from "next/server";
import { getKpis, logEvent } from "@/lib/analytics";
import { getSession } from "@/lib/auth";
import { EVENT_APP_OPEN, EVENT_REMINDER_TRIGGER } from "@/lib/constants";
import { isAdminEmail } from "@/lib/email";

export async function POST(request: Request) {
  const user = await getSession();
  if (!user) {
    return NextResponse.json({ error: "Sign in required." }, { status: 401 });
  }
  const body = (await request.json()) as {
    subject?: string;
    day?: string;
    phase?: string;
  };
  if (body.phase === "app_open") {
    await logEvent(EVENT_APP_OPEN, user.email);
    return NextResponse.json({ ok: true });
  }
  await logEvent(EVENT_REMINDER_TRIGGER, user.email, {
    subject: body.subject ?? "",
    day: body.day ?? "",
    phase: body.phase ?? "fired",
  });
  return NextResponse.json({ ok: true });
}

export async function GET() {
  const user = await getSession();
  if (!user || !isAdminEmail(user.email)) {
    return NextResponse.json({ error: "Admin only." }, { status: 403 });
  }
  return NextResponse.json(await getKpis());
}
