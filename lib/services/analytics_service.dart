import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class AnalyticsService {
  AnalyticsService({required this.enabled});

  final bool enabled;
  FirebaseAnalytics? get _fa =>
      enabled ? FirebaseAnalytics.instance : null;

  Future<void> logAppOpen() async {
    await _log(AppConstants.eventAppOpen);
    await _fa?.logAppOpen();
  }

  Future<void> logLogin({required String method}) async {
    await _log(AppConstants.eventLogin, {'method': method});
    await _fa?.logLogin(loginMethod: method);
  }

  Future<void> logFileUpload({required String fileName, required int sessionCount}) {
    return _log(AppConstants.eventFileUpload, {
      'file_name': fileName,
      'session_count': sessionCount,
    });
  }

  Future<void> logSubjectSelection({required int electiveCount}) {
    return _log(AppConstants.eventSubjectSelection, {
      'elective_count': electiveCount,
    });
  }

  Future<void> logReminderTrigger({
    required String subject,
    required String day,
    String phase = 'fired',
  }) {
    return _log(AppConstants.eventReminderTrigger, {
      'subject': subject,
      'day': day,
      'phase': phase,
    });
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    debugPrint('analytics:$name ${params ?? {}}');
    if (!enabled) return;
    try {
      await _fa?.logEvent(name: name, parameters: params);
    } catch (error) {
      debugPrint('analytics failed: $error');
    }
  }
}
