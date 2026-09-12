import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_profile.dart';
import '../models/timetable.dart';
import '../utils/constants.dart';

class TimetableRepository {
  TimetableRepository({
    required SharedPreferences prefs,
    required this.firebaseReady,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;
  final bool firebaseReady;

  static const _timetableKey = 'official_timetable_json';
  static const _profilePrefix = 'profile_';

  Future<OfficialTimetable?> loadOfficialTimetable() async {
    if (firebaseReady) {
      final snap = await FirebaseFirestore.instance
          .doc(AppConstants.firestoreTimetableDoc)
          .get();
      if (!snap.exists || snap.data() == null) return null;
      return OfficialTimetable.fromMap(snap.data()!);
    }
    final raw = _prefs.getString(_timetableKey);
    if (raw == null) return null;
    return OfficialTimetable.fromMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveOfficialTimetable(OfficialTimetable timetable) async {
    if (firebaseReady) {
      await FirebaseFirestore.instance
          .doc(AppConstants.firestoreTimetableDoc)
          .set(timetable.toMap());
      return;
    }
    await _prefs.setString(_timetableKey, jsonEncode(timetable.toMap()));
  }

  Future<StudentProfile> loadProfile(StudentProfile user) async {
    if (firebaseReady) {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.firestoreUsersCollection)
          .doc(user.uid)
          .get();
      if (!snap.exists || snap.data() == null) {
        await saveProfile(user);
        return user;
      }
      final stored = StudentProfile.fromMap(snap.data()!);
      return user.copyWith(selectedElectiveKeys: stored.selectedElectiveKeys);
    }
    final raw = _prefs.getString('$_profilePrefix${user.uid}');
    if (raw == null) return user;
    final stored = StudentProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    return user.copyWith(selectedElectiveKeys: stored.selectedElectiveKeys);
  }

  Future<void> saveProfile(StudentProfile profile) async {
    if (firebaseReady) {
      await FirebaseFirestore.instance
          .collection(AppConstants.firestoreUsersCollection)
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
      return;
    }
    await _prefs.setString(
      '$_profilePrefix${profile.uid}',
      jsonEncode(profile.toMap()),
    );
  }
}
