import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/auth_service.dart';
import '../../data/dto/settings/app_settings_dto.dart';
import '../../data/local/database_helper.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/providers/semester_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/sync_service.dart';
import 'semester_selection_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final activityLogsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
        data: (settings) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Semester Card Selection
                _buildSemesterCard(context, ref),
                const SizedBox(height: 20),

                // Theme toggle
                _buildSectionHeader('APPEARANCE'),
                const SizedBox(height: 10),
                _buildThemeToggleCard(context, ref, settings),
                const SizedBox(height: 24),

                // Module Toggles
                _buildSectionHeader('APP MODULES'),
                const SizedBox(height: 10),
                _buildModuleTogglesCard(context, ref, settings),
                const SizedBox(height: 24),

                // Digest / Notifications Toggles
                _buildSectionHeader('DIGESTS & NOTIFICATIONS'),
                const SizedBox(height: 10),
                _buildNotificationsCard(context, ref, settings),
                const SizedBox(height: 24),

                // Synchronization
                _buildSectionHeader('OFFLINE SYNCHRONIZATION'),
                const SizedBox(height: 10),
                _buildSyncCard(context, ref),
                const SizedBox(height: 24),

                // Activity Timeline
                _buildSectionHeader('ACTIVITY TIMELINE'),
                const SizedBox(height: 10),
                _buildActivityTimelineCard(activityLogsAsync),
                const SizedBox(height: 24),

                // About Card
                _buildSectionHeader('ABOUT'),
                const SizedBox(height: 10),
                _buildAboutCard(),
                const SizedBox(height: 24),

                // Sign Out
                _buildSignOutCard(context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
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

  Widget _buildThemeToggleCard(BuildContext context, WidgetRef ref, AppSettingsDto settings) {
    final isDark = settings.themeMode == 'dark';
    return Card(
      child: SwitchListTile(
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
        onChanged: (val) async {
          try {
            await ref.read(appSettingsProvider.notifier).updateSetting(
                  AppSettingsUpdateRequest(themeMode: val ? 'dark' : 'light'),
                );
          } catch (e) {
            AppSnackbar.error(context, 'Failed to update theme setting: $e');
          }
        },
      ),
    );
  }

  Widget _buildSemesterCard(BuildContext context, WidgetRef ref) {
    final activeSem = ref.watch(activeSemesterProvider);
    final String semesterText = activeSem != null ? 'Semester ${activeSem.semesterNumber}' : 'No Active Semester';

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
                  Text(
                    'Currently viewing: $semesterText',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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

  Widget _buildModuleTogglesCard(BuildContext context, WidgetRef ref, AppSettingsDto settings) {
    final enabled = settings.financeEnabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SwitchListTile(
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
          onChanged: (val) async {
            try {
              await ref.read(appSettingsProvider.notifier).updateSetting(
                    AppSettingsUpdateRequest(financeEnabled: val),
                  );
            } catch (e) {
              AppSnackbar.error(context, 'Failed to update module setting: $e');
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsCard(BuildContext context, WidgetRef ref, AppSettingsDto settings) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            activeColor: AppTheme.primary,
            title: const Text('Morning Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Daily schedules & notifications sent at 8:00 AM.', style: TextStyle(fontSize: 11)),
            value: settings.morningDigestEnabled,
            onChanged: (v) async {
              try {
                await ref.read(appSettingsProvider.notifier).updateSetting(
                      AppSettingsUpdateRequest(morningDigestEnabled: v),
                    );
              } catch (e) {
                AppSnackbar.error(context, 'Failed to update morning digest setting: $e');
              }
            },
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          SwitchListTile(
            activeColor: AppTheme.primary,
            title: const Text('Night Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Daily summary of classes and transactions at 9:00 PM.', style: TextStyle(fontSize: 11)),
            value: settings.nightDigestEnabled,
            onChanged: (v) async {
              try {
                await ref.read(appSettingsProvider.notifier).updateSetting(
                      AppSettingsUpdateRequest(nightDigestEnabled: v),
                    );
              } catch (e) {
                AppSnackbar.error(context, 'Failed to update night digest setting: $e');
              }
            },
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          SwitchListTile(
            activeColor: AppTheme.primary,
            title: const Text('Before Lecture Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: settings.attendancePromptEnabled,
            onChanged: (v) async {
              try {
                await ref.read(appSettingsProvider.notifier).updateSetting(
                      AppSettingsUpdateRequest(attendancePromptEnabled: v),
                    );
              } catch (e) {
                AppSnackbar.error(context, 'Failed to update reminder settings: $e');
              }
            },
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          SwitchListTile(
            activeColor: AppTheme.primary,
            title: const Text('After Lecture Log Prompts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: settings.attendancePromptEnabled,
            onChanged: (v) async {
              try {
                await ref.read(appSettingsProvider.notifier).updateSetting(
                      AppSettingsUpdateRequest(attendancePromptEnabled: v),
                    );
              } catch (e) {
                AppSnackbar.error(context, 'Failed to update log prompt settings: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard(AsyncValue<List<dynamic>> activityLogsAsync) {
    return activityLogsAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))),
      error: (err, _) => Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('Failed to load timeline: $err')))),
      data: (logs) {
        if (logs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No activity timeline events recorded.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = logs[index];
                final timeStr = DateFormat('d MMM yyyy, h:mm a').format(item.createdAt);
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
                            item.activityMessage,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
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
      },
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
                        'v1.0.0 — Sprint 13: Authentication',
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

  Widget _buildSignOutCard(BuildContext context) {
    return Card(
      color: AppTheme.danger.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.danger.withOpacity(0.25)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.danger,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          AuthService.instance.currentUser?.email ?? '',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await AuthService.instance.signOut();
            await DatabaseHelper.instance.closeDatabase();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (syncState.status) {
      case SyncStatus.idle:
        statusColor = Colors.grey;
        statusIcon = Icons.sync_disabled_rounded;
        statusText = 'Idle';
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync_rounded;
        statusText = 'Syncing...';
        break;
      case SyncStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done_rounded;
        statusText = 'Synced';
        break;
      case SyncStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off_rounded;
        statusText = 'Sync Error';
        break;
    }

    final lastSyncStr = syncState.lastSyncTime != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(syncState.lastSyncTime!).toLocal())
        : 'Never';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                if (syncState.status == SyncStatus.syncing)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                else
                  Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (syncState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            syncState.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Last Successful Sync',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  lastSyncStr,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Operations',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: syncState.pendingCount > 0 ? Colors.amber.shade900 : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${syncState.pendingCount}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
