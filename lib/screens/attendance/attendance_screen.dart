import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/semester_provider.dart';
import 'history_tab.dart';
import 'subjects_tab.dart';
import 'attendance_settings_tab.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int _currentTab = 0; // 0: History, 1: Subjects, 2: Settings
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSem = ref.watch(activeSemesterProvider);

    if (activeSem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: AppTheme.textMuted.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Semester Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select or create a semester from Settings first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          HistoryTab(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const SubjectsTab(),
          const AttendanceSettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSubTabItem(0, 'History', Icons.history_rounded),
              _buildSubTabItem(1, 'Subjects', Icons.menu_book_rounded),
              _buildSubTabItem(2, 'Settings', Icons.tune_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabItem(int tabIndex, String label, IconData icon) {
    final bool isSelected = _currentTab == tabIndex;
    final Color activeColor = AppTheme.primary;
    final Color inactiveColor = AppTheme.textMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTab = tabIndex;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
