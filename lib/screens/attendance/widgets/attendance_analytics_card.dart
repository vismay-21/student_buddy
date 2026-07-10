import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceAnalyticsCard extends StatelessWidget {
  final int totalDays;
  final int attendedDays;
  final int missedDays;
  final int offDays;
  final int mixedDays;

  final int totalLectures;
  final int attendedLectures;
  final int missedLectures;
  final int offLectures;
  final double attendancePercentage;

  const AttendanceAnalyticsCard({
    super.key,
    required this.totalDays,
    required this.attendedDays,
    required this.missedDays,
    required this.offDays,
    required this.mixedDays,
    required this.totalLectures,
    required this.attendedLectures,
    required this.missedLectures,
    required this.offLectures,
    required this.attendancePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color labelColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Card(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Days
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAYS SUMMARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow('Total Days', '$totalDays', labelColor),
                  _buildStatRow('Attended', '$attendedDays', AppTheme.accent),
                  _buildStatRow('Missed', '$missedDays', AppTheme.danger),
                  _buildStatRow('Off/Holiday', '$offDays', AppTheme.warning),
                  _buildStatRow('Mixed', '$mixedDays', AppTheme.secondary),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Vertical Separator
            Container(
              height: 110,
              width: 1,
              color: borderColor,
            ),
            const SizedBox(width: 16),
            // Right Column: Lectures
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LECTURE STATS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow('Total Lectures', '$totalLectures', labelColor),
                  _buildStatRow('Attended', '$attendedLectures', AppTheme.accent),
                  _buildStatRow('Missed', '$missedLectures', AppTheme.danger),
                  _buildStatRow('Off/Holiday', '$offLectures', AppTheme.warning),
                  _buildStatRow('Attendance', '${attendancePercentage.toStringAsFixed(2)}%', AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
