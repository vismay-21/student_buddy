import '../dto/subject/subject_dto.dart';
import 'sqlite/sqlite_subject_repository.dart';

abstract class SubjectRepository {
  factory SubjectRepository() => SqliteSubjectRepository();

  Future<List<SubjectDto>> getSubjects(String semesterId);
  Future<SubjectDto> createSubject(SubjectCreateRequest request);
  Future<SubjectDto> getSubjectById(String subjectId);
  Future<SubjectDto> updateSubject(String subjectId, SubjectUpdateRequest request);
  Future<void> deleteSubject(String subjectId, {bool deleteNotesSubject = false});
}
