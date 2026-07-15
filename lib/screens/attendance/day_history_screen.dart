import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dummy_data.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/dto/lecture/lecture_instance_dto.dart';
import '../../../data/dto/holiday/holiday_dto.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/semester_provider.dart';
import 'widgets/lecture_card.dart';

class DayHistoryScreen extends ConsumerWidget {
  final DateTime date;

  const DayHistoryScreen({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final String dateStr = DateFormat('yyyy-MM-dd').format(date);
    final String titleStr = DateFormat('EEEE, d MMMM yyyy').format(date);

    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Day Logs Details')),
        body: const Center(child: Text('No active semester')),
      );
    }

    final instancesAsync = ref.watch(dateLecturesProvider(dateStr));
    final holidays = ref.watch(holidaysProvider).value ?? [];
    final settings = ref.watch(attendanceSettingsProvider).value;

    final holidayToday = holidays.firstWhere(
      (h) => h.holidayDate.year == date.year && h.holidayDate.month == date.month && h.holidayDate.day == date.day,
      orElse: () => HolidayDto(holidayId: '', semesterId: '', holidayDate: date, holidayName: '', createdAt: date, updatedAt: date),
    );
    final bool hasHolidayToday = holidayToday.holidayId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Day Logs Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: instancesAsync.hasValue
          ? Builder(
              builder: (context) {
                final instances = instancesAsync.value!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Day Header Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleStr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${instances.length} scheduled lectures for this day',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (hasHolidayToday)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1D4ED8).withOpacity(0.3), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'University Holiday',
                                      style: TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      holidayToday.holidayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Whole day action panel
                    if (instances.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Card(
                          color: cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: borderColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: _buildWholeDayButton(
                                        context, ref, activeSem.semesterId, dateStr, hasHolidayToday, 'clear', 'Clear',
                                        AppTheme.textMuted, Icons.remove_circle_outline)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: _buildWholeDayButton(
                                        context, ref, activeSem.semesterId, dateStr, hasHolidayToday, 'off', 'Day Off',
                                        AppTheme.warning, Icons.pause_circle_outline)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: _buildWholeDayButton(
                                        context, ref, activeSem.semesterId, dateStr, hasHolidayToday, 'missed', 'Missed',
                                        AppTheme.danger, Icons.highlight_off)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: _buildWholeDayButton(
                                        context, ref, activeSem.semesterId, dateStr, hasHolidayToday, 'attended', 'Attended',
                                        AppTheme.accent, Icons.check_circle_rounded)),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        'LECTURES LIST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    Expanded(
                      child: instances.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.weekend_rounded,
                                    size: 48,
                                    color: AppTheme.textMuted.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No classes scheduled for this day.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: instances.length,
                              itemBuilder: (context, index) {
                                final inst = instances[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: LectureCardWrapper(
                                    inst: inst,
                                    hasHoliday: hasHolidayToday,
                                    overallGoal: settings?.overallAttendanceGoal ?? 75,
                                    criteriaMode: settings?.criteriaMode ?? 'overall',
                                    onActionChanged: (action) => _onActionTapped(context, ref, inst, action),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            )
          : instancesAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(child: Text('Error: ${instancesAsync.error}')),
    );
  }

  void _onActionTapped(BuildContext context, WidgetRef ref, LectureInstanceDto inst, String action) async {
    String? newAttendanceStatus;
    String? newLectureStatus;

    if (action == 'attended') {
      newAttendanceStatus = 'present';
      newLectureStatus = 'scheduled';
    } else if (action == 'missed') {
      newAttendanceStatus = 'absent';
      newLectureStatus = 'scheduled';
    } else if (action == 'off') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'holiday';
    } else if (action == 'clear') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'scheduled';
    }

    try {
      await ref.read(attendanceActionsProvider).updateAttendance(
            inst.lectureInstanceId,
            LectureInstanceUpdateRequest(
              attendanceStatus: newAttendanceStatus,
              lectureStatus: newLectureStatus,
            ),
            subjectId: inst.lectureTemplate.subjectId,
            oldStatus: inst.attendanceStatus,
            dateStr: DateFormat('yyyy-MM-dd').format(inst.lectureDate),
          );
      AppSnackbar.success(context, 'Attendance updated.');
    } catch (e) {
      AppSnackbar.error(context, 'Failed to update attendance: $e');
    }
  }

  void _onWholeDayAction(BuildContext context, WidgetRef ref, String semesterId, String dateStr, String action) async {
    String? newAttendanceStatus;
    String? newLectureStatus;

    if (action == 'attended') {
      newAttendanceStatus = 'present';
      newLectureStatus = 'scheduled';
    } else if (action == 'missed') {
      newAttendanceStatus = 'absent';
      newLectureStatus = 'scheduled';
    } else if (action == 'clear') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'scheduled';
    } else if (action == 'off') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'holiday';
    } else {
      AppSnackbar.warning(context, 'Invalid action type.');
      return;
    }

