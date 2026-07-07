import '../subject/subject_dto.dart';

class LectureInstanceDto {
  final String lectureInstanceId;
  final String lectureTemplateId;
  final DateTime lectureDate;
  final String lectureStatus; // scheduled, holiday, cancelled
  final String attendanceStatus; // unmarked, present, absent
  final String? markedBy;
  final DateTime? markedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LectureTemplateNestedDto lectureTemplate;

  LectureInstanceDto({
    required this.lectureInstanceId,
    required this.lectureTemplateId,
    required this.lectureDate,
    required this.lectureStatus,
    required this.attendanceStatus,
    this.markedBy,
    this.markedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lectureTemplate,
  });

  factory LectureInstanceDto.fromJson(Map<String, dynamic> json) {
    return LectureInstanceDto(
      lectureInstanceId: json['lecture_instance_id'] as String,
      lectureTemplateId: json['lecture_template_id'] as String,
      lectureDate: DateTime.parse(json['lecture_date'] as String),
      lectureStatus: json['lecture_status'] as String? ?? 'scheduled',
      attendanceStatus: json['attendance_status'] as String? ?? 'unmarked',
      markedBy: json['marked_by'] as String?,
      markedAt: json['marked_at'] != null ? DateTime.parse(json['marked_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lectureTemplate: LectureTemplateNestedDto.fromJson(
        json['lecture_template'] as Map<String, dynamic>,
      ),
    );
  }
}

class LectureTemplateNestedDto {
  final String lectureTemplateId;
  final String subjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final SubjectDto subject;

  LectureTemplateNestedDto({
    required this.lectureTemplateId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.subject,
  });

  factory LectureTemplateNestedDto.fromJson(Map<String, dynamic> json) {
    return LectureTemplateNestedDto(
      lectureTemplateId: json['lecture_template_id'] as String,
      subjectId: json['subject_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] as String?,
      subject: SubjectDto.fromJson(json['subject'] as Map<String, dynamic>),
    );
  }
}

class LectureInstanceUpdateRequest {
  final String? attendanceStatus;
  final String? lectureStatus;

  LectureInstanceUpdateRequest({
    this.attendanceStatus,
    this.lectureStatus,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (attendanceStatus != null) data['attendance_status'] = attendanceStatus;
    if (lectureStatus != null) data['lecture_status'] = lectureStatus;
    return data;
  }
}

class LectureInstanceBulkUpdateRequest {
  final String lectureDate; // format yyyy-MM-dd
  final String attendanceStatus; // present, absent
  final String? semesterId;

  LectureInstanceBulkUpdateRequest({
    required this.lectureDate,
    required this.attendanceStatus,
    this.semesterId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'lecture_date': lectureDate,
      'attendance_status': attendanceStatus,
    };
    if (semesterId != null) data['semester_id'] = semesterId;
    return data;
  }
}

class LectureInstanceBulkUpdateResponseDto {
  final int updatedCount;
  final int skippedCount;

  LectureInstanceBulkUpdateResponseDto({
    required this.updatedCount,
    required this.skippedCount,
  });

  factory LectureInstanceBulkUpdateResponseDto.fromJson(Map<String, dynamic> json) {
    return LectureInstanceBulkUpdateResponseDto(
      updatedCount: json['updated_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
    );
  }
}

class AttendanceStatsDto {
  final int totalLectures;
  final int presentLectures;
  final int absentLectures;
  final double attendancePercentage;
  final int remainingLectures;
  final int safeSkipCount;
  final String statusMessage;
  final String? criteriaMode;

  AttendanceStatsDto({
    required this.totalLectures,
    required this.presentLectures,
    required this.absentLectures,
    required this.attendancePercentage,
    required this.remainingLectures,
    required this.safeSkipCount,
    required this.statusMessage,
    this.criteriaMode,
  });

  factory AttendanceStatsDto.fromJson(Map<String, dynamic> json) {
    return AttendanceStatsDto(
      totalLectures: json['total_lectures'] as int? ?? 0,
      presentLectures: json['present_lectures'] as int? ?? 0,
      absentLectures: json['absent_lectures'] as int? ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num? ?? 0.0).toDouble(),
      remainingLectures: json['remaining_lectures'] as int? ?? 0,
      safeSkipCount: json['safe_skip_count'] as int? ?? 0,
      statusMessage: json['status_message'] as String? ?? '',
      criteriaMode: json['criteria_mode'] as String?,
    );
  }
}
