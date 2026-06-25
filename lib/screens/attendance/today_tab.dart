import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dummy_data.dart';
import 'widgets/attendance_overview_card.dart';
import 'widgets/attendance_subject_card.dart';

class TodayTab extends StatelessWidget {
  final String dayName;
  final String dateString;
  final double overallPercentage;
  final int targetPercentage;
  final String criteriaMode;
  final List<Map<String, dynamic>> belowTargetSubjects;
  final List<LectureMock> todayLectures;
  final Map<String, String> lectureActions; // lectureId -> action
  final Map<String, Map<String, dynamic>> subjectsMetrics; // subjectName -> metrics
  final Function(LectureMock lecture, String action) onLectureActionChanged;
  final Function(String action) onWholeDayAction;

  const TodayTab({
    super.key,
    required this.dayName,
    required this.dateString,
    required this.overallPercentage,
    required this.targetPercentage,
    required this.criteriaMode,
    required this.belowTargetSubjects,
    required this.todayLectures,
    required this.lectureActions,
    required this.subjectsMetrics,
    required this.onLectureActionChanged,
    required this.onWholeDayAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day and Date Header (matching Timetable screen)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  dateString,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall Attendance Status card
            AttendanceOverviewCard(
              overallPercentage: overallPercentage,
              targetPercentage: targetPercentage,
              isSubjectWise: criteriaMode == 'subject_wise',
              belowTargetSubjects: belowTargetSubjects,
            ),
            const SizedBox(height: 20),

            // Whole Day Actions
            const Text(
              'MARK WHOLE DAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildWholeDayButton('clear', 'Clear', AppTheme.textMuted, Icons.remove_circle_outline)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildWholeDayButton('off', 'Day Off', AppTheme.warning, Icons.pause_circle_outline)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildWholeDayButton('missed', 'Missed', AppTheme.danger, Icons.highlight_off)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildWholeDayButton('attended', 'Attended', AppTheme.accent, Icons.check_circle_rounded)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (todayLectures.isEmpty)
              Card(
                color: cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No classes scheduled today',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enjoy your free day!',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...todayLectures.map((lecture) {
                // Find subject details
                final metrics = subjectsMetrics[lecture.name] ??
                    {
                      'percent': 0.0,
                      'target': targetPercentage,
                      'attended': 0,
                      'total': 0,
                      'statusMessage': 'No details',
                      'isAboveTarget': false,
                    };

                final currentAction = lectureActions[lecture.id] ?? 'clear';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                      child: Text(
                        '${lecture.startTime} - ${lecture.endTime} (Room ${lecture.room})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    AttendanceSubjectCard(
                      subjectName: lecture.name,
                      attendancePercent: metrics['percent'],
                      targetPercent: metrics['target'],
                      attended: metrics['attended'],
                      total: metrics['total'],
                      statusMessage: metrics['statusMessage'],
                      isAboveTarget: metrics['isAboveTarget'],
                      showActions: true,
                      currentAction: currentAction,
                      onActionChanged: (action) {
                        onLectureActionChanged(lecture, action);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWholeDayButton(String action, String label, Color color, IconData icon) {
    return InkWell(
      onTap: () => onWholeDayAction(action),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
