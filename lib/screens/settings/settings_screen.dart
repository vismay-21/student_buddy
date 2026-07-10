import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/auth_service.dart';
import '../../data/dto/settings/app_settings_dto.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../data/dto/activity_log/activity_log_dto.dart';
import '../../data/repositories/activity_log_repository.dart';
import 'semester_selection_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = AppSettingsRepository();
  final _activityRepo = ActivityLogRepository();

  bool _isLoading = false;
  List<ActivityLogDto> _activityLogsList = [];

  @override
  void initState() {
    super.initState();
    _loadBackendSettings();
  }

  ThemeMode _themeModeFromString(String modeStr) {
    switch (modeStr.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _loadBackendSettings() async {
    setState(() => _isLoading = true);
    try {
      final s = await _settingsRepo.getSettings();
      AppState.instance.themeMode.value = _themeModeFromString(s.themeMode);
      AppState.instance.isFinanceEnabled.value = s.financeEnabled;
      AppState.instance.morningDigest.value = s.morningDigestEnabled;
      AppState.instance.nightDigest.value = s.nightDigestEnabled;
      AppState.instance.beforeLectureNotif.value = s.attendancePromptEnabled;
      AppState.instance.afterLectureNotif.value = s.attendancePromptEnabled;

      final logs = await _activityRepo.getActivityLogs(limit: 5);
      setState(() {
        _activityLogsList = logs;
      });
    } catch (e) {
      // Failed to load backend settings, fallback to local/defaults
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(AppSettingsUpdateRequest request) async {
    try {
      await _settingsRepo.updateSettings(request);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update setting: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            const SizedBox(height: 24),

            // Sign Out
            _buildSignOutCard(),
            const SizedBox(height: 32),
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
              final mode = val ? ThemeMode.dark : ThemeMode.light;
              AppState.instance.themeMode.value = mode;
              _updateSetting(AppSettingsUpdateRequest(themeMode: val ? 'dark' : 'light'));
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
                _updateSetting(AppSettingsUpdateRequest(financeEnabled: val));
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
              onChanged: (v) {
                AppState.instance.morningDigest.value = v;
                _updateSetting(AppSettingsUpdateRequest(morningDigestEnabled: v));
              },
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
              onChanged: (v) {
                AppState.instance.nightDigest.value = v;
                _updateSetting(AppSettingsUpdateRequest(nightDigestEnabled: v));
              },
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppState.instance.beforeLectureNotif,
            builder: (context, val, _) => SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text('Before Lecture Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: val,
              onChanged: (v) {
                AppState.instance.beforeLectureNotif.value = v;
                _updateSetting(AppSettingsUpdateRequest(attendancePromptEnabled: v));
              },
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppState.instance.afterLectureNotif,
            builder: (context, val, _) => SwitchListTile(
              activeColor: AppTheme.primary,
              title: const Text('After Lecture Log Prompts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: val,
              onChanged: (v) {
                AppState.instance.afterLectureNotif.value = v;
                _updateSetting(AppSettingsUpdateRequest(attendancePromptEnabled: v));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard() {
    if (_activityLogsList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Center(
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
          itemCount: _activityLogsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _activityLogsList[index];
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

  Widget _buildSignOutCard() {
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
                  child:
                      Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) {
            await AuthService.instance.signOut();
            if (mounted) {
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
}
