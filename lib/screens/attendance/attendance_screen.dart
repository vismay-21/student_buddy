import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Store actions locally to simulate mock interactions
  final Map<String, String> _subjectActions = {
    for (var subject in DummyData.attendanceList) subject.id: 'clear'
  };

  void _onActionTapped(String subjectId, String action) {
    setState(() {
      _subjectActions[subjectId] = action;
    });

    // Show feedback
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Attendance marked as "${action.toUpperCase()}" (Mock Simulation)'),
        backgroundColor: action == 'attended' 
            ? AppTheme.accent 
            : action == 'missed' 
                ? AppTheme.danger 
                : action == 'off' 
                    ? AppTheme.warning 
                    : AppTheme.textMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Global Goal Card
            _buildGlobalGoalCard(),
            const SizedBox(height: 20),

            // Legend indicators
            _buildLegendRow(),
            const SizedBox(height: 16),

            // Subject Cards List
            const Text(
              'SUBJECT WISE DETAILS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: DummyData.attendanceList.length,
              itemBuilder: (context, index) {
                final subject = DummyData.attendanceList[index];
                final currentAction = _subjectActions[subject.id] ?? 'clear';
                return _buildSubjectCard(subject, currentAction);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalGoalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance Status',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target Goal: 85% | Active Semester average',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '87.03%',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E293B)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your attendance trend is stable. All core subjects except DBMS are above target.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _legendItem('Attended', AppTheme.accent, Icons.check_circle_outline),
          _legendItem('Missed', AppTheme.danger, Icons.highlight_off),
          _legendItem('Off', AppTheme.warning, Icons.pause_circle_outline),
          _legendItem('Clear', AppTheme.textMuted, Icons.remove_circle_outline),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(SubjectAttendanceMock subject, String currentAction) {
    final isAboveTarget = subject.attendancePercent >= subject.targetPercent;
    final ringColor = isAboveTarget ? AppTheme.accent : AppTheme.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                          progress: subject.attendancePercent / 100,
                          ringColor: ringColor,
                          backgroundColor: ringColor.withOpacity(0.15),
                        ),
                      ),
                      Text(
                        '${subject.attendancePercent.toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
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
                        subject.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${subject.targetPercent}% • Attended: ${subject.attended}/${subject.total}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      // Skip Status
                      Text(
                        subject.status == 'safe_to_skip'
                            ? 'Safe to skip: ${subject.canMiss} lecture${subject.canMiss > 1 ? 's' : ''}'
                            : 'Must attend next classes (Below Target)',
                        style: TextStyle(
                          color: subject.status == 'safe_to_skip' ? AppTheme.accent : AppTheme.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1E293B)),
            const SizedBox(height: 8),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(subject.id, 'clear', Icons.remove_circle_outline, AppTheme.textMuted, currentAction == 'clear'),
                const SizedBox(width: 8),
                _buildActionButton(subject.id, 'off', Icons.pause_circle_outline, AppTheme.warning, currentAction == 'off'),
                const SizedBox(width: 8),
                _buildActionButton(subject.id, 'missed', Icons.highlight_off, AppTheme.danger, currentAction == 'missed'),
                const SizedBox(width: 8),
                _buildActionButton(subject.id, 'attended', Icons.check_circle_rounded, AppTheme.accent, currentAction == 'attended'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String subjectId, String action, IconData icon, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => _onActionTapped(subjectId, action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppTheme.surfaceLight,
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
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              action.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textSecondary,
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
