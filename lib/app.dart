import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'models/student_profile.dart';
import 'models/timetable.dart';
import 'screens/login_screen.dart';
import 'screens/subject_selection_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/upload_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

class CommunityApp extends StatelessWidget {
  const CommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentProfile?>(
      stream: AppBootstrap.auth.authState(),
      initialData: AppBootstrap.auth.currentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return SessionGate(user: user);
      },
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.user});

  final StudentProfile user;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<_SessionData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant SessionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _future = _load();
    }
  }

  Future<_SessionData> _load() async {
    final timetable = await AppBootstrap.timetable.loadOfficialTimetable();
    final profile = await AppBootstrap.timetable.loadProfile(widget.user);
    return _SessionData(timetable: timetable, profile: profile);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SessionData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppConstants.appName)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load timetable: ${snapshot.error}'),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        if (data.timetable == null) {
          return UploadScreen(
            user: data.profile,
            onUploaded: _reload,
          );
        }
        if (data.timetable!.electives.isNotEmpty &&
            data.profile.selectedElectiveKeys.isEmpty) {
          return SubjectSelectionScreen(
            user: data.profile,
            timetable: data.timetable!,
            onSaved: _reload,
          );
        }
        return TimetableScreen(
          user: data.profile,
          timetable: data.timetable!,
          onChanged: _reload,
        );
      },
    );
  }
}

class _SessionData {
  const _SessionData({required this.timetable, required this.profile});
  final OfficialTimetable? timetable;
  final StudentProfile profile;
}
