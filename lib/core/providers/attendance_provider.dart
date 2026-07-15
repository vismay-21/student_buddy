import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/dto/holiday/holiday_dto.dart';
import '../../data/dto/attendance/attendance_settings_dto.dart';
import 'common_providers.dart';
import 'semester_provider.dart';
import 'timetable_provider.dart';

// ==========================================
// 1. Semester Attendance Statistics Provider
// ==========================================
class AttendanceStatsNotifier extends AsyncNotifier<AttendanceStatsDto> {
  @override
  Future<AttendanceStatsDto> build() async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) {
      return AttendanceStatsDto(
        totalLectures: 0,
        presentLectures: 0,
        absentLectures: 0,
        attendancePercentage: 0.0,
        remainingLectures: 0,
        safeSkipCount: 0,
        statusMessage: 'No active semester',
      );
    }

    // Refresh when today's lectures list updates
    ref.watch(todayLecturesProvider);

    final service = ref.watch(attendanceServiceProvider);
    return service.getSemesterStats(activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) {
        return AttendanceStatsDto(
          totalLectures: 0,
          presentLectures: 0,
          absentLectures: 0,
          attendancePercentage: 0.0,
          remainingLectures: 0,
          safeSkipCount: 0,
          statusMessage: 'No active semester',
        );
      }
      return ref.read(attendanceServiceProvider).getSemesterStats(activeSem.semesterId);
    });
  }

  /// Optimistically update the attendance state in-memory before SQLite write completes
  void updateStatsOptimistically(String? oldStatus, String? newStatus) {
    if (state.value == null) return;
    final currentStats = state.value!;

    int presentDelta = 0;
    int absentDelta = 0;

    if (oldStatus == 'attended') presentDelta--;
    if (oldStatus == 'absent') absentDelta--;

    if (newStatus == 'attended') presentDelta++;
    if (newStatus == 'absent') absentDelta++;

    final newTotal = currentStats.totalLectures + (oldStatus == null ? 1 : 0) - (newStatus == null ? 1 : 0);
    final newPresent = currentStats.presentLectures + presentDelta;
    final newAbsent = currentStats.absentLectures + absentDelta;
    final newPercent = newTotal > 0 ? (newPresent / newTotal) * 100 : 0.0;

    state = AsyncValue.data(
      AttendanceStatsDto(
        totalLectures: newTotal,
        presentLectures: newPresent,
        absentLectures: newAbsent,
        attendancePercentage: newPercent,
        remainingLectures: currentStats.remainingLectures,
        safeSkipCount: currentStats.safeSkipCount,
        statusMessage: currentStats.statusMessage,
        criteriaMode: currentStats.criteriaMode,
      ),
    );
  }
}

final attendanceStatsProvider =
    AsyncNotifierProvider<AttendanceStatsNotifier, AttendanceStatsDto>(AttendanceStatsNotifier.new);

// ==========================================
// 2. Subject Attendance Statistics Family Provider
// ==========================================
final subjectAttendanceStatsProvider = FutureProvider.family<AttendanceStatsDto, String>((ref, subjectId) async {
  // Listen to today lectures to reload stats on change
  ref.watch(todayLecturesProvider);
  
  final service = ref.watch(attendanceServiceProvider);
  return service.getSubjectStats(subjectId);
});

// ==========================================
// 3. Holidays Provider
// ==========================================
class HolidaysNotifier extends AsyncNotifier<List<HolidayDto>> {
  @override
  Future<List<HolidayDto>> build() async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) return [];

    final service = ref.watch(attendanceServiceProvider);
    return service.getHolidays(semesterId: activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) return <HolidayDto>[];
      return ref.read(attendanceServiceProvider).getHolidays(semesterId: activeSem.semesterId);
    });
  }
}

final holidaysProvider = AsyncNotifierProvider<HolidaysNotifier, List<HolidayDto>>(HolidaysNotifier.new);

// ==========================================
// 4. Attendance Actions Provider
// ==========================================
class AttendanceActions {
  final Ref _ref;
  AttendanceActions(this._ref);

