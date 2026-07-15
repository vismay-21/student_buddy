import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/dto/holiday/holiday_dto.dart';
import '../../data/dto/attendance/attendance_settings_dto.dart';
import 'common_providers.dart';
import 'semester_provider.dart';
import 'timetable_provider.dart';
import 'subject_provider.dart';

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

    if (oldStatus == 'present' || oldStatus == 'attended') presentDelta--;
    if (oldStatus == 'absent' || oldStatus == 'missed') absentDelta--;

    if (newStatus == 'present' || newStatus == 'attended') presentDelta++;
    if (newStatus == 'absent' || newStatus == 'missed') absentDelta++;

    final newPresent = currentStats.presentLectures + presentDelta;
    final newAbsent = currentStats.absentLectures + absentDelta;
    final int marked = newPresent + newAbsent;
    final newTotal = currentStats.totalLectures;

    final double newPercent = marked == 0 ? 100.0 : double.parse(((newPresent / marked) * 100.0).toStringAsFixed(2));

    int goal = 75;
    final settings = ref.read(attendanceSettingsProvider).value;
    if (settings != null) {
      goal = settings.overallAttendanceGoal;
    }

    int skip = 0;
    if (marked > 0) {
      final double valK = (100 * newPresent - goal * marked) / goal;
      final int k = valK.floor();
      skip = k > 0 ? k : 0;
    }

    String msg = "can't skip next lecture";
    if (marked > 0) {
      final double valK = (100 * newPresent - goal * marked) / goal;
      final int k = valK.floor();
      if (k > 0) {
        msg = "can skip $k lectures";
      } else if (k == 0) {
        msg = "can't skip next lecture";
      } else {
        final int divisor = 100 - goal;
        if (divisor <= 0) {
          msg = newAbsent > 0 ? "need to attend next lecture" : "can't skip next lecture";
        } else {
          final double valM = (goal * marked - 100 * newPresent) / divisor;
          final int m = valM.ceil();
          msg = "need to attend next $m lectures";
        }
      }
    }

    state = AsyncValue.data(
      AttendanceStatsDto(
        totalLectures: newTotal,
        presentLectures: newPresent,
        absentLectures: newAbsent,
        attendancePercentage: newPercent,
        remainingLectures: currentStats.remainingLectures,
        safeSkipCount: skip,
        statusMessage: msg,
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
class SubjectAttendanceStatsNotifier extends FamilyAsyncNotifier<AttendanceStatsDto, String> {
  @override
  Future<AttendanceStatsDto> build(String arg) async {
    final service = ref.watch(attendanceServiceProvider);
    return service.getSubjectStats(arg);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final service = ref.read(attendanceServiceProvider);
      return service.getSubjectStats(arg);
    });
  }

  void updateStatsOptimistically(String? oldStatus, String? newStatus, double targetGoal) {
    if (state.value == null) return;
    final currentStats = state.value!;

    int presentDelta = 0;
    int absentDelta = 0;

    if (oldStatus == 'present' || oldStatus == 'attended') presentDelta--;
    if (oldStatus == 'absent' || oldStatus == 'missed') absentDelta--;

    if (newStatus == 'present' || newStatus == 'attended') presentDelta++;
    if (newStatus == 'absent' || newStatus == 'missed') absentDelta++;

    final newPresent = currentStats.presentLectures + presentDelta;
    final newAbsent = currentStats.absentLectures + absentDelta;
    final int marked = newPresent + newAbsent;
    final newTotal = currentStats.totalLectures;

    final double newPercent = marked == 0 ? 100.0 : double.parse(((newPresent / marked) * 100.0).toStringAsFixed(2));
    final int goal = targetGoal.toInt();

    int skip = 0;
    if (marked > 0) {
      final double valK = (100 * newPresent - goal * marked) / goal;
      final int k = valK.floor();
      skip = k > 0 ? k : 0;
    }

    String msg = "can't skip next lecture";
    if (marked > 0) {
      final double valK = (100 * newPresent - goal * marked) / goal;
      final int k = valK.floor();
      if (k > 0) {
        msg = "can skip $k lectures";
      } else if (k == 0) {
        msg = "can't skip next lecture";
      } else {
        final int divisor = 100 - goal;
        if (divisor <= 0) {
          msg = newAbsent > 0 ? "need to attend next lecture" : "can't skip next lecture";
        } else {
          final double valM = (goal * marked - 100 * newPresent) / divisor;
          final int m = valM.ceil();
          msg = "need to attend next $m lectures";
        }
      }
    }

    state = AsyncValue.data(
      AttendanceStatsDto(
        attendancePercentage: newPercent,
        presentLectures: newPresent,
        absentLectures: newAbsent,
        totalLectures: newTotal,
        remainingLectures: currentStats.remainingLectures,
        safeSkipCount: skip,
        statusMessage: msg,
        criteriaMode: currentStats.criteriaMode,
      ),
    );
  }
}

