import '../api/subject_api.dart';
import '../dto/subject/subject_dto.dart';

class SubjectRepository {
  final SubjectApi _subjectApi;

  SubjectRepository({SubjectApi? subjectApi}) : _subjectApi = subjectApi ?? SubjectApi();

  Future<List<SubjectDto>> getSubjects(String semesterId) async {
    return _subjectApi.getSubjects(semesterId);
  }

  Future<SubjectDto> createSubject(SubjectCreateRequest request) async {
    return _subjectApi.createSubject(request);
  }

  Future<SubjectDto> getSubjectById(String subjectId) async {
    return _subjectApi.getSubjectById(subjectId);
  }

  Future<SubjectDto> updateSubject(String subjectId, SubjectUpdateRequest request) async {
    return _subjectApi.updateSubject(subjectId, request);
  }

  Future<void> deleteSubject(String subjectId, {bool deleteNotesSubject = false}) async {
    return _subjectApi.deleteSubject(subjectId, deleteNotesSubject: deleteNotesSubject);
  }
}
