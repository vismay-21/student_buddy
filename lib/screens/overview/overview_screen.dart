import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/utils/color_helper.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/expandable_section.dart';
import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/repositories/lecture_instance_repository.dart';
import '../../data/repositories/review_queue_repository.dart';
import '../review_queue/review_queue_screen.dart';
import '../settings/semester_selection_screen.dart';
import '../attendance/widgets/lecture_card.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final _lectureRepo = LectureInstanceRepository();
  final _reviewRepo = ReviewQueueRepository();

  List<LectureInstanceDto> _todayInstances = [];
  int _pendingReviewsCount = 0;
  bool _isLoading = false;
  late VoidCallback _stateListener;

  @override
  void initState() {
    super.initState();
    _loadData();
    _stateListener = () {
      if (mounted) {
        _loadData();
      }
    };
    AppState.instance.activeSemesterDto.addListener(_stateListener);
    AppState.instance.isFinanceEnabled.addListener(_stateListener);
  }

  @override
  void dispose() {
    AppState.instance.activeSemesterDto.removeListener(_stateListener);
    AppState.instance.isFinanceEnabled.removeListener(_stateListener);
    super.dispose();
  }

  Future<void> _loadData() async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      setState(() {
        _todayInstances = [];
        _pendingReviewsCount = 0;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final instances = await _lectureRepo.getTodayLectures(
        date: todayStr,
        semesterId: activeSem.semesterId,
      );
      final reviews = await _reviewRepo.getReviewQueue(status: 'pending');

      setState(() {
        _todayInstances = instances;
        _pendingReviewsCount = reviews.length;
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

  String? _getNextClassNotification() {
    if (_todayInstances.isEmpty) return null;
    final now = DateTime.now();
    final nowTimeStr = DateFormat('HH:mm').format(now);

    final futureClasses = _todayInstances.where((inst) {
      if (inst.lectureStatus != 'scheduled') return false;
      final startTime = inst.lectureTemplate.startTime;
      return startTime.compareTo(nowTimeStr) > 0;
    }).toList();

    if (futureClasses.isEmpty) return null;

    futureClasses.sort((a, b) => a.lectureTemplate.startTime.compareTo(b.lectureTemplate.startTime));
    final nextClass = futureClasses.first;
    final template = nextClass.lectureTemplate;
    return '${template.subject.subjectName} starts at ${template.startTime.substring(0, 5)}${template.room != null ? " (Room ${template.room})" : ""}';
  }

  Widget _buildNoSemesterState(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Semester',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'To start tracking attendance, timetable schedule, tasks, and notes, please select or create an academic semester.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Configure Semester'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SemesterSelectionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNoSemesterState(context),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nextClassNotif = _getNextClassNotification();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewQueueCard(context),

            // Dynamic Notifications Bar
            if (nextClassNotif != null) ...[
              _buildNotificationsBanner(context, nextClassNotif),
              const SizedBox(height: 16),
            ],

            // Collapsible Classes Section
            ExpandableSection(
              title: 'TODAY\'S CLASSES',
              subtitle: ' (${_todayInstances.length})',
              showFrame: true,
              children: [
                if (_todayInstances.isNotEmpty) ...[
                  _buildSectionHeader('MARK WHOLE DAY'),
                  const SizedBox(height: 6),
                  _buildWholeDayActionPanel(context, _todayInstances),
                  const SizedBox(height: 10),
                ],
                _buildLecturesSection(context, _todayInstances),
              ],
            ),
            const SizedBox(height: 16),

            // Optional Finance Card
            if (AppState.instance.isFinanceEnabled.value) ...[
              ExpandableSection(
                title: 'FINANCE SUMMARY',
                showFrame: true,
                children: [
                  _buildFinanceSummaryCard(context),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildNotificationsBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholeDayActionPanel(BuildContext context, List<LectureInstanceDto> lectures) {
    if (lectures.isEmpty) return const SizedBox.shrink();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
              Expanded(child: _buildWholeDayButton('missed', 'Missed', AppTheme.danger, Icons.highlight_off)),
              const SizedBox(width: 6),
              Expanded(child: _buildWholeDayButton('attended', 'Attended', AppTheme.accent, Icons.check_circle_rounded)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWholeDayButton(String action, String label, Color color, IconData icon) {
    return InkWell(
      onTap: () async {
        String? newAttendanceStatus;
        if (action == 'attended') {
          newAttendanceStatus = 'present';
        } else if (action == 'missed') {
          newAttendanceStatus = 'absent';
        } else {
          AppSnackbar.warning(context, 'Only "attended" or "missed" can be bulk applied to the whole day.');
          return;
        }

        final activeSem = AppState.instance.activeSemesterDto.value;
        if (activeSem == null) return;

        try {
          await _lectureRepo.markWholeDay(LectureInstanceBulkUpdateRequest(
            lectureDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            attendanceStatus: newAttendanceStatus,
            semesterId: activeSem.semesterId,
          ));
          _loadData();
          if (mounted) {
            AppSnackbar.show(
              context,
              message: 'Whole day marked as "${action.toUpperCase()}"',
              icon: icon,
              color: color,
            );
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.error(context, 'Failed to bulk update: $e');
          }
        }
      },
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
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
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

  Widget _buildLecturesSection(BuildContext context, List<LectureInstanceDto> lectures) {
    if (lectures.isEmpty) {
      return Card(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No classes scheduled for today 🎉',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final calculatedSubjects = AppState.instance.getCalculatedSubjects();

    return Column(
      children: lectures.map((inst) {
        final lecture = _mapToMock(inst);
        final currentAction = inst.attendanceStatus == 'present'
            ? 'attended'
            : (inst.attendanceStatus == 'absent'
                ? 'missed'
                : (inst.lectureStatus == 'holiday' ? 'off' : 'clear'));

        final metrics = calculatedSubjects.firstWhere(
          (sub) => sub['name'] == lecture.name,
          orElse: () => {
            'percent': 0.0,
            'target': 80,
            'attended': 0,
            'total': 0,
            'statusMessage': 'No details',
            'isAboveTarget': false,
          },
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
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
            onActionChanged: (action) async {
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
                await _lectureRepo.updateAttendance(
                  inst.lectureInstanceId,
                  LectureInstanceUpdateRequest(
                    attendanceStatus: newAttendanceStatus,
                    lectureStatus: newLectureStatus,
                  ),
                );
                _loadData();
              } catch (e) {
                if (mounted) {
                  AppSnackbar.error(context, 'Failed to update attendance: $e');
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinanceSummaryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Balance',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      Text(
                        '₹17,000.00',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Today\'s Expenses',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '₹120.00',
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQueueCard(BuildContext context) {
    if (_pendingReviewsCount == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.danger.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$_pendingReviewsCount item${_pendingReviewsCount > 1 ? "s" : ""} need your review',
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReviewQueueScreen()),
                );
                _loadData();
              },
              child: const Text(
                'Review Now',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
