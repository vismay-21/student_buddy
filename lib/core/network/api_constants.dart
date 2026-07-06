class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, localhost/127.0.0.1 for iOS simulator / Web / Desktop.
  // We can dynamically check, but keeping it configurable with a default.
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Academic Endpoints
  static const String semesters = '/academic/semesters';
  static const String subjects = '/academic/subjects';
  static const String lectureTemplates = '/academic/lecture-templates';
  static const String lectureInstances = '/academic/lecture-instances';
  static const String attendanceSettings = '/academic/attendance-settings';
  static const String holidays = '/academic/holidays';

  // App Settings Endpoints
  static const String appSettings = '/app-settings';

  // Core Features
  static const String todos = '/todos';
  static const String notes = '/notes';
  static const String reviewQueue = '/review-queue';
  static const String activityLogs = '/activity-logs';
}
