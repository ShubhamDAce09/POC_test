import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/timetable_repository.dart';
import 'utils/constants.dart';

class AppBootstrap {
  AppBootstrap._();

  static bool firebaseReady = false;
  static late AuthService auth;
  static late TimetableRepository timetable;
  static late AnalyticsService analytics;
  static late NotificationService notifications;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(AppConstants.timezoneName));

    firebaseReady = await _tryFirebase();
    final prefs = await SharedPreferences.getInstance();

    analytics = AnalyticsService(enabled: firebaseReady);
    auth = AuthService(prefs: prefs, firebaseReady: firebaseReady);
    timetable = TimetableRepository(
      prefs: prefs,
      firebaseReady: firebaseReady,
    );
    notifications = NotificationService(analytics: analytics);
    try {
      await notifications.initialize();
    } catch (error) {
      debugPrint('Notifications unavailable: $error');
    }

    await analytics.logAppOpen();
  }

  static Future<bool> _tryFirebase() async {
    const apiKey = String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: '',
    );
    final configured = !DefaultFirebaseOptions.android.apiKey.startsWith('REPLACE_') ||
        apiKey.isNotEmpty;
    if (!configured) {
      debugPrint('Firebase placeholders detected; running in local demo mode.');
      return false;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
      return true;
    } catch (error, stack) {
      debugPrint('Firebase unavailable, using local demo mode: $error');
      debugPrint('$stack');
      return false;
    }
  }
}
