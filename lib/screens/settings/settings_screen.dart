import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import 'semester_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester Card Selection
            _buildSemesterCard(),
            const SizedBox(height: 20),

            // Theme toggle
            _buildSectionHeader('APPEARANCE'),
            const SizedBox(height: 10),
            _buildThemeToggleCard(),
            const SizedBox(height: 24),

            // Module Toggles
            _buildSectionHeader('APP MODULES'),
            const SizedBox(height: 10),
            _buildModuleTogglesCard(),
            const SizedBox(height: 24),

            // Digest / Notifications Toggles
            _buildSectionHeader('DIGESTS & NOTIFICATIONS'),
            const SizedBox(height: 10),
            _buildNotificationsCard(),
            const SizedBox(height: 24),

            // Activity Timeline
            _buildSectionHeader('ACTIVITY TIMELINE'),
            const SizedBox(height: 10),
            _buildActivityTimelineCard(),
            const SizedBox(height: 24),

            // About Card
            _buildSectionHeader('ABOUT'),
            const SizedBox(height: 10),
            _buildAboutCard(),
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

  Widget _buildThemeToggleCard() {
    return Card(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppState.instance.themeMode,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;
          return SwitchListTile(
            activeColor: AppTheme.primary,
            secondary: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? AppTheme.secondary : AppTheme.warning,
                size: 26,
              ),
            ),
            title: Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              isDark ? 'Switch to a brighter interface' : 'Switch to a darker interface',
              style: const TextStyle(fontSize: 11),
            ),
            value: isDark,
            onChanged: (val) {
              AppState.instance.themeMode.value =
                  val ? ThemeMode.dark : ThemeMode.light;
            },
          );
        },
      ),
    );
  }

  Widget _buildSemesterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Academic Semester',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: AppState.instance.activeSemester,
                    builder: (context, sem, _) => Text(
                      'Currently viewing: $sem',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SemesterSelectionScreen()),
                );
              },
              child: const Text('Change', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTogglesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ValueListenableBuilder<bool>(
          valueListenable: AppState.instance.isFinanceEnabled,
          builder: (context, enabled, _) {
            return SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text(
                'Enable Finance Module',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Track wallets, UPI expenses, stipend income, and transactions.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              value: enabled,
              onChanged: (val) {
                AppState.instance.isFinanceEnabled.value = val;
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AppState.instance.morningDigest,
            builder: (context, val, _) => SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text('Morning Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Daily schedules & notifications sent at 8:00 AM.', style: TextStyle(fontSize: 11)),
              value: val,
              onChanged: (v) => AppState.instance.morningDigest.value = v,
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppState.instance.nightDigest,
            builder: (context, val, _) => SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text('Night Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Daily summary of classes and transactions at 9:00 PM.', style: TextStyle(fontSize: 11)),
              value: val,
              onChanged: (v) => AppState.instance.nightDigest.value = v,
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppState.instance.beforeLectureNotif,
            builder: (context, val, _) => SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text('Before Lecture Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: val,
              onChanged: (v) => AppState.instance.beforeLectureNotif.value = v,
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppState.instance.afterLectureNotif,
            builder: (context, val, _) => SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text('After Lecture Log Prompts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: val,
              onChanged: (v) => AppState.instance.afterLectureNotif.value = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard() {
    final List<Map<String, String>> timeline = [
      {'time': 'Today, 10:30 AM', 'event': 'Marked Attendance: DBMS (Attended)'},
      {'time': 'Yesterday, 4:15 PM', 'event': 'Completed Task: CN Socket Programming Lab'},
      {'time': '22 Jun, 11:00 AM', 'event': 'Changed Criteria Mode to Overall (85%)'},
    ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timeline.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = timeline[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['event']!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['time']!,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Student Buddy',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'v1.0.0 (Phase 1 Refactored)',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Designed to reduce micro-decisions in a student\'s daily life. All your schedules, attendance targets, and task trackers in one unified place.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
