class SemesterDto {
  final String semesterId;
  final int semesterNumber;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SemesterDto({
    required this.semesterId,
    required this.semesterNumber,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SemesterDto.fromJson(Map<String, dynamic> json) {
    return SemesterDto(
      semesterId: json['semester_id'] as String,
      semesterNumber: json['semester_number'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester_id': semesterId,
      'semester_number': semesterNumber,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SemesterCreateRequest {
  final int semesterNumber;
  final DateTime startDate;
  final DateTime endDate;

  SemesterCreateRequest({
    required this.semesterNumber,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'semester_number': semesterNumber,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
    };
  }
}
