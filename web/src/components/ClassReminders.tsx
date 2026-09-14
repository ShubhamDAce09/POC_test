"use client";

import { useEffect } from "react";
import { REMINDER_LEAD_MINUTES, TIMEZONE } from "@/lib/constants";
import { formatMinutes, weekdayName, type ClassSession } from "@/lib/types";

export function ClassReminders({ sessions }: { sessions: ClassSession[] }) {
  useEffect(() => {
    let cancelled = false;
    const timers: number[] = [];

    async function setup() {
      if (!("Notification" in window)) return;
      const permission =
        Notification.permission === "granted"
          ? "granted"
          : await Notification.requestPermission();
      if (cancelled || permission !== "granted") return;

      const now = new Date();
      for (const session of sessions) {
        const fireAt = nextOccurrence(session, now);
        const delay = fireAt.getTime() - now.getTime();
        if (delay <= 0 || delay > 1000 * 60 * 60 * 24 * 8) continue;
        timers.push(
          window.setTimeout(() => {
            new Notification(`${session.subjectName} starts soon`, {
              body: `${weekdayName(session.day)} ${formatMinutes(session.startMinutes)}–${formatMinutes(session.endMinutes)}${session.venue ? ` · ${session.venue}` : ""}`,
            });
            void fetch("/api/analytics", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                subject: session.subjectName,
                day: weekdayName(session.day),
                phase: "fired",
              }),
            });
          }, delay),
        );
        void fetch("/api/analytics", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            subject: session.subjectName,
            day: weekdayName(session.day),
            phase: "scheduled",
          }),
        });
      }
    }

    void setup();
    return () => {
      cancelled = true;
      timers.forEach((id) => window.clearTimeout(id));
    };
  }, [sessions]);

  return null;
}

function nextOccurrence(session: ClassSession, now: Date) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: TIMEZONE,
    weekday: "short",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const get = (type: string) => parts.find((part) => part.type === type)?.value ?? "0";
  const current = new Date(
    `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}:00+05:30`,
  );
  const fireMinutes = session.startMinutes - REMINDER_LEAD_MINUTES;
  const candidate = new Date(current);
  candidate.setHours(Math.floor(Math.max(fireMinutes, 0) / 60), Math.max(fireMinutes, 0) % 60, 0, 0);
  while (isoWeekday(candidate) !== session.day || candidate <= current) {
    candidate.setDate(candidate.getDate() + 1);
    candidate.setHours(Math.floor(Math.max(fireMinutes, 0) / 60), Math.max(fireMinutes, 0) % 60, 0, 0);
  }
  return candidate;
}

function isoWeekday(date: Date) {
  const day = date.getDay();
  return day === 0 ? 7 : day;
}
