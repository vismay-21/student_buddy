import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/utils/app_state.dart';
import 'widgets/lecture_card.dart';

class SubjectHistoryScreen extends StatefulWidget {
  final String subjectName;
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final List<Map<String, dynamic>> holidays;
  final Map<String, Map<String, String>> dateActions;
  final int criteriaPercentage;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  const SubjectHistoryScreen({
    super.key,
    required this.subjectName,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.holidays,
    required this.dateActions,
    required this.criteriaPercentage,
    required this.onLectureActionChanged,
  });

  @override
  State<SubjectHistoryScreen> createState() => _SubjectHistoryScreenState();
}

class _SubjectHistoryScreenState extends State<SubjectHistoryScreen> {
  late Map<String, Map<String, String>> _localDateActions;

  @override
  void initState() {
    super.initState();
    // Create a local deep copy of the date actions to update UI instantly
    _localDateActions = {
      for (var entry in widget.dateActions.entries)
        entry.key: Map<String, String>.from(entry.value)
    };
  }

  void _onActionTapped(DateTime date, LectureMock lecture, String action) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      _localDateActions[dateKey] ??= {};
      _localDateActions[dateKey]![lecture.id] = action;
    });
    widget.onLectureActionChanged(date, lecture, action);
  }

  List<Map<String, dynamic>> _generateClassRecords() {
    final List<Map<String, dynamic>> list = [];
    DateTime current = widget.semesterStartDate;

    while (current.isBefore(widget.semesterEndDate) ||
        current.isAtSameMomentAs(widget.semesterEndDate)) {
      final int dayIdx = current.weekday - 1;
      final lectures = DummyData.getLecturesForDay(dayIdx);

      final bool isHoliday = widget.holidays.any((h) {
        final DateTime hDate = h['date'];
        return hDate.year == current.year &&
            hDate.month == current.month &&
            hDate.day == current.day;
      });

      for (var lec in lectures) {
        if (lec.name == widget.subjectName) {
          final dateKey = DateFormat('yyyy-MM-dd').format(current);
          final action = (_localDateActions[dateKey] ?? {})[lec.id] ?? 'clear';

          list.add({
            'date': current,
            'lecture': lec,
            'action': action,
            'isHoliday': isHoliday,
          });
        }
      }

      current = current.add(const Duration(days: 1));
    }

    return list.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color ringColor = AppTheme.primary;

    final records = _generateClassRecords();

    // Fetch calculation metrics from AppState
    final calculatedSubjects = AppState.instance.getCalculatedSubjects();
    final metrics = calculatedSubjects.firstWhere(
      (sub) => sub['name'] == widget.subjectName,
      orElse: () => {
        'percent': 0.0,
        'target': widget.criteriaPercentage,
        'attended': 0,
        'total': 0,
        'statusMessage': 'No logs',
        'isAboveTarget': false,
      },
    );

    final double attendancePercent = metrics['percent'] as double;
    final bool isAboveTarget = metrics['isAboveTarget'] as bool;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subjectName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header summary card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Circular Progress Ring
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: attendancePercent / 100,
                            strokeWidth: 6,
                            backgroundColor: ringColor.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAboveTarget ? AppTheme.accent : AppTheme.danger,
                            ),
                          ),
                          Text(
                            '${alignmentPercentString(attendancePercent)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
                            'Criteria Goal: ${widget.criteriaPercentage}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Classes Logged: ${metrics['attended']}/${metrics['total']}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metrics['statusMessage'],
                            style: TextStyle(
                              color: isAboveTarget ? AppTheme.accent : AppTheme.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CLASS RECORD HISTORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${records.length} Lectures',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable list of history instances
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text(
                      'No classes scheduled for this subject',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final item = records[index];
                      final DateTime date = item['date'];
                      final LectureMock lecture = item['lecture'];
                      final String action = item['action'];
                      final bool isHoliday = item['isHoliday'];
                      
                      final String dateStr = DateFormat('EEEE, d MMMM yyyy').format(date);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  if (isHoliday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'HOLIDAY',
                                        style: TextStyle(
                                          color: AppTheme.warning,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            LectureCard(
                              lecture: lecture,
                              showAttendance: true,
                              currentAction: action,
                              attendancePercent: metrics['percent'],
                              targetPercent: metrics['target'],
                              attended: metrics['attended'],
                              total: metrics['total'],
                              statusMessage: metrics['statusMessage'],
                              isAboveTarget: metrics['isAboveTarget'],
                              onActionChanged: (newAction) => _onActionTapped(date, lecture, newAction),
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

  String alignmentPercentString(double val) {
    return val.toInt().toString();
  }
}
