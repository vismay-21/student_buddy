import '../../data/dto/semester/semester_dto.dart';
import '../../data/repositories/semester_repository.dart';

class SemesterService {
  final SemesterRepository _repository = SemesterRepository();

  Future<SemesterDto> createSemester(SemesterCreateRequest request) => _repository.createSemester(request);
  
  Future<List<SemesterDto>> getSemesters() => _repository.getSemesters();
  
  Future<SemesterDto> getSemester(String semesterId) => _repository.getSemesterById(semesterId);
  
  Future<SemesterDto> updateSemester(String semesterId, SemesterUpdateRequest request) => _repository.updateSemester(semesterId, request);
  
  Future<void> deleteSemester(String semesterId) => _repository.deleteSemester(semesterId);
}