  Future<void> updateAttendance(
    String instanceId,
    LectureInstanceUpdateRequest request, {
    String? subjectId,
    String? oldStatus,
  }) async {
    final service = _ref.read(attendanceServiceProvider);

    // 1. Optimistic Update
    _ref.read(todayLecturesProvider.notifier).updateLecturesOptimistically(
          instanceId,
          request.attendanceStatus ?? 'unmarked',
        );

    _ref.read(attendanceStatsProvider.notifier).updateStatsOptimistically(
          oldStatus,
          request.attendanceStatus,
        );

    if (subjectId != null) {
      _ref.invalidate(subjectAttendanceStatsProvider(subjectId));
    }

    try {
      await service.updateAttendance(instanceId, request);
      // 2. Refresh lists and stats silently to ensure sync with DB
      _ref.read(todayLecturesProvider.notifier).refresh();
      _ref.read(attendanceStatsProvider.notifier).refresh();
      _ref.read(semesterInstancesProvider.notifier).refresh();
      _ref.invalidate(subjectInstancesProvider);
      _ref.invalidate(dateLecturesProvider);
      if (subjectId != null) {
        _ref.invalidate(subjectAttendanceStatsProvider(subjectId));
      }
      
      // Trigger sync
      _ref.read(syncServiceProvider).sync();
    } catch (e) {
      // 3. Rollback on failure
      _ref.read(todayLecturesProvider.notifier).refresh();
      _ref.read(attendanceStatsProvider.notifier).refresh();
      _ref.read(semesterInstancesProvider.notifier).refresh();
      _ref.invalidate(subjectInstancesProvider);
      _ref.invalidate(dateLecturesProvider);
      if (subjectId != null) {
        _ref.invalidate(subjectAttendanceStatsProvider(subjectId));
      }
      rethrow;
    }
  }

  Future<void> markWholeDay(LectureInstanceBulkUpdateRequest request) async {
    final service = _ref.read(attendanceServiceProvider);
    await service.markWholeDay(request);
    _ref.read(todayLecturesProvider.notifier).refresh();
    _ref.read(attendanceStatsProvider.notifier).refresh();
    _ref.read(semesterInstancesProvider.notifier).refresh();
    _ref.invalidate(subjectInstancesProvider);
    _ref.invalidate(dateLecturesProvider);
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
  }

  Future<HolidayDto> createHoliday(HolidayCreateRequest request) async {
    final service = _ref.read(attendanceServiceProvider);
    final result = await service.createHoliday(request);
    _ref.read(holidaysProvider.notifier).refresh();
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
    return result;
  }

  Future<void> deleteHoliday(String holidayId) async {
    final service = _ref.read(attendanceServiceProvider);
    await service.deleteHoliday(holidayId);
    _ref.read(holidaysProvider.notifier).refresh();
    
    // Trigger sync
    _ref.read(syncServiceProvider).sync();
  }
}

final attendanceActionsProvider = Provider<AttendanceActions>((ref) => AttendanceActions(ref));

// ==========================================
// 5. Attendance Settings Provider
// ==========================================
class AttendanceSettingsNotifier extends AsyncNotifier<AttendanceSettingsDto> {
  @override
  Future<AttendanceSettingsDto> build() async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) {
      throw StateError('No active semester');
    }
    final service = ref.watch(attendanceServiceProvider);
    return service.getSettings(activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) throw StateError('No active semester');
      return ref.read(attendanceServiceProvider).getSettings(activeSem.semesterId);
    });
  }

  Future<void> updateSettings(AttendanceSettingsUpdateRequest request) async {
    final activeSem = ref.read(activeSemesterProvider);
    if (activeSem == null) throw StateError('No active semester');
    final service = ref.read(attendanceServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await service.updateSettings(activeSem.semesterId, request);
      // Trigger sync
      ref.read(syncServiceProvider).sync();
      return res;
    });
  }
}

final attendanceSettingsProvider =
    AsyncNotifierProvider<AttendanceSettingsNotifier, AttendanceSettingsDto>(AttendanceSettingsNotifier.new);

// ==========================================
// 6. Semester Instances Provider
// ==========================================
class SemesterInstancesNotifier extends AsyncNotifier<List<LectureInstanceDto>> {
  @override
  Future<List<LectureInstanceDto>> build() async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) return [];
    final service = ref.watch(attendanceServiceProvider);
    return service.getInstances(semesterId: activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) return <LectureInstanceDto>[];
      return ref.read(attendanceServiceProvider).getInstances(semesterId: activeSem.semesterId);
    });
  }
}

final semesterInstancesProvider =
    AsyncNotifierProvider<SemesterInstancesNotifier, List<LectureInstanceDto>>(SemesterInstancesNotifier.new);

// ==========================================
// 7. Subject Instances Provider (Family)
// ==========================================
final subjectInstancesProvider = FutureProvider.family<List<LectureInstanceDto>, String>((ref, subjectId) async {
  final activeSem = ref.watch(activeSemesterProvider);
  if (activeSem == null) return [];
  final service = ref.watch(attendanceServiceProvider);
  return service.getInstances(semesterId: activeSem.semesterId, subjectId: subjectId);
});

// ==========================================
// 8. Date Lectures Provider (Family)
// ==========================================
final dateLecturesProvider = FutureProvider.family<List<LectureInstanceDto>, String>((ref, dateStr) async {
  final activeSem = ref.watch(activeSemesterProvider);
  if (activeSem == null) return [];
  final service = ref.watch(attendanceServiceProvider);
  return service.getTodayLectures(date: dateStr, semesterId: activeSem.semesterId);
});
