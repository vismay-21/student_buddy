import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/attendance_ring_label.dart';
import '../../../core/providers/subject_provider.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../data/dto/subject/subject_dto.dart';
import 'subject_history_screen.dart';

class SubjectsTab extends ConsumerWidget {
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final settingsAsync = ref.watch(attendanceSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
        data: (settings) {
          final criteriaMode = settings.criteriaMode == 'subject' ? 'subject_wise' : settings.criteriaMode;
          final overallGoal = settings.overallAttendanceGoal;

          return subjectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading subjects: $err')),
            data: (subjects) {
              if (subjects.isEmpty) {
                return const Center(
                  child: Text(
                    'No subjects added yet.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
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
                  ...subjects.map((sub) => SubjectCardWidget(
                        subject: sub,
                        criteriaMode: criteriaMode,
                        overallGoal: overallGoal,
                      )),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class SubjectCardWidget extends ConsumerWidget {
  final SubjectDto subject;
  final String criteriaMode;
  final int overallGoal;

  const SubjectCardWidget({
    super.key,
    required this.subject,
    required this.criteriaMode,
    required this.overallGoal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(subjectAttendanceStatsProvider(subject.subjectId));
    final templatesAsync = ref.watch(timetableTemplatesProvider(subject.subjectId));

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SizedBox(
        height: 100,
        child: Center(child: Text('Failed to load stats', style: TextStyle(color: AppTheme.textMuted))),
      ),
      data: (stats) {
        final room = (templatesAsync.value != null &&
                templatesAsync.value!.isNotEmpty &&
                templatesAsync.value!.first.room != null)
            ? templatesAsync.value!.first.room!
            : 'Room TBD';

        int target = overallGoal;
        if (criteriaMode == 'custom') {
          target = subject.attendanceGoal;
        }

        final bool isAboveTarget = stats.attendancePercentage >= target;

        final subMap = {
          'id': subject.subjectId,
          'name': subject.subjectName,
          'percent': stats.attendancePercentage,
          'target': target,
          'attended': stats.presentLectures,
          'absent': stats.absentLectures,
          'total': stats.totalLectures,
          'statusMessage': stats.statusMessage,
          'isAboveTarget': isAboveTarget,
          'color': subject.themeColor,
          'faculty': subject.facultyName ?? 'Faculty TBD',
          'room': room,
        };

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
                    subjectId: subject.subjectId,
                    subjectName: subject.subjectName,
                    criteriaPercentage: target,
                    facultyName: subject.facultyName ?? 'Faculty TBD',
                    roomName: room,
                    onLectureActionChanged: (date, lecture, action) {
                      // Handled reactively
                    },
                  ),
                ),
              );
            },
            child: _buildSubjectCard(context, subMap),
          ),
        );
      },
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
