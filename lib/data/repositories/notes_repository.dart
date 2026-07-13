import '../dto/notes/notes_dto.dart';
import 'sqlite/sqlite_notes_repository.dart';

abstract class NotesRepository {
  factory NotesRepository() => SqliteNotesRepository();

  Future<List<NotesSubjectDto>> getSubjects(String semesterId);
  Future<NotesSubjectDto> getSubject(String notesSubjectId);
  Future<List<NotesSectionDto>> getSections(String notesSubjectId);
  Future<NotesSectionDto> createSection(NotesSectionCreateRequest request);
  Future<NotesSectionDto> updateSection(String sectionId, NotesSectionUpdateRequest request);
  Future<void> deleteSection(String sectionId);
  Future<List<NotesResourceDto>> getResources({
    String? sectionId,
    String? q,
    String? semesterId,
  });
  Future<NotesResourceDto> createResource(NotesResourceCreateRequest request);
  Future<NotesResourceDto> updateResource(String resourceId, NotesResourceUpdateRequest request);
  Future<void> deleteResource(String resourceId);
  Future<List<NotesSubjectDetailDto>> getHierarchy(String semesterId);
}
