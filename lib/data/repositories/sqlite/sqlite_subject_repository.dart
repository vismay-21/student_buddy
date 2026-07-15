import '../../local/database_helper.dart';
import '../subject_repository.dart';
import '../../dto/subject/subject_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteSubjectRepository implements SubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<SubjectDto>> getSubjects(String semesterId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'subject_name ASC',
    );
    return List.generate(maps.length, (i) => SubjectDto.fromJson(maps[i]));
  }

  @override
  Future<SubjectDto> createSubject(SubjectCreateRequest request) async {
    final db = _dbHelper.database;
    final subjectId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    // Validate unique subject name within semester
    final List<Map<String, dynamic>> existing = await db.query(
      'subjects',
      where: 'semester_id = ? AND subject_name = ?',
      whereArgs: [request.semesterId, request.subjectName],
    );
    if (existing.isNotEmpty) {
      throw Exception("Subject '${request.subjectName}' already exists in this semester");
    }

    final newSubject = {
      'subject_id': subjectId,
      'semester_id': request.semesterId,
      'subject_name': request.subjectName,
      'faculty_name': request.facultyName,
      'theme_color': request.themeColor ?? '#4A90E2', // fallback default theme color
      'attendance_goal': request.attendanceGoal,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.insert('subjects', newSubject);
      await _dbHelper.enqueueOperation(txn, 'subject', subjectId, 'create', newSubject);

      // Automatically create corresponding Notes Subject
      final notesSubjectId = subjectId;
      await txn.insert('notes_subjects', {
        'notes_subject_id': notesSubjectId,
        'user_id': _dbHelper.currentUserId ?? '',
        'semester_id': request.semesterId,
        'notes_subject_name': request.subjectName,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'subject',
        'entity_id': subjectId,
        'action_type': 'created',
        'activity_message': 'Created subject ${request.subjectName}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return SubjectDto.fromJson(newSubject);
  }

  @override
  Future<SubjectDto> getSubjectById(String subjectId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    if (maps.isEmpty) {
      throw Exception("Subject with ID $subjectId not found");
    }
    return SubjectDto.fromJson(maps.first);
  }

  @override
  Future<SubjectDto> updateSubject(String subjectId, SubjectUpdateRequest request) async {
    final db = _dbHelper.database;
    final sub = await getSubjectById(subjectId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.subjectName != null) {
      updates['subject_name'] = request.subjectName;
    }
    if (request.facultyName != null) {
      updates['faculty_name'] = request.facultyName;
    }
    if (request.themeColor != null) {
      updates['theme_color'] = request.themeColor;
    }
    if (request.attendanceGoal != null) {
      updates['attendance_goal'] = request.attendanceGoal;
    }

    if (request.subjectName != null && request.subjectName != sub.subjectName) {
      final List<Map<String, dynamic>> existing = await db.query(
        'subjects',
        where: 'semester_id = ? AND subject_name = ? AND subject_id != ?',
        whereArgs: [sub.semesterId, request.subjectName, subjectId],
      );
      if (existing.isNotEmpty) {
        throw Exception("Subject '${request.subjectName}' already exists in this semester");
      }
    }

    await db.transaction((txn) async {
      await txn.update(
        'subjects',
        updates,
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'subjects',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'subject', subjectId, 'update', updatedMaps.first);
      }

      // If name changed, rename corresponding Notes Subject
      if (request.subjectName != null && request.subjectName != sub.subjectName) {
        await txn.update(
          'notes_subjects',
          {
            'notes_subject_name': request.subjectName,
            'updated_at': nowStr,
          },
          where: 'semester_id = ? AND notes_subject_name = ?',
          whereArgs: [sub.semesterId, sub.subjectName],
        );
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'subject',
        'entity_id': subjectId,
        'action_type': 'updated',
        'activity_message': 'Updated subject ${request.subjectName ?? sub.subjectName} details.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'subjects',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    return SubjectDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteSubject(String subjectId, {bool deleteNotesSubject = false}) async {
    final db = _dbHelper.database;
    final sub = await getSubjectById(subjectId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'subjects',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );

      await _dbHelper.enqueueOperation(txn, 'subject', subjectId, 'delete', null);

      if (deleteNotesSubject) {
        await txn.delete(
          'notes_subjects',
          where: 'semester_id = ? AND notes_subject_name = ?',
          whereArgs: [sub.semesterId, sub.subjectName],
        );
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'subject',
        'entity_id': subjectId,
        'action_type': 'deleted',
        'activity_message': 'Deleted subject ${sub.subjectName}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }
}
