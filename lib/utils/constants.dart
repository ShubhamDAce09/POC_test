class AppConstants {
  static const String appName = 'IIM Shillong Timetable';
  static const String instituteName = 'IIM Shillong';
  static const String allowedEmailDomain = 'iimshillong.ac.in';
  static const Duration reminderLeadTime = Duration(minutes: 15);
  static const String timezoneName = 'Asia/Kolkata';

  static const String firestoreTimetableDoc = 'office_timetables/current';
  static const String firestoreUsersCollection = 'users';

  static const String eventLogin = 'login';
  static const String eventFileUpload = 'file_upload';
  static const String eventSubjectSelection = 'subject_selection';
  static const String eventReminderTrigger = 'reminder_trigger';
  static const String eventAppOpen = 'app_open';
}
