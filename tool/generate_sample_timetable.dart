import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

List<List<String>> sampleRows() => const [
      [
        'Day',
        'Start Time',
        'End Time',
        'Course Code',
        'Subject',
        'Type',
        'Faculty',
        'Venue',
      ],
      [
        'Monday',
        '09:00',
        '10:30',
        'PGPEX-C1',
        'Managerial Economics',
        'Core',
        'Faculty A',
        'CH-1',
      ],
      [
        'Monday',
        '11:00',
        '12:30',
        'PGPEX-E1',
        'FinTech Strategy',
        'Elective',
        'Faculty B',
        'CH-2',
      ],
      [
        'Tuesday',
        '09:00',
        '10:30',
        'PGPEX-C2',
        'Financial Accounting',
        'Core',
        'Faculty C',
        'CH-1',
      ],
      [
        'Tuesday',
        '14:00',
        '15:30',
        'PGPEX-E2',
        'Digital Marketing',
        'Elective',
        'Faculty D',
        'CH-3',
      ],
      [
        'Wednesday',
        '09:00',
        '10:30',
        'PGPEX-C3',
        'Organizational Behaviour',
        'Core',
        'Faculty E',
        'CH-1',
      ],
      [
        'Thursday',
        '11:00',
        '12:30',
        'PGPEX-E1',
        'FinTech Strategy',
        'Elective',
        'Faculty B',
        'CH-2',
      ],
      [
        'Friday',
        '09:00',
        '10:30',
        'PGPEX-C1',
        'Managerial Economics',
        'Core',
        'Faculty A',
        'CH-1',
      ],
      [
        'Friday',
        '14:00',
        '15:30',
        'PGPEX-E3',
        'Supply Chain Analytics',
        'Elective',
        'Faculty F',
        'CH-4',
      ],
    ];

List<int> buildSampleTimetableBytes() {
  final workbook = Excel.createExcel();
  final sheet = workbook['Timetable'];
  workbook.setDefaultSheet('Timetable');
  for (final row in sampleRows()) {
    sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
  }
  final defaultSheet = workbook.tables.keys.firstWhere(
    (name) => name != 'Timetable',
    orElse: () => '',
  );
  if (defaultSheet.isNotEmpty) {
    workbook.delete(defaultSheet);
  }
  return workbook.encode()!;
}

void main() {
  final bytes = buildSampleTimetableBytes();
  final out = File(p.join('assets', 'sample_timetable.xlsx'));
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes);
  stdout.writeln('Wrote ${out.path} (${bytes.length} bytes)');
}
