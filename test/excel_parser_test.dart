import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iim_shillong_community/models/class_session.dart';
import 'package:iim_shillong_community/services/excel_parser_service.dart';
import 'package:iim_shillong_community/utils/email.dart';

import '../tool/generate_sample_timetable.dart';

void main() {
  test('accepts only iimshillong.ac.in emails', () {
    expect(isInstituteEmail('shubham.pgpex26@iimshillong.ac.in'), isTrue);
    expect(isInstituteEmail('dean@IIMShillong.ac.in'), isTrue);
    expect(isInstituteEmail('student@gmail.com'), isFalse);
    expect(isInstituteEmail('@iimshillong.ac.in'), isFalse);
  });

  test('parses core and elective sessions from the office Excel layout', () {
    final parser = ExcelParserService();
    final timetable = parser.parseBytes(
      bytes: buildSampleTimetableBytes(),
      fileName: 'office.xlsx',
      uploadedBy: 'office@iimshillong.ac.in',
    );

    expect(timetable.sessions, isNotEmpty);
    expect(timetable.coreSubjects.map((s) => s.courseCode), contains('PGPEX-C1'));
    expect(timetable.electives.map((s) => s.courseCode), contains('PGPEX-E1'));

    final personalized = timetable.personalized({'pgpex-e1'});
    expect(
      personalized.any((s) => s.courseCode == 'PGPEX-E2'),
      isFalse,
    );
    expect(
      personalized.any((s) => s.kind == SubjectKind.core),
      isTrue,
    );
    expect(
      personalized.where((s) => s.courseCode == 'PGPEX-E1'),
      isNotEmpty,
    );
  });

  test('parses 12-hour clock times', () {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    sheet.appendRow([
      TextCellValue('Day'),
      TextCellValue('Start Time'),
      TextCellValue('End Time'),
      TextCellValue('Subject'),
      TextCellValue('Type'),
    ]);
    sheet.appendRow([
      TextCellValue('Mon'),
      TextCellValue('2:00 PM'),
      TextCellValue('3:30 PM'),
      TextCellValue('Strategy'),
      TextCellValue('Core'),
    ]);
    final timetable = ExcelParserService().parseBytes(
      bytes: workbook.encode()!,
      fileName: 'times.xlsx',
      uploadedBy: 'office@iimshillong.ac.in',
    );
    expect(timetable.sessions.single.startMinutes, 14 * 60);
    expect(timetable.sessions.single.endMinutes, 15 * 60 + 30);
  });
}
