class AppSettingsDto {
  final int settingsId;
  final String? activeSemesterId;
  final String themeMode;
  final bool financeEnabled;
  final bool morningDigestEnabled;
  final bool nightDigestEnabled;
  final bool attendancePromptEnabled;
  final String? notesDownloadDirectory;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppSettingsDto({
    required this.settingsId,
    this.activeSemesterId,
    required this.themeMode,
    required this.financeEnabled,
    required this.morningDigestEnabled,
    required this.nightDigestEnabled,
    required this.attendancePromptEnabled,
    this.notesDownloadDirectory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettingsDto.fromJson(Map<String, dynamic> json) {
    return AppSettingsDto(
      settingsId: json['settings_id'] as int,
      activeSemesterId: json['active_semester_id'] as String?,
      themeMode: json['theme_mode'] as String? ?? 'system',
      financeEnabled: json['finance_enabled'] as bool? ?? false,
      morningDigestEnabled: json['morning_digest_enabled'] as bool? ?? false,
      nightDigestEnabled: json['night_digest_enabled'] as bool? ?? false,
      attendancePromptEnabled: json['attendance_prompt_enabled'] as bool? ?? false,
      notesDownloadDirectory: json['notes_download_directory'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settings_id': settingsId,
      'active_semester_id': activeSemesterId,
      'theme_mode': themeMode,
      'finance_enabled': financeEnabled,
      'morning_digest_enabled': morningDigestEnabled,
      'night_digest_enabled': nightDigestEnabled,
      'attendance_prompt_enabled': attendancePromptEnabled,
      'notes_download_directory': notesDownloadDirectory,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AppSettingsUpdateRequest {
  final String? activeSemesterId;
  final String? themeMode;
  final bool? financeEnabled;
  final bool? morningDigestEnabled;
  final bool? nightDigestEnabled;
  final bool? attendancePromptEnabled;
  final String? notesDownloadDirectory;

  AppSettingsUpdateRequest({
    this.activeSemesterId,
    this.themeMode,
    this.financeEnabled,
    this.morningDigestEnabled,
    this.nightDigestEnabled,
    this.attendancePromptEnabled,
    this.notesDownloadDirectory,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (activeSemesterId != null) data['active_semester_id'] = activeSemesterId;
    if (themeMode != null) data['theme_mode'] = themeMode;
    if (financeEnabled != null) data['finance_enabled'] = financeEnabled;
    if (morningDigestEnabled != null) data['morning_digest_enabled'] = morningDigestEnabled;
    if (nightDigestEnabled != null) data['night_digest_enabled'] = nightDigestEnabled;
    if (attendancePromptEnabled != null) data['attendance_prompt_enabled'] = attendancePromptEnabled;
    if (notesDownloadDirectory != null) data['notes_download_directory'] = notesDownloadDirectory;
    return data;
  }
}
