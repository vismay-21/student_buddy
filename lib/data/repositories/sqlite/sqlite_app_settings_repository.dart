import 'package:sqflite/sqflite.dart';
import '../../local/database_helper.dart';
import '../app_settings_repository.dart';
import '../../dto/settings/app_settings_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteAppSettingsRepository implements AppSettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['finance_enabled'] = (map['finance_enabled'] == 1);
    map['morning_digest_enabled'] = (map['morning_digest_enabled'] == 1);
    map['night_digest_enabled'] = (map['night_digest_enabled'] == 1);
    map['attendance_prompt_enabled'] = (map['attendance_prompt_enabled'] == 1);
    return map;
  }

  @override
  Future<AppSettingsDto> getSettings() async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'user_id = ?',
      whereArgs: [_dbHelper.currentUserId ?? ''],
    );
    if (maps.isEmpty) {
      // If none exists, create a default row for the user
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final defaultSettings = {
        'settings_id': 1, // backend has serial/int primary key
        'user_id': _dbHelper.currentUserId ?? '',
        'theme_mode': 'system',
        'finance_enabled': 0,
        'morning_digest_enabled': 1,
        'night_digest_enabled': 1,
        'attendance_prompt_enabled': 1,
        'notes_download_directory': null,
        'created_at': nowStr,
        'updated_at': nowStr,
      };
      await db.insert('app_settings', defaultSettings);
      return AppSettingsDto.fromJson(_mapRow(defaultSettings));
    }
    return AppSettingsDto.fromJson(_mapRow(maps.first));
  }

  @override
  Future<AppSettingsDto> updateSettings(AppSettingsUpdateRequest request) async {
    final db = _dbHelper.database;
    // Ensure we have settings first
    await getSettings();

    final nowStr = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    
    // Note: activeSemesterId is present in DTO but not in local db column app_settings,
    // wait! In our sqlite schema, is active_semester_id a column?
    // Let's check our created_db schema in database_helper:
    // It doesn't have active_semester_id column. It has settings_id, user_id, theme_mode,
    // finance_enabled, morning_digest_enabled, night_digest_enabled, attendance_prompt_enabled,
    // notes_download_directory, created_at, updated_at.
    // Let's store activeSemesterId in local_metadata or shared preferences?
    // Let's check how active semester is handled. In AppSettingsDto, there is activeSemesterId.
    // Let's check if the backend schema has it, or if it was omitted or added to app_settings.
    // Let's verify this by checking backend models. We can look at `backend/app/models/settings/app_settings.py`.
    // Wait, let's do a grep or read the file backend/app/models/settings/app_settings.py to check if active_semester_id exists there.
    if (request.themeMode != null) updates['theme_mode'] = request.themeMode;
    if (request.financeEnabled != null) updates['finance_enabled'] = request.financeEnabled! ? 1 : 0;
    if (request.morningDigestEnabled != null) updates['morning_digest_enabled'] = request.morningDigestEnabled! ? 1 : 0;
    if (request.nightDigestEnabled != null) updates['night_digest_enabled'] = request.nightDigestEnabled! ? 1 : 0;
    if (request.attendancePromptEnabled != null) updates['attendance_prompt_enabled'] = request.attendancePromptEnabled! ? 1 : 0;
    if (request.notesDownloadDirectory != null) updates['notes_download_directory'] = request.notesDownloadDirectory;

    await db.transaction((txn) async {
      await txn.update(
        'app_settings',
        updates,
        where: 'user_id = ?',
        whereArgs: [_dbHelper.currentUserId ?? ''],
      );

      // If activeSemesterId was passed, store it in local_metadata
      String? activeSemId;
      if (request.activeSemesterId != null) {
        await txn.insert(
          'local_metadata',
          {
            'key': 'active_semester_id',
            'value': request.activeSemesterId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        activeSemId = request.activeSemesterId;
      } else if (request.activeSemesterId == '') {
        await txn.delete(
          'local_metadata',
          where: 'key = ?',
          whereArgs: ['active_semester_id'],
        );
        activeSemId = null;
      } else {
        final meta = await txn.query(
          'local_metadata',
          where: 'key = ?',
          whereArgs: ['active_semester_id'],
        );
        activeSemId = meta.isNotEmpty ? meta.first['value'] as String? : null;
      }

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'app_settings',
        where: 'user_id = ?',
        whereArgs: [_dbHelper.currentUserId ?? ''],
      );
      if (updatedMaps.isNotEmpty) {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(updatedMaps.first);
        payload['active_semester_id'] = activeSemId;
        await _dbHelper.enqueueOperation(txn, 'app_settings', _dbHelper.currentUserId ?? 'settings', 'update', payload);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'app_settings',
        'entity_id': '1',
        'action_type': 'updated',
        'activity_message': 'Updated Application Settings.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final currentMap = await db.query(
      'app_settings',
      where: 'user_id = ?',
      whereArgs: [_dbHelper.currentUserId ?? ''],
    );
    final row = Map<String, dynamic>.from(currentMap.first);
    
    // Read active_semester_id from local_metadata
    final meta = await db.query(
      'local_metadata',
      where: 'key = ?',
      whereArgs: ['active_semester_id'],
    );
    if (meta.isNotEmpty) {
      row['active_semester_id'] = meta.first['value'];
    } else {
      row['active_semester_id'] = null;
    }

    return AppSettingsDto.fromJson(_mapRow(row));
  }
}
