import 'dart:async';
import '../../local/database_helper.dart';
import '../lecture_template_repository.dart';
import '../../dto/lecture/lecture_template_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteLectureTemplateRepository implements LectureTemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<LectureTemplateDto>> getTemplates(String subjectId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lecture_templates',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'day_of_week ASC, start_time ASC',
    );
    return List.generate(maps.length, (i) => LectureTemplateDto.fromJson(maps[i]));
  }

  @override
  Future<LectureTemplateDto> createTemplate(LectureTemplateCreateRequest request) async {
    final db = _dbHelper.database;
    final templateId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    // 1. Get Subject to verify it exists and get its semester_id
    final List<Map<String, dynamic>> subjectRows = await db.query(
      'subjects',
      where: 'subject_id = ?',
      whereArgs: [request.subjectId],
    );
    if (subjectRows.isEmpty) {
      throw Exception("Subject with ID ${request.subjectId} not found");
    }
    final semesterId = subjectRows.first['semester_id'] as String;
    final subjectName = subjectRows.first['subject_name'] as String;

    // 2. Get Semester
    final List<Map<String, dynamic>> semesterRows = await db.query(
      'semesters',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    if (semesterRows.isEmpty) {
      throw Exception("Semester with ID $semesterId not found");
    }
    final startDate = DateTime.parse(semesterRows.first['start_date'] as String);
    final endDate = DateTime.parse(semesterRows.first['end_date'] as String);

    // 3. Timetable Overlap Conflict Validation
    // Overlap condition: start_time_1 < end_time_2 AND start_time_2 < end_time_1
    final List<Map<String, dynamic>> existingTemplates = await db.rawQuery('''
      SELECT lt.* FROM lecture_templates lt
      JOIN subjects s ON lt.subject_id = s.subject_id
      WHERE s.semester_id = ? AND lt.day_of_week = ?
    ''', [semesterId, request.dayOfWeek]);

    for (final ext in existingTemplates) {
      final extStart = ext['start_time'] as String;
      final extEnd = ext['end_time'] as String;
      if (request.startTime.compareTo(extEnd) < 0 && extStart.compareTo(request.endTime) < 0) {
        throw Exception("Lecture template overlaps in time with existing class on day ${request.dayOfWeek}.");
      }
    }

    final newTemplate = {
      'lecture_template_id': templateId,
      'subject_id': request.subjectId,
      'day_of_week': request.dayOfWeek,
      'start_time': request.startTime,
      'end_time': request.endTime,
      'room': request.room,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    // 4. Get holidays for semester
    final List<Map<String, dynamic>> holidays = await db.query(
      'holidays',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    final holidayDatesStr = holidays.map((h) => h['holiday_date'] as String).toSet();

    await db.transaction((txn) async {
      await txn.insert('lecture_templates', newTemplate);
      await _dbHelper.enqueueOperation(txn, 'lecture_template', templateId, 'create', newTemplate);

      // Generate Lecture Instances
      var current = startDate;
      while (current.compareTo(endDate) <= 0) {
        if (current.weekday == request.dayOfWeek) {
          final dateStr = current.toIso8601String().substring(0, 10);
          final isHoliday = holidayDatesStr.contains(dateStr);
          await txn.insert('lecture_instances', {
            'lecture_instance_id': generateUuid(),
            'lecture_template_id': templateId,
            'lecture_date': dateStr,
            'lecture_status': isHoliday ? 'holiday' : 'scheduled',
            'attendance_status': 'unmarked',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }
        current = current.add(const Duration(days: 1));
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'subject',
        'entity_id': request.subjectId,
        'action_type': 'created',
        'activity_message': "Created lecture template for subject '$subjectName' on day ${request.dayOfWeek} at ${request.startTime}.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return LectureTemplateDto.fromJson(newTemplate);
  }

  @override
  Future<LectureTemplateDto> getTemplateById(String templateId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lecture_templates',
      where: 'lecture_template_id = ?',
      whereArgs: [templateId],
    );
    if (maps.isEmpty) {
      throw Exception("Lecture template with ID $templateId not found");
    }
    return LectureTemplateDto.fromJson(maps.first);
  }

  @override
  Future<LectureTemplateDto> updateTemplate(String templateId, LectureTemplateUpdateRequest request) async {
    final db = _dbHelper.database;
    final temp = await getTemplateById(templateId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.dayOfWeek != null) updates['day_of_week'] = request.dayOfWeek;
    if (request.startTime != null) updates['start_time'] = request.startTime;
    if (request.endTime != null) updates['end_time'] = request.endTime;
    if (request.room != null) updates['room'] = request.room;

    // Timetable overlap verification if day or time changes
    if (request.dayOfWeek != null || request.startTime != null || request.endTime != null) {
      final newDay = request.dayOfWeek ?? temp.dayOfWeek;
      final newStart = request.startTime ?? temp.startTime;
      final newEnd = request.endTime ?? temp.endTime;

      // Get Subject
      final List<Map<String, dynamic>> subjectRows = await db.query(
        'subjects',
        where: 'subject_id = ?',
        whereArgs: [temp.subjectId],
      );
      final semesterId = subjectRows.first['semester_id'] as String;

      final List<Map<String, dynamic>> existingTemplates = await db.rawQuery('''
        SELECT lt.* FROM lecture_templates lt
        JOIN subjects s ON lt.subject_id = s.subject_id
        WHERE s.semester_id = ? AND lt.day_of_week = ? AND lt.lecture_template_id != ?
      ''', [semesterId, newDay, templateId]);

      for (final ext in existingTemplates) {
        final extStart = ext['start_time'] as String;
        final extEnd = ext['end_time'] as String;
        if (newStart.compareTo(extEnd) < 0 && extStart.compareTo(newEnd) < 0) {
          throw Exception("Updated lecture template overlaps in time with existing class.");
        }
      }
    }

    await db.transaction((txn) async {
      await txn.update(
        'lecture_templates',
        updates,
        where: 'lecture_template_id = ?',
        whereArgs: [templateId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'lecture_templates',
        where: 'lecture_template_id = ?',
        whereArgs: [templateId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'lecture_template', templateId, 'update', updatedMaps.first);
      }

      // Note: Scheduling regenerates future instances if changed,
      // but for Sprint 14A simple update is sufficient, or we can regenerate future instances.
      // Let's implement future instance regeneration!
      final schedulingChanged = (request.dayOfWeek != null && request.dayOfWeek != temp.dayOfWeek) ||
          (request.startTime != null && request.startTime != temp.startTime) ||
          (request.endTime != null && request.endTime != temp.endTime);

      if (schedulingChanged) {
        final todayStr = DateTime.now().toUtc().toIso8601String().substring(0, 10);
        
        // 1. Delete future scheduled unmarked instances
        await txn.delete(
          'lecture_instances',
          where: 'lecture_template_id = ? AND lecture_date > ? AND attendance_status = ?',
          whereArgs: [templateId, todayStr, 'unmarked'],
        );

        // 2. Fetch subject and semester to get dates
        final List<Map<String, dynamic>> subjectRows = await txn.query(
          'subjects',
          where: 'subject_id = ?',
          whereArgs: [temp.subjectId],
        );
        final semesterId = subjectRows.first['semester_id'] as String;

        final List<Map<String, dynamic>> semesterRows = await txn.query(
          'semesters',
          where: 'semester_id = ?',
          whereArgs: [semesterId],
        );
        final semesterEnd = DateTime.parse(semesterRows.first['end_date'] as String);

        // 3. Get existing instances to avoid duplicates
        final List<Map<String, dynamic>> existing = await txn.query(
          'lecture_instances',
          where: 'lecture_template_id = ?',
          whereArgs: [templateId],
        );
        final existingDates = existing.map((e) => e['lecture_date'] as String).toSet();

        // 4. Get holidays
        final List<Map<String, dynamic>> holidays = await txn.query(
          'holidays',
          where: 'semester_id = ?',
          whereArgs: [semesterId],
        );
        final holidayDatesStr = holidays.map((h) => h['holiday_date'] as String).toSet();

        // 5. Generate future instances from tomorrow
        final tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
        var current = tomorrow;
        final newDay = request.dayOfWeek ?? temp.dayOfWeek;
        while (current.compareTo(semesterEnd) <= 0) {
          if (current.weekday == newDay) {
            final dateStr = current.toIso8601String().substring(0, 10);
            if (!existingDates.contains(dateStr)) {
              final isHoliday = holidayDatesStr.contains(dateStr);
              await txn.insert('lecture_instances', {
                'lecture_instance_id': generateUuid(),
                'lecture_template_id': templateId,
                'lecture_date': dateStr,
                'lecture_status': isHoliday ? 'holiday' : 'scheduled',
                'attendance_status': 'unmarked',
                'created_at': nowStr,
                'updated_at': nowStr,
              });
            }
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'subject',
        'entity_id': temp.subjectId,
        'action_type': 'updated',
        'activity_message': "Updated lecture template.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'lecture_templates',
      where: 'lecture_template_id = ?',
      whereArgs: [templateId],
    );
    return LectureTemplateDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    final db = _dbHelper.database;
    final temp = await getTemplateById(templateId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'lecture_templates',
        where: 'lecture_template_id = ?',
        whereArgs: [templateId],
      );

      await _dbHelper.enqueueOperation(txn, 'lecture_template', templateId, 'delete', null);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'subject',
        'entity_id': temp.subjectId,
        'action_type': 'deleted',
        'activity_message': "Deleted lecture template.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }
}
