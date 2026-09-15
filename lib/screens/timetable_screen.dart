import 'package:flutter/material.dart';

import '../app_bootstrap.dart';
import '../models/class_session.dart';
import '../models/student_profile.dart';
import '../models/timetable.dart';
import 'subject_selection_screen.dart';
import 'upload_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({
    super.key,
    required this.user,
    required this.timetable,
    required this.onChanged,
  });

  final StudentProfile user;
  final OfficialTimetable timetable;
  final VoidCallback onChanged;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late List<ClassSession> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.timetable.personalized(widget.user.selectedElectiveKeys);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppBootstrap.notifications.syncReminders(_sessions);
    });
  }

  @override
  void didUpdateWidget(covariant TimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sessions = widget.timetable.personalized(widget.user.selectedElectiveKeys);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<ClassSession>>{};
    for (final session in _sessions) {
      grouped.putIfAbsent(session.day, () => []).add(session);
    }
    final days = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My timetable'),
        actions: [
          IconButton(
            tooltip: 'Change electives',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubjectSelectionScreen(
                    user: widget.user,
                    timetable: widget.timetable,
                    onSaved: () {
                      Navigator.of(context).pop();
                      widget.onChanged();
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Replace office file',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UploadScreen(
                    user: widget.user,
                    replaceExisting: true,
                    onUploaded: () {
                      Navigator.of(context).pop();
                      widget.onChanged();
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
          ),
          IconButton(
            onPressed: () => AppBootstrap.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: days.isEmpty
          ? const Center(child: Text('No classes for the current selection.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final items = grouped[day]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      child: Text(
                        ClassSession.weekdayName(day),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final session in items)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(session.kind == SubjectKind.core ? 'C' : 'E'),
                          ),
                          title: Text(
                            session.courseCode.isEmpty
                                ? session.subjectName
                                : '${session.courseCode} · ${session.subjectName}',
                          ),
                          subtitle: Text(
                            [
                              '${session.startLabel} – ${session.endLabel}',
                              if (session.venue.isNotEmpty) session.venue,
                              if (session.faculty.isNotEmpty) session.faculty,
                            ].join(' · '),
                          ),
                          trailing: Text(
                            session.kind == SubjectKind.core ? 'Core' : 'Elective',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
