import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';

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

  // Helper to check if a date is a default day off (we assume Sunday Only or Saturday & Sunday are default off)
  // Let's default to Sunday Only inside this screen, or Saturday & Sunday based on standard weekends
  bool _isDefaultDayOff(DateTime date) {
    // For simplicity, we align with the standard weekend (Sunday only is typical, but let's check)
    // Actually, to make it consistent, we can just treat Sundays as default off
    return date.weekday == DateTime.sunday;
  }

  // Compile list of scheduled class dates and their logged actions
  List<Map<String, dynamic>> _getHistoryRecords() {
    final List<Map<String, dynamic>> records = [];
    
    // Find all weekdays where this subject has a lecture
    final Map<int, List<LectureMock>> subjectLecturesByWeekday = {};
    for (int weekday = 0; weekday < 7; weekday++) {
      final lectures = DummyData.getLecturesForDay(weekday);
      final matching = lectures.where((l) => l.name == widget.subjectName).toList();
      if (matching.isNotEmpty) {
        subjectLecturesByWeekday[weekday] = matching;
      }
    }

    // Iterate through all days in semester duration
    DateTime current = widget.semesterStartDate;
    while (!current.isAfter(widget.semesterEndDate)) {
      final int weekdayIndex = current.weekday - 1;
      
      if (subjectLecturesByWeekday.containsKey(weekdayIndex)) {
        final dateKey = DateFormat('yyyy-MM-dd').format(current);
        final dayActions = _localDateActions[dateKey] ?? {};
        
        final bool isHoliday = widget.holidays.any((h) {
          final DateTime hDate = h['date'];
          return hDate.year == current.year && hDate.month == current.month && hDate.day == current.day;
        });

        for (var lecture in subjectLecturesByWeekday[weekdayIndex]!) {
          final action = dayActions[lecture.id] ?? 'clear';
          records.add({
            'date': current,
            'lecture': lecture,
            'action': action,
            'isHoliday': isHoliday,
            'isDefaultDayOff': _isDefaultDayOff(current),
          });
        }
      }
      current = current.add(const Duration(days: 1));
    }

    // Sort descending by date (newest first)
    records.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return records;
  }

  // Recalculates metrics for this subject locally
  Map<String, dynamic> _getLocalMetrics() {
    // Start with baseline totals
    int attended = 0;
    int total = 0;

    // Find baseline attended/total
    for (var baselineSub in DummyData.attendanceList) {
      if (baselineSub.name == widget.subjectName) {
        attended = baselineSub.attended;
        total = baselineSub.total;
        break;
      }
    }

    // Scan local action modifications
    _localDateActions.forEach((dateKey, dayActions) {
      final date = DateTime.tryParse(dateKey);
      if (date != null) {
        final bool isHoliday = widget.holidays.any((h) {
          final DateTime hDate = h['date'];
          return hDate.year == date.year && hDate.month == date.month && hDate.day == date.day;
        });

        if (!isHoliday && !_isDefaultDayOff(date)) {
          final weekdayIndex = date.weekday - 1;
          final lectures = DummyData.getLecturesForDay(weekdayIndex);
          for (var lec in lectures) {
            if (lec.name == widget.subjectName) {
              final action = dayActions[lec.id] ?? 'clear';
              if (action == 'attended') {
                attended++;
                total++;
              } else if (action == 'missed') {
                total++;
              }
            }
          }
        }
      }
    });

    final double percent = total == 0 ? 0.0 : (attended / total) * 100;
    final int target = widget.criteriaPercentage;
    final bool isAboveTarget = percent >= target;

    String statusMessage = '';
    if (isAboveTarget) {
      int skip = 0;
      if (target > 0) {
        skip = (attended * 100 / target).floor() - total;
        if (skip < 0) skip = 0;
      }
      statusMessage = 'Safe to skip: $skip classes';
    } else {
      int must = 0;
      if (target < 100) {
        must = ((target * total - 100 * attended) / (100 - target)).ceil();
      } else {
        must = 99;
      }
      statusMessage = 'Must attend next $must classes';
    }

    return {
      'percent': percent,
      'attended': attended,
      'total': total,
      'statusMessage': statusMessage,
      'isAboveTarget': isAboveTarget,
    };
  }

  void _onActionTapped(DateTime date, LectureMock lecture, String action) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      _localDateActions[dateKey] ??= {};
      _localDateActions[dateKey]![lecture.id] = action;
    });

    // Notify parent state
    widget.onLectureActionChanged(date, lecture, action);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    
    final metrics = _getLocalMetrics();
    final double attendancePercent = metrics['percent'];
    final bool isAboveTarget = metrics['isAboveTarget'];
    final Color ringColor = isAboveTarget ? AppTheme.accent : AppTheme.danger;
    
    final records = _getHistoryRecords();

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
                            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                          ),
                          Text(
                            '${attendancePercent.toInt()}%',
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
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
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${lecture.startTime} - ${lecture.endTime} • Room: ${lecture.room} • Faculty: ${lecture.teacher}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildLogButton('clear', Icons.remove_circle_outline, AppTheme.textMuted, action, date, lecture),
                                  const SizedBox(width: 8),
                                  _buildLogButton('off', Icons.pause_circle_outline, AppTheme.warning, action, date, lecture),
                                  const SizedBox(width: 8),
                                  _buildLogButton('missed', Icons.highlight_off, AppTheme.danger, action, date, lecture),
                                  const SizedBox(width: 8),
                                  _buildLogButton('attended', Icons.check_circle_rounded, AppTheme.accent, action, date, lecture),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogButton(String logAction, IconData icon, Color color, String currentAction, DateTime date, LectureMock lecture) {
    final bool isSelected = currentAction == logAction;
    return GestureDetector(
      onTap: () => _onActionTapped(date, lecture, logAction),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? color : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              logAction.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
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
