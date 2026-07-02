import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';
import 'history_tab.dart';
import 'subjects_tab.dart';
import 'attendance_settings_tab.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _currentTab = 0; // 0: History, 1: Subjects, 2: Settings
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Register listeners on AppState variables to trigger rebuilds on change
    AppState.instance.dateActions.addListener(_updateState);
    AppState.instance.criteriaMode.addListener(_updateState);
    AppState.instance.targetPercentage.addListener(_updateState);
    AppState.instance.subjectCustomTargets.addListener(_updateState);
    AppState.instance.defaultDaysOff.addListener(_updateState);
    AppState.instance.semesterStartDate.addListener(_updateState);
    AppState.instance.semesterEndDate.addListener(_updateState);
    AppState.instance.holidays.addListener(_updateState);
  }

  @override
  void dispose() {
    // Unregister listeners to avoid memory leaks
    AppState.instance.dateActions.removeListener(_updateState);
    AppState.instance.criteriaMode.removeListener(_updateState);
    AppState.instance.targetPercentage.removeListener(_updateState);
    AppState.instance.subjectCustomTargets.removeListener(_updateState);
    AppState.instance.defaultDaysOff.removeListener(_updateState);
    AppState.instance.semesterStartDate.removeListener(_updateState);
    AppState.instance.semesterEndDate.removeListener(_updateState);
    AppState.instance.holidays.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  // ── Callbacks for state mutation ───────────────────────────────────────────
  void _onLectureActionChanged(DateTime date, LectureMock lecture, String action) {
    AppState.instance.setLectureAction(date, lecture.id, action);

    IconData icon = Icons.info_outline_rounded;
    Color color = AppTheme.textMuted;
    if (action == 'attended') {
      icon = Icons.check_circle_outline_rounded;
      color = AppTheme.accent;
    } else if (action == 'missed') {
      icon = Icons.highlight_off_rounded;
      color = AppTheme.danger;
    } else if (action == 'off') {
      icon = Icons.pause_circle_outline_rounded;
      color = AppTheme.warning;
    }

    AppSnackbar.show(
      context,
      message: '"${lecture.name}" marked as "${action.toUpperCase()}"',
      icon: icon,
      color: color,
    );
  }

  void _onHolidayAdded(String name, DateTime date) {
    AppState.instance.addHoliday(name, date);
    AppSnackbar.success(context, 'Holiday "$name" added successfully');
  }

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final calculatedSubjects = AppState.instance.getCalculatedSubjects();
    final overallStats = AppState.instance.getOverallStats(calculatedSubjects);

    // Prepare tab bodies
    Widget tabBody;
    switch (_currentTab) {
      case 0:
        tabBody = HistoryTab(
          semesterStartDate: AppState.instance.semesterStartDate.value,
          semesterEndDate: AppState.instance.semesterEndDate.value,
          selectedDate: _selectedDate,
          holidays: AppState.instance.holidays.value,
          dateActions: AppState.instance.dateActions.value,
          defaultDaysOff: AppState.instance.defaultDaysOff.value,
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
      case 1:
        tabBody = SubjectsTab(
          overallPercentage: overallStats['percent'],
          targetPercentage: AppState.instance.targetPercentage.value,
          criteriaMode: AppState.instance.criteriaMode.value,
          belowTargetSubjects: List<Map<String, dynamic>>.from(overallStats['belowTarget']),
          subjectsList: calculatedSubjects,
          semesterStartDate: AppState.instance.semesterStartDate.value,
          semesterEndDate: AppState.instance.semesterEndDate.value,
          holidays: AppState.instance.holidays.value,
          dateActions: AppState.instance.dateActions.value,
          onLectureActionChanged: _onLectureActionChanged,
        );
        break;
      case 2:
        tabBody = AttendanceSettingsTab(
          criteriaMode: AppState.instance.criteriaMode.value,
          targetPercentage: AppState.instance.targetPercentage.value,
          semesterStartDate: AppState.instance.semesterStartDate.value,
          semesterEndDate: AppState.instance.semesterEndDate.value,
          holidays: AppState.instance.holidays.value,
          subjectCustomTargets: AppState.instance.subjectCustomTargets.value,
          defaultDaysOff: AppState.instance.defaultDaysOff.value,
          onCriteriaModeChanged: (val) => AppState.instance.criteriaMode.value = val,
          onTargetPercentageChanged: (val) => AppState.instance.targetPercentage.value = val,
          onSemesterStartDateChanged: (val) => AppState.instance.semesterStartDate.value = val,
          onSemesterEndDateChanged: (val) => AppState.instance.semesterEndDate.value = val,
          onHolidayAdded: _onHolidayAdded,
          onSubjectCustomTargetChanged: (subName, target) {
            final current = Map<String, int>.from(AppState.instance.subjectCustomTargets.value);
            current[subName] = target;
            AppState.instance.subjectCustomTargets.value = current;
          },
          onDefaultDaysOffChanged: (val) => AppState.instance.defaultDaysOff.value = val,
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
              _buildSubTabItem(0, 'History', Icons.history_rounded),
              _buildSubTabItem(1, 'Subjects', Icons.menu_book_rounded),
              _buildSubTabItem(2, 'Settings', Icons.tune_rounded),
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
