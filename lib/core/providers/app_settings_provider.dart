import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common_providers.dart';
import '../models/subject_template.dart';
import '../../data/dto/settings/app_settings_dto.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../data/dto/activity_log/activity_log_dto.dart';
import '../../data/repositories/activity_log_repository.dart';

// ==========================================
// 1. App Settings Async Provider (SQLite backed)
// ==========================================
class AppSettingsNotifier extends AsyncNotifier<AppSettingsDto> {
  @override
  Future<AppSettingsDto> build() async {
    final repo = AppSettingsRepository();
    final settings = await repo.getSettings();
    return settings;
  }

  Future<void> updateSetting(AppSettingsUpdateRequest request) async {
    final repo = AppSettingsRepository();
    final updated = await repo.updateSettings(request);
    state = AsyncValue.data(updated);
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettingsDto>(AppSettingsNotifier.new);

// ==========================================
// 2. Theme Provider
// ==========================================
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    ref.listen<AsyncValue<AppSettingsDto>>(appSettingsProvider, (prev, next) {
      if (next is AsyncData<AppSettingsDto>) {
        final modeStr = next.value.themeMode;
        final mode = modeStr == 'light' ? ThemeMode.light : (modeStr == 'dark' ? ThemeMode.dark : ThemeMode.system);
        if (state != mode) {
          state = mode;
          ref.read(sharedPreferencesProvider).setString(_key, mode.name);
        }
      }
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    final val = prefs.getString(_key);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.dark; // Default to dark mode as requested
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, next.name);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

// ==========================================
// 3. Notification Settings Provider
// ==========================================
class NotificationSettingsState {
  final bool morningDigest;
  final bool nightDigest;
  final bool beforeLectureNotif;
  final bool afterLectureNotif;

  NotificationSettingsState({
    required this.morningDigest,
    required this.nightDigest,
    required this.beforeLectureNotif,
    required this.afterLectureNotif,
  });

  NotificationSettingsState copyWith({
    bool? morningDigest,
    bool? nightDigest,
    bool? beforeLectureNotif,
    bool? afterLectureNotif,
  }) {
    return NotificationSettingsState(
      morningDigest: morningDigest ?? this.morningDigest,
      nightDigest: nightDigest ?? this.nightDigest,
      beforeLectureNotif: beforeLectureNotif ?? this.beforeLectureNotif,
      afterLectureNotif: afterLectureNotif ?? this.afterLectureNotif,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  static const _keyMorning = 'notif_morning_digest';
  static const _keyNight = 'notif_night_digest';
  static const _keyBefore = 'notif_before_lecture';
  static const _keyAfter = 'notif_after_lecture';

  @override
  NotificationSettingsState build() {
    ref.listen<AsyncValue<AppSettingsDto>>(appSettingsProvider, (prev, next) {
      if (next is AsyncData<AppSettingsDto>) {
        final settings = next.value;
        final newState = state.copyWith(
          morningDigest: settings.morningDigestEnabled,
          nightDigest: settings.nightDigestEnabled,
          beforeLectureNotif: settings.attendancePromptEnabled,
          afterLectureNotif: settings.attendancePromptEnabled,
        );
        state = newState;
      }
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationSettingsState(
      morningDigest: prefs.getBool(_keyMorning) ?? true,
      nightDigest: prefs.getBool(_keyNight) ?? true,
      beforeLectureNotif: prefs.getBool(_keyBefore) ?? true,
      afterLectureNotif: prefs.getBool(_keyAfter) ?? true,
    );
  }

  void updateSettings({
    bool? morningDigest,
    bool? nightDigest,
    bool? beforeLectureNotif,
    bool? afterLectureNotif,
  }) {
    final prefs = ref.read(sharedPreferencesProvider);
    final newState = state.copyWith(
      morningDigest: morningDigest,
      nightDigest: nightDigest,
      beforeLectureNotif: beforeLectureNotif,
      afterLectureNotif: afterLectureNotif,
    );
    state = newState;

    if (morningDigest != null) prefs.setBool(_keyMorning, morningDigest);
    if (nightDigest != null) prefs.setBool(_keyNight, nightDigest);
    if (beforeLectureNotif != null) prefs.setBool(_keyBefore, beforeLectureNotif);
    if (afterLectureNotif != null) prefs.setBool(_keyAfter, afterLectureNotif);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(NotificationSettingsNotifier.new);

// ==========================================
// 4. Finance Settings Provider
// ==========================================
class FinanceSettingsState {
  final bool isFinanceEnabled;
  final String defaultAccount;
  final List<String> categories;
  final List<Map<String, dynamic>> mockAccountsList;

  FinanceSettingsState({
    required this.isFinanceEnabled,
    required this.defaultAccount,
    required this.categories,
    required this.mockAccountsList,
  });

  FinanceSettingsState copyWith({
    bool? isFinanceEnabled,
    String? defaultAccount,
    List<String>? categories,
    List<Map<String, dynamic>>? mockAccountsList,
  }) {
    return FinanceSettingsState(
      isFinanceEnabled: isFinanceEnabled ?? this.isFinanceEnabled,
      defaultAccount: defaultAccount ?? this.defaultAccount,
      categories: categories ?? this.categories,
      mockAccountsList: mockAccountsList ?? this.mockAccountsList,
    );
  }
}

class FinanceSettingsNotifier extends Notifier<FinanceSettingsState> {
  static const _keyFinanceEnabled = 'is_finance_enabled';
  static const _keyDefaultAccount = 'default_account';

  @override
  FinanceSettingsState build() {
    ref.listen<AsyncValue<AppSettingsDto>>(appSettingsProvider, (prev, next) {
      if (next is AsyncData<AppSettingsDto>) {
        final settings = next.value;
        if (state.isFinanceEnabled != settings.financeEnabled) {
          state = state.copyWith(isFinanceEnabled: settings.financeEnabled);
          ref.read(sharedPreferencesProvider).setBool(_keyFinanceEnabled, settings.financeEnabled);
        }
      }
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    return FinanceSettingsState(
      isFinanceEnabled: prefs.getBool(_keyFinanceEnabled) ?? false,
      defaultAccount: prefs.getString(_keyDefaultAccount) ?? 'UPI (GPay/PhonePe)',
      categories: [
        'Food',
        'Academics',
        'Transport',
        'Entertainment',
        'Stipend',
        'Others',
      ],
      mockAccountsList: [
        {'name': 'UPI (GPay/PhonePe)', 'balance': 3450.00},
        {'name': 'Cash Wallet',        'balance':  450.00},
        {'name': 'Savings Account',    'balance': 12300.00},
        {'name': 'Pocket Money',       'balance':  800.00},
      ],
    );
  }

  void toggleFinance(bool enable) {
    state = state.copyWith(isFinanceEnabled: enable);
    ref.read(sharedPreferencesProvider).setBool(_keyFinanceEnabled, enable);
  }

  void updateDefaultAccount(String account) {
    state = state.copyWith(defaultAccount: account);
    ref.read(sharedPreferencesProvider).setString(_keyDefaultAccount, account);
  }

  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isNotEmpty && !state.categories.contains(trimmed)) {
      state = state.copyWith(categories: [...state.categories, trimmed]);
    }
  }

  void addAccount(String name, double initialBalance) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      state = state.copyWith(
        mockAccountsList: [
          ...state.mockAccountsList,
          {'name': trimmed, 'balance': initialBalance},
        ],
      );
    }
  }
}

final financeSettingsProvider =
    NotifierProvider<FinanceSettingsNotifier, FinanceSettingsState>(FinanceSettingsNotifier.new);

// ==========================================
// 5. App Preferences Provider
// ==========================================
class AppPreferencesState {
  final List<SubjectTemplate> subjectTemplates;

  AppPreferencesState({
    required this.subjectTemplates,
  });

  AppPreferencesState copyWith({
    List<SubjectTemplate>? subjectTemplates,
  }) {
    return AppPreferencesState(
      subjectTemplates: subjectTemplates ?? this.subjectTemplates,
    );
  }
}

class AppPreferencesNotifier extends Notifier<AppPreferencesState> {
  @override
  AppPreferencesState build() {
    return AppPreferencesState(subjectTemplates: []);
  }

  void upsertSubjectTemplate(SubjectTemplate template) {
    final current = List<SubjectTemplate>.from(state.subjectTemplates);
    final idx = current.indexWhere(
      (t) => t.name.toLowerCase() == template.name.toLowerCase(),
    );
    if (idx != -1) {
      current[idx] = template;
    } else {
      current.add(template);
    }
    state = state.copyWith(subjectTemplates: current);
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferencesState>(AppPreferencesNotifier.new);

// ==========================================
// 6. Activity Logs Provider
// ==========================================
final activityLogsProvider = FutureProvider<List<ActivityLogDto>>((ref) async {
  final repo = ActivityLogRepository();
  return repo.getActivityLogs(limit: 5);
});
