import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/dummy_data.dart';
import '../../../core/widgets/attendance_ring_label.dart';
import 'subject_history_screen.dart';

class SubjectsTab extends StatelessWidget {
  final double overallPercentage;
  final int targetPercentage;
  final String criteriaMode;
  final List<Map<String, dynamic>> belowTargetSubjects;
  final List<Map<String, dynamic>> subjectsList; // list of subject metrics
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final List<Map<String, dynamic>> holidays;
  final Map<String, Map<String, String>> dateActions;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  const SubjectsTab({
    super.key,
    required this.overallPercentage,
    required this.targetPercentage,
    required this.criteriaMode,
    required this.belowTargetSubjects,
    required this.subjectsList,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.holidays,
    required this.dateActions,
    required this.onLectureActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          // Subjects Title
          const Text(
            'SEMESTER SUBJECTS ANALYTICS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // List of Subject Cards (Clickable)
          ...subjectsList.map((sub) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.transparent,
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectHistoryScreen(
                        subjectId: sub['id'] as String,
                        subjectName: sub['name'] as String,
                        criteriaPercentage: sub['target'] as int,
                        facultyName: sub['faculty'] as String? ?? 'Faculty TBD',
                        roomName: sub['room'] as String? ?? 'Room TBD',
                        onLectureActionChanged: onLectureActionChanged,
                      ),
                    ),
                  );
                },
                child: _buildSubjectCard(context, sub),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> sub) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color ringColor = sub['isAboveTarget'] as bool ? AppTheme.accent : AppTheme.danger;

    Color accentColor = AppTheme.primary;
    if (sub['color'] != null) {
      accentColor = parseHexColor(sub['color'] as String);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.01),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Left color bar
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),

          // Middle: details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub['name'] as String,
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Attended: ${sub['attended']}/${(sub['attended'] as int) + (sub['absent'] as int)} • Total Lectures: ${sub['total']}',
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub['statusMessage'] as String,
                  style: TextStyle(
                    color: sub['isAboveTarget'] as bool ? AppTheme.accent : AppTheme.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: circular progress
          // Right: circular progress
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(44, 44),
                  painter: _RingPainter(
                    progress: (sub['percent'] as double) / 100,
                    ringColor: ringColor,
                    backgroundColor: ringColor.withOpacity(0.15),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AttendanceRingLabel(
                      current: sub['percent'] as double,
                      target: (sub['target'] as int).toDouble(),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = backgroundColor);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      stroke..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
