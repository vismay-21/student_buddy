import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_buddy/data/dto/semester/semester_dto.dart';
import '../models/subject_template.dart';

class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // ── Attendance State ───────────────────────────────────────────────────────
  final ValueNotifier<String> criteriaMode = ValueNotifier<String>('subject_wise'); // 'overall', 'subject_wise', 'custom'
  final ValueNotifier<int> targetPercentage = ValueNotifier<int>(80);
  final ValueNotifier<Map<String, int>> subjectCustomTargets = ValueNotifier<Map<String, int>>({});
  final ValueNotifier<DateTime> semesterStartDate = ValueNotifier<DateTime>(DateTime(2026, 6, 1));
  final ValueNotifier<DateTime> semesterEndDate = ValueNotifier<DateTime>(DateTime(2026, 11, 30));

  // ── Theme ──────────────────────────────────────────────────────────────────
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // ── Semester ───────────────────────────────────────────────────────────────
  final ValueNotifier<String> activeSemester = ValueNotifier<String>('No Active Semester');
  final ValueNotifier<SemesterDto?> activeSemesterDto = ValueNotifier<SemesterDto?>(null);

  // ── Feature Toggles ────────────────────────────────────────────────────────
  final ValueNotifier<bool> isFinanceEnabled = ValueNotifier<bool>(false);

  // ── Initialization & Persistence ──────────────────────────────────────────
  static const String _keyFinanceEnabled = 'is_finance_enabled';
  static const String _keyActiveSemesterId = 'active_semester_id';
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

  String? get savedActiveSemesterId => _prefs.getString(_keyActiveSemesterId);

  void setActiveSemester(SemesterDto? semester) {
    activeSemesterDto.value = semester;
    if (semester != null) {
      activeSemester.value = 'Semester ${semester.semesterNumber}';
      semesterStartDate.value = semester.startDate;
      semesterEndDate.value = semester.endDate;
      _prefs.setString(_keyActiveSemesterId, semester.semesterId);
    } else {
      activeSemester.value = 'No Active Semester';
      _prefs.remove(_keyActiveSemesterId);
    }
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
}
