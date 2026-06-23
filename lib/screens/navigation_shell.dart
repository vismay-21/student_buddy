import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_state.dart';
import '../core/widgets/app_drawer.dart';
import 'attendance/attendance_screen.dart';
import 'finance/finance_screen.dart';
import 'overview/overview_screen.dart';
import 'settings/settings_screen.dart';
import 'timetable/timetable_screen.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Overview tab by default (usually index 0)

  // Pages structure based on whether Finance is enabled
  List<Widget> _getPages(bool isFinanceEnabled) {
    if (isFinanceEnabled) {
      return const [
        OverviewScreen(),
        TimetableScreen(),
        AttendanceScreen(),
        FinanceScreen(),
        SettingsScreen(),
      ];
    } else {
      return const [
        OverviewScreen(),
        TimetableScreen(),
        AttendanceScreen(),
        SettingsScreen(),
      ];
    }
  }

  // Get active page title
  String _getPageTitle(int index, bool isFinanceEnabled) {
    if (isFinanceEnabled) {
      switch (index) {
        case 0:
          return 'Student Buddy';
        case 1:
          return 'Timetable';
        case 2:
          return 'Attendance';
        case 3:
          return 'Finance';
        case 4:
          return 'Settings';
        default:
          return 'Student Buddy';
      }
    } else {
      switch (index) {
        case 0:
          return 'Student Buddy';
        case 1:
          return 'Timetable';
        case 2:
          return 'Attendance';
        case 3:
          return 'Settings';
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
          key: _scaffoldKey,
          endDrawer: const AppDrawer(),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_getPageTitle(_selectedIndex, isFinanceEnabled)),
            actions: [
              // Active Semester Badge
              ValueListenableBuilder<String>(
                valueListenable: AppState.instance.activeSemester,
                builder: (context, semester, _) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Text(
                      semester,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              // Menu hamburger icon for endDrawer
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open sidebar menu',
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: pages[_selectedIndex],
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

  List<BottomNavigationBarItem> _getBottomNavBarItems(bool isFinanceEnabled) {
    if (isFinanceEnabled) {
      return const [
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
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ];
    } else {
      return const [
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
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ];
    }
  }
}
