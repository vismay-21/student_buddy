import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/utils/color_helper.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/expandable_section.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/dto/holiday/holiday_dto.dart';
import '../../core/providers/semester_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/review_queue_provider.dart';
import '../../core/providers/app_settings_provider.dart';
import '../review_queue/review_queue_screen.dart';
import '../settings/semester_selection_screen.dart';
import '../attendance/widgets/lecture_card.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  String? _getNextClassNotification(List<LectureInstanceDto> todayInstances) {
    if (todayInstances.isEmpty) return null;
    final now = DateTime.now();
    final nowTimeStr = DateFormat('HH:mm').format(now);

    final futureClasses = todayInstances.where((inst) {
      if (inst.lectureStatus != 'scheduled') return false;
      final startTime = inst.lectureTemplate.startTime;
      return startTime.compareTo(nowTimeStr) > 0;
    }).toList();

    if (futureClasses.isEmpty) return null;

    futureClasses.sort((a, b) => a.lectureTemplate.startTime.compareTo(b.lectureTemplate.startTime));
    final nextClass = futureClasses.first;
    final template = nextClass.lectureTemplate;
    return '${template.subject.subjectName} starts at ${template.startTime.substring(0, 5)}${template.room != null ? " (Room ${template.room})" : ""}';
  }

  Widget _buildNoSemesterState(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Semester',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'To start tracking attendance, timetable schedule, tasks, and notes, please select or create an academic semester.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Configure Semester'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SemesterSelectionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNoSemesterState(context),
          ),
        ),
      );
    }

    final todayLecturesAsync = ref.watch(todayLecturesProvider);
    final pendingReviewsAsync = ref.watch(pendingReviewQueueProvider);
    final holidaysAsync = ref.watch(holidaysProvider);
    final financeSettings = ref.watch(financeSettingsProvider);

    // Determine loading state
    if (todayLecturesAsync.isLoading || pendingReviewsAsync.isLoading || holidaysAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final todayInstances = todayLecturesAsync.value ?? [];
    final pendingReviewsCount = pendingReviewsAsync.value?.length ?? 0;
    final holidays = holidaysAsync.value ?? [];

    // Calculate if today is holiday
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    HolidayDto? holidayToday;
    for (final h in holidays) {
      if (h.holidayDate.year == todayDateOnly.year &&
          h.holidayDate.month == todayDateOnly.month &&
          h.holidayDate.day == todayDateOnly.day) {
        holidayToday = h;
        break;
      }
    }
    final bool isTodayHoliday = holidayToday != null;

    final nextClassNotif = _getNextClassNotification(todayInstances);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewQueueCard(context, pendingReviewsCount),

            // Dynamic Notifications Bar
            if (nextClassNotif != null) ...[
              _buildNotificationsBanner(context, nextClassNotif),
              const SizedBox(height: 16),
            ],

            // Collapsible Classes Section
            ExpandableSection(
              title: 'TODAY\'S CLASSES',
              subtitle: ' (${todayInstances.length})',
              showFrame: true,
              children: [
                if (holidayToday != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
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
                ],
                if (todayInstances.isNotEmpty) ...[
                  _buildSectionHeader('MARK WHOLE DAY'),
                  const SizedBox(height: 6),
                  _buildWholeDayActionPanel(context, todayInstances, isTodayHoliday),
                  const SizedBox(height: 10),
                ],
                _buildLecturesSection(context, todayInstances, isTodayHoliday),
              ],
            ),
            const SizedBox(height: 16),

            // Optional Finance Card
            if (financeSettings.isFinanceEnabled) ...[
              ExpandableSection(
                title: 'FINANCE SUMMARY',
                showFrame: true,
                children: [
                  _buildFinanceSummaryCard(context),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildNotificationsBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholeDayActionPanel(BuildContext context, List<LectureInstanceDto> lectures, bool isHoliday) {
    if (lectures.isEmpty) return const SizedBox.shrink();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
              Expanded(child: _buildWholeDayButton('clear', 'Clear', isDark ? AppTheme.textMuted : Colors.black54, Icons.remove_circle_outline, isHoliday)),
              const SizedBox(width: 4),
              Expanded(child: _buildWholeDayButton('off', 'Day Off', AppTheme.warning, Icons.pause_circle_outline, isHoliday)),
              const SizedBox(width: 4),
              Expanded(child: _buildWholeDayButton('missed', 'Missed', AppTheme.danger, Icons.highlight_off, isHoliday)),
              const SizedBox(width: 4),
              Expanded(child: _buildWholeDayButton('attended', 'Attended', AppTheme.accent, Icons.check_circle_rounded, isHoliday)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWholeDayButton(String action, String label, Color color, IconData icon, bool isHoliday) {
    final bool isClickable = !isHoliday;
    return InkWell(
      onTap: isClickable ? () async {
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
          return;
        }

        final activeSem = ref.read(activeSemesterProvider);
        if (activeSem == null) return;

        try {
          await ref.read(attendanceActionsProvider).markWholeDay(LectureInstanceBulkUpdateRequest(
            lectureDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            attendanceStatus: newAttendanceStatus,
            lectureStatus: newLectureStatus,
            semesterId: activeSem.semesterId,
          ));
          if (mounted) {
            AppSnackbar.show(
              context,
              message: 'Whole day marked as "${action.toUpperCase()}"',
              icon: icon,
              color: color,
            );
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.error(context, 'Failed to bulk update: $e');
          }
        }
      } : null,
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
                Icon(icon, size: 15, color: isClickable ? color : AppTheme.textMuted),
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

  Widget _buildLecturesSection(BuildContext context, List<LectureInstanceDto> lectures, bool isHoliday) {
    if (lectures.isEmpty) {
      return Card(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No classes scheduled for today 🎉',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    return Column(
      children: lectures.map((inst) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _OverviewLectureCard(
            inst: inst,
            isTodayHoliday: isHoliday,
            onActionChanged: !isHoliday
                ? (action) async {
                    String newAttendanceStatus = 'unmarked';
                    String newLectureStatus = 'scheduled';
                    if (action == 'attended') {
                      newAttendanceStatus = 'present';
                    } else if (action == 'missed') {
                      newAttendanceStatus = 'absent';
                    } else if (action == 'off') {
                      newLectureStatus = 'holiday';
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
                    } catch (e) {
                      if (mounted) {
                        AppSnackbar.error(context, 'Failed to update attendance: $e');
                      }
                    }
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinanceSummaryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Balance',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      Text(
                        '₹17,000.00',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Today\'s Expenses',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '₹120.00',
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQueueCard(BuildContext context, int pendingReviewsCount) {
    if (pendingReviewsCount == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.danger.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$pendingReviewsCount item${pendingReviewsCount > 1 ? "s" : ""} need your review',
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReviewQueueScreen()),
                );
              },
              child: const Text(
                'Review Now',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewLectureCard extends ConsumerWidget {
  final LectureInstanceDto inst;
  final bool isTodayHoliday;
  final ValueChanged<String>? onActionChanged;

  const _OverviewLectureCard({
    required this.inst,
    required this.isTodayHoliday,
    this.onActionChanged,
  });

  LectureMock _mapToMock(LectureInstanceDto inst) {
    final template = inst.lectureTemplate;
    final subject = template.subject;
    final colorVal = parseHexColor(subject.themeColor).value;
    return LectureMock(
      id: inst.lectureInstanceId,
      name: subject.subjectName,
      startTime: template.startTime.substring(0, 5),
      endTime: template.endTime.substring(0, 5),
      room: template.room ?? 'Room TBD',
      teacher: subject.facultyName ?? 'Faculty TBD',
      colorValue: colorVal,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecture = _mapToMock(inst);
    final currentAction = inst.attendanceStatus == 'present'
        ? 'attended'
        : (inst.attendanceStatus == 'absent'
            ? 'missed'
            : (inst.lectureStatus == 'holiday' ? 'off' : 'clear'));

    final statsAsync = ref.watch(subjectAttendanceStatsProvider(inst.lectureTemplate.subjectId));
    final settingsAsync = ref.watch(attendanceSettingsProvider);

    if (statsAsync.hasValue) {
      final stats = statsAsync.value!;
      final settings = settingsAsync.value;
      final mappedMode = settings?.criteriaMode == 'subject' ? 'subject_wise' : settings?.criteriaMode;
      int target = settings?.overallAttendanceGoal ?? 80;
      if (mappedMode == 'custom') {
        target = inst.lectureTemplate.subject.attendanceGoal;
      }
      final bool isAboveTarget = stats.attendancePercentage >= target;

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
        onActionChanged: onActionChanged,
      );
    } else if (statsAsync.isLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      return Text('Error loading stats: ${statsAsync.error}');
    }
  }
}
