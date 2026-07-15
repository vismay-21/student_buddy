import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/dto/lecture/lecture_template_dto.dart';
import 'common_providers.dart';
import 'semester_provider.dart';
import 'subject_provider.dart';

// ==========================================
// 1. Timetable Templates Family Provider
// ==========================================
class TimetableTemplatesNotifier extends FamilyAsyncNotifier<List<LectureTemplateDto>, String> {
  @override
  Future<List<LectureTemplateDto>> build(String arg) async {
    final service = ref.watch(attendanceServiceProvider);
    return service.getTemplates(arg);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return ref.read(attendanceServiceProvider).getTemplates(arg);
    });
  }
}

final timetableTemplatesProvider =
    AsyncNotifierProviderFamily<TimetableTemplatesNotifier, List<LectureTemplateDto>, String>(
  TimetableTemplatesNotifier.new,
);

// ==========================================
// 2. All Lecture Templates Weekly Provider
// ==========================================
final allLectureTemplatesProvider = FutureProvider<List<LectureTemplateDto>>((ref) async {
  final subjectsAsync = ref.watch(subjectsProvider);
  final subjects = subjectsAsync.value ?? [];
  final service = ref.watch(attendanceServiceProvider);
  final List<LectureTemplateDto> all = [];
  for (final sub in subjects) {
    final temps = await service.getTemplates(sub.subjectId);
    all.addAll(temps);
  }
  return all;
});

// ==========================================
// 3. Today's Lectures Provider
// ==========================================
class TodayLecturesNotifier extends AsyncNotifier<List<LectureInstanceDto>> {
  @override
  Future<List<LectureInstanceDto>> build() async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) return [];

    final service = ref.watch(attendanceServiceProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return service.getTodayLectures(date: todayStr, semesterId: activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) return <LectureInstanceDto>[];
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return ref.read(attendanceServiceProvider).getTodayLectures(date: todayStr, semesterId: activeSem.semesterId);
    });
  }

  void updateLecturesOptimistically(String instanceId, String newStatus) {
    if (state.value == null) return;
    state = AsyncValue.data(
      state.value!.map((l) {
        if (l.lectureInstanceId == instanceId) {
          return l.copyWith(attendanceStatus: newStatus);
        }
        return l;
      }).toList(),
    );
  }
}

final todayLecturesProvider =
    AsyncNotifierProvider<TodayLecturesNotifier, List<LectureInstanceDto>>(TodayLecturesNotifier.new);

// ==========================================
// 4. Timetable Actions Provider
// ==========================================
class TimetableActions {
  final Ref _ref;
  TimetableActions(this._ref);

  Future<LectureTemplateDto> createTemplate(LectureTemplateCreateRequest request) async {
    final service = _ref.read(attendanceServiceProvider);
    final result = await service.createTemplate(request);
    _ref.read(timetableTemplatesProvider(request.subjectId).notifier).refresh();
    _ref.invalidate(allLectureTemplatesProvider);
    _ref.read(todayLecturesProvider.notifier).refresh();
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
    return result;
  }

  Future<LectureTemplateDto> updateTemplate(
    String templateId,
    LectureTemplateUpdateRequest request,
    String subjectId,
  ) async {
    final service = _ref.read(attendanceServiceProvider);
    final result = await service.updateTemplate(templateId, request);
    _ref.read(timetableTemplatesProvider(subjectId).notifier).refresh();
    _ref.invalidate(allLectureTemplatesProvider);
    _ref.read(todayLecturesProvider.notifier).refresh();
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
    return result;
  }

  Future<void> deleteTemplate(String templateId, String subjectId) async {
    final service = _ref.read(attendanceServiceProvider);
    await service.deleteTemplate(templateId);
    _ref.read(timetableTemplatesProvider(subjectId).notifier).refresh();
    _ref.invalidate(allLectureTemplatesProvider);
    _ref.read(todayLecturesProvider.notifier).refresh();
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
  }
}

final timetableActionsProvider = Provider<TimetableActions>((ref) => TimetableActions(ref));
