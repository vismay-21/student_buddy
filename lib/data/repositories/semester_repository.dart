import '../dto/semester/semester_dto.dart';
import 'sqlite/sqlite_semester_repository.dart';

abstract class SemesterRepository {
  factory SemesterRepository() => SqliteSemesterRepository();

  Future<List<SemesterDto>> getSemesters();
  Future<SemesterDto> createSemester(SemesterCreateRequest request);
  Future<SemesterDto> getSemesterById(String semesterId);
  Future<void> deleteSemester(String semesterId);
  Future<SemesterDto> updateSemester(String semesterId, SemesterUpdateRequest request);
}
