import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/utils/color_helper.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/repositories/lecture_instance_repository.dart';
import 'widgets/lecture_card.dart';

class SubjectHistoryScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final int criteriaPercentage;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  const SubjectHistoryScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.criteriaPercentage,
    required this.onLectureActionChanged,
  });

  @override
  State<SubjectHistoryScreen> createState() => _SubjectHistoryScreenState();
}

class _SubjectHistoryScreenState extends State<SubjectHistoryScreen> {
  final _instanceRepo = LectureInstanceRepository();
  List<LectureInstanceDto> _instances = [];
  AttendanceStatsDto? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;

    setState(() => _isLoading = true);
    try {
      final list = await _instanceRepo.getInstances(
        subjectId: widget.subjectId,
        semesterId: activeSem.semesterId,
      );
      final stats = await _instanceRepo.getSubjectStats(widget.subjectId);

      // Sort reverse-chronologically by date
      list.sort((a, b) => b.lectureDate.compareTo(a.lectureDate));

      setState(() {
        _instances = list;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _onActionTapped(LectureInstanceDto inst, String action) async {
    String newAttendanceStatus = 'unmarked';
    String newLectureStatus = 'scheduled';
    if (action == 'attended') {
      newAttendanceStatus = 'present';
    } else if (action == 'missed') {
      newAttendanceStatus = 'absent';
    } else if (action == 'off') {
      newLectureStatus = 'holiday';
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
      final dateVal = inst.lectureDate;
      widget.onLectureActionChanged(dateVal, _mapToMock(inst), action);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update attendance: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color ringColor = AppTheme.primary;

    final double attendancePercent = _stats?.attendancePercentage ?? 0.0;
    final bool isAboveTarget = (_stats?.attendancePercentage ?? 0.0) >= widget.criteriaPercentage;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                  'Classes Logged: ${_stats?.presentLectures ?? 0}/${_stats?.totalLectures ?? 0}',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _stats?.statusMessage ?? 'No logs',
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
                        '${_instances.length} Lectures',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Scrollable list of history instances
                Expanded(
                  child: _instances.isEmpty
                      ? const Center(
                          child: Text(
                            'No classes scheduled for this subject',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _instances.length,
                          itemBuilder: (context, index) {
                            final inst = _instances[index];
                            final DateTime date = inst.lectureDate;
                            final LectureMock lecture = _mapToMock(inst);
                            final String action = inst.attendanceStatus == 'present'
                                ? 'attended'
                                : (inst.attendanceStatus == 'absent'
                                    ? 'missed'
                                    : (inst.lectureStatus == 'holiday' ? 'off' : 'clear'));
                            final bool isHoliday = inst.lectureStatus == 'holiday';

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
                                    attendancePercent: attendancePercent,
                                    targetPercent: widget.criteriaPercentage,
                                    attended: _stats?.presentLectures ?? 0,
                                    total: _stats?.totalLectures ?? 0,
                                    statusMessage: _stats?.statusMessage ?? '',
                                    isAboveTarget: isAboveTarget,
                                    onActionChanged: (newAction) => _onActionTapped(inst, newAction),
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
}
