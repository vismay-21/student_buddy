import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/semester/semester_dto.dart';
import 'common_providers.dart';
import 'auth_provider.dart';
import 'attendance_provider.dart';
import 'timetable_provider.dart';
import 'subject_provider.dart';

// ==========================================
// 1. Semesters List Provider
// ==========================================
class SemestersNotifier extends AsyncNotifier<List<SemesterDto>> {
  @override
  Future<List<SemesterDto>> build() async {
    final bootstrapAsync = ref.watch(bootstrapStatusProvider);
    if (bootstrapAsync.isLoading) {
      return Completer<List<SemesterDto>>().future;
    }
    if (bootstrapAsync.hasError) {
      throw bootstrapAsync.error!;
    }
    final bootstrapState = bootstrapAsync.value;
    if (bootstrapState != BootstrapState.success) {
      return Completer<List<SemesterDto>>().future;
    }
    final service = ref.watch(semesterServiceProvider);
    return service.getSemesters();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return ref.read(semesterServiceProvider).getSemesters();
    });
  }
}

final semestersProvider = AsyncNotifierProvider<SemestersNotifier, List<SemesterDto>>(SemestersNotifier.new);

// ==========================================
// 2. Active Semester Provider
// ==========================================
class ActiveSemesterNotifier extends Notifier<SemesterDto?> {
  static const _key = 'active_semester_id';

  @override
  SemesterDto? build() {
    final semestersAsync = ref.watch(semestersProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedId = prefs.getString(_key);

    return semestersAsync.when(
      data: (list) {
        if (list.isEmpty) return null;
        if (savedId != null) {
          final found = list.where((s) => s.semesterId == savedId);
          if (found.isNotEmpty) return found.first;
        }
        return list.first; // Fallback to first
      },
      error: (_, __) => null,
      loading: () => null,
    );
  }

  void setActiveSemester(SemesterDto? semester) {
    state = semester;
    final prefs = ref.read(sharedPreferencesProvider);
    if (semester != null) {
      prefs.setString(_key, semester.semesterId);
    } else {
      prefs.remove(_key);
    }
  }
}

final activeSemesterProvider = NotifierProvider<ActiveSemesterNotifier, SemesterDto?>(ActiveSemesterNotifier.new);


// ==========================================
// 3. Semester Actions Provider
// ==========================================
class SemesterActions {
  final Ref _ref;
  SemesterActions(this._ref);

  Future<SemesterDto> createSemester(SemesterCreateRequest request) async {
    final service = _ref.read(semesterServiceProvider);
    final result = await service.createSemester(request);
    _ref.read(semestersProvider.notifier).refresh();
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
    return result;
  }

  Future<void> selectActiveSemester(SemesterDto? semester) async {
    _ref.read(activeSemesterProvider.notifier).setActiveSemester(semester);
  }

  Future<SemesterDto> updateSemester(String semesterId, SemesterUpdateRequest request) async {
    final service = _ref.read(semesterServiceProvider);
    final result = await service.updateSemester(semesterId, request);
    _ref.read(semestersProvider.notifier).refresh();

    // Invalidate/refresh all affected providers
    _ref.read(attendanceStatsProvider.notifier).refresh();
    _ref.read(semesterInstancesProvider.notifier).refresh();
    _ref.read(todayLecturesProvider.notifier).refresh();
    _ref.read(holidaysProvider.notifier).refresh();

    final subjects = _ref.read(subjectsProvider).value ?? [];
    for (final sub in subjects) {
      _ref.read(subjectAttendanceStatsProvider(sub.subjectId).notifier).refresh();
      _ref.read(subjectInstancesProvider(sub.subjectId).notifier).refresh();
    }

    // Trigger sync
    _ref.read(syncServiceProvider).sync();
    return result;
  }

  Future<void> deleteSemester(String semesterId) async {
    final service = _ref.read(semesterServiceProvider);
    await service.deleteSemester(semesterId);
    _ref.read(semestersProvider.notifier).refresh();

    // Trigger sync
    _ref.read(syncServiceProvider).sync();
  }
}

final semesterActionsProvider = Provider<SemesterActions>((ref) => SemesterActions(ref));
