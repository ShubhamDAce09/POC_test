import { desc, eq } from "drizzle-orm";
import { db, ensureSchema } from "./db";
import { officeTimetable, userElectives } from "./schema";
import type { ClassSession, OfficialTimetable } from "./types";

export async function loadOfficialTimetable(): Promise<OfficialTimetable | null> {
  await ensureSchema();
  const row = await db()
    .select()
    .from(officeTimetable)
    .orderBy(desc(officeTimetable.uploadedAt))
    .limit(1);
  const current = row[0];
  if (!current) return null;
  return {
    fileName: current.fileName,
    uploadedBy: current.uploadedBy,
    uploadedAt: current.uploadedAt.toISOString(),
    sessions: current.sessions,
  };
}

export async function saveOfficialTimetable(timetable: OfficialTimetable) {
  await ensureSchema();
  await db().delete(officeTimetable);
  await db().insert(officeTimetable).values({
    fileName: timetable.fileName,
    uploadedBy: timetable.uploadedBy,
    uploadedAt: new Date(timetable.uploadedAt),
    sessions: timetable.sessions as ClassSession[],
  });
}

export async function loadElectives(userId: string) {
  await ensureSchema();
  const row = (
    await db().select().from(userElectives).where(eq(userElectives.userId, userId)).limit(1)
  )[0];
  return row?.keys ?? [];
}

export async function saveElectives(userId: string, keys: string[]) {
  await ensureSchema();
  await db()
    .insert(userElectives)
    .values({ userId, keys, updatedAt: new Date() })
    .onConflictDoUpdate({
      target: userElectives.userId,
      set: { keys, updatedAt: new Date() },
    });
}
