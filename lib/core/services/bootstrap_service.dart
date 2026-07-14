import 'package:sqflite/sqflite.dart';
import '../../data/api/user_api.dart';
import '../../data/local/database_helper.dart';

class BootstrapService {
  static final BootstrapService instance = BootstrapService._internal();
  final UserApi _userApi = UserApi();

  BootstrapService._internal();

  /// Runs the full workspace bootstrap flow for a logged-in user.
  /// 1. Initialize user database
  /// 2. Fetch workspace snapshot from backend
  /// 3. Run atomic transaction to clear and populate SQLite tables
  Future<void> bootstrapUser(String userId) async {
    // 1. Initialize user-scoped SQLite DB
    await DatabaseHelper.instance.initDatabase(userId);

    // 2. Fetch bootstrap data
    final data = await _userApi.getBootstrapData();

    // 3. Populate database atomically
    final db = DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Clear all tables within the transaction
      await txn.delete('local_metadata');
      await txn.delete('app_settings');
      await txn.delete('semesters');
      await txn.delete('attendance_settings');
      await txn.delete('subjects');
      await txn.delete('lecture_templates');
      await txn.delete('lecture_instances');
      await txn.delete('holidays');
      await txn.delete('todos');
      await txn.delete('notes_subjects');
      await txn.delete('notes_sections');
      await txn.delete('notes_resources');
      await txn.delete('review_queue');
      await txn.delete('activity_logs');

      // 1. Insert App Settings
      final settings = data['app_settings'];
      if (settings != null) {
        // Store active_semester_id in local_metadata if present
        final activeSemId = settings['active_semester_id'];
        if (activeSemId != null) {
          await txn.insert(
            'local_metadata',
            {
              'key': 'active_semester_id',
              'value': activeSemId.toString(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await txn.insert('app_settings', {
          'settings_id': settings['settings_id'],
          'user_id': userId,
          'theme_mode': settings['theme_mode'] ?? 'system',
          'finance_enabled': (settings['finance_enabled'] == true) ? 1 : 0,
          'morning_digest_enabled': (settings['morning_digest_enabled'] == true) ? 1 : 0,
          'night_digest_enabled': (settings['night_digest_enabled'] == true) ? 1 : 0,
          'attendance_prompt_enabled': (settings['attendance_prompt_enabled'] == true) ? 1 : 0,
          'notes_download_directory': settings['notes_download_directory'],
          'created_at': settings['created_at'],
          'updated_at': settings['updated_at'],
        });
      } else {
        // Create default settings row if none provided
        final nowStr = DateTime.now().toUtc().toIso8601String();
        await txn.insert('app_settings', {
          'settings_id': 1,
          'user_id': userId,
          'theme_mode': 'system',
          'finance_enabled': 0,
          'morning_digest_enabled': 1,
          'night_digest_enabled': 1,
          'attendance_prompt_enabled': 1,
          'notes_download_directory': null,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }

      // 2. Insert Semesters
      final semesters = data['semesters'] as List<dynamic>? ?? [];
      for (final sem in semesters) {
        await txn.insert('semesters', {
          'semester_id': sem['semester_id'],
          'user_id': userId,
          'semester_number': sem['semester_number'],
          'start_date': sem['start_date'],
          'end_date': sem['end_date'],
          'created_at': sem['created_at'],
          'updated_at': sem['updated_at'],
        });
      }

      // 3. Insert Attendance Settings
      final attendanceSettings = data['attendance_settings'] as List<dynamic>? ?? [];
      for (final att in attendanceSettings) {
        await txn.insert('attendance_settings', {
          'attendance_settings_id': att['attendance_settings_id'],
          'semester_id': att['semester_id'],
          'criteria_mode': att['criteria_mode'] ?? 'overall',
          'overall_attendance_goal': att['overall_attendance_goal'],
          'created_at': att['created_at'],
          'updated_at': att['updated_at'],
        });
      }

      // 4. Insert Subjects
      final subjects = data['subjects'] as List<dynamic>? ?? [];
      for (final sub in subjects) {
        await txn.insert('subjects', {
          'subject_id': sub['subject_id'],
          'semester_id': sub['semester_id'],
          'subject_name': sub['subject_name'],
          'faculty_name': sub['faculty_name'],
          'theme_color': sub['theme_color'],
          'attendance_goal': sub['attendance_goal'] ?? 75,
          'created_at': sub['created_at'],
          'updated_at': sub['updated_at'],
        });
      }

      // 5. Insert Lecture Templates
      final templates = data['lecture_templates'] as List<dynamic>? ?? [];
      for (final temp in templates) {
        await txn.insert('lecture_templates', {
          'lecture_template_id': temp['lecture_template_id'],
          'subject_id': temp['subject_id'],
          'day_of_week': temp['day_of_week'],
          'start_time': temp['start_time'],
          'end_time': temp['end_time'],
          'room': temp['room'],
          'created_at': temp['created_at'],
          'updated_at': temp['updated_at'],
        });
      }

      // 6. Insert Lecture Instances
      final instances = data['lecture_instances'] as List<dynamic>? ?? [];
      for (final inst in instances) {
        await txn.insert('lecture_instances', {
          'lecture_instance_id': inst['lecture_instance_id'],
          'lecture_template_id': inst['lecture_template_id'],
          'lecture_date': inst['lecture_date'],
          'lecture_status': inst['lecture_status'] ?? 'scheduled',
          'attendance_status': inst['attendance_status'] ?? 'unmarked',
          'created_at': inst['created_at'],
          'updated_at': inst['updated_at'],
        });
      }

      // 7. Insert Holidays
      final holidays = data['holidays'] as List<dynamic>? ?? [];
      for (final hol in holidays) {
        await txn.insert('holidays', {
          'holiday_id': hol['holiday_id'],
          'semester_id': hol['semester_id'],
          'holiday_date': hol['holiday_date'],
          'holiday_name': hol['holiday_name'],
          'created_at': hol['created_at'],
          'updated_at': hol['updated_at'],
        });
      }

      // 8. Insert Todos
      final todos = data['todos'] as List<dynamic>? ?? [];
      for (final todo in todos) {
        await txn.insert('todos', {
          'todo_id': todo['todo_id'],
          'user_id': userId,
          'title': todo['title'],
          'priority': todo['priority'] ?? 'medium',
          'status': todo['status'] ?? 'pending',
          'created_by': todo['created_by'] ?? 'user',
          'due_datetime': todo['due_datetime'],
          'completed_at': todo['completed_at'],
          'created_at': todo['created_at'],
          'updated_at': todo['updated_at'],
        });
      }

      // 9. Insert Notes Hierarchy
      final notesSubjects = data['notes_subjects'] as List<dynamic>? ?? [];
      for (final ns in notesSubjects) {
        await txn.insert('notes_subjects', {
          'notes_subject_id': ns['notes_subject_id'],
          'user_id': userId,
          'semester_id': ns['semester_id'],
          'notes_subject_name': ns['notes_subject_name'],
          'created_at': ns['created_at'],
          'updated_at': ns['updated_at'],
        });

        final sections = ns['sections'] as List<dynamic>? ?? [];
        for (final sec in sections) {
          await txn.insert('notes_sections', {
            'section_id': sec['section_id'],
            'notes_subject_id': sec['notes_subject_id'],
            'section_name': sec['section_name'],
            'created_at': sec['created_at'],
            'updated_at': sec['updated_at'],
          });

          final resources = sec['resources'] as List<dynamic>? ?? [];
          for (final res in resources) {
            await txn.insert('notes_resources', {
              'resource_id': res['resource_id'],
              'section_id': res['section_id'],
              'resource_name': res['resource_name'],
              'file_name': res['file_name'],
              'mime_type': res['mime_type'],
              'file_size_bytes': res['file_size_bytes'],
              'storage_path': res['storage_path'],
              'uploaded_via': res['uploaded_via'] ?? 'app',
              'created_at': res['created_at'],
              'updated_at': res['updated_at'],
            });
          }
        }
      }

      // 10. Insert Review Queue
      final reviewQueue = data['review_queue'] as List<dynamic>? ?? [];
      for (final item in reviewQueue) {
        await txn.insert('review_queue', {
          'review_id': item['review_id'],
          'user_id': userId,
          'review_type': item['review_type'],
          'entity_type': item['entity_type'],
          'entity_id': item['entity_id'],
          'review_message': item['review_message'],
          'review_status': item['review_status'] ?? 'pending',
          'resolved_by': item['resolved_by'] ?? 'user',
          'created_at': item['created_at'],
          'resolved_at': item['resolved_at'],
        });
      }

      // 11. Insert Activity Logs
      final activityLogs = data['activity_logs'] as List<dynamic>? ?? [];
      for (final log in activityLogs) {
        await txn.insert('activity_logs', {
          'activity_id': log['activity_id'],
          'user_id': userId,
          'actor_type': log['actor_type'],
          'entity_type': log['entity_type'],
          'entity_id': log['entity_id'],
          'action_type': log['action_type'],
          'activity_message': log['activity_message'],
          'correlation_id': log['correlation_id'],
          'created_at': log['created_at'],
        });
      }

      // 12. Mark bootstrap complete
      await txn.insert(
        'local_metadata',
        {
          'key': 'bootstrap_completed',
          'value': 'true',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
