import 'package:flutter/material.dart';

import '../app_bootstrap.dart';
import '../models/student_profile.dart';
import '../models/timetable.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({
    super.key,
    required this.user,
    required this.timetable,
    required this.onSaved,
  });

  final StudentProfile user;
  final OfficialTimetable timetable;
  final VoidCallback onSaved;

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  late Set<String> _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.user.selectedElectiveKeys};
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final profile = widget.user.copyWith(selectedElectiveKeys: _selected);
    await AppBootstrap.timetable.saveProfile(profile);
    await AppBootstrap.analytics.logSubjectSelection(
      electiveCount: _selected.length,
    );
    if (mounted) {
      setState(() => _busy = false);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = widget.timetable.coreSubjects;
    final electives = widget.timetable.electives;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your subjects'),
        actions: [
          IconButton(
            onPressed: () => AppBootstrap.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Text(
            'Core courses are included for every student. Choose the electives you registered for.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('Core', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final subject in cores)
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(subject.displayLabel),
                subtitle: const Text('Included automatically'),
              ),
            ),
          const SizedBox(height: 20),
          Text('Electives', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (electives.isEmpty)
            const Text('This office file has no elective rows.'),
          for (final subject in electives)
            CheckboxListTile(
              value: _selected.contains(subject.key),
              title: Text(subject.displayLabel),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(subject.key);
                  } else {
                    _selected.remove(subject.key);
                  }
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(
              electives.isEmpty
                  ? 'Continue to timetable'
                  : 'Save ${_selected.length} elective${_selected.length == 1 ? '' : 's'}',
            ),
          ),
        ),
      ),
    );
  }
}
