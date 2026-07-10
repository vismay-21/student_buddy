import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/subject/subject_dto.dart';
import '../../data/dto/attendance/attendance_settings_dto.dart';
import '../../data/dto/holiday/holiday_dto.dart';
import '../../data/dto/semester/semester_dto.dart';
import '../../data/repositories/subject_repository.dart';
import '../../data/repositories/lecture_instance_repository.dart';
import '../../data/repositories/attendance_settings_repository.dart';
import '../../data/repositories/holiday_repository.dart';
import '../../data/repositories/semester_repository.dart';
import 'history_tab.dart';
import 'subjects_tab.dart';
import 'attendance_settings_tab.dart';
import '../../data/repositories/lecture_template_repository.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _currentTab = 0; // 0: History, 1: Subjects, 2: Settings
  DateTime _selectedDate = DateTime.now();

  final _subjectRepo = SubjectRepository();
  final _instanceRepo = LectureInstanceRepository();
  final _settingsRepo = AttendanceSettingsRepository();
  final _holidayRepo = HolidayRepository();
  final _semesterRepo = SemesterRepository();

  bool _isLoading = false;
  double _overallPercentage = 0.0;
  List<Map<String, dynamic>> _subjectsList = [];
  List<Map<String, dynamic>> _belowTargetSubjects = [];
  List<Map<String, dynamic>> _holidaysList = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    AppState.instance.activeSemesterDto.addListener(_loadStats);
  }

  @override
  void dispose() {
    AppState.instance.activeSemesterDto.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      setState(() {
        _overallPercentage = 0.0;
        _subjectsList = [];
        _belowTargetSubjects = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Load settings
      final settings = await _settingsRepo.getSettings(activeSem.semesterId);
      final mappedMode = settings.criteriaMode == 'subject' ? 'subject_wise' : settings.criteriaMode;
      AppState.instance.criteriaMode.value = mappedMode;
      AppState.instance.targetPercentage.value = settings.overallAttendanceGoal;

      // 2. Load overall stats
      final semStats = await _instanceRepo.getSemesterStats(activeSem.semesterId);

      // 3. Load all subjects and stats
      final subjects = await _subjectRepo.getSubjects(activeSem.semesterId);
      
      final List<Map<String, dynamic>> subList = [];
      final List<Map<String, dynamic>> belowTarget = [];

      final _templateRepo = LectureTemplateRepository();
      for (final sub in subjects) {
        final stats = await _instanceRepo.getSubjectStats(sub.subjectId);
        final templates = await _templateRepo.getTemplates(sub.subjectId);
        final String room = (templates.isNotEmpty && templates.first.room != null) ? templates.first.room! : 'Room TBD';

        int target = settings.overallAttendanceGoal;
        if (mappedMode == 'custom') {
          target = sub.attendanceGoal;
        }

        final bool isAboveTarget = stats.attendancePercentage >= target;

        subList.add({
          'id': sub.subjectId,
          'name': sub.subjectName,
          'percent': stats.attendancePercentage,
          'target': target,
          'attended': stats.presentLectures,
          'absent': stats.absentLectures,
          'total': stats.totalLectures,
          'statusMessage': stats.statusMessage,
          'isAboveTarget': isAboveTarget,
          'color': sub.themeColor,
          'faculty': sub.facultyName ?? 'Faculty TBD',
          'room': room,
        });

        if (!isAboveTarget) {
          belowTarget.add({
            'name': sub.subjectName,
            'percent': stats.attendancePercentage,
          });
        }
      }

      // 4. Load holidays
      final holidays = await _holidayRepo.getHolidays(semesterId: activeSem.semesterId);
      final List<Map<String, dynamic>> mappedHolidays = holidays.map((h) => {
        'id': h.holidayId,
        'name': h.holidayName,
        'date': h.holidayDate,
      }).toList();

      final int totalTaken = semStats.presentLectures + semStats.absentLectures;
      final double overallPercentageCalculated = totalTaken == 0
          ? 0.0
          : (semStats.presentLectures / totalTaken) * 100;

      setState(() {
        _overallPercentage = overallPercentageCalculated;
        _subjectsList = subList;
        _belowTargetSubjects = belowTarget;
        _holidaysList = mappedHolidays;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCriteriaMode(String val) async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;
    final backendMode = val == 'subject_wise' ? 'subject' : val;
    try {
      await _settingsRepo.updateSettings(
        activeSem.semesterId,
        AttendanceSettingsUpdateRequest(criteriaMode: backendMode),
      );
      AppState.instance.criteriaMode.value = val;

      // When switching TO custom mode, seed every subject's goal to the
      // current overall targetPercentage so the dialog starts with sensible
      // baseline values (the user can then fine-tune per subject).
      if (val == 'custom') {
        final seedTarget = AppState.instance.targetPercentage.value;
        for (final s in _subjectsList) {
          await _updateSubjectCustomTarget(s['name'] as String, seedTarget);
        }
      }

      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update criteria mode: $e');
      }
    }
  }

  Future<void> _updateTargetPercentage(int val) async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;
    try {
      await _settingsRepo.updateSettings(
        activeSem.semesterId,
        AttendanceSettingsUpdateRequest(overallAttendanceGoal: val),
      );
      AppState.instance.targetPercentage.value = val;
      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update target: $e');
      }
    }
  }

  Future<void> _updateSubjectCustomTarget(String subjectName, int target) async {
    final match = _subjectsList.firstWhere(
      (s) => s['name'] == subjectName,
      orElse: () => null as dynamic,
    );
    if (match == null) return;
    final subjectId = match['id'] as String;

    try {
      await _subjectRepo.updateSubject(
        subjectId,
        SubjectUpdateRequest(attendanceGoal: target),
      );
      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update target: $e');
      }
    }
  }

  void _onLectureActionChanged(DateTime date, dynamic lecture, String action) {
    _loadStats();
  }

  Future<void> _addHoliday(String name, DateTime date) async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;
    try {
      await _holidayRepo.createHoliday(HolidayCreateRequest(
        semesterId: activeSem.semesterId,
        holidayDate: date,
        holidayName: name,
      ));
      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to add holiday: $e');
      }
    }
  }

  Future<void> _deleteHoliday(String holidayId) async {
    try {
      await _holidayRepo.deleteHoliday(holidayId);
      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to delete holiday: $e');
      }
    }
  }

  Future<void> _updateSemesterStartDate(DateTime date) async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;
    try {
      final updated = await _semesterRepo.updateSemester(
        activeSem.semesterId,
        SemesterUpdateRequest(startDate: date),
      );
      AppState.instance.setActiveSemester(updated);
      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update start date: $e');
      }
    }
  }

  Future<void> _updateSemesterEndDate(DateTime date) async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;
    try {
      final updated = await _semesterRepo.updateSemester(
        activeSem.semesterId,
        SemesterUpdateRequest(endDate: date),
      );
      AppState.instance.setActiveSemester(updated);
      _loadStats();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update end date: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text(
                  'No Active Semester Selected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select or create a semester from Settings first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Prepare tab bodies
    Widget tabBody;
    switch (_currentTab) {
      case 0:
        tabBody = HistoryTab(
          semesterStartDate: activeSem.startDate,
          semesterEndDate: activeSem.endDate,
          selectedDate: _selectedDate,
          holidays: _holidaysList,
          dateActions: const {},
          subjectsMetrics: const {},
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          onLectureActionChanged: _onLectureActionChanged,
          overallPercentage: _overallPercentage,
          belowTargetSubjects: _belowTargetSubjects,
          subjectsList: _subjectsList,
        );
        break;
      case 1:
        tabBody = SubjectsTab(
          overallPercentage: _overallPercentage,
          targetPercentage: AppState.instance.targetPercentage.value,
          criteriaMode: AppState.instance.criteriaMode.value,
          belowTargetSubjects: _belowTargetSubjects,
          subjectsList: _subjectsList,
          semesterStartDate: activeSem.startDate,
          semesterEndDate: activeSem.endDate,
          holidays: _holidaysList,
          dateActions: const {},
          onLectureActionChanged: _onLectureActionChanged,
        );
        break;
      case 2:
        tabBody = AttendanceSettingsTab(
          criteriaMode: AppState.instance.criteriaMode.value,
          targetPercentage: AppState.instance.targetPercentage.value,
          semesterStartDate: activeSem.startDate,
          semesterEndDate: activeSem.endDate,
          holidays: _holidaysList,
          subjectCustomTargets: {
            for (var s in _subjectsList) s['name']: s['target'] as int
          },
          onCriteriaModeChanged: _updateCriteriaMode,
          onTargetPercentageChanged: _updateTargetPercentage,
          onSemesterStartDateChanged: _updateSemesterStartDate,
          onSemesterEndDateChanged: _updateSemesterEndDate,
          onHolidayAdded: _addHoliday,
          onHolidayDeleted: _deleteHoliday,
          onSubjectCustomTargetChanged: _updateSubjectCustomTarget,
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
