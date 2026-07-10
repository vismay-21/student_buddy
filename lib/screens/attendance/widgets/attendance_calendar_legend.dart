import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceCalendarLegend extends StatelessWidget {
  final bool transparentBackground;

  const AttendanceCalendarLegend({
    super.key,
    this.transparentBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final Widget legendRow = Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 30,
      runSpacing: 8,
      children: [
        _legendItem('Present', AppTheme.accent),
        _legendItem('Absent', AppTheme.danger),
        _legendItem('Mixed', AppTheme.secondary),
        _legendItem('Day Off', AppTheme.warning),
        _legendItem('Holiday', const Color(0xFF0033FF)),
        _legendItem('Not Marked', AppTheme.textMuted),
      ],
    );

    if (transparentBackground) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: legendRow,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: legendRow,
    );
  }

  Widget _legendItem(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