    try {
      await ref.read(attendanceActionsProvider).markWholeDay(
            LectureInstanceBulkUpdateRequest(
              lectureDate: dateStr,
              attendanceStatus: newAttendanceStatus,
              lectureStatus: newLectureStatus,
              semesterId: semesterId,
            ),
          );
      AppSnackbar.success(context, 'Whole day status updated.');
    } catch (e) {
      AppSnackbar.error(context, 'Failed to bulk update: $e');
    }
  }

  Widget _buildWholeDayButton(
    BuildContext context,
    WidgetRef ref,
    String semesterId,
    String dateStr,
    bool hasHolidayToday,
    String action,
    String label,
    Color color,
    IconData icon,
  ) {
    final bool isClickable = !hasHolidayToday;
    return InkWell(
      onTap: isClickable ? () => _onWholeDayAction(context, ref, semesterId, dateStr, action) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isClickable ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isClickable ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.12),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: isClickable ? 1.0 : 0.35,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isClickable ? color : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isClickable ? color : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LectureCardWrapper extends ConsumerWidget {
  final LectureInstanceDto inst;
  final bool hasHoliday;
  final int overallGoal;
  final String criteriaMode;
  final Function(String action) onActionChanged;

  const LectureCardWrapper({
    super.key,
    required this.inst,
    required this.hasHoliday,
    required this.overallGoal,
    required this.criteriaMode,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = inst.lectureTemplate.subject;
    final statsAsync = ref.watch(subjectAttendanceStatsProvider(sub.subjectId));

    if (statsAsync.hasValue) {
      final stats = statsAsync.value!;
        int target = overallGoal;
        if (criteriaMode == 'custom') {
          target = sub.attendanceGoal;
        }

        final bool isAboveTarget = stats.attendancePercentage >= target;

        final template = inst.lectureTemplate;
        final subject = template.subject;
        final colorVal = parseHexColor(subject.themeColor).value;

        final lecture = LectureMock(
          id: inst.lectureInstanceId,
          name: subject.subjectName,
          startTime: template.startTime.substring(0, 5),
          endTime: template.endTime.substring(0, 5),
          room: template.room ?? 'Room TBD',
          teacher: subject.facultyName ?? 'Faculty TBD',
          colorValue: colorVal,
        );

        String currentAction = 'clear';
        if (inst.lectureStatus == 'holiday') {
          currentAction = 'off';
        } else if (inst.attendanceStatus == 'present') {
          currentAction = 'attended';
        } else if (inst.attendanceStatus == 'absent') {
          currentAction = 'missed';
        }

        return LectureCard(
          lecture: lecture,
          showAttendance: true,
          currentAction: currentAction,
          attendancePercent: stats.attendancePercentage,
          targetPercent: target,
          attended: stats.presentLectures,
          total: stats.totalLectures,
          statusMessage: stats.statusMessage,
          isAboveTarget: isAboveTarget,
          onActionChanged: hasHoliday ? null : onActionChanged,
        );
    } else if (statsAsync.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Failed to load stats', style: TextStyle(color: AppTheme.textMuted))),
      );
    }
  }
}
