import '../api/semester_api.dart';
import '../dto/semester/semester_dto.dart';

class SemesterRepository {
  final SemesterApi _semesterApi = SemesterApi();

  Future<List<SemesterDto>> getSemesters() {
    return _semesterApi.getSemesters();
  }

  Future<SemesterDto> createSemester(SemesterCreateRequest request) {
    return _semesterApi.createSemester(request);
  }

  Future<SemesterDto> getSemesterById(String semesterId) {
    return _semesterApi.getSemesterById(semesterId);
  }

  Future<void> deleteSemester(String semesterId) {
    return _semesterApi.deleteSemester(semesterId);
  }
}
