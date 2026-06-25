import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import 'today_tab.dart';
import 'history_tab.dart';
import 'subjects_tab.dart';
import 'attendance_settings_tab.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _currentTab = 0; // 0: Today, 1: History, 2: Subjects, 3: Settings
  DateTime _selectedDate = DateTime.now();

  // Settings State
  String _criteriaMode = 'subject_wise'; // 'overall', 'subject_wise', 'custom'
  int _targetPercentage = 80;
  final Map<String, int> _subjectCustomTargets = {};
  String _defaultDaysOff = 'Sunday Only'; // 'Sunday Only', 'Saturday & Sunday', 'None'
  DateTime _semesterStartDate = DateTime(2026, 6, 1);
  DateTime _semesterEndDate = DateTime(2026, 11, 30);

  // Holiday list
  final List<Map<String, dynamic>> _holidays = [
    {'name': 'Independence Day', 'date': DateTime(2026, 8, 15)},
    {'name': 'Gandhi Jayanti', 'date': DateTime(2026, 10, 2)},
  ];

  // Logs state: dateKey ("yyyy-MM-dd") -> Map of lectureId -> action ('attended', 'missed', 'off', 'clear')
  final Map<String, Map<String, String>> _dateActions = {};

  @override
  void initState() {
    super.initState();
  }

  // ── Helper to format date keys ─────────────────────────────────────────────
  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // ── Timetable coupling: get day and date details ───────────────────────────
  String _getFullDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  String _getFormattedDate(DateTime date) {
    final day = date.day;
    String suffix = 'th';
    if (day < 11 || day > 13) {
      switch (day % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
      }
    }
    return '$day$suffix ${DateFormat('MMMM').format(date)}';
  }

  // ── Dynamic calculations ───────────────────────────────────────────────────
  
  // Computes the live metrics for each subject based on baseline + dateActions log overrides
  List<Map<String, dynamic>> _getCalculatedSubjects() {
    final List<Map<String, dynamic>> calculatedList = [];

    for (var baselineSub in DummyData.attendanceList) {
      int attended = baselineSub.attended;
      int total = baselineSub.total;

      // Scan all logged dateActions
      _dateActions.forEach((dateKey, dayActions) {
        // Parse date key to see if it is a holiday or a default day off
        final date = DateTime.tryParse(dateKey);
        if (date != null) {
          final bool isHoliday = _holidays.any((h) {
            final DateTime hDate = h['date'];
            return hDate.year == date.year && hDate.month == date.month && hDate.day == date.day;
          });

          // Check default days off
          bool isDefaultDayOff = false;
          if (_defaultDaysOff == 'Sunday Only' && date.weekday == DateTime.sunday) {
            isDefaultDayOff = true;
          } else if (_defaultDaysOff == 'Saturday & Sunday' && 
              (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday)) {
            isDefaultDayOff = true;
          }

          // Holidays or default days off ignore classes
          if (!isHoliday && !isDefaultDayOff) {
            final lectures = DummyData.getLecturesForDay(date.weekday - 1);
            for (var lec in lectures) {
              if (lec.name == baselineSub.name) {
                final action = dayActions[lec.id] ?? 'clear';
                if (action == 'attended') {
                  attended++;
                  total++;
                } else if (action == 'missed') {
                  total++;
                }
                // 'off' and 'clear' do not change cumulative counts
              }
            }
          }
        }
      });

      final double percent = total == 0 ? 0.0 : (attended / total) * 100;
      
      // Determine the target based on the criteriaMode
      int target = _targetPercentage;
      if (_criteriaMode == 'subject_wise') {
        target = baselineSub.targetPercent;
      } else if (_criteriaMode == 'custom') {
        target = _subjectCustomTargets[baselineSub.name] ?? _targetPercentage;
      }

      final bool isAboveTarget = percent >= target;

      String statusMessage = '';
      if (isAboveTarget) {
        // Calculate safe-to-skip lectures: (attended / (total + skip)) * 100 >= target
        int skip = 0;
        if (target > 0) {
          skip = (attended * 100 / target).floor() - total;
          if (skip < 0) skip = 0;
        }
        statusMessage = 'Safe to skip: $skip class${skip != 1 ? 'es' : ''}';
      } else {
        // Calculate must-attend consecutive classes: ((attended + must) / (total + must)) * 100 >= target
        int must = 0;
        if (target < 100) {
          must = ((target * total - 100 * attended) / (100 - target)).ceil();
        } else {
          must = 99; // fallback if target is 100%
        }
        statusMessage = 'Must attend next $must class${must != 1 ? 'es' : ''} (Below Criteria)';
      }

      calculatedList.add({
        'id': baselineSub.id,
        'name': baselineSub.name,
        'percent': percent,
        'target': target,
        'attended': attended,
        'total': total,
        'statusMessage': statusMessage,
        'isAboveTarget': isAboveTarget,
      });
    }

    return calculatedList;
  }

  // Calculates overall attendance stats
  Map<String, dynamic> _getOverallStats(List<Map<String, dynamic>> calculatedSubjects) {
    int totalAttended = 0;
    int totalClasses = 0;
    final List<Map<String, dynamic>> belowTarget = [];

    for (var sub in calculatedSubjects) {
      totalAttended += sub['attended'] as int;
      totalClasses += sub['total'] as int;

      if (!(sub['isAboveTarget'] as bool)) {
        belowTarget.add({
          'name': sub['name'],
          'percent': sub['percent'],
        });
      }
    }

    final double overallPercent = totalClasses == 0 ? 0.0 : (totalAttended / totalClasses) * 100;

    return {
      'percent': overallPercent,
      'belowTarget': belowTarget,
    };
  }

  // ── Callbacks for state mutation ───────────────────────────────────────────
  void _onLectureActionChanged(DateTime date, LectureMock lecture, String action) {
    final dateKey = _formatDateKey(date);
    setState(() {
      _dateActions[dateKey] ??= {};
      _dateActions[dateKey]![lecture.id] = action;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 800),
        content: Text('"${lecture.name}" marked as "${action.toUpperCase()}"'),
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

  void _onWholeDayAction(String action) {
    final todayKey = _formatDateKey(DateTime.now());
    final todayLectures = DummyData.getLecturesForDay(DateTime.now().weekday - 1);

    if (todayLectures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No classes scheduled for today to mark!'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _dateActions[todayKey] ??= {};
      for (var lec in todayLectures) {
        _dateActions[todayKey]![lec.id] = action;
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All of today\'s lectures marked as "${action.toUpperCase()}"'),
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

  void _onHolidayAdded(String name, DateTime date) {
    setState(() {
      _holidays.add({'name': name, 'date': date});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Holiday "$name" added successfully'),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final calculatedSubjects = _getCalculatedSubjects();
    final overallStats = _getOverallStats(calculatedSubjects);

    // Prepare tab bodies
    Widget tabBody;
    switch (_currentTab) {
      case 0:
        tabBody = TodayTab(
          dayName: _getFullDayName(DateTime.now()),
          dateString: _getFormattedDate(DateTime.now()),
          overallPercentage: overallStats['percent'],
          targetPercentage: _targetPercentage,
          criteriaMode: _criteriaMode,
          belowTargetSubjects: List<Map<String, dynamic>>.from(overallStats['belowTarget']),
          todayLectures: DummyData.getLecturesForDay(DateTime.now().weekday - 1),
          lectureActions: _dateActions[_formatDateKey(DateTime.now())] ?? {},
          subjectsMetrics: {
            for (var sub in calculatedSubjects) sub['name']: sub
          },
          onLectureActionChanged: (lecture, action) => _onLectureActionChanged(DateTime.now(), lecture, action),
          onWholeDayAction: _onWholeDayAction,
        );
        break;
      case 1:
        tabBody = HistoryTab(
          semesterStartDate: _semesterStartDate,
          semesterEndDate: _semesterEndDate,
          selectedDate: _selectedDate,
          holidays: _holidays,
          dateActions: _dateActions,
          defaultDaysOff: _defaultDaysOff,
          subjectsMetrics: {
            for (var sub in calculatedSubjects) sub['name']: sub
          },
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          onLectureActionChanged: _onLectureActionChanged,
        );
        break;
      case 2:
        tabBody = SubjectsTab(
          overallPercentage: overallStats['percent'],
          targetPercentage: _targetPercentage,
          criteriaMode: _criteriaMode,
          belowTargetSubjects: List<Map<String, dynamic>>.from(overallStats['belowTarget']),
          subjectsList: calculatedSubjects,
          semesterStartDate: _semesterStartDate,
          semesterEndDate: _semesterEndDate,
          holidays: _holidays,
          dateActions: _dateActions,
          onLectureActionChanged: _onLectureActionChanged,
        );
        break;
      case 3:
        tabBody = AttendanceSettingsTab(
          criteriaMode: _criteriaMode,
          targetPercentage: _targetPercentage,
          semesterStartDate: _semesterStartDate,
          semesterEndDate: _semesterEndDate,
          holidays: _holidays,
          subjectCustomTargets: _subjectCustomTargets,
          defaultDaysOff: _defaultDaysOff,
          onCriteriaModeChanged: (val) => setState(() => _criteriaMode = val),
          onTargetPercentageChanged: (val) => setState(() => _targetPercentage = val),
          onSemesterStartDateChanged: (val) => setState(() => _semesterStartDate = val),
          onSemesterEndDateChanged: (val) => setState(() => _semesterEndDate = val),
          onHolidayAdded: _onHolidayAdded,
          onSubjectCustomTargetChanged: (subName, target) => setState(() => _subjectCustomTargets[subName] = target),
          onDefaultDaysOffChanged: (val) => setState(() => _defaultDaysOff = val),
        );
        break;
      default:
        tabBody = const Center(child: Text('Tab Not Found'));
    }

    return Scaffold(
      body: tabBody,
      bottomNavigationBar: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSubTabItem(0, 'Today', Icons.today_rounded),
              _buildSubTabItem(1, 'History', Icons.history_rounded),
              _buildSubTabItem(2, 'Subjects', Icons.menu_book_rounded),
              _buildSubTabItem(3, 'Settings', Icons.tune_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabItem(int tabIndex, String label, IconData icon) {
    final bool isSelected = _currentTab == tabIndex;
    final Color activeColor = AppTheme.primary;
    final Color inactiveColor = AppTheme.textMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTab = tabIndex;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
