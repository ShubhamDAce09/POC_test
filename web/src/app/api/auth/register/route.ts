import { NextResponse } from "next/server";
import { AuthError, createSessionCookie, registerUser } from "@/lib/auth";
import { logEvent } from "@/lib/analytics";
import { EVENT_LOGIN } from "@/lib/constants";

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as { email?: string; password?: string };
    const user = await registerUser(body.email ?? "", body.password ?? "");
    await createSessionCookie(user);
    await logEvent(EVENT_LOGIN, user.email, { method: "register" });
    return NextResponse.json({ user });
  } catch (error) {
    const message = error instanceof AuthError ? error.message : "Registration failed.";
    const status = error instanceof AuthError ? 400 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
