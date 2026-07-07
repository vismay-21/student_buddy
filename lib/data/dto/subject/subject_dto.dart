class SubjectDto {
  final String subjectId;
  final String semesterId;
  final String subjectName;
  final String? facultyName;
  final String? themeColor;
  final int attendanceGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubjectDto({
    required this.subjectId,
    required this.semesterId,
    required this.subjectName,
    this.facultyName,
    this.themeColor,
    required this.attendanceGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubjectDto.fromJson(Map<String, dynamic> json) {
    return SubjectDto(
      subjectId: json['subject_id'] as String,
      semesterId: json['semester_id'] as String,
      subjectName: json['subject_name'] as String,
      facultyName: json['faculty_name'] as String?,
      themeColor: json['theme_color'] as String?,
      attendanceGoal: json['attendance_goal'] as int? ?? 75,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'semester_id': semesterId,
      'subject_name': subjectName,
      'faculty_name': facultyName,
      'theme_color': themeColor,
      'attendance_goal': attendanceGoal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SubjectCreateRequest {
  final String semesterId;
  final String subjectName;
  final String? facultyName;
  final String? themeColor;
  final int attendanceGoal;

  SubjectCreateRequest({
    required this.semesterId,
    required this.subjectName,
    this.facultyName,
    this.themeColor,
    this.attendanceGoal = 75,
  });

  Map<String, dynamic> toJson() {
    return {
      'semester_id': semesterId,
      'subject_name': subjectName,
      'faculty_name': facultyName,
      'theme_color': themeColor,
      'attendance_goal': attendanceGoal,
    };
  }
}

class SubjectUpdateRequest {
  final String? subjectName;
  final String? facultyName;
  final String? themeColor;
  final int? attendanceGoal;

  SubjectUpdateRequest({
    this.subjectName,
    this.facultyName,
    this.themeColor,
    this.attendanceGoal,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (subjectName != null) data['subject_name'] = subjectName;
    if (facultyName != null) data['faculty_name'] = facultyName;
    if (themeColor != null) data['theme_color'] = themeColor;
    if (attendanceGoal != null) data['attendance_goal'] = attendanceGoal;
    return data;
  }
}
