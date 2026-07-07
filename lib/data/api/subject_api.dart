import 'package:student_buddy/core/network/base_api.dart';
import '../../core/network/api_constants.dart';
import '../dto/subject/subject_dto.dart';

class SubjectApi extends BaseApi {
  Future<List<SubjectDto>> getSubjects(String semesterId) async {
    final response = await get<List<SubjectDto>>(
      '${ApiConstants.subjects}?semester_id=$semesterId',
      parser: (json) => (json as List)
          .map((item) => SubjectDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<SubjectDto> createSubject(SubjectCreateRequest request) async {
    final response = await post<SubjectDto>(
      ApiConstants.subjects,
      data: request.toJson(),
      parser: (json) => SubjectDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SubjectDto> getSubjectById(String subjectId) async {
    final response = await get<SubjectDto>(
      '${ApiConstants.subjects}/$subjectId',
      parser: (json) => SubjectDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SubjectDto> updateSubject(String subjectId, SubjectUpdateRequest request) async {
    final response = await put<SubjectDto>(
      '${ApiConstants.subjects}/$subjectId',
      data: request.toJson(),
      parser: (json) => SubjectDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> deleteSubject(String subjectId, {bool deleteNotesSubject = false}) async {
    await delete('${ApiConstants.subjects}/$subjectId?delete_notes_subject=$deleteNotesSubject');
  }
}
