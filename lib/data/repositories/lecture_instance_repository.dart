import '../dto/lecture/lecture_instance_dto.dart';
import 'sqlite/sqlite_lecture_instance_repository.dart';

abstract class LectureInstanceRepository {
  factory LectureInstanceRepository() => SqliteLectureInstanceRepository();

  Future<List<LectureInstanceDto>> getInstances({
    String? semesterId,
    String? subjectId,
    String? startDate,
    String? endDate,
    String? attendanceStatus,
    String? lectureStatus,
  });

  Future<List<LectureInstanceDto>> getTodayLectures({String? date, String? semesterId});
  Future<LectureInstanceDto> getInstanceById(String instanceId);
  Future<LectureInstanceBulkUpdateResponseDto> markWholeDay(LectureInstanceBulkUpdateRequest request);
  Future<LectureInstanceDto> updateAttendance(String instanceId, LectureInstanceUpdateRequest request);
  Future<AttendanceStatsDto> getSubjectStats(String subjectId);
  Future<AttendanceStatsDto> getSemesterStats(String semesterId);
}
