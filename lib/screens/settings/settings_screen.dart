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
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountBalanceController = TextEditingController();

  void _addNewCategory() {
    final String text = _categoryController.text.trim();
    if (text.isNotEmpty) {
      AppState.instance.addCategory(text);
      _categoryController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.accent, content: Text('Mock category "$text" added!')),
      );
    }
  }

  void _addNewAccount() {
    final String name = _accountNameController.text.trim();
    final double? bal = double.tryParse(_accountBalanceController.text.trim());
    if (name.isNotEmpty && bal != null) {
      AppState.instance.addAccount(name, bal);
      _accountNameController.clear();
      _accountBalanceController.clear();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.accent, content: Text('Mock account "$name" added!')),
      );
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Account (Mock)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _accountNameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Initial Balance (₹)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: _addNewAccount,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            // Finance Settings (Conditionally shown if Finance module is enabled!)
            ValueListenableBuilder<bool>(
              valueListenable: AppState.instance.isFinanceEnabled,
              builder: (context, financeEnabled, _) {
                if (!financeEnabled) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('FINANCE PREFERENCES'),
                    const SizedBox(height: 10),
                    _buildFinancePrefsCard(),
                    const SizedBox(height: 24),

                    _buildSectionHeader('MANAGE CATEGORIES'),
                    const SizedBox(height: 10),
                    _buildManageCategoriesCard(),
                    const SizedBox(height: 24),

                    _buildSectionHeader('MANAGE ACCOUNTS'),
                    const SizedBox(height: 10),
                    _buildManageAccountsCard(),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
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

  Widget _buildFinancePrefsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Default Finance Account',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            ValueListenableBuilder<String>(
              valueListenable: AppState.instance.defaultAccount,
              builder: (context, defAcc, _) {
                return ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: AppState.instance.mockAccountsList,
                  builder: (context, accounts, _) {
                    final names = accounts.map((a) => a['name'] as String).toList();
                    final selected = names.contains(defAcc) ? defAcc : names.first;

                    return DropdownButton<String>(
                      dropdownColor: AppTheme.surface,
                      value: selected,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      items: names
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          AppState.instance.defaultAccount.value = val;
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageCategoriesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: 'New Category',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addNewCategory,
                  icon: const Icon(Icons.add_box_rounded, color: AppTheme.primary, size: 36),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<String>>(
              valueListenable: AppState.instance.categories,
              builder: (context, cats, _) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) {
                  return Chip(
                    backgroundColor: AppTheme.surfaceLight,
                    side: const BorderSide(color: Color(0xFF1E293B)),
                    label: Text(
                      cat,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageAccountsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Accounts list',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddAccountDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Account', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: AppState.instance.mockAccountsList,
              builder: (context, accs, _) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accs.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B), height: 1),
                itemBuilder: (context, index) {
                  final acc = accs[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(acc['name'], style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                    trailing: Text(
                      '₹${acc['balance'].toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
