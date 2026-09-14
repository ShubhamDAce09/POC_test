import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import * as schema from "./schema";

function databaseUrl() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error(
      "DATABASE_URL is not set. Create a Neon Postgres database and add the connection string to Vercel / .env.local.",
    );
  }
  return url;
}

let drizzleCached: ReturnType<typeof drizzle<typeof schema>> | null = null;
let schemaPromise: Promise<void> | null = null;

export function db() {
  if (!drizzleCached) {
    drizzleCached = drizzle(neon(databaseUrl()), { schema });
  }
  return drizzleCached;
}

export async function ensureSchema() {
  if (!schemaPromise) {
    schemaPromise = (async () => {
      const sql = neon(databaseUrl());
      await sql`CREATE TABLE IF NOT EXISTS users (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        email text NOT NULL UNIQUE,
        password_hash text NOT NULL,
        created_at timestamptz NOT NULL DEFAULT now()
      )`;
      await sql`CREATE TABLE IF NOT EXISTS office_timetable (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        file_name text NOT NULL,
        uploaded_by text NOT NULL,
        uploaded_at timestamptz NOT NULL DEFAULT now(),
        sessions jsonb NOT NULL
      )`;
      await sql`CREATE TABLE IF NOT EXISTS user_electives (
        user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        keys jsonb NOT NULL DEFAULT '[]'::jsonb,
        updated_at timestamptz NOT NULL DEFAULT now()
      )`;
      await sql`CREATE TABLE IF NOT EXISTS analytics_events (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name text NOT NULL,
        user_email text,
        payload jsonb,
        created_at timestamptz NOT NULL DEFAULT now()
      )`;
      await sql`CREATE INDEX IF NOT EXISTS analytics_events_name_idx ON analytics_events (name)`;
      await sql`CREATE INDEX IF NOT EXISTS analytics_events_created_idx ON analytics_events (created_at)`;
    })();
  }
  await schemaPromise;
}
