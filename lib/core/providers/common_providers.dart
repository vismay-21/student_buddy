import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/local/database_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/todo_service.dart';
import '../services/semester_service.dart';
import '../services/subject_service.dart';
import '../services/attendance_service.dart';
import '../services/notes_service.dart';
import '../services/review_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Low-level dependencies
final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must override sharedPreferencesProvider in ProviderScope');
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);

final syncServiceProvider = Provider<SyncService>((ref) => SyncService.instance);

final todoServiceProvider = Provider<TodoService>((ref) => TodoService());

final semesterServiceProvider = Provider<SemesterService>((ref) => SemesterService());

final subjectServiceProvider = Provider<SubjectService>((ref) => SubjectService());

final attendanceServiceProvider = Provider<AttendanceService>((ref) => AttendanceService());

final notesServiceProvider = Provider<NotesService>((ref) => NotesService());

final reviewQueueServiceProvider = Provider<ReviewQueueService>((ref) => ReviewQueueService());
