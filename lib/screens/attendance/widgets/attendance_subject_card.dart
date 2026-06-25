import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceSubjectCard extends StatelessWidget {
  final String subjectName;
  final double attendancePercent;
  final int targetPercent;
  final int attended;
  final int total;
  final String statusMessage;
  final bool isAboveTarget;
  final bool showActions;
  final String currentAction; // 'clear', 'off', 'missed', 'attended'
  final Function(String action)? onActionChanged;

  const AttendanceSubjectCard({
    super.key,
    required this.subjectName,
    required this.attendancePercent,
    required this.targetPercent,
    required this.attended,
    required this.total,
    required this.statusMessage,
    required this.isAboveTarget,
    this.showActions = true,
    this.currentAction = 'clear',
    this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color ringColor = isAboveTarget ? AppTheme.accent : AppTheme.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Custom Circular Ring
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(56, 56),
                        painter: _RingPainter(
                          progress: attendancePercent / 100,
                          ringColor: ringColor,
                          backgroundColor: ringColor.withOpacity(0.15),
                        ),
                      ),
                      Text(
                        '${attendancePercent.toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Criteria: $targetPercent% • Attended: $attended/$total',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Skip/Attend Status Advice
                      Text(
                        statusMessage,
                        style: TextStyle(
                          color: isAboveTarget ? AppTheme.accent : AppTheme.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Divider(color: borderColor),
              const SizedBox(height: 8),
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton('clear', Icons.remove_circle_outline, AppTheme.textMuted),
                  const SizedBox(width: 8),
                  _buildActionButton('off', Icons.pause_circle_outline, AppTheme.warning),
                  const SizedBox(width: 8),
                  _buildActionButton('missed', Icons.highlight_off, AppTheme.danger),
                  const SizedBox(width: 8),
                  _buildActionButton('attended', Icons.check_circle_rounded, AppTheme.accent),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              action.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
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
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    // Background arc
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = backgroundColor);
    // Active progress arc
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
