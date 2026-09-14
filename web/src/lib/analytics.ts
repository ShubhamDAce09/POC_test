import { desc, sql } from "drizzle-orm";
import { db, ensureSchema } from "./db";
import { analyticsEvents } from "./schema";

export async function logEvent(
  name: string,
  userEmail?: string | null,
  payload?: Record<string, unknown>,
) {
  await ensureSchema();
  await db().insert(analyticsEvents).values({
    name,
    userEmail: userEmail ?? null,
    payload: payload ?? {},
  });
}

export async function getKpis() {
  await ensureSchema();
  const counts = await db()
    .select({
      name: analyticsEvents.name,
      count: sql<number>`count(*)::int`,
    })
    .from(analyticsEvents)
    .groupBy(analyticsEvents.name);

  const recent = await db()
    .select()
    .from(analyticsEvents)
    .orderBy(desc(analyticsEvents.createdAt))
    .limit(50);

  const uniqueLogins = await db()
    .select({
      count: sql<number>`count(distinct ${analyticsEvents.userEmail})::int`,
    })
    .from(analyticsEvents)
    .where(sql`${analyticsEvents.name} = 'login'`);

  const map = Object.fromEntries(counts.map((row) => [row.name, row.count]));
  return {
    totals: {
      app_open: map.app_open ?? 0,
      login: map.login ?? 0,
      file_upload: map.file_upload ?? 0,
      subject_selection: map.subject_selection ?? 0,
      reminder_trigger: map.reminder_trigger ?? 0,
    },
    uniqueLoginUsers: uniqueLogins[0]?.count ?? 0,
    recent,
  };
}
