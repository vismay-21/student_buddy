import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_template.dart';
import 'dummy_data.dart';

class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // ── Attendance State ───────────────────────────────────────────────────────
  final ValueNotifier<String> criteriaMode = ValueNotifier<String>('subject_wise'); // 'overall', 'subject_wise', 'custom'
  final ValueNotifier<int> targetPercentage = ValueNotifier<int>(80);
  final ValueNotifier<Map<String, int>> subjectCustomTargets = ValueNotifier<Map<String, int>>({});
  final ValueNotifier<String> defaultDaysOff = ValueNotifier<String>('Sunday Only'); // 'Sunday Only', 'Saturday & Sunday', 'None'
  final ValueNotifier<DateTime> semesterStartDate = ValueNotifier<DateTime>(DateTime(2026, 6, 1));
  final ValueNotifier<DateTime> semesterEndDate = ValueNotifier<DateTime>(DateTime(2026, 11, 30));
  
  final ValueNotifier<List<Map<String, dynamic>>> holidays = ValueNotifier<List<Map<String, dynamic>>>([
    {'name': 'Independence Day', 'date': DateTime(2026, 8, 15)},
    {'name': 'Gandhi Jayanti', 'date': DateTime(2026, 10, 2)},
  ]);

  // dateKey ("yyyy-MM-dd") -> Map of lectureId -> action ('attended', 'missed', 'off', 'clear')
  final ValueNotifier<Map<String, Map<String, String>>> dateActions = ValueNotifier<Map<String, Map<String, String>>>({});

  // ── Theme ──────────────────────────────────────────────────────────────────
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // ── Semester ───────────────────────────────────────────────────────────────
  final ValueNotifier<String> activeSemester = ValueNotifier<String>('Semester 4');

  // ── Feature Toggles ────────────────────────────────────────────────────────
  final ValueNotifier<bool> isFinanceEnabled = ValueNotifier<bool>(false);

  // ── Initialization & Persistence ──────────────────────────────────────────
  static const String _keyFinanceEnabled = 'is_finance_enabled';
  late final SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Load persisted value, defaulting to false
    isFinanceEnabled.value = _prefs.getBool(_keyFinanceEnabled) ?? false;
    
    // Listen to changes to save them automatically
    isFinanceEnabled.addListener(() {
      _prefs.setBool(_keyFinanceEnabled, isFinanceEnabled.value);
    });
    
    _isInitialized = true;
  }

  // ── Notification Toggles ───────────────────────────────────────────────────
  final ValueNotifier<bool> morningDigest    = ValueNotifier<bool>(true);
  final ValueNotifier<bool> nightDigest      = ValueNotifier<bool>(true);
  final ValueNotifier<bool> beforeLectureNotif = ValueNotifier<bool>(true);
  final ValueNotifier<bool> afterLectureNotif  = ValueNotifier<bool>(true);

  // ── Finance ────────────────────────────────────────────────────────────────
  final ValueNotifier<String> defaultAccount = ValueNotifier<String>('UPI (GPay/PhonePe)');

  final ValueNotifier<List<String>> categories = ValueNotifier<List<String>>([
    'Food', 'Academics', 'Transport', 'Entertainment', 'Stipend', 'Others',
  ]);

  final ValueNotifier<List<Map<String, dynamic>>> mockAccountsList =
      ValueNotifier<List<Map<String, dynamic>>>([
    {'name': 'UPI (GPay/PhonePe)', 'balance': 3450.00},
    {'name': 'Cash Wallet',        'balance':  450.00},
    {'name': 'Savings Account',    'balance': 12300.00},
    {'name': 'Pocket Money',       'balance':  800.00},
  ]);

  // ── Timetable Subject Templates ────────────────────────────────────────────
  /// Stores one template per unique subject name. Used to pre-fill Room,
  /// Teacher, and Color when adding the same subject on another day.
  final ValueNotifier<List<SubjectTemplate>> subjectTemplates =
      ValueNotifier<List<SubjectTemplate>>([]);

  // ── Helpers ────────────────────────────────────────────────────────────────
  void addCategory(String category) {
    if (category.trim().isNotEmpty && !categories.value.contains(category)) {
      categories.value = [...categories.value, category.trim()];
    }
  }

  void addAccount(String name, double initialBalance) {
    if (name.trim().isNotEmpty) {
      mockAccountsList.value = [
        ...mockAccountsList.value,
        {'name': name.trim(), 'balance': initialBalance},
      ];
    }
  }

  /// Upserts a subject template — updates if same name exists, adds otherwise.
  void upsertSubjectTemplate(SubjectTemplate template) {
    final current = List<SubjectTemplate>.from(subjectTemplates.value);
    final idx = current.indexWhere(
      (t) => t.name.toLowerCase() == template.name.toLowerCase(),
    );
    if (idx != -1) {
      current[idx] = template;
    } else {
      current.add(template);
    }
    subjectTemplates.value = current;
  }

  // ── Attendance helper methods & metrics ────────────────────────────────────

  void setLectureAction(DateTime date, String lectureId, String action) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final current = Map<String, Map<String, String>>.from(dateActions.value);
    current[dateKey] = Map<String, String>.from(current[dateKey] ?? {});
    current[dateKey]![lectureId] = action;
    dateActions.value = current;
  }

  void setWholeDayAction(DateTime date, List<LectureMock> lectures, String action) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final current = Map<String, Map<String, String>>.from(dateActions.value);
    current[dateKey] = Map<String, String>.from(current[dateKey] ?? {});
    for (var lec in lectures) {
      current[dateKey]![lec.id] = action;
    }
    dateActions.value = current;
  }

  void addHoliday(String name, DateTime date) {
    holidays.value = [...holidays.value, {'name': name, 'date': date}];
  }

  List<Map<String, dynamic>> getCalculatedSubjects() {
    final List<Map<String, dynamic>> calculatedList = [];

    for (var baselineSub in DummyData.attendanceList) {
      int attended = baselineSub.attended;
      int total = baselineSub.total;

      // Scan all logged dateActions
      dateActions.value.forEach((dateKey, dayActions) {
        final date = DateTime.tryParse(dateKey);
        if (date != null) {
          final bool isHoliday = holidays.value.any((h) {
            final DateTime hDate = h['date'];
            return hDate.year == date.year && hDate.month == date.month && hDate.day == date.day;
          });

          bool isDefaultDayOff = false;
          if (defaultDaysOff.value == 'Sunday Only' && date.weekday == DateTime.sunday) {
            isDefaultDayOff = true;
          } else if (defaultDaysOff.value == 'Saturday & Sunday' && 
              (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday)) {
            isDefaultDayOff = true;
          }

          if (!isHoliday && !isDefaultDayOff) {
            final lectures = DummyData.getLecturesForDay(date.weekday - 1);
            for (var lec in lectures) {
              if (lec.name == baselineSub.name) {
                final action = dayActions[lec.id] ?? 'clear';
                if (action == 'attended') {
                  attended++;
                  total++;
                } else if (action == 'missed') {
                  total++;
                }
              }
            }
          }
        }
      });

      final double percent = total == 0 ? 0.0 : (attended / total) * 100;
      
      int target = targetPercentage.value;
      if (criteriaMode.value == 'subject_wise') {
        target = baselineSub.targetPercent;
      } else if (criteriaMode.value == 'custom') {
        target = subjectCustomTargets.value[baselineSub.name] ?? targetPercentage.value;
      }

      final bool isAboveTarget = percent >= target;

      String statusMessage = '';
      if (percent >= target) {
        int skip = 0;
        if (target > 0) {
          skip = (attended * 100 / target).floor() - total;
          if (skip < 0) skip = 0;
        }
        if (skip > 0) {
          statusMessage = 'can skip $skip lecture${skip != 1 ? 's' : ''}';
        } else {
          statusMessage = "can't skip next lecture";
        }
      } else {
        int must = 0;
        if (target < 100) {
          must = ((target * total - 100 * attended) / (100 - target)).ceil();
        } else {
          must = 99;
        }
        statusMessage = 'need to attend next $must lecture${must != 1 ? 's' : ''}';
      }

      calculatedList.add({
        'id': baselineSub.id,
        'name': baselineSub.name,
        'percent': percent,
        'target': target,
        'attended': attended,
        'total': total,
        'statusMessage': statusMessage,
        'isAboveTarget': isAboveTarget,
      });
    }

    return calculatedList;
  }

  Map<String, dynamic> getOverallStats(List<Map<String, dynamic>> calculatedSubjects) {
    int totalAttended = 0;
    int totalClasses = 0;
    final List<Map<String, dynamic>> belowTarget = [];

    for (var sub in calculatedSubjects) {
      totalAttended += sub['attended'] as int;
      totalClasses += sub['total'] as int;

      if (!(sub['isAboveTarget'] as bool)) {
        belowTarget.add({
          'name': sub['name'],
          'percent': sub['percent'],
        });
      }
    }

    final double overallPercent = totalClasses == 0 ? 0.0 : (totalAttended / totalClasses) * 100;

    return {
      'percent': overallPercent,
      'belowTarget': belowTarget,
    };
  }
}
