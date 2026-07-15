import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/notes/notes_dto.dart';
import 'common_providers.dart';
import 'semester_provider.dart';

// ==========================================
// 1. Notes Hierarchy Provider (Read Provider)
// ==========================================
final notesHierarchyProvider = FutureProvider<List<NotesSubjectDetailDto>>((ref) async {
  final activeSem = ref.watch(activeSemesterProvider);
  if (activeSem == null) return [];
  final service = ref.watch(notesServiceProvider);
  return service.getHierarchy(activeSem.semesterId);
});

// ==========================================
// 2. Notes Subjects Provider
// ==========================================
final notesSubjectsProvider = FutureProvider.family<List<NotesSubjectDto>, String>((ref, semesterId) async {
  final service = ref.watch(notesServiceProvider);
  return service.getSubjects(semesterId);
});

// ==========================================
// 3. Notes Sections Provider
// ==========================================
final notesSectionsProvider = FutureProvider.family<List<NotesSectionDto>, String>((ref, notesSubjectId) async {
  final service = ref.watch(notesServiceProvider);
  return service.getSections(notesSubjectId);
});

// ==========================================
// 4. Notes Actions Provider (CQRS Action Provider)
// ==========================================
class NotesActions {
  final Ref _ref;
  NotesActions(this._ref);

  Future<NotesSectionDto> createSection(NotesSectionCreateRequest request) async {
    final service = _ref.read(notesServiceProvider);
    final result = await service.createSection(request);
    _ref.invalidate(notesHierarchyProvider);
    _ref.invalidate(notesSectionsProvider(request.notesSubjectId));
    return result;
  }

  Future<NotesSectionDto> updateSection(String sectionId, NotesSectionUpdateRequest request) async {
    final service = _ref.read(notesServiceProvider);
    final result = await service.updateSection(sectionId, request);
    _ref.invalidate(notesHierarchyProvider);
    return result;
  }

  Future<void> deleteSection(String sectionId) async {
    final service = _ref.read(notesServiceProvider);
    await service.deleteSection(sectionId);
    _ref.invalidate(notesHierarchyProvider);
  }

  Future<NotesResourceDto> createResource(NotesResourceCreateRequest request) async {
    final service = _ref.read(notesServiceProvider);
    final result = await service.createResource(request);
    _ref.invalidate(notesHierarchyProvider);
    return result;
  }

  Future<NotesResourceDto> updateResource(String resourceId, NotesResourceUpdateRequest request) async {
    final service = _ref.read(notesServiceProvider);
    final result = await service.updateResource(resourceId, request);
    _ref.invalidate(notesHierarchyProvider);
    return result;
  }

  Future<void> deleteResource(String resourceId) async {
    final service = _ref.read(notesServiceProvider);
    await service.deleteResource(resourceId);
    _ref.invalidate(notesHierarchyProvider);
  }
}

final notesActionsProvider = Provider<NotesActions>((ref) => NotesActions(ref));
