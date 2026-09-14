import * as XLSX from "xlsx";
import type { ClassSession, OfficialTimetable, SubjectKind } from "./types";

export class ExcelParseError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ExcelParseError";
  }
}

export function parseTimetableExcel(
  bytes: ArrayBuffer | Buffer | Uint8Array,
  fileName: string,
  uploadedBy: string,
): OfficialTimetable {
  const workbook = XLSX.read(bytes, { type: "buffer", cellDates: true });
  if (!workbook.SheetNames.length) {
    throw new ExcelParseError("The Excel file has no worksheets.");
  }

  const sessions: ClassSession[] = [];
  for (const name of workbook.SheetNames) {
    const sheet = workbook.Sheets[name];
    if (!sheet) continue;
    sessions.push(...parseSheet(sheet));
  }

  if (!sessions.length) {
    throw new ExcelParseError(
      "No class rows found. Expected headers: Day, Start Time, End Time, Subject, Type.",
    );
  }

  return {
    fileName,
    uploadedBy,
    uploadedAt: new Date().toISOString(),
    sessions,
  };
}

function parseSheet(sheet: XLSX.WorkSheet): ClassSession[] {
  const rows = XLSX.utils.sheet_to_json<(string | number | Date | null)[]>(sheet, {
    header: 1,
    raw: true,
    defval: "",
  });
  if (rows.length < 2) return [];

  const headerIndex = findHeaderRow(rows);
  const header = (rows[headerIndex] ?? []).map((cell) => normalizeHeader(cellString(cell)));
  const col = columnMap(header);
  if (col.day == null || col.start == null || col.end == null || col.subject == null) {
    return [];
  }

  const sessions: ClassSession[] = [];
  for (let r = headerIndex + 1; r < rows.length; r += 1) {
    const values = (rows[r] ?? []).map(cellString);
    if (values.every((value) => !value.trim())) continue;

    const day = parseDay(values[col.day] ?? "");
    const start = parseTime(values[col.start] ?? "", rows[r]?.[col.start]);
    const end = parseTime(values[col.end] ?? "", rows[r]?.[col.end]);
    const subject = (values[col.subject] ?? "").trim();
    if (day == null || start == null || end == null || !subject) continue;

    sessions.push({
      id: crypto.randomUUID(),
      subjectName: subject,
      courseCode: col.code != null ? (values[col.code] ?? "").trim() : "",
      kind: parseKind(col.type != null ? values[col.type] ?? "core" : "core"),
      day,
      startMinutes: start,
      endMinutes: end,
      faculty: col.faculty != null ? (values[col.faculty] ?? "").trim() : "",
      venue: col.venue != null ? (values[col.venue] ?? "").trim() : "",
    });
  }
  return sessions;
}

function findHeaderRow(rows: (string | number | Date | null)[][]) {
  const limit = Math.min(rows.length, 15);
  for (let r = 0; r < limit; r += 1) {
    const headers = (rows[r] ?? []).map((cell) => normalizeHeader(cellString(cell)));
    if (
      headers.includes("day") &&
      headers.some((h) => h === "start" || h === "starttime") &&
      headers.some((h) => h === "end" || h === "endtime") &&
      headers.some((h) => h === "subject" || h === "course" || h === "coursename")
    ) {
      return r;
    }
  }
  return 0;
}

function columnMap(headers: string[]) {
  const map: Record<string, number> = {};
  headers.forEach((h, i) => {
    if (h === "day" || h === "weekday") map.day ??= i;
    if (h === "start" || h === "starttime" || h === "from") map.start ??= i;
    if (h === "end" || h === "endtime" || h === "to") map.end ??= i;
    if (h === "subject" || h === "course" || h === "coursename") map.subject ??= i;
    if (h === "code" || h === "coursecode" || h === "subjectcode") map.code ??= i;
    if (h === "type" || h === "category" || h === "kind") map.type ??= i;
    if (h === "faculty" || h === "instructor" || h === "professor") map.faculty ??= i;
    if (h === "venue" || h === "room" || h === "location") map.venue ??= i;
  });
  return map;
}

function cellString(value: string | number | Date | null | undefined) {
  if (value == null || value === "") return "";
  if (value instanceof Date) {
    return `${value.getHours()}:${String(value.getMinutes()).padStart(2, "0")}`;
  }
  return String(value);
}

function normalizeHeader(raw: string) {
  return raw.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function parseDay(raw: string) {
  const value = raw.trim().toLowerCase();
  const names: Record<string, number> = {
    monday: 1,
    mon: 1,
    tuesday: 2,
    tue: 2,
    tues: 2,
    wednesday: 3,
    wed: 3,
    thursday: 4,
    thu: 4,
    thur: 4,
    thurs: 4,
    friday: 5,
    fri: 5,
    saturday: 6,
    sat: 6,
    sunday: 7,
    sun: 7,
  };
  if (value in names) return names[value];
  const asInt = Number.parseInt(value, 10);
  if (asInt >= 1 && asInt <= 7) return asInt;
  return null;
}

function parseTime(raw: string, original?: string | number | Date | null) {
  if (original instanceof Date) {
    return original.getHours() * 60 + original.getMinutes();
  }
  if (typeof original === "number" && original >= 0 && original < 1) {
    return Math.round(original * 24 * 60);
  }

  let value = raw.trim().toUpperCase().replace(/\./g, ":");
  if (!value) return null;

  const asDouble = Number.parseFloat(raw.trim());
  if (!Number.isNaN(asDouble) && asDouble >= 0 && asDouble < 1) {
    return Math.round(asDouble * 24 * 60);
  }

  let isPm = false;
  let isAm = false;
  if (value.endsWith("PM")) {
    isPm = true;
    value = value.slice(0, -2).trim();
  } else if (value.endsWith("AM")) {
    isAm = true;
    value = value.slice(0, -2).trim();
  }

  const parts = value.split(":");
  const hour = Number.parseInt(parts[0] ?? "", 10);
  const minute = parts.length > 1 ? Number.parseInt(parts[1] ?? "0", 10) : 0;
  if (Number.isNaN(hour) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  let h = hour;
  if (isPm && h < 12) h += 12;
  if (isAm && h === 12) h = 0;
  return h * 60 + minute;
}

function parseKind(raw: string): SubjectKind {
  const value = raw.trim().toLowerCase();
  if (value.includes("elect") || value.includes("optional")) return "elective";
  return "core";
}
