import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/expandable_section.dart';
import '../review_queue/review_queue_screen.dart';
import '../attendance/widgets/lecture_card.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late VoidCallback _stateListener;

  @override
  void initState() {
    super.initState();
    _stateListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    AppState.instance.dateActions.addListener(_stateListener);
    AppState.instance.criteriaMode.addListener(_stateListener);
    AppState.instance.targetPercentage.addListener(_stateListener);
    AppState.instance.defaultDaysOff.addListener(_stateListener);
    AppState.instance.holidays.addListener(_stateListener);
    AppState.instance.activeSemester.addListener(_stateListener);
    AppState.instance.isFinanceEnabled.addListener(_stateListener);
  }

  @override
  void dispose() {
    AppState.instance.dateActions.removeListener(_stateListener);
    AppState.instance.criteriaMode.removeListener(_stateListener);
    AppState.instance.targetPercentage.removeListener(_stateListener);
    AppState.instance.defaultDaysOff.removeListener(_stateListener);
    AppState.instance.holidays.removeListener(_stateListener);
    AppState.instance.activeSemester.removeListener(_stateListener);
    AppState.instance.isFinanceEnabled.removeListener(_stateListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayIndex = (today.weekday - 1) % 7;
    final todayLectures = DummyData.getLecturesForDay(todayIndex);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewQueueCard(context),

            // Notifications Bar
            _buildNotificationsBanner(context),
            const SizedBox(height: 16),

            // Collapsible Classes Section
            ExpandableSection(
              title: 'TODAY\'S CLASSES',
              subtitle: ' (${todayLectures.length})',
              showFrame: true,
              children: [
                if (todayLectures.isNotEmpty) ...[
                  _buildSectionHeader('MARK WHOLE DAY'),
                  const SizedBox(height: 6),
                  _buildWholeDayActionPanel(context, todayLectures),
                  const SizedBox(height: 10),
                ],
                _buildLecturesSection(context, todayLectures),
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


  Widget _buildNotificationsBanner(BuildContext context) {
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
          const Expanded(
            child: Text(
              'DBMS starts in 15 mins (Room B-204)',
              style: TextStyle(
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

  Widget _buildWholeDayActionPanel(BuildContext context, List<LectureMock> lectures) {
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
              Expanded(child: _buildWholeDayButton('clear', 'Clear', AppTheme.textMuted, Icons.remove_circle_outline, lectures)),
              const SizedBox(width: 6),
              Expanded(child: _buildWholeDayButton('off', 'Day Off', AppTheme.warning, Icons.pause_circle_outline, lectures)),
              const SizedBox(width: 6),
              Expanded(child: _buildWholeDayButton('missed', 'Missed', AppTheme.danger, Icons.highlight_off, lectures)),
              const SizedBox(width: 6),
              Expanded(child: _buildWholeDayButton('attended', 'Attended', AppTheme.accent, Icons.check_circle_rounded, lectures)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWholeDayButton(String action, String label, Color color, IconData icon, List<LectureMock> lectures) {
    return InkWell(
      onTap: () {
        AppState.instance.setWholeDayAction(DateTime.now(), lectures, action);
        AppSnackbar.show(
          context,
          message: 'Whole day marked as "${action.toUpperCase()}"',
          icon: icon,
          color: color,
        );
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
              const SizedBox(width: 3),
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

  Widget _buildLecturesSection(BuildContext context, List<LectureMock> lectures) {
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

    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);
    final calculatedSubjects = AppState.instance.getCalculatedSubjects();

    return Column(
      children: lectures.map((lecture) {
        final currentAction = (AppState.instance.dateActions.value[dateKey] ?? {})[lecture.id] ?? 'clear';
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
            onActionChanged: (action) {
              AppState.instance.setLectureAction(today, lecture.id, action);
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
    final pendingReviews = DummyData.reviewQueue.length;
    if (pendingReviews == 0) return const SizedBox.shrink();

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
                '$pendingReviews item${pendingReviews > 1 ? "s" : ""} need your review',
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
                setState(() {});
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
