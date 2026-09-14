enum SubjectKind { core, elective }

class ClassSession {
  const ClassSession({
    required this.id,
    required this.subjectName,
    required this.courseCode,
    required this.kind,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    this.faculty = '',
    this.venue = '',
  });

  final String id;
  final String subjectName;
  final String courseCode;
  final SubjectKind kind;
  final int day; // DateTime.monday ... DateTime.sunday
  final int startMinutes;
  final int endMinutes;
  final String faculty;
  final String venue;

  String get subjectKey =>
      (courseCode.isNotEmpty ? courseCode : subjectName).trim().toLowerCase();

  String get startLabel => _formatMinutes(startMinutes);
  String get endLabel => _formatMinutes(endMinutes);
  String get dayLabel => weekdayName(day);

  static String weekdayName(int day) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (day < 1 || day > 7) return 'Unknown';
    return names[day];
  }

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '${hour12.toString().padLeft(2, ' ')}:${m.toString().padLeft(2, '0')} $period';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectName': subjectName,
        'courseCode': courseCode,
        'kind': kind.name,
        'day': day,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'faculty': faculty,
        'venue': venue,
      };

  factory ClassSession.fromMap(Map<String, dynamic> map) {
    return ClassSession(
      id: map['id'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      kind: (map['kind'] as String?) == SubjectKind.elective.name
          ? SubjectKind.elective
          : SubjectKind.core,
      day: (map['day'] as num?)?.toInt() ?? DateTime.monday,
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
      faculty: map['faculty'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
    );
  }
}

class SubjectOption {
  const SubjectOption({
    required this.key,
    required this.name,
    required this.courseCode,
    required this.kind,
  });

  final String key;
  final String name;
  final String courseCode;
  final SubjectKind kind;

  String get displayLabel =>
      courseCode.isEmpty ? name : '$courseCode · $name';
}
