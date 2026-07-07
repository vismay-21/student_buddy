import '../api/lecture_instance_api.dart';
import '../dto/lecture/lecture_instance_dto.dart';

class LectureInstanceRepository {
  final LectureInstanceApi _instanceApi;

  LectureInstanceRepository({LectureInstanceApi? instanceApi})
      : _instanceApi = instanceApi ?? LectureInstanceApi();

  Future<List<LectureInstanceDto>> getInstances({
    String? semesterId,
    String? subjectId,
    String? startDate,
    String? endDate,
    String? attendanceStatus,
    String? lectureStatus,
  }) async {
    return _instanceApi.getInstances(
      semesterId: semesterId,
      subjectId: subjectId,
      startDate: startDate,
      endDate: endDate,
      attendanceStatus: attendanceStatus,
      lectureStatus: lectureStatus,
    );
  }

  Future<List<LectureInstanceDto>> getTodayLectures({String? date, String? semesterId}) async {
    return _instanceApi.getTodayLectures(date: date, semesterId: semesterId);
  }

  Future<LectureInstanceDto> getInstanceById(String instanceId) async {
    return _instanceApi.getInstanceById(instanceId);
  }

  Future<LectureInstanceBulkUpdateResponseDto> markWholeDay(LectureInstanceBulkUpdateRequest request) async {
    return _instanceApi.markWholeDay(request);
  }

  Future<LectureInstanceDto> updateAttendance(String instanceId, LectureInstanceUpdateRequest request) async {
    return _instanceApi.updateAttendance(instanceId, request);
  }

  Future<AttendanceStatsDto> getSubjectStats(String subjectId) async {
    return _instanceApi.getSubjectStats(subjectId);
  }

  Future<AttendanceStatsDto> getSemesterStats(String semesterId) async {
    return _instanceApi.getSemesterStats(semesterId);
  }
}
