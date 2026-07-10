import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/dummy_data.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/repositories/lecture_instance_repository.dart';
import '../../data/repositories/subject_repository.dart';
import '../../data/repositories/lecture_template_repository.dart';
import 'widgets/attendance_calendar_legend.dart';
import 'widgets/attendance_analytics_card.dart';
import 'widgets/attendance_overview_card.dart';
import 'day_history_screen.dart';

class HistoryTab extends StatefulWidget {
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> holidays;
  final Map<String, Map<String, String>> dateActions; // dateStr -> lectureId -> action
  final Map<String, Map<String, dynamic>> subjectsMetrics;
  final Function(DateTime date) onDateSelected;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  final double overallPercentage;
  final List<Map<String, dynamic>> belowTargetSubjects;
  final List<Map<String, dynamic>> subjectsList;

  const HistoryTab({
    super.key,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.selectedDate,
    required this.holidays,
    required this.dateActions,
    required this.subjectsMetrics,
    required this.onDateSelected,
    required this.onLectureActionChanged,
    required this.overallPercentage,
    required this.belowTargetSubjects,
    required this.subjectsList,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late PageController _pageController;
  late DateTime _visibleMonth;
  int _totalMonths = 1;

  final _instanceRepo = LectureInstanceRepository();
  final _subjectRepo = SubjectRepository();
  final _templateRepo = LectureTemplateRepository();
  List<LectureInstanceDto> _allInstances = [];
  Set<int> _workingWeekdays = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _totalMonths = _calculateTotalMonths();
    _visibleMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    final int initialPage = _getPageIndexForDate(widget.selectedDate);
    _pageController = PageController(initialPage: initialPage);
    _loadInstances();
  }

  @override
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _totalMonths = _calculateTotalMonths();
    _loadInstances();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInstances() async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) return;
    try {
      final list = await _instanceRepo.getInstances(semesterId: activeSem.semesterId);
      final subjects = await _subjectRepo.getSubjects(activeSem.semesterId);
      final Set<int> workingDays = {};
      for (final sub in subjects) {
        final temps = await _templateRepo.getTemplates(sub.subjectId);
        for (final t in temps) {
          workingDays.add(t.dayOfWeek);
        }
      }
      if (mounted) {
        setState(() {
          _allInstances = list;
          _workingWeekdays = workingDays;
        });
      }
    } catch (_) {}
  }

  int _calculateTotalMonths() {
    return ((widget.semesterEndDate.year - widget.semesterStartDate.year) * 12) +
        widget.semesterEndDate.month - widget.semesterStartDate.month + 1;
  }

  int _getPageIndexForDate(DateTime date) {
    final int offset = ((date.year - widget.semesterStartDate.year) * 12) +
        date.month - widget.semesterStartDate.month;
    return offset.clamp(0, _totalMonths - 1);
  }

  DateTime _getMonthForIndex(int index) {
    int newMonthValue = widget.semesterStartDate.month + index;
    int yearOffset = (newMonthValue - 1) ~/ 12;
    int month = ((newMonthValue - 1) % 12) + 1;
    return DateTime(widget.semesterStartDate.year + yearOffset, month, 1);
  }

  bool _isHoliday(DateTime date) {
    return widget.holidays.any((h) {
      final dynamic hDateRaw = h['date'];
      if (hDateRaw == null) return false;
      final DateTime hDate = hDateRaw is String ? DateTime.parse(hDateRaw) : hDateRaw as DateTime;
      return hDate.year == date.year &&
          hDate.month == date.month &&
          hDate.day == date.day;
    });
  }

  // ── Date status logic ──────────────────────────────────────────────────────
  String _getDateStatus(DateTime date) {
    // 1. Holiday Check (strictly University Holiday)
    if (_isHoliday(date)) {
      return 'holiday';
    }

    final dayInstances = _allInstances.where((inst) {
      return inst.lectureDate.year == date.year &&
          inst.lectureDate.month == date.month &&
          inst.lectureDate.day == date.day;
    }).toList();

    // 2. Day Off Check
    final Set<int> workingWeekdays = _workingWeekdays.isNotEmpty
        ? _workingWeekdays
        : const {1, 2, 3, 4, 5}; // Monday to Friday fallback

    final bool isDefaultDayOff = !workingWeekdays.contains(date.weekday);

    if (dayInstances.isEmpty) {
      return isDefaultDayOff ? 'day_off' : 'clear';
    }

    // Check if all instances are marked as day off (holiday status)
    final bool allOff = dayInstances.every((inst) => inst.lectureStatus == 'holiday');
    if (allOff) {
      return 'day_off';
    }

    final bool hasHoliday = dayInstances.any((inst) => inst.lectureStatus == 'holiday');
    final scheduled = dayInstances.where((inst) => inst.lectureStatus == 'scheduled').toList();

    if (hasHoliday && scheduled.isNotEmpty) {
      return 'mixed';
    }

    if (scheduled.isEmpty) {
      return isDefaultDayOff ? 'day_off' : 'clear';
    }

    final int attendedCount = scheduled.where((inst) => inst.attendanceStatus == 'present').length;
    final int missedCount = scheduled.where((inst) => inst.attendanceStatus == 'absent').length;
    final int unmarkedCount = scheduled.where((inst) => inst.attendanceStatus == 'unmarked').length;

    if (unmarkedCount == scheduled.length) {
      return 'clear';
    }
    if (attendedCount == scheduled.length) {
      return 'attended';
    }
    if (missedCount == scheduled.length) {
      return 'missed';
    }
    return 'mixed';
  }

  // ── Monthly statistics calculations ────────────────────────────────────────
  Map<String, dynamic> _calculateMonthlySummaries(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int totalDays = 0;
    
    int attendedDays = 0;
    int missedDays = 0;
    int offDays = 0;
    int mixedDays = 0;

    int totalLectures = 0;
    int attendedLectures = 0;
    int missedLectures = 0;
    int offLectures = 0;

    final DateTime startLimit = DateTime(widget.semesterStartDate.year, widget.semesterStartDate.month, widget.semesterStartDate.day);
    final DateTime endLimit = DateTime(widget.semesterEndDate.year, widget.semesterEndDate.month, widget.semesterEndDate.day);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final bool inRange = (date.isAfter(startLimit) || date.isAtSameMomentAs(startLimit)) &&
          (date.isBefore(endLimit) || date.isAtSameMomentAs(endLimit));
      
      if (!inRange) continue;

      totalDays++;
      final status = _getDateStatus(date);
      
      switch (status) {
        case 'attended': attendedDays++; break;
        case 'missed': missedDays++; break;
        case 'day_off':
        case 'holiday': offDays++; break;
        case 'mixed': mixedDays++; break;
        default: break;
      }

      final dayInstances = _allInstances.where((inst) {
        return inst.lectureDate.year == date.year &&
            inst.lectureDate.month == date.month &&
            inst.lectureDate.day == date.day;
      }).toList();

      for (var inst in dayInstances) {
        if (inst.lectureStatus == 'holiday') {
          offLectures++;
        } else if (inst.lectureStatus == 'scheduled') {
          totalLectures++;
          if (inst.attendanceStatus == 'present') {
            attendedLectures++;
          } else if (inst.attendanceStatus == 'absent') {
            missedLectures++;
          }
        }
      }
    }

    final double attendancePercentage = (attendedLectures + missedLectures) == 0
        ? 0.0
        : (attendedLectures / (attendedLectures + missedLectures)) * 100;

    return {
      'totalDays': totalDays,
      'attendedDays': attendedDays,
      'missedDays': missedDays,
      'offDays': offDays,
      'mixedDays': mixedDays,
      'totalLectures': totalLectures,
      'attendedLectures': attendedLectures,
      'missedLectures': missedLectures,
      'offLectures': offLectures,
      'attendancePercentage': attendancePercentage,
    };
  }

  Map<String, dynamic> _calculateSemesterSummaries() {
    int totalDays = 0;
    
    int attendedDays = 0;
    int missedDays = 0;
    int offDays = 0;
    int mixedDays = 0;

    int totalLectures = 0;
    int attendedLectures = 0;
    int missedLectures = 0;
    int offLectures = 0;

    DateTime current = DateTime(widget.semesterStartDate.year, widget.semesterStartDate.month, widget.semesterStartDate.day);
    final DateTime end = DateTime(widget.semesterEndDate.year, widget.semesterEndDate.month, widget.semesterEndDate.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      totalDays++;
      final status = _getDateStatus(current);
      
      switch (status) {
        case 'attended': attendedDays++; break;
        case 'missed': missedDays++; break;
        case 'day_off':
        case 'holiday': offDays++; break;
        case 'mixed': mixedDays++; break;
        default: break;
      }

      final dayInstances = _allInstances.where((inst) {
        return inst.lectureDate.year == current.year &&
            inst.lectureDate.month == current.month &&
            inst.lectureDate.day == current.day;
      }).toList();

      for (var inst in dayInstances) {
        if (inst.lectureStatus == 'holiday') {
          offLectures++;
        } else if (inst.lectureStatus == 'scheduled') {
          totalLectures++;
          if (inst.attendanceStatus == 'present') {
            attendedLectures++;
          } else if (inst.attendanceStatus == 'absent') {
            missedLectures++;
          }
        }
      }

      current = current.add(const Duration(days: 1));
    }

    final double attendancePercentage = (attendedLectures + missedLectures) == 0
        ? 0.0
        : (attendedLectures / (attendedLectures + missedLectures)) * 100;

    return {
      'totalDays': totalDays,
      'attendedDays': attendedDays,
      'missedDays': missedDays,
      'offDays': offDays,
      'mixedDays': mixedDays,
      'totalLectures': totalLectures,
      'attendedLectures': attendedLectures,
      'missedLectures': missedLectures,
      'offLectures': offLectures,
      'attendancePercentage': attendancePercentage,
    };
  }


  void _showSemesterStatsDialog(BuildContext context) {
    final stats = _calculateSemesterSummaries();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtextColor = isDark ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Semester Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Day Summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAY SUMMARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPopupStatRow('Total Days', '${stats['totalDays']}', textColor, subtextColor),
                          _buildPopupStatRow('Attended', '${stats['attendedDays']}', textColor, subtextColor),
                          _buildPopupStatRow('Missed', '${stats['missedDays']}', textColor, subtextColor),
                          _buildPopupStatRow('Off/Holiday', '${stats['offDays']}', textColor, subtextColor),
                          _buildPopupStatRow('Mixed', '${stats['mixedDays']}', textColor, subtextColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Divider
                    Container(
                      width: 1,
                      height: 160,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 16),
                    // Right Column: Lecture Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LECTURE STATS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPopupStatRow('Total Lectures', '${stats['totalLectures']}', textColor, subtextColor),
                          _buildPopupStatRow('Attended', '${stats['attendedLectures']}', textColor, subtextColor),
                          _buildPopupStatRow('Missed', '${stats['missedLectures']}', textColor, subtextColor),
                          _buildPopupStatRow('Off/Holiday', '${stats['offLectures']}', textColor, subtextColor),
                          _buildPopupStatRow('Attendance %', '${(stats['attendancePercentage'] as double).toStringAsFixed(2)}%', textColor, subtextColor, isBoldVal: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupStatRow(String label, String value, Color textColor, Color subtextColor, {bool isBoldVal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBoldVal ? FontWeight.w800 : FontWeight.w600,
              color: isBoldVal ? AppTheme.primary : textColor,
            ),
          ),
        ],
      ),
    );
  }

  double _getCalendarCardHeight() {
    final int daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final int firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;
    final int startOffset = firstWeekday < 0 ? 0 : firstWeekday;
    final int totalGridCells = daysInMonth + startOffset;
    final int rowCount = (totalGridCells / 7.0).ceil();
    return 136.0 + (rowCount * 48.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    
    final summaries = _calculateMonthlySummaries(_visibleMonth);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 0. Overall Attendance Status card (Clickable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AttendanceOverviewCard(
                overallPercentage: widget.overallPercentage,
                targetPercentage: AppState.instance.targetPercentage.value,
                isSubjectWise: AppState.instance.criteriaMode.value == 'subject_wise',
                belowTargetSubjects: widget.belowTargetSubjects,
                onTap: () => _showSemesterStatsDialog(context),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Calendar Month View Holder
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: _getCalendarCardHeight(),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_visibleMonth),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final int currentPage = _pageController.page?.round() ?? 0;
                                if (currentPage > 0) {
                                  _pageController.animateToPage(
                                    currentPage - 1,
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final int currentPage = _pageController.page?.round() ?? 0;
                                if (currentPage < _totalMonths - 1) {
                                  _pageController.animateToPage(
                                    currentPage + 1,
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Calendar View Body
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _totalMonths,
                      onPageChanged: (index) {
                        setState(() {
                          _visibleMonth = _getMonthForIndex(index);
                        });
                      },
                      itemBuilder: (context, index) {
                        final monthDate = _getMonthForIndex(index);
                        return _buildCalendarGrid(monthDate);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  const AttendanceCalendarLegend(transparentBackground: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Consolidated Analytics Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AttendanceAnalyticsCard(
                totalDays: summaries['totalDays'],
                attendedDays: summaries['attendedDays'],
                missedDays: summaries['missedDays'],
                offDays: summaries['offDays'],
                mixedDays: summaries['mixedDays'],
                totalLectures: summaries['totalLectures'],
                attendedLectures: summaries['attendedLectures'],
                missedLectures: summaries['missedLectures'],
                offLectures: summaries['offLectures'],
                attendancePercentage: summaries['attendancePercentage'],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildCalendarGrid(DateTime monthDate) {
    final int daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    // Align first weekday of month to Monday = 0
    final int firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday - 1;
    final int totalGridCells = daysInMonth + firstWeekday;

    return Column(
      children: [
        // Weekday short initials
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayInit('M'),
              _WeekdayInit('T'),
              _WeekdayInit('W'),
              _WeekdayInit('T'),
              _WeekdayInit('F'),
              _WeekdayInit('S'),
              _WeekdayInit('S'),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 6),

        // Monthly Grid View
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: 44,
            ),
            itemCount: totalGridCells,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox();
              }

              final int dayNumber = index - firstWeekday + 1;
              final DateTime date = DateTime(monthDate.year, monthDate.month, dayNumber);
              final bool isOutsideSemester = date.isBefore(widget.semesterStartDate) || date.isAfter(widget.semesterEndDate);
              
              final bool isSelected = date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;

              Color dotColor = Colors.transparent;
              if (!isOutsideSemester) {
                final String status = _getDateStatus(date);
                switch (status) {
                  case 'attended': dotColor = AppTheme.accent; break;
                  case 'missed': dotColor = AppTheme.danger; break;
                  case 'holiday': dotColor = const Color(0xFF0033FF); break;
                  case 'day_off': dotColor = AppTheme.warning; break;
                  case 'mixed': dotColor = AppTheme.secondary; break;
                  case 'clear':
                    dotColor = AppTheme.textMuted;
                    break;
                }
              }

              final bool isDark = Theme.of(context).brightness == Brightness.dark;

              return GestureDetector(
                onTap: () {
                  if (!isOutsideSemester) {
                    final dummyLecture = LectureMock(
                      id: '',
                      name: '',
                      startTime: '',
                      endTime: '',
                      teacher: '',
                      room: '',
                      colorValue: 0,
                    );
                    widget.onDateSelected(date);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DayHistoryScreen(
                          date: date,
                          onAttendanceChanged: () {
                            widget.onLectureActionChanged(date, dummyLecture, 'changed');
                          },
                        ),
                      ),
                    ).then((_) {
                      widget.onLectureActionChanged(date, dummyLecture, 'changed');
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primary.withOpacity(0.18) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isOutsideSemester
                              ? AppTheme.textMuted.withOpacity(0.4)
                              : isSelected
                                  ? AppTheme.primary
                                  : isDark
                                      ? AppTheme.textPrimary
                                      : AppTheme.lightTextPrimary,
                        ),
                      ),
                      if (!isOutsideSemester) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekdayInit extends StatelessWidget {
  final String char;
  const _WeekdayInit(this.char);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
