import '../../data/dto/notes/notes_dto.dart';
import '../../data/repositories/notes_repository.dart';

class NotesService {
  final NotesRepository _repository = NotesRepository();

  Future<List<NotesSubjectDto>> getSubjects(String semesterId) => _repository.getSubjects(semesterId);
  Future<NotesSubjectDto> getSubject(String notesSubjectId) => _repository.getSubject(notesSubjectId);
  
  Future<List<NotesSectionDto>> getSections(String notesSubjectId) => _repository.getSections(notesSubjectId);
  Future<NotesSectionDto> createSection(NotesSectionCreateRequest request) => _repository.createSection(request);
  Future<NotesSectionDto> updateSection(String sectionId, NotesSectionUpdateRequest request) => _repository.updateSection(sectionId, request);
  Future<void> deleteSection(String sectionId) => _repository.deleteSection(sectionId);
  
  Future<List<NotesResourceDto>> getResources({String? sectionId, String? q, String? semesterId}) =>
      _repository.getResources(sectionId: sectionId, q: q, semesterId: semesterId);
  Future<NotesResourceDto> createResource(NotesResourceCreateRequest request) => _repository.createResource(request);
  Future<NotesResourceDto> updateResource(String resourceId, NotesResourceUpdateRequest request) =>
      _repository.updateResource(resourceId, request);
  Future<void> deleteResource(String resourceId) => _repository.deleteResource(resourceId);
  
  Future<List<NotesSubjectDetailDto>> getHierarchy(String semesterId) => _repository.getHierarchy(semesterId);
}
