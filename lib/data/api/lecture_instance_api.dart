import 'package:student_buddy/core/network/base_api.dart';
import '../../core/network/api_constants.dart';
import '../dto/lecture/lecture_instance_dto.dart';

class LectureInstanceApi extends BaseApi {
  Future<List<LectureInstanceDto>> getInstances({
    String? semesterId,
    String? subjectId,
    String? startDate,
    String? endDate,
    String? attendanceStatus,
    String? lectureStatus,
  }) async {
    final queryParams = <String, String>{};
    if (semesterId != null) queryParams['semester_id'] = semesterId;
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (attendanceStatus != null) queryParams['attendance_status'] = attendanceStatus;
    if (lectureStatus != null) queryParams['lecture_status'] = lectureStatus;

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isEmpty ? ApiConstants.lectureInstances : '${ApiConstants.lectureInstances}?$queryString';

    final response = await get<List<LectureInstanceDto>>(
      path,
      parser: (json) => (json as List)
          .map((item) => LectureInstanceDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<LectureInstanceDto>> getTodayLectures({String? date, String? semesterId}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (semesterId != null) queryParams['semester_id'] = semesterId;

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isEmpty
        ? '${ApiConstants.lectureInstances}/today'
        : '${ApiConstants.lectureInstances}/today?$queryString';

    final response = await get<List<LectureInstanceDto>>(
      path,
      parser: (json) => (json as List)
          .map((item) => LectureInstanceDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<LectureInstanceDto> getInstanceById(String instanceId) async {
    final response = await get<LectureInstanceDto>(
      '${ApiConstants.lectureInstances}/$instanceId',
      parser: (json) => LectureInstanceDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<LectureInstanceBulkUpdateResponseDto> markWholeDay(LectureInstanceBulkUpdateRequest request) async {
    final response = await put<LectureInstanceBulkUpdateResponseDto>(
      '${ApiConstants.lectureInstances}/day',
      data: request.toJson(),
      parser: (json) => LectureInstanceBulkUpdateResponseDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<LectureInstanceDto> updateAttendance(String instanceId, LectureInstanceUpdateRequest request) async {
    final response = await put<LectureInstanceDto>(
      '${ApiConstants.lectureInstances}/$instanceId',
      data: request.toJson(),
      parser: (json) => LectureInstanceDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AttendanceStatsDto> getSubjectStats(String subjectId) async {
    final response = await get<AttendanceStatsDto>(
      '${ApiConstants.lectureInstances}/stats/subject/$subjectId',
      parser: (json) => AttendanceStatsDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AttendanceStatsDto> getSemesterStats(String semesterId) async {
    final response = await get<AttendanceStatsDto>(
      '${ApiConstants.lectureInstances}/stats/semester/$semesterId',
      parser: (json) => AttendanceStatsDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
