import '../../local/database_helper.dart';
import '../attendance_settings_repository.dart';
import '../../dto/attendance/attendance_settings_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteAttendanceSettingsRepository implements AttendanceSettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<AttendanceSettingsDto> getSettings(String semesterId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_settings',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    if (maps.isEmpty) {
      // Create default local row
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final defaultSettings = {
        'attendance_settings_id': generateUuid(),
        'semester_id': semesterId,
        'criteria_mode': 'overall',
        'overall_attendance_goal': 75,
        'created_at': nowStr,
        'updated_at': nowStr,
      };
      await db.insert('attendance_settings', defaultSettings);
      return AttendanceSettingsDto.fromJson(defaultSettings);
    }
    return AttendanceSettingsDto.fromJson(maps.first);
  }

  @override
  Future<AttendanceSettingsDto> updateSettings(
    String semesterId,
    AttendanceSettingsUpdateRequest request,
  ) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();
    
    // Ensure default exists first
    await getSettings(semesterId);

    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.criteriaMode != null) {
      updates['criteria_mode'] = request.criteriaMode;
    }
    if (request.overallAttendanceGoal != null) {
      updates['overall_attendance_goal'] = request.overallAttendanceGoal;
    }

    await db.transaction((txn) async {
      await txn.update(
        'attendance_settings',
        updates,
        where: 'semester_id = ?',
        whereArgs: [semesterId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'attendance_settings',
        where: 'semester_id = ?',
        whereArgs: [semesterId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'attendance_settings', semesterId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'attendance_settings',
        'entity_id': semesterId,
        'action_type': 'updated',
        'activity_message': 'Updated Attendance Settings.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'attendance_settings',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    return AttendanceSettingsDto.fromJson(maps.first);
  }
}
