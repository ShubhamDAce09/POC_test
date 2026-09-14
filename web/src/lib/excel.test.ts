import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";
import { isInstituteEmail } from "./email";
import { parseTimetableExcel } from "./excel";
import { personalizedSessions, uniqueSubjects } from "./types";
import * as XLSX from "xlsx";

test("accepts only iimshillong.ac.in emails", () => {
  assert.equal(isInstituteEmail("shubham.pgpex26@iimshillong.ac.in"), true);
  assert.equal(isInstituteEmail("dean@IIMShillong.ac.in"), true);
  assert.equal(isInstituteEmail("student@gmail.com"), false);
});

test("parses core and elective sessions from the office Excel layout", () => {
  const bytes = readFileSync(path.join(process.cwd(), "public", "sample_timetable.xlsx"));
  const timetable = parseTimetableExcel(bytes, "office.xlsx", "office@iimshillong.ac.in");
  assert.ok(timetable.sessions.length > 0);
  assert.ok(uniqueSubjects(timetable.sessions, "core").some((s) => s.courseCode === "PGPEX-C1"));
  assert.ok(uniqueSubjects(timetable.sessions, "elective").some((s) => s.courseCode === "PGPEX-E1"));
  const personalized = personalizedSessions(timetable.sessions, ["pgpex-e1"]);
  assert.equal(personalized.some((s) => s.courseCode === "PGPEX-E2"), false);
  assert.ok(personalized.some((s) => s.kind === "core"));
  assert.ok(personalized.some((s) => s.courseCode === "PGPEX-E1"));
});

test("parses 12-hour clock times", () => {
  const workbook = XLSX.utils.book_new();
  const sheet = XLSX.utils.aoa_to_sheet([
    ["Day", "Start Time", "End Time", "Subject", "Type"],
    ["Mon", "2:00 PM", "3:30 PM", "Strategy", "Core"],
  ]);
  XLSX.utils.book_append_sheet(workbook, sheet, "Sheet1");
  const bytes = XLSX.write(workbook, { type: "buffer", bookType: "xlsx" }) as Buffer;
  const timetable = parseTimetableExcel(bytes, "times.xlsx", "office@iimshillong.ac.in");
  assert.equal(timetable.sessions[0]?.startMinutes, 14 * 60);
  assert.equal(timetable.sessions[0]?.endMinutes, 15 * 60 + 30);
});
