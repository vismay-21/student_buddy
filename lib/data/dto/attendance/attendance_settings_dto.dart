class AttendanceSettingsDto {
  final String criteriaMode; // overall, subject, custom
  final int overallAttendanceGoal;

  AttendanceSettingsDto({
    required this.criteriaMode,
    required this.overallAttendanceGoal,
  });

  factory AttendanceSettingsDto.fromJson(Map<String, dynamic> json) {
    return AttendanceSettingsDto(
      criteriaMode: json['criteria_mode'] as String? ?? 'overall',
      overallAttendanceGoal: json['overall_attendance_goal'] as int? ?? 75,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criteria_mode': criteriaMode,
      'overall_attendance_goal': overallAttendanceGoal,
    };
  }

  AttendanceSettingsDto copyWith({
    String? criteriaMode,
    int? overallAttendanceGoal,
  }) {
    return AttendanceSettingsDto(
      criteriaMode: criteriaMode ?? this.criteriaMode,
      overallAttendanceGoal: overallAttendanceGoal ?? this.overallAttendanceGoal,
    );
  }
}

class AttendanceSettingsUpdateRequest {
  final String? criteriaMode;
  final int? overallAttendanceGoal;

  AttendanceSettingsUpdateRequest({
    this.criteriaMode,
    this.overallAttendanceGoal,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (criteriaMode != null) data['criteria_mode'] = criteriaMode;
    if (overallAttendanceGoal != null) data['overall_attendance_goal'] = overallAttendanceGoal;
    return data;
  }
}
