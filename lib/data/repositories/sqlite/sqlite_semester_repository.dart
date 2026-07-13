import '../../local/database_helper.dart';
import '../../../core/utils/uuid_generator.dart';
import '../semester_repository.dart';
import '../../dto/semester/semester_dto.dart';
import 'package:sqflite/sqflite.dart';

class SqliteSemesterRepository implements SemesterRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<SemesterDto>> getSemesters() async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'semesters',
      orderBy: 'semester_number ASC',
    );
    return List.generate(maps.length, (i) => SemesterDto.fromJson(maps[i]));
  }

  @override
  Future<SemesterDto> createSemester(SemesterCreateRequest request) async {
    final db = _dbHelper.database;
    final semesterId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();
    
    // Check semester number conflict
    final existing = await db.query(
      'semesters',
      where: 'semester_number = ?',
      whereArgs: [request.semesterNumber],
    );
    if (existing.isNotEmpty) {
      throw Exception("Semester number ${request.semesterNumber} already exists");
    }

    final newSemester = {
      'semester_id': semesterId,
      'user_id': _dbHelper.currentUserId ?? '',
      'semester_number': request.semesterNumber,
      'start_date': request.startDate.toIso8601String().substring(0, 10),
      'end_date': request.endDate.toIso8601String().substring(0, 10),
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.insert('semesters', newSemester);
      
      // Create default AttendanceSettings
      final settingsId = generateUuid();
      await txn.insert('attendance_settings', {
        'attendance_settings_id': settingsId,
        'semester_id': semesterId,
        'criteria_mode': 'overall',
        'overall_attendance_goal': 75,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await _dbHelper.enqueueOperation(txn, 'semester', semesterId, 'create', newSemester);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'semester',
        'entity_id': semesterId,
        'action_type': 'created',
        'activity_message': 'Created Semester ${request.semesterNumber}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return SemesterDto.fromJson(newSemester);
  }

  @override
  Future<SemesterDto> getSemesterById(String semesterId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'semesters',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    if (maps.isEmpty) {
      throw Exception("Semester with ID $semesterId not found");
    }
    return SemesterDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteSemester(String semesterId) async {
    final db = _dbHelper.database;
    final sem = await getSemesterById(semesterId);

    final nowStr = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete(
        'semesters',
        where: 'semester_id = ?',
        whereArgs: [semesterId],
      );

      await _dbHelper.enqueueOperation(txn, 'semester', semesterId, 'delete', null);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'semester',
        'entity_id': semesterId,
        'action_type': 'deleted',
        'activity_message': 'Deleted Semester ${sem.semesterNumber}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }

  @override
  Future<SemesterDto> updateSemester(String semesterId, SemesterUpdateRequest request) async {
    final db = _dbHelper.database;
    final sem = await getSemesterById(semesterId);

    final nowStr = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.semesterNumber != null) {
      updates['semester_number'] = request.semesterNumber;
    }
    if (request.startDate != null) {
      updates['start_date'] = request.startDate!.toIso8601String().substring(0, 10);
    }
    if (request.endDate != null) {
      updates['end_date'] = request.endDate!.toIso8601String().substring(0, 10);
    }

    await db.transaction((txn) async {
      await txn.update(
        'semesters',
        updates,
        where: 'semester_id = ?',
        whereArgs: [semesterId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'semesters',
        where: 'semester_id = ?',
        whereArgs: [semesterId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'semester', semesterId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'semester',
        'entity_id': semesterId,
        'action_type': 'updated',
        'activity_message': 'Updated Semester ${request.semesterNumber ?? sem.semesterNumber}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final updated = await getSemesterById(semesterId);
    return updated;
  }
}
