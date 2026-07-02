import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dummy_data.dart';
import '../../../core/widgets/attendance_ring_label.dart';

class LectureCard extends StatelessWidget {
  final LectureMock lecture;
  final bool showAttendance;
  final String currentAction; // 'clear', 'off', 'missed', 'attended'
  final double attendancePercent;
  final int targetPercent;
  final int attended;
  final int total;
  final String statusMessage;
  final bool isAboveTarget;
  final Function(String action)? onActionChanged;

  const LectureCard({
    super.key,
    required this.lecture,
    this.showAttendance = false,
    this.currentAction = 'clear',
    this.attendancePercent = 0.0,
    this.targetPercent = 80,
    this.attended = 0,
    this.total = 0,
    this.statusMessage = '',
    this.isAboveTarget = true,
    this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color cardColor = Color(lecture.colorValue);
    final Color ringColor = isAboveTarget ? AppTheme.accent : AppTheme.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              cardColor.withOpacity(0.12),
              cardColor.withOpacity(0.03),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time, Divider, Subject/Faculty/Room details, Ring (optional)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Colored accent bar
                Container(
                  width: 5,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),

                // Time column
                SizedBox(
                  width: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lecture.startTime,
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        lecture.endTime,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Thin vertical separator
                Container(
                  width: 1,
                  height: 38,
                  color: cardColor.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                // Subject details: name → room → teacher
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture.name,
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 11, color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            lecture.room,
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 11, color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lecture.teacher,
                              style: TextStyle(
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Attendance circular ring on the right (if showAttendance is true)
                if (showAttendance) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(44, 44),
                          painter: _RingPainter(
                            progress: attendancePercent / 100,
                            ringColor: ringColor,
                            backgroundColor: ringColor.withOpacity(0.15),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: AttendanceRingLabel(
                              current: attendancePercent,
                              target: targetPercent.toDouble(),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Bottom section: Metrics and Action Buttons (if showAttendance is true)
            if (showAttendance) ...[
              const SizedBox(height: 6),
              Divider(color: borderColor),
              const SizedBox(height: 6),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        color: isAboveTarget ? AppTheme.accent : AppTheme.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton('clear', Icons.remove_circle_outline, isDark ? AppTheme.textMuted : Colors.black54),
                      const SizedBox(width: 4),
                      _buildActionButton('off', Icons.pause_circle_outline, AppTheme.warning),
                      const SizedBox(width: 4),
                      _buildActionButton('missed', Icons.highlight_off, AppTheme.danger),
                      const SizedBox(width: 4),
                      _buildActionButton('attended', Icons.check_circle_rounded, AppTheme.accent),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String action, IconData icon, Color color) {
    final bool isSelected = currentAction == action;
    return GestureDetector(
      onTap: () {
        if (onActionChanged != null) {
          onActionChanged!(action);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? color : AppTheme.textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                action.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
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
