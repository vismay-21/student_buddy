class HolidayDto {
  final String holidayId;
  final String semesterId;
  final DateTime holidayDate;
  final String holidayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  HolidayDto({
    required this.holidayId,
    required this.semesterId,
    required this.holidayDate,
    required this.holidayName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HolidayDto.fromJson(Map<String, dynamic> json) {
    return HolidayDto(
      holidayId: json['holiday_id'] as String,
      semesterId: json['semester_id'] as String,
      holidayDate: DateTime.parse(json['holiday_date'] as String),
      holidayName: json['holiday_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'holiday_id': holidayId,
      'semester_id': semesterId,
      'holiday_date': holidayDate.toIso8601String().substring(0, 10),
      'holiday_name': holidayName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class HolidayCreateRequest {
  final String semesterId;
  final DateTime holidayDate;
  final String holidayName;

  HolidayCreateRequest({
    required this.semesterId,
    required this.holidayDate,
    required this.holidayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'semester_id': semesterId,
      'holiday_date': holidayDate.toIso8601String().substring(0, 10),
      'holiday_name': holidayName,
    };
  }
}

class HolidayUpdateRequest {
  final DateTime? holidayDate;
  final String? holidayName;

  HolidayUpdateRequest({
    this.holidayDate,
    this.holidayName,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (holidayDate != null) {
      data['holiday_date'] = holidayDate!.toIso8601String().substring(0, 10);
    }
    if (holidayName != null) {
      data['holiday_name'] = holidayName;
    }
    return data;
  }
}
