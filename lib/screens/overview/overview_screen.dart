import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';
import '../assignments/assignments_screen.dart';
import '../notes/notes_screen.dart';
import '../review_queue/review_queue_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todayIndex = (DateTime.now().weekday - 1) % 7;
    final todayLectures = DummyData.getLecturesForDay(todayIndex);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greet Header Card
            _buildGreetingCard(context),
            const SizedBox(height: 20),

            // Notifications Bar
            _buildNotificationsBanner(context),
            const SizedBox(height: 20),

            // Grid / List of Dashboard items
            _buildSectionHeader('TODAY\'S LECTURES'),
            const SizedBox(height: 10),
            _buildLecturesSection(context, todayLectures),
            const SizedBox(height: 24),

            _buildSectionHeader('ACADEMIC STATUS'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAttendanceSummaryCard(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildAssignmentsSummaryCard(context)),
              ],
            ),
            const SizedBox(height: 12),
            _buildSafeSkipCard(context),
            const SizedBox(height: 24),

            // Optional Finance Card
            ValueListenableBuilder<bool>(
              valueListenable: AppState.instance.isFinanceEnabled,
              builder: (context, enabled, child) {
                if (!enabled) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('FINANCE SUMMARY'),
                    const SizedBox(height: 10),
                    _buildFinanceSummaryCard(context),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            _buildSectionHeader('UPCOMING EVENTS'),
            const SizedBox(height: 10),
            _buildAcademicEventsCard(context),
            const SizedBox(height: 24),

            _buildSectionHeader('QUICK SHORTCUTS'),
            const SizedBox(height: 10),
            _buildQuickShortcutsGrid(context),
            const SizedBox(height: 20),
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

  Widget _buildGreetingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your day is looking busy. Check your schedules and tasks below.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              ValueListenableBuilder<String>(
                valueListenable: AppState.instance.activeSemester,
                builder: (context, sem, _) => Text(
                  'Active Semester: $sem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
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
          Icon(Icons.notification_important_rounded, color: AppTheme.warning, size: 20),
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

  Widget _buildLecturesSection(BuildContext context, List<LectureMock> lectures) {
    if (lectures.isEmpty) {
      return Card(
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

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lectures.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B), height: 1),
        itemBuilder: (context, index) {
          final lecture = lectures[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Color(lecture.colorValue),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              lecture.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${lecture.teacher} • Room ${lecture.room}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: Text(
              '${lecture.startTime} - ${lecture.endTime}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fact_check_rounded, color: AppTheme.accent, size: 24),
            const SizedBox(height: 12),
            const Text(
              'Attendance',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '87.0%',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'avg',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Goal 80%',
                style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsSummaryCard(BuildContext context) {
    final pendingCount = DummyData.assignments.where((a) => !a.isCompleted).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.assignment_rounded, color: AppTheme.secondary, size: 24),
            const SizedBox(height: 12),
            const Text(
              'Assignments',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'pending',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Next: Tomorrow',
                style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeSkipCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safe Skip Status',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You can safely skip 1 Computer Networks lecture today without falling below your 85% goal.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
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
      ),
    );
  }

  Widget _buildAcademicEventsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_rounded, color: AppTheme.warning, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Internal Exam in 3 Days',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '25 Jun',
                  style: TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Academic Calendar mentions: Semester Internal Exams start on Thursday, 25 June. Attendance calculations will ignore scheduled lecture slots during this exam period.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShortcutsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildShortcutItem(
          context: context,
          icon: Icons.assignment_rounded,
          color: AppTheme.secondary,
          label: 'Assignments',
          destination: const AssignmentsScreen(),
        ),
        _buildShortcutItem(
          context: context,
          icon: Icons.folder_shared_rounded,
          color: AppTheme.primary,
          label: 'Notes Repository',
          destination: const NotesScreen(),
        ),
        _buildShortcutItem(
          context: context,
          icon: Icons.rate_review_rounded,
          color: AppTheme.danger,
          label: 'Review Queue',
          destination: const ReviewQueueScreen(),
          badgeCount: DummyData.reviewQueue.length,
        ),
      ],
    );
  }

  Widget _buildShortcutItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required Widget destination,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
