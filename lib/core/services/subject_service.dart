import '../../data/dto/subject/subject_dto.dart';
import '../../data/repositories/subject_repository.dart';

class SubjectService {
  final SubjectRepository _repository = SubjectRepository();

  Future<SubjectDto> createSubject(SubjectCreateRequest request) => _repository.createSubject(request);
  
  Future<List<SubjectDto>> getSubjects(String semesterId) => _repository.getSubjects(semesterId);
  
  Future<SubjectDto> getSubject(String subjectId) => _repository.getSubjectById(subjectId);
  
  Future<SubjectDto> updateSubject(String subjectId, SubjectUpdateRequest request) => _repository.updateSubject(subjectId, request);
  
  Future<void> deleteSubject(String subjectId, {bool deleteNotesSubject = false}) => _repository.deleteSubject(subjectId, deleteNotesSubject: deleteNotesSubject);
}
