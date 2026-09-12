import 'class_session.dart';

class OfficialTimetable {
  const OfficialTimetable({
    required this.fileName,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.sessions,
  });

  final String fileName;
  final String uploadedBy;
  final DateTime uploadedAt;
  final List<ClassSession> sessions;

  List<SubjectOption> get coreSubjects => _uniqueByKind(SubjectKind.core);
  List<SubjectOption> get electives => _uniqueByKind(SubjectKind.elective);

  List<SubjectOption> _uniqueByKind(SubjectKind kind) {
    final seen = <String>{};
    final result = <SubjectOption>[];
    for (final session in sessions.where((s) => s.kind == kind)) {
      if (seen.add(session.subjectKey)) {
        result.add(
          SubjectOption(
            key: session.subjectKey,
            name: session.subjectName,
            courseCode: session.courseCode,
            kind: session.kind,
          ),
        );
      }
    }
    result.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
    return result;
  }

  List<ClassSession> personalized(Set<String> selectedElectiveKeys) {
    final filtered = sessions.where((session) {
      if (session.kind == SubjectKind.core) return true;
      return selectedElectiveKeys.contains(session.subjectKey);
    }).toList()
      ..sort((a, b) {
        final dayCmp = a.day.compareTo(b.day);
        if (dayCmp != 0) return dayCmp;
        return a.startMinutes.compareTo(b.startMinutes);
      });
    return filtered;
  }

  Map<String, dynamic> toMap() => {
        'fileName': fileName,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt.toIso8601String(),
        'sessions': sessions.map((s) => s.toMap()).toList(),
      };

  factory OfficialTimetable.fromMap(Map<String, dynamic> map) {
    final rawSessions = map['sessions'] as List<dynamic>? ?? const [];
    return OfficialTimetable(
      fileName: map['fileName'] as String? ?? 'timetable.xlsx',
      uploadedBy: map['uploadedBy'] as String? ?? '',
      uploadedAt: DateTime.tryParse(map['uploadedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sessions: rawSessions
          .whereType<Map>()
          .map((row) => ClassSession.fromMap(Map<String, dynamic>.from(row)))
          .toList(),
    );
  }
}
