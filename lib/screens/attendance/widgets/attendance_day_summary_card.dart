import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceDaySummaryCard extends StatelessWidget {
  final int totalDays;
  final int attendedDays;
  final int missedDays;
  final int offDays;
  final int mixedDays;

  const AttendanceDaySummaryCard({
    super.key,
    required this.totalDays,
    required this.attendedDays,
    required this.missedDays,
    required this.offDays,
    required this.mixedDays,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Card(
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MONTHLY DAY SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', totalDays, isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                _buildSummaryItem('Attended', attendedDays, AppTheme.accent),
                _buildSummaryItem('Missed', missedDays, AppTheme.danger),
                _buildSummaryItem('Off', offDays, AppTheme.warning),
                _buildSummaryItem('Mixed', mixedDays, AppTheme.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
