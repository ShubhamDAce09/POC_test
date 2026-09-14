import { compare, hash } from "bcryptjs";
import { eq } from "drizzle-orm";
import { jwtVerify, SignJWT } from "jose";
import { cookies } from "next/headers";
import { SESSION_COOKIE } from "./constants";
import { db, ensureSchema } from "./db";
import { isInstituteEmail, normalizeEmail } from "./email";
import { users } from "./schema";

export type SessionUser = {
  id: string;
  email: string;
};

function secretKey() {
  const secret = process.env.AUTH_SECRET;
  if (!secret) {
    if (process.env.NODE_ENV === "production") {
      throw new Error("AUTH_SECRET is required in production.");
    }
    return new TextEncoder().encode("iim-shillong-dev-secret-change-me");
  }
  return new TextEncoder().encode(secret);
}

export async function createSessionCookie(user: SessionUser) {
  const token = await new SignJWT({ email: user.email })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.id)
    .setIssuedAt()
    .setExpirationTime("30d")
    .sign(secretKey());

  const jar = await cookies();
  jar.set(SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });
}

export async function clearSessionCookie() {
  const jar = await cookies();
  jar.delete(SESSION_COOKIE);
}

export async function getSession(): Promise<SessionUser | null> {
  const jar = await cookies();
  const token = jar.get(SESSION_COOKIE)?.value;
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, secretKey());
    if (!payload.sub || typeof payload.email !== "string") return null;
    return { id: payload.sub, email: payload.email };
  } catch {
    return null;
  }
}

export async function registerUser(email: string, password: string) {
  assertCredentials(email, password);
  await ensureSchema();
  const normalized = normalizeEmail(email);
  const existing = (
    await db().select().from(users).where(eq(users.email, normalized)).limit(1)
  )[0];
  if (existing) {
    throw new AuthError("That institute email is already registered.");
  }
  const [created] = await db()
    .insert(users)
    .values({
      email: normalized,
      passwordHash: await hash(password, 10),
    })
    .returning();
  if (!created) throw new AuthError("Could not create the account.");
  return { id: created.id, email: created.email };
}

export async function loginUser(email: string, password: string) {
  assertCredentials(email, password);
  await ensureSchema();
  const normalized = normalizeEmail(email);
  const existing = (
    await db().select().from(users).where(eq(users.email, normalized)).limit(1)
  )[0];
  if (!existing || !(await compare(password, existing.passwordHash))) {
    throw new AuthError("Incorrect email or password.");
  }
  return { id: existing.id, email: existing.email };
}

function assertCredentials(email: string, password: string) {
  if (!isInstituteEmail(email)) {
    throw new AuthError("Use your institute email ending with @iimshillong.ac.in");
  }
  if (password.length < 6) {
    throw new AuthError("Password must be at least 6 characters.");
  }
}

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AuthError";
  }
}
