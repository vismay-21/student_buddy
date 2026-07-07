import '../api/notes_api.dart';
import '../dto/notes/notes_dto.dart';

class NotesRepository {
  final NotesApi _api = NotesApi();

  Future<List<NotesSubjectDto>> getSubjects(String semesterId) async {
    final response = await _api.getSubjects(semesterId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<NotesSubjectDto> getSubject(String notesSubjectId) async {
    final response = await _api.getSubject(notesSubjectId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<List<NotesSectionDto>> getSections(String notesSubjectId) async {
    final response = await _api.getSections(notesSubjectId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<NotesSectionDto> createSection(NotesSectionCreateRequest request) async {
    final response = await _api.createSection(request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<NotesSectionDto> updateSection(String sectionId, NotesSectionUpdateRequest request) async {
    final response = await _api.updateSection(sectionId, request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<void> deleteSection(String sectionId) async {
    final response = await _api.deleteSection(sectionId);
    if (!response.success) {
      throw Exception(response.message);
    }
  }

  Future<List<NotesResourceDto>> getResources({
    String? sectionId,
    String? q,
    String? semesterId,
  }) async {
    final response = await _api.getResources(
      sectionId: sectionId,
      q: q,
      semesterId: semesterId,
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<NotesResourceDto> createResource(NotesResourceCreateRequest request) async {
    final response = await _api.createResource(request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<NotesResourceDto> updateResource(String resourceId, NotesResourceUpdateRequest request) async {
    final response = await _api.updateResource(resourceId, request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<void> deleteResource(String resourceId) async {
    final response = await _api.deleteResource(resourceId);
    if (!response.success) {
      throw Exception(response.message);
    }
  }

  Future<List<NotesSubjectDetailDto>> getHierarchy(String semesterId) async {
    final response = await _api.getHierarchy(semesterId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }
}
