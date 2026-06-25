import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dummy_data.dart';
import 'widgets/attendance_subject_card.dart';

class DayHistoryScreen extends StatefulWidget {
  final DateTime date;
  final List<LectureMock> todayLectures;
  final Map<String, String> lectureActions;
  final Map<String, Map<String, dynamic>> subjectsMetrics;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  const DayHistoryScreen({
    super.key,
    required this.date,
    required this.todayLectures,
    required this.lectureActions,
    required this.subjectsMetrics,
    required this.onLectureActionChanged,
  });

  @override
  State<DayHistoryScreen> createState() => _DayHistoryScreenState();
}

class _DayHistoryScreenState extends State<DayHistoryScreen> {
  late Map<String, String> _localLectureActions;

  @override
  void initState() {
    super.initState();
    // Copy actions to local state to allow instant UI updates on click
    _localLectureActions = Map<String, String>.from(widget.lectureActions);
  }

  void _onActionTapped(LectureMock lecture, String action) {
    setState(() {
      _localLectureActions[lecture.id] = action;
    });
    // Trigger callback to bubble changes to the parent controller
    widget.onLectureActionChanged(widget.date, lecture, action);
  }

  void _onWholeDayAction(String action) {
    setState(() {
      for (var lecture in widget.todayLectures) {
        _localLectureActions[lecture.id] = action;
        widget.onLectureActionChanged(widget.date, lecture, action);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final String titleStr = DateFormat('EEEE, d MMMM yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Day Logs Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Day Header Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.todayLectures.length} scheduled lectures for this day',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Whole day action panel (copied from Today tab)
          if (widget.todayLectures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              'LECTURES LIST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),

          Expanded(
            child: widget.todayLectures.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.weekend_rounded,
                          size: 48,
                          color: AppTheme.textMuted.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No classes scheduled for this day.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.todayLectures.length,
                    itemBuilder: (context, index) {
                      final lecture = widget.todayLectures[index];
                      final metrics = widget.subjectsMetrics[lecture.name] ??
                          {
                            'percent': 0.0,
                            'target': 80,
                            'attended': 0,
                            'total': 0,
                            'statusMessage': 'No details',
                            'isAboveTarget': false,
                          };

                      final currentAction = _localLectureActions[lecture.id] ?? 'clear';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                              child: Text(
                                'Time: ${lecture.startTime} - ${lecture.endTime} (Room ${lecture.room})',
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
                              onActionChanged: (action) => _onActionTapped(lecture, action),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholeDayButton(String action, String label, Color color, IconData icon) {
    return InkWell(
      onTap: () => _onWholeDayAction(action),
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
