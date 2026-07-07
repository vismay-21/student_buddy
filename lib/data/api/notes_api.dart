import '../../core/network/base_api.dart';
import '../../core/network/api_response.dart';
import '../dto/notes/notes_dto.dart';

class NotesApi extends BaseApi {
  Future<ApiResponse<List<NotesSubjectDto>>> getSubjects(String semesterId) async {
    return get<List<NotesSubjectDto>>(
      '/notes/subjects',
      queryParameters: {'semester_id': semesterId},
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => NotesSubjectDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<NotesSubjectDto>> getSubject(String notesSubjectId) async {
    return get<NotesSubjectDto>(
      '/notes/subjects/$notesSubjectId',
      parser: (json) => NotesSubjectDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<NotesSectionDto>>> getSections(String notesSubjectId) async {
    return get<List<NotesSectionDto>>(
      '/notes/sections',
      queryParameters: {'notes_subject_id': notesSubjectId},
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => NotesSectionDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<NotesSectionDto>> createSection(NotesSectionCreateRequest request) async {
    return post<NotesSectionDto>(
      '/notes/sections',
      data: request.toJson(),
      parser: (json) => NotesSectionDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<NotesSectionDto>> updateSection(String sectionId, NotesSectionUpdateRequest request) async {
    return put<NotesSectionDto>(
      '/notes/sections/$sectionId',
      data: request.toJson(),
      parser: (json) => NotesSectionDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteSection(String sectionId) async {
    return delete('/notes/sections/$sectionId');
  }

  Future<ApiResponse<List<NotesResourceDto>>> getResources({
    String? sectionId,
    String? q,
    String? semesterId,
  }) async {
    final Map<String, dynamic> params = {};
    if (sectionId != null) params['section_id'] = sectionId;
    if (q != null) params['q'] = q;
    if (semesterId != null) params['semester_id'] = semesterId;

    return get<List<NotesResourceDto>>(
      '/notes/resources',
      queryParameters: params,
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => NotesResourceDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<NotesResourceDto>> createResource(NotesResourceCreateRequest request) async {
    return post<NotesResourceDto>(
      '/notes/resources',
      data: request.toJson(),
      parser: (json) => NotesResourceDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<NotesResourceDto>> updateResource(String resourceId, NotesResourceUpdateRequest request) async {
    return put<NotesResourceDto>(
      '/notes/resources/$resourceId',
      data: request.toJson(),
      parser: (json) => NotesResourceDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteResource(String resourceId) async {
    return delete('/notes/resources/$resourceId');
  }

  Future<ApiResponse<List<NotesSubjectDetailDto>>> getHierarchy(String semesterId) async {
    return get<List<NotesSubjectDetailDto>>(
      '/notes/hierarchy/$semesterId',
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => NotesSubjectDetailDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }
}
