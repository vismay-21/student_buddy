import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_state.dart';
import 'attendance/attendance_screen.dart';
import 'finance/finance_screen.dart';
import 'notes/notes_screen.dart';
import 'overview/overview_screen.dart';
import 'settings/settings_screen.dart';
import 'timetable/timetable_screen.dart';
import 'todo/todo_screen.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 1; // Default index is 1 (Overview)

  // Pages structure based on whether Finance is enabled
  List<Widget> _getPages(bool isFinanceEnabled) {
    if (isFinanceEnabled) {
      return const [
        TodoScreen(),
        OverviewScreen(),
        TimetableScreen(),
        AttendanceScreen(),
        FinanceScreen(),
      ];
    } else {
      return const [
        TodoScreen(),
        OverviewScreen(),
        TimetableScreen(),
        AttendanceScreen(),
      ];
    }
  }

  // Get active page title
  String _getPageTitle(int index, bool isFinanceEnabled) {
    if (isFinanceEnabled) {
      switch (index) {
        case 0:
          return 'To Do';
        case 1:
          return 'Student Buddy';
        case 2:
          return 'Timetable';
        case 3:
          return 'Attendance';
        case 4:
          return 'Finance';
        default:
          return 'Student Buddy';
      }
    } else {
      switch (index) {
        case 0:
          return 'To Do';
        case 1:
          return 'Student Buddy';
        case 2:
          return 'Timetable';
        case 3:
          return 'Attendance';
        default:
          return 'Student Buddy';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.instance.isFinanceEnabled,
      builder: (context, isFinanceEnabled, child) {
        final pages = _getPages(isFinanceEnabled);
        
        // Safety check if index becomes out of bounds after disabling finance
        if (_selectedIndex >= pages.length) {
          _selectedIndex = pages.length - 1;
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_getPageTitle(_selectedIndex, isFinanceEnabled)),
            actions: [
              _buildTopRightAction(
                context,
                icon: Icons.folder_shared_rounded,
                label: 'Notes',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotesScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildTopRightAction(
                context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: _getBottomNavBarItems(isFinanceEnabled),
          ),
        );
      },
    );
  }

  Widget _buildTopRightAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavBarItems(bool isFinanceEnabled) {
    if (isFinanceEnabled) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_turned_in_rounded),
          label: 'To Do',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Timetable',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_rounded),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Finance',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_turned_in_rounded),
          label: 'To Do',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Timetable',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_rounded),
          label: 'Attendance',
        ),
      ];
    }
  }
}
