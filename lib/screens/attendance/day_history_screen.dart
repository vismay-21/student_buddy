import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dummy_data.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/dto/lecture/lecture_instance_dto.dart';
import '../../../data/dto/holiday/holiday_dto.dart';
import '../../../data/repositories/lecture_instance_repository.dart';
import '../../../data/repositories/attendance_settings_repository.dart';
import '../../../data/repositories/holiday_repository.dart';
import 'widgets/lecture_card.dart';

class DayHistoryScreen extends StatefulWidget {
  final DateTime date;
  final VoidCallback? onAttendanceChanged;

  const DayHistoryScreen({
    super.key,
    required this.date,
    this.onAttendanceChanged,
  });

  @override
  State<DayHistoryScreen> createState() => _DayHistoryScreenState();
}

class _DayHistoryScreenState extends State<DayHistoryScreen> {
  final _instanceRepo = LectureInstanceRepository();
  final _settingsRepo = AttendanceSettingsRepository();
  final _holidayRepo = HolidayRepository();

  bool _isLoading = true;
  List<LectureInstanceDto> _instances = [];
  Map<String, Map<String, dynamic>> _subjectsMetrics = {};
  HolidayDto? _holidayToday;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 1. Get today's instances
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      final list = await _instanceRepo.getTodayLectures(date: dateStr, semesterId: activeSem.semesterId);

      // 2. Fetch holidays to check if this is a university holiday
      final holidays = await _holidayRepo.getHolidays(semesterId: activeSem.semesterId);
      HolidayDto? holidayToday;
      for (final h in holidays) {
        if (h.holidayDate.year == widget.date.year &&
            h.holidayDate.month == widget.date.month &&
            h.holidayDate.day == widget.date.day) {
          holidayToday = h;
          break;
        }
      }

      // 3. Get settings for mode
      final settings = await _settingsRepo.getSettings(activeSem.semesterId);
      final mappedMode = settings.criteriaMode == 'subject' ? 'subject_wise' : settings.criteriaMode;

      // 4. For each subject in today's lectures, get stats
      final Map<String, Map<String, dynamic>> metrics = {};
      for (final inst in list) {
        final sub = inst.lectureTemplate.subject;
        final stats = await _instanceRepo.getSubjectStats(sub.subjectId);
        
        int target = settings.overallAttendanceGoal;
        if (mappedMode == 'custom') {
          target = sub.attendanceGoal;
        }

        final bool isAboveTarget = stats.attendancePercentage >= target;

        metrics[sub.subjectName] = {
          'percent': stats.attendancePercentage,
          'target': target,
          'attended': stats.presentLectures,
          'total': stats.totalLectures,
          'statusMessage': stats.statusMessage,
          'isAboveTarget': isAboveTarget,
        };
      }

      setState(() {
        _instances = list;
        _subjectsMetrics = metrics;
        _holidayToday = holidayToday;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onActionTapped(LectureInstanceDto inst, String action) async {
    if (_holidayToday != null) return;
    String? newAttendanceStatus;
    String? newLectureStatus;

    if (action == 'attended') {
      newAttendanceStatus = 'present';
      newLectureStatus = 'scheduled';
    } else if (action == 'missed') {
      newAttendanceStatus = 'absent';
      newLectureStatus = 'scheduled';
    } else if (action == 'off') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'holiday';
    } else if (action == 'clear') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'scheduled';
    }

    try {
      await _instanceRepo.updateAttendance(
        inst.lectureInstanceId,
        LectureInstanceUpdateRequest(
          attendanceStatus: newAttendanceStatus,
          lectureStatus: newLectureStatus,
        ),
      );
      
      await _loadData();

      if (widget.onAttendanceChanged != null) {
        widget.onAttendanceChanged!();
      }

      if (mounted) {
        AppSnackbar.success(context, 'Attendance updated.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update attendance: $e');
      }
    }
  }

  void _onWholeDayAction(String action) async {
    if (_holidayToday != null) return;
    String? newAttendanceStatus;
    String? newLectureStatus;

    if (action == 'attended') {
      newAttendanceStatus = 'present';
      newLectureStatus = 'scheduled';
    } else if (action == 'missed') {
      newAttendanceStatus = 'absent';
      newLectureStatus = 'scheduled';
    } else if (action == 'clear') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'scheduled';
    } else if (action == 'off') {
      newAttendanceStatus = 'unmarked';
      newLectureStatus = 'holiday';
    } else {
      AppSnackbar.warning(context, 'Invalid action type.');
      return;
    }

    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      AppSnackbar.warning(context, 'Please select or create a semester first');
      return;
    }

    try {
      await _instanceRepo.markWholeDay(LectureInstanceBulkUpdateRequest(
        lectureDate: DateFormat('yyyy-MM-dd').format(widget.date),
        attendanceStatus: newAttendanceStatus,
        lectureStatus: newLectureStatus,
        semesterId: activeSem.semesterId,
      ));
      
      await _loadData();

      if (widget.onAttendanceChanged != null) {
        widget.onAttendanceChanged!();
      }

      if (mounted) {
        AppSnackbar.success(context, 'Whole day status updated.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to bulk update: $e');
      }
    }
  }

  LectureMock _mapToMock(LectureInstanceDto inst) {
    final template = inst.lectureTemplate;
    final subject = template.subject;
    final colorVal = parseHexColor(subject.themeColor).value;
    return LectureMock(
      id: inst.lectureInstanceId,
      name: subject.subjectName,
      startTime: template.startTime.substring(0, 5),
      endTime: template.endTime.substring(0, 5),
      room: template.room ?? 'Room TBD',
      teacher: subject.facultyName ?? 'Faculty TBD',
      colorValue: colorVal,
    );
  }

  String _getAction(LectureInstanceDto inst) {
    if (inst.lectureStatus == 'holiday') {
      return 'off';
    }
    if (inst.attendanceStatus == 'present') {
      return 'attended';
    }
    if (inst.attendanceStatus == 'absent') {
      return 'missed';
    }
    return 'clear';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final String titleStr = DateFormat('EEEE, d MMMM yyyy').format(widget.date);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Day Logs Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                          '${_instances.length} scheduled lectures for this day',
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

          if (_holidayToday != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1D4ED8).withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'University Holiday',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _holidayToday!.holidayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Whole day action panel
          if (_instances.isNotEmpty)
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
            child: _instances.isEmpty
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
                    itemCount: _instances.length,
                    itemBuilder: (context, index) {
                      final inst = _instances[index];
                      final lecture = _mapToMock(inst);
                      final metrics = _subjectsMetrics[lecture.name] ??
                          {
                            'percent': 0.0,
                            'target': 80,
                            'attended': 0,
                            'total': 0,
                            'statusMessage': 'No details',
                            'isAboveTarget': false,
                          };

                      final currentAction = _getAction(inst);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: LectureCard(
                          lecture: lecture,
                          showAttendance: true,
                          currentAction: currentAction,
                          attendancePercent: metrics['percent'],
                          targetPercent: metrics['target'],
                          attended: metrics['attended'],
                          total: metrics['total'],
                          statusMessage: metrics['statusMessage'],
                          isAboveTarget: metrics['isAboveTarget'],
                          onActionChanged: _holidayToday == null
                              ? (action) => _onActionTapped(inst, action)
                              : null,
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
    final bool isClickable = _holidayToday == null;
    return InkWell(
      onTap: isClickable ? () => _onWholeDayAction(action) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isClickable ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isClickable ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.12),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: isClickable ? 1.0 : 0.35,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isClickable ? color : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isClickable ? color : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
