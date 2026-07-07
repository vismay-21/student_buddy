import 'package:student_buddy/core/network/base_api.dart';
import '../../core/network/api_constants.dart';
import '../dto/lecture/lecture_template_dto.dart';

class LectureTemplateApi extends BaseApi {
  Future<List<LectureTemplateDto>> getTemplates(String subjectId) async {
    final response = await get<List<LectureTemplateDto>>(
      '${ApiConstants.lectureTemplates}?subject_id=$subjectId',
      parser: (json) => (json as List)
          .map((item) => LectureTemplateDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<LectureTemplateDto> createTemplate(LectureTemplateCreateRequest request) async {
    final response = await post<LectureTemplateDto>(
      ApiConstants.lectureTemplates,
      data: request.toJson(),
      parser: (json) => LectureTemplateDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<LectureTemplateDto> getTemplateById(String templateId) async {
    final response = await get<LectureTemplateDto>(
      '${ApiConstants.lectureTemplates}/$templateId',
      parser: (json) => LectureTemplateDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<LectureTemplateDto> updateTemplate(String templateId, LectureTemplateUpdateRequest request) async {
    final response = await put<LectureTemplateDto>(
      '${ApiConstants.lectureTemplates}/$templateId',
      data: request.toJson(),
      parser: (json) => LectureTemplateDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> deleteTemplate(String templateId) async {
    await delete('${ApiConstants.lectureTemplates}/$templateId');
  }
}
