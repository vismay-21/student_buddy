import 'package:flutter/material.dart';
import '../models/subject_template.dart';

class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // ── Theme ──────────────────────────────────────────────────────────────────
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // ── Semester ───────────────────────────────────────────────────────────────
  final ValueNotifier<String> activeSemester = ValueNotifier<String>('Semester 4');

  // ── Feature Toggles ────────────────────────────────────────────────────────
  final ValueNotifier<bool> isFinanceEnabled = ValueNotifier<bool>(true);

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
