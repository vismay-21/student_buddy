import '../dto/lecture/lecture_template_dto.dart';
import 'sqlite/sqlite_lecture_template_repository.dart';

abstract class LectureTemplateRepository {
  factory LectureTemplateRepository() => SqliteLectureTemplateRepository();

  Future<List<LectureTemplateDto>> getTemplates(String subjectId);
  Future<LectureTemplateDto> createTemplate(LectureTemplateCreateRequest request);
  Future<LectureTemplateDto> getTemplateById(String templateId);
  Future<LectureTemplateDto> updateTemplate(String templateId, LectureTemplateUpdateRequest request);
  Future<void> deleteTemplate(String templateId);
}
