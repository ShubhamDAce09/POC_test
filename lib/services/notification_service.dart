import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/class_session.dart';
import '../utils/constants.dart';
import 'analytics_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('notification background tap: ${response.payload}');
}

class NotificationService {
  NotificationService({required AnalyticsService analytics})
      : _analytics = analytics;

  final AnalyticsService _analytics;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'class_reminders',
    'Class reminders',
    description: 'Alerts 15 minutes before an IIM Shillong class',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _analytics.logReminderTrigger(
            subject: data['subject'] as String? ?? '',
            day: data['day'] as String? ?? '',
            phase: 'opened',
          );
        } catch (_) {}
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> syncReminders(List<ClassSession> sessions) async {
    await _plugin.cancelAll();
    for (final session in sessions) {
      await _schedule(session);
    }
  }

  Future<void> _schedule(ClassSession session) async {
    final fireMinutes = session.startMinutes -
        AppConstants.reminderLeadTime.inMinutes;
    if (fireMinutes < 0) return;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      fireMinutes ~/ 60,
      fireMinutes % 60,
    );
    while (next.weekday != session.day || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    final id = Object.hash(session.subjectKey, session.day, session.startMinutes) &
        0x7fffffff;
    final payload = jsonEncode({
      'subject': session.subjectName,
      'day': session.dayLabel,
    });

    try {
      await _plugin.zonedSchedule(
        id,
        '${session.subjectName} starts soon',
        '${session.dayLabel} ${session.startLabel}–${session.endLabel}'
            '${session.venue.isEmpty ? '' : ' · ${session.venue}'}',
        next,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
      await _analytics.logReminderTrigger(
        subject: session.subjectName,
        day: session.dayLabel,
        phase: 'scheduled',
      );
    } catch (error) {
      debugPrint('Failed to schedule reminder for ${session.subjectName}: $error');
    }
  }
}
