import '../api/lecture_template_api.dart';
import '../dto/lecture/lecture_template_dto.dart';

class LectureTemplateRepository {
  final LectureTemplateApi _templateApi;

  LectureTemplateRepository({LectureTemplateApi? templateApi}) : _templateApi = templateApi ?? LectureTemplateApi();

  Future<List<LectureTemplateDto>> getTemplates(String subjectId) async {
    return _templateApi.getTemplates(subjectId);
  }

  Future<LectureTemplateDto> createTemplate(LectureTemplateCreateRequest request) async {
    return _templateApi.createTemplate(request);
  }

  Future<LectureTemplateDto> getTemplateById(String templateId) async {
    return _templateApi.getTemplateById(templateId);
  }

  Future<LectureTemplateDto> updateTemplate(String templateId, LectureTemplateUpdateRequest request) async {
    return _templateApi.updateTemplate(templateId, request);
  }

  Future<void> deleteTemplate(String templateId) async {
    return _templateApi.deleteTemplate(templateId);
  }
}