final subjectAttendanceStatsProvider =
    AsyncNotifierProviderFamily<SubjectAttendanceStatsNotifier, AttendanceStatsDto, String>(
  SubjectAttendanceStatsNotifier.new,
);

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
    String? dateStr,
  }) async {
    final service = _ref.read(attendanceServiceProvider);
    final newStatus = request.attendanceStatus ?? 'unmarked';

    // 1. Optimistic Update
    _ref.read(todayLecturesProvider.notifier).updateLecturesOptimistically(
          instanceId,
          newStatus,
        );

    _ref.read(attendanceStatsProvider.notifier).updateStatsOptimistically(
          oldStatus,
          request.attendanceStatus,
        );

    // Get settings overall goal or custom subject goal to update subject stats
    double targetGoal = 75.0;
    final settings = _ref.read(attendanceSettingsProvider).value;
    if (settings != null) {
      targetGoal = settings.overallAttendanceGoal.toDouble();
    }

    if (subjectId != null) {
      final subjects = _ref.read(subjectsProvider).value;
      if (subjects != null && subjects.isNotEmpty) {
        final sub = subjects.firstWhere(
          (s) => s.subjectId == subjectId,
          orElse: () => subjects.first,
        );
        targetGoal = sub.attendanceGoal.toDouble();
      }

      _ref.read(subjectAttendanceStatsProvider(subjectId).notifier).updateStatsOptimistically(
            oldStatus,
            request.attendanceStatus,
            targetGoal,
          );
      _ref.read(subjectInstancesProvider(subjectId).notifier).updateLecturesOptimistically(
            instanceId,
            newStatus,
          );
    }

    if (dateStr != null) {
      _ref.read(dateLecturesProvider(dateStr).notifier).updateLecturesOptimistically(
            instanceId,
            newStatus,
          );
    }

    try {
      await service.updateAttendance(instanceId, request);
      // 2. Refresh lists and stats silently to ensure sync with DB
      _ref.read(todayLecturesProvider.notifier).refresh();
      _ref.read(attendanceStatsProvider.notifier).refresh();
      _ref.read(semesterInstancesProvider.notifier).refresh();
      if (subjectId != null) {
        _ref.read(subjectAttendanceStatsProvider(subjectId).notifier).refresh();
        _ref.read(subjectInstancesProvider(subjectId).notifier).refresh();
      }
      if (dateStr != null) {
        _ref.read(dateLecturesProvider(dateStr).notifier).refresh();
      }
      
      // Trigger sync
      _ref.read(syncServiceProvider).sync();
    } catch (e) {
      // 3. Rollback on failure
      _ref.read(todayLecturesProvider.notifier).refresh();
      _ref.read(attendanceStatsProvider.notifier).refresh();
      _ref.read(semesterInstancesProvider.notifier).refresh();
      if (subjectId != null) {
        _ref.read(subjectAttendanceStatsProvider(subjectId).notifier).refresh();
        _ref.read(subjectInstancesProvider(subjectId).notifier).refresh();
      }
      if (dateStr != null) {
        _ref.read(dateLecturesProvider(dateStr).notifier).refresh();
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
    
    _ref.read(dateLecturesProvider(request.lectureDate).notifier).refresh();
    
    final activeSem = _ref.read(activeSemesterProvider);
    if (activeSem != null) {
      final subjects = _ref.read(subjectsProvider).value ?? [];
      for (var sub in subjects) {
        _ref.read(subjectAttendanceStatsProvider(sub.subjectId).notifier).refresh();
        _ref.read(subjectInstancesProvider(sub.subjectId).notifier).refresh();
      }
    }
    
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
    
    // Save previous state for potential rollback
    final previousState = state;

    // Optimistically update local state if we have data
    if (state.hasValue) {
      final current = state.value!;
      final updated = current.copyWith(
        criteriaMode: request.criteriaMode ?? current.criteriaMode,
        overallAttendanceGoal: request.overallAttendanceGoal ?? current.overallAttendanceGoal,
      );
      state = AsyncValue.data(updated);
    }

    try {
      final res = await service.updateSettings(activeSem.semesterId, request);
      state = AsyncValue.data(res);
      // Trigger sync
      ref.read(syncServiceProvider).sync();
    } catch (e) {
      // Rollback on error
      state = previousState;
      rethrow;
    }
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
class SubjectInstancesNotifier extends FamilyAsyncNotifier<List<LectureInstanceDto>, String> {
  @override
  Future<List<LectureInstanceDto>> build(String arg) async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) return [];
    final service = ref.watch(attendanceServiceProvider);
    return service.getInstances(semesterId: activeSem.semesterId, subjectId: arg);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) return <LectureInstanceDto>[];
      final service = ref.read(attendanceServiceProvider);
      return service.getInstances(semesterId: activeSem.semesterId, subjectId: arg);
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

final subjectInstancesProvider =
    AsyncNotifierProviderFamily<SubjectInstancesNotifier, List<LectureInstanceDto>, String>(
  SubjectInstancesNotifier.new,
);

// ==========================================
// 8. Date Lectures Provider (Family)
// ==========================================
class DateLecturesNotifier extends FamilyAsyncNotifier<List<LectureInstanceDto>, String> {
  @override
  Future<List<LectureInstanceDto>> build(String arg) async {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) return [];
    final service = ref.watch(attendanceServiceProvider);
    return service.getTodayLectures(date: arg, semesterId: activeSem.semesterId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final activeSem = ref.read(activeSemesterProvider);
      if (activeSem == null) return <LectureInstanceDto>[];
      final service = ref.read(attendanceServiceProvider);
      return service.getTodayLectures(date: arg, semesterId: activeSem.semesterId);
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

final dateLecturesProvider =
    AsyncNotifierProviderFamily<DateLecturesNotifier, List<LectureInstanceDto>, String>(
  DateLecturesNotifier.new,
);
