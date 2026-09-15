import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';

import '../models/class_session.dart';
import '../models/timetable.dart';

class ExcelParseException implements Exception {
  ExcelParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ExcelParserService {
  ExcelParserService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  OfficialTimetable parseBytes({
    required List<int> bytes,
    required String fileName,
    required String uploadedBy,
  }) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw ExcelParseException('The Excel file has no worksheets.');
    }

    final sessions = <ClassSession>[];
    for (final sheet in workbook.tables.values) {
      sessions.addAll(_parseSheet(sheet));
    }

    if (sessions.isEmpty) {
      throw ExcelParseException(
        'No class rows found. Expected headers: Day, Start Time, End Time, Subject, Type.',
      );
    }

    return OfficialTimetable(
      fileName: fileName,
      uploadedBy: uploadedBy,
      uploadedAt: DateTime.now(),
      sessions: sessions,
    );
  }

  List<ClassSession> _parseSheet(Sheet sheet) {
    if (sheet.maxRows < 2) return const [];
    final headerIndex = _findHeaderRow(sheet);
    if (headerIndex == null) return const [];

    final header = _cells(sheet, headerIndex).map(_normalizeHeader).toList();
    final col = _columnMap(header);

    if (!col.containsKey('day') ||
        !col.containsKey('start') ||
        !col.containsKey('end') ||
        !col.containsKey('subject')) {
      return const [];
    }

    final sessions = <ClassSession>[];
    for (var r = headerIndex + 1; r < sheet.maxRows; r++) {
      final values = _cells(sheet, r);
      if (values.isEmpty || values.every((v) => v.trim().isEmpty)) continue;

      final day = _parseDay(values[_safe(col['day']!, values)]);
      final start = _parseTime(values[_safe(col['start']!, values)]);
      final end = _parseTime(values[_safe(col['end']!, values)]);
      final subject = values[_safe(col['subject']!, values)].trim();
      if (day == null || start == null || end == null || subject.isEmpty) {
        continue;
      }

      final code = col.containsKey('code')
          ? values[_safe(col['code']!, values)].trim()
          : '';
      final typeRaw = col.containsKey('type')
          ? values[_safe(col['type']!, values)]
          : 'core';
      final faculty = col.containsKey('faculty')
          ? values[_safe(col['faculty']!, values)].trim()
          : '';
      final venue = col.containsKey('venue')
          ? values[_safe(col['venue']!, values)].trim()
          : '';

      sessions.add(
        ClassSession(
          id: _uuid.v4(),
          subjectName: subject,
          courseCode: code,
          kind: _parseKind(typeRaw),
          day: day,
          startMinutes: start,
          endMinutes: end,
          faculty: faculty,
          venue: venue,
        ),
      );
    }
    return sessions;
  }

  int? _findHeaderRow(Sheet sheet) {
    final limit = sheet.maxRows < 15 ? sheet.maxRows : 15;
    for (var r = 0; r < limit; r++) {
      final headers = _cells(sheet, r).map(_normalizeHeader).toList();
      if (headers.contains('day') &&
          headers.any((h) => h == 'start' || h == 'starttime') &&
          headers.any((h) => h == 'end' || h == 'endtime') &&
          headers.any((h) => h == 'subject' || h == 'course' || h == 'coursename')) {
        return r;
      }
    }
    return 0;
  }

  Map<String, int> _columnMap(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (h == 'day' || h == 'weekday') map.putIfAbsent('day', () => i);
      if (h == 'start' || h == 'starttime' || h == 'from') {
        map.putIfAbsent('start', () => i);
      }
      if (h == 'end' || h == 'endtime' || h == 'to') {
        map.putIfAbsent('end', () => i);
      }
      if (h == 'subject' || h == 'course' || h == 'coursename') {
        map.putIfAbsent('subject', () => i);
      }
      if (h == 'code' || h == 'coursecode' || h == 'subjectcode') {
        map.putIfAbsent('code', () => i);
      }
      if (h == 'type' || h == 'category' || h == 'kind') {
        map.putIfAbsent('type', () => i);
      }
      if (h == 'faculty' || h == 'instructor' || h == 'professor') {
        map.putIfAbsent('faculty', () => i);
      }
      if (h == 'venue' || h == 'room' || h == 'location') {
        map.putIfAbsent('venue', () => i);
      }
    }
    return map;
  }

  List<String> _cells(Sheet sheet, int rowIndex) {
    final row = sheet.rows.length > rowIndex ? sheet.rows[rowIndex] : const [];
    return [
      for (final cell in row) _cellString(cell?.value),
    ];
  }

  String _cellString(dynamic value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is IntCellValue) return '${value.value}';
    if (value is DoubleCellValue) return '${value.value}';
    if (value is DateTimeCellValue) {
      final dt = value.asDateTimeLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (value is TimeCellValue) {
      return '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
    }
    if (value is bool) return value ? 'true' : 'false';
    return value.toString();
  }

  String _normalizeHeader(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  int _safe(int index, List<String> values) {
    if (values.isEmpty) return 0;
    if (index < 0) return 0;
    return index < values.length ? index : values.length - 1;
  }

  int? _parseDay(String raw) {
    final value = raw.trim().toLowerCase();
    const names = {
      'monday': DateTime.monday,
      'mon': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'tue': DateTime.tuesday,
      'tues': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'wed': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'thu': DateTime.thursday,
      'thur': DateTime.thursday,
      'thurs': DateTime.thursday,
      'friday': DateTime.friday,
      'fri': DateTime.friday,
      'saturday': DateTime.saturday,
      'sat': DateTime.saturday,
      'sunday': DateTime.sunday,
      'sun': DateTime.sunday,
    };
    if (names.containsKey(value)) return names[value];
    final asInt = int.tryParse(value);
    if (asInt != null && asInt >= 1 && asInt <= 7) return asInt;
    return null;
  }

  int? _parseTime(String raw) {
    var value = raw.trim().toUpperCase().replaceAll('.', ':');
    if (value.isEmpty) return null;

    final asDouble = double.tryParse(raw.trim());
    if (asDouble != null && asDouble >= 0 && asDouble < 1) {
      return (asDouble * 24 * 60).round();
    }

    var minutesOffset = 0;
    var isPm = false;
    var isAm = false;
    if (value.endsWith('PM')) {
      isPm = true;
      value = value.substring(0, value.length - 2).trim();
    } else if (value.endsWith('AM')) {
      isAm = true;
      value = value.substring(0, value.length - 2).trim();
    }

    final parts = value.split(':');
    if (parts.isEmpty) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    var h = hour;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    return h * 60 + minute + minutesOffset;
  }

  SubjectKind _parseKind(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('elect') || value.contains('optional')) {
      return SubjectKind.elective;
    }
    return SubjectKind.core;
  }
}
