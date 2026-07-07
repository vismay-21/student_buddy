class LectureTemplateDto {
  final String lectureTemplateId;
  final String subjectId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // format HH:mm:ss or HH:mm
  final String endTime; // format HH:mm:ss or HH:mm
  final String? room;
  final DateTime createdAt;
  final DateTime updatedAt;

  LectureTemplateDto({
    required this.lectureTemplateId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LectureTemplateDto.fromJson(Map<String, dynamic> json) {
    return LectureTemplateDto(
      lectureTemplateId: json['lecture_template_id'] as String,
      subjectId: json['subject_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lecture_template_id': lectureTemplateId,
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class LectureTemplateCreateRequest {
  final String subjectId;
  final int dayOfWeek;
  final String startTime; // format "HH:mm"
  final String endTime; // format "HH:mm"
  final String? room;

  LectureTemplateCreateRequest({
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }
}

class LectureTemplateUpdateRequest {
  final int? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final String? room;

  LectureTemplateUpdateRequest({
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.room,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (dayOfWeek != null) data['day_of_week'] = dayOfWeek;
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (room != null) data['room'] = room;
    return data;
  }
}
