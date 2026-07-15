import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/subject/subject_dto.dart';
import 'common_providers.dart';
import 'semester_provider.dart';

// ==========================================
// 1. Subjects List Provider
// ==========================================
class SubjectsNotifier extends AsyncNotifier<List<SubjectDto>> {
  @override
  Future<List<SubjectDto>> build() async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) return [];

    final service = ref.watch(subjectServiceProvider);
    return service.getSubjects(activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) return <SubjectDto>[];
      return ref.read(subjectServiceProvider).getSubjects(activeSem.semesterId);
    });
  }
}

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<SubjectDto>>(SubjectsNotifier.new);

// ==========================================
// 2. Subject Actions Provider
// ==========================================
class SubjectActions {
  final Ref _ref;
  SubjectActions(this._ref);

  Future<SubjectDto> createSubject(SubjectCreateRequest request) async {
    final service = _ref.read(subjectServiceProvider);
    final result = await service.createSubject(request);
    _ref.read(subjectsProvider.notifier).refresh();
    return result;
  }

  Future<SubjectDto> updateSubject(String subjectId, SubjectUpdateRequest request) async {
    final service = _ref.read(subjectServiceProvider);
    final result = await service.updateSubject(subjectId, request);
    _ref.read(subjectsProvider.notifier).refresh();
    return result;
  }

  Future<void> deleteSubject(String subjectId) async {
    final service = _ref.read(subjectServiceProvider);
    await service.deleteSubject(subjectId);
    _ref.read(subjectsProvider.notifier).refresh();
  }
}

final subjectActionsProvider = Provider<SubjectActions>((ref) => SubjectActions(ref));
