import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/utils/color_helper.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/attendance_ring_label.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/repositories/lecture_instance_repository.dart';

class SubjectHistoryScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final int criteriaPercentage;
  final String facultyName;
  final String roomName;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  const SubjectHistoryScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.criteriaPercentage,
    required this.facultyName,
    required this.roomName,
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
    if (inst.lectureStatus == 'holiday') return;
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

  Widget _buildActionButton(
    BuildContext context,
    String currentAction,
    String action,
    IconData icon,
    Color color,
    Function(String)? onActionChanged,
  ) {
    final bool isSelected = currentAction == action;
    final bool isClickable = onActionChanged != null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: isClickable
          ? () {
              onActionChanged(action);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isClickable ? color.withOpacity(0.12) : color.withOpacity(0.06)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (isClickable ? color.withOpacity(0.5) : color.withOpacity(0.25)) 
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)).withOpacity(isClickable ? 1.0 : 0.4),
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: isClickable ? 1.0 : (isSelected ? 0.75 : 0.25),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : AppTheme.textMuted,
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Text(
                  action.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                            width: 52,
                            height: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(52, 52),
                                  painter: _RingPainter(
                                    progress: attendancePercent / 100,
                                    ringColor: isAboveTarget ? AppTheme.accent : AppTheme.danger,
                                    backgroundColor: (isAboveTarget ? AppTheme.accent : AppTheme.danger).withOpacity(0.15),
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: AttendanceRingLabel(
                                      current: attendancePercent,
                                      target: widget.criteriaPercentage.toDouble(),
                                      fontSize: 13,
                                    ),
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
                                  'Attended: ${_stats?.presentLectures ?? 0}/${(_stats?.presentLectures ?? 0) + (_stats?.absentLectures ?? 0)} • Total Lectures: ${_stats?.totalLectures ?? 0}',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 12,
                                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.facultyName,
                                      style: TextStyle(
                                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.meeting_room_outlined,
                                      size: 12,
                                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.roomName,
                                      style: TextStyle(
                                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left side: Timing
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 15,
                                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${lecture.startTime} - ${lecture.endTime}',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Right side: 4 action buttons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildActionButton(
                                              context,
                                              action,
                                              'clear',
                                              Icons.remove_circle_outline,
                                              isDark ? AppTheme.textMuted : Colors.black54,
                                              !isHoliday ? (newAct) => _onActionTapped(inst, newAct) : null,
                                            ),
                                            const SizedBox(width: 4),
                                            _buildActionButton(
                                              context,
                                              action,
                                              'off',
                                              Icons.pause_circle_outline,
                                              AppTheme.warning,
                                              !isHoliday ? (newAct) => _onActionTapped(inst, newAct) : null,
                                            ),
                                            const SizedBox(width: 4),
                                            _buildActionButton(
                                              context,
                                              action,
                                              'missed',
                                              Icons.highlight_off,
                                              AppTheme.danger,
                                              !isHoliday ? (newAct) => _onActionTapped(inst, newAct) : null,
                                            ),
                                            const SizedBox(width: 4),
                                            _buildActionButton(
                                              context,
                                              action,
                                              'attended',
                                              Icons.check_circle_rounded,
                                              AppTheme.accent,
                                              !isHoliday ? (newAct) => _onActionTapped(inst, newAct) : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = backgroundColor);
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
