import { jsonb, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
import type { ClassSession } from "./types";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
});

export const officeTimetable = pgTable("office_timetable", {
  id: uuid("id").primaryKey().defaultRandom(),
  fileName: text("file_name").notNull(),
  uploadedBy: text("uploaded_by").notNull(),
  uploadedAt: timestamp("uploaded_at", { withTimezone: true }).defaultNow().notNull(),
  sessions: jsonb("sessions").$type<ClassSession[]>().notNull(),
});

export const userElectives = pgTable("user_electives", {
  userId: uuid("user_id")
    .primaryKey()
    .references(() => users.id, { onDelete: "cascade" }),
  keys: jsonb("keys").$type<string[]>().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
});

export const analyticsEvents = pgTable("analytics_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  userEmail: text("user_email"),
  payload: jsonb("payload").$type<Record<string, unknown>>(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
});
