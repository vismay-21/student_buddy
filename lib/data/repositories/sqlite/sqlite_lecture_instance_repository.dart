import '../../local/database_helper.dart';
import '../lecture_instance_repository.dart';
import '../../dto/lecture/lecture_instance_dto.dart';
import '../../dto/subject/subject_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteLectureInstanceRepository implements LectureInstanceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic> _buildNestedMap(Map<String, dynamic> row) {
    return {
      'lecture_instance_id': row['lecture_instance_id'],
      'lecture_template_id': row['lecture_template_id'],
      'lecture_date': row['lecture_date'],
      'lecture_status': row['lecture_status'],
      'attendance_status': row['attendance_status'],
      'created_at': row['instance_created_at'],
      'updated_at': row['instance_updated_at'],
      'lecture_template': {
        'lecture_template_id': row['lecture_template_id'],
        'subject_id': row['subject_id'],
        'day_of_week': row['day_of_week'],
        'start_time': row['start_time'],
        'end_time': row['end_time'],
        'room': row['room'],
        'subject': {
          'subject_id': row['subject_id'],
          'semester_id': row['semester_id'],
          'subject_name': row['subject_name'],
          'faculty_name': row['faculty_name'],
          'theme_color': row['theme_color'],
          'attendance_goal': row['attendance_goal'] ?? 75,
          'created_at': row['subject_created_at'],
          'updated_at': row['subject_updated_at'],
        }
      }
    };
  }

  // Attendance stats math
  double _calculateAttendancePercentage(int present, int absent) {
    final int marked = present + absent;
    if (marked == 0) return 100.0;
    return double.parse(((present / marked) * 100.0).toStringAsFixed(2));
  }

  int _calculateSafeSkip(int present, int absent, int goal) {
    final int marked = present + absent;
    if (marked == 0) return 0;
    final double valK = (100 * present - goal * marked) / goal;
    final int k = valK.floor();
    return k > 0 ? k : 0;
  }

  int _calculateRemainingLectures(List<Map<String, dynamic>> scheduledInstances, DateTime today) {
    int count = 0;
    final todayStr = today.toIso8601String().substring(0, 10);
    for (final inst in scheduledInstances) {
      final dateStr = inst['lecture_date'] as String;
      final status = inst['attendance_status'] as String;
      if (dateStr.compareTo(todayStr) > 0 && status == 'unmarked') {
        count++;
      }
    }
    return count;
  }

  String _calculateStatusMessage(int present, int absent, int goal) {
    final int marked = present + absent;
    if (marked == 0) return "can't skip next lecture";
    final double valK = (100 * present - goal * marked) / goal;
    final int k = valK.floor();
    if (k > 0) {
      return "can skip $k lectures";
    } else if (k == 0) {
      return "can't skip next lecture";
    } else {
      final int divisor = 100 - goal;
      if (divisor <= 0) {
        return absent > 0 ? "need to attend next lecture" : "can't skip next lecture";
      }
      final double valM = (goal * marked - 100 * present) / divisor;
      final int m = valM.ceil();
      return "need to attend next $m lectures";
    }
  }

  int _calculateNeedToAttend(int present, int absent, int goal) {
    final int marked = present + absent;
    if (marked == 0) return 0;
    final double valK = (100 * present - goal * marked) / goal;
    final int k = valK.floor();
    if (k >= 0) return 0;
    final int divisor = 100 - goal;
    if (divisor <= 0) {
      return absent > 0 ? 1 : 0;
    }
    final double valM = (goal * marked - 100 * present) / divisor;
    return valM.ceil();
  }

  @override
  Future<List<LectureInstanceDto>> getInstances({
    String? semesterId,
    String? subjectId,
    String? startDate,
    String? endDate,
    String? attendanceStatus,
    String? lectureStatus,
  }) async {
    final db = _dbHelper.database;
    
    String query = '''
      SELECT 
        li.lecture_instance_id,
        li.lecture_template_id,
        li.lecture_date,
        li.lecture_status,
        li.attendance_status,
        li.created_at AS instance_created_at,
        li.updated_at AS instance_updated_at,
        lt.subject_id,
        lt.day_of_week,
        lt.start_time,
        lt.end_time,
        lt.room,
        s.semester_id,
        s.subject_name,
        s.faculty_name,
        s.theme_color,
        s.attendance_goal,
        s.created_at AS subject_created_at,
        s.updated_at AS subject_updated_at
      FROM lecture_instances li
      JOIN lecture_templates lt ON li.lecture_template_id = lt.lecture_template_id
      JOIN subjects s ON lt.subject_id = s.subject_id
      WHERE 1=1
    ''';
    
    final List<dynamic> args = [];
    if (semesterId != null) {
      query += ' AND s.semester_id = ?';
      args.add(semesterId);
    }
    if (subjectId != null) {
      query += ' AND lt.subject_id = ?';
      args.add(subjectId);
    }
    if (startDate != null) {
      query += ' AND li.lecture_date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      query += ' AND li.lecture_date <= ?';
      args.add(endDate);
    }
    if (attendanceStatus != null) {
      query += ' AND li.attendance_status = ?';
      args.add(attendanceStatus);
    }
    if (lectureStatus != null) {
      query += ' AND li.lecture_status = ?';
      args.add(lectureStatus);
    }
    
    query += ' ORDER BY li.lecture_date ASC, lt.start_time ASC';
    
    final List<Map<String, dynamic>> rows = await db.rawQuery(query, args);
    return rows.map((r) => LectureInstanceDto.fromJson(_buildNestedMap(r))).toList();
  }

  @override
  Future<List<LectureInstanceDto>> getTodayLectures({String? date, String? semesterId}) async {
    final targetDate = date ?? DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return getInstances(
      semesterId: semesterId,
      startDate: targetDate,
      endDate: targetDate,
    );
  }

  @override
  Future<LectureInstanceDto> getInstanceById(String instanceId) async {
    final db = _dbHelper.database;
    final String query = '''
      SELECT 
        li.lecture_instance_id,
        li.lecture_template_id,
        li.lecture_date,
        li.lecture_status,
        li.attendance_status,
        li.created_at AS instance_created_at,
        li.updated_at AS instance_updated_at,
        lt.subject_id,
        lt.day_of_week,
        lt.start_time,
        lt.end_time,
        lt.room,
        s.semester_id,
        s.subject_name,
        s.faculty_name,
        s.theme_color,
        s.attendance_goal,
        s.created_at AS subject_created_at,
        s.updated_at AS subject_updated_at
      FROM lecture_instances li
      JOIN lecture_templates lt ON li.lecture_template_id = lt.lecture_template_id
      JOIN subjects s ON lt.subject_id = s.subject_id
      WHERE li.lecture_instance_id = ?
    ''';
    final List<Map<String, dynamic>> rows = await db.rawQuery(query, [instanceId]);
    if (rows.isEmpty) {
      throw Exception("Lecture instance with ID $instanceId not found");
    }
    return LectureInstanceDto.fromJson(_buildNestedMap(rows.first));
  }

  @override
  Future<LectureInstanceBulkUpdateResponseDto> markWholeDay(LectureInstanceBulkUpdateRequest request) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();
    
    // Find all scheduled lecture instances for that day
    final List<LectureInstanceDto> list = await getInstances(
      semesterId: request.semesterId,
      startDate: request.lectureDate,
      endDate: request.lectureDate,
      lectureStatus: 'scheduled',
    );

    int updated = 0;
    await db.transaction((txn) async {
      for (final inst in list) {
        final Map<String, dynamic> updates = {
          'updated_at': nowStr,
        };
        if (request.attendanceStatus != null) {
          updates['attendance_status'] = request.attendanceStatus;
        }
        if (request.lectureStatus != null) {
          updates['lecture_status'] = request.lectureStatus;
        }

        final count = await txn.update(
          'lecture_instances',
          updates,
          where: 'lecture_instance_id = ?',
          whereArgs: [inst.lectureInstanceId],
        );
        updated += count;

        final List<Map<String, dynamic>> updatedMaps = await txn.query(
          'lecture_instances',
          where: 'lecture_instance_id = ?',
          whereArgs: [inst.lectureInstanceId],
        );
        if (updatedMaps.isNotEmpty) {
          await _dbHelper.enqueueOperation(txn, 'lecture_instance', inst.lectureInstanceId, 'update', updatedMaps.first);
        }
      }
    });

    return LectureInstanceBulkUpdateResponseDto(updatedCount: updated, skippedCount: 0);
  }

  @override
  Future<LectureInstanceDto> updateAttendance(String instanceId, LectureInstanceUpdateRequest request) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();
    
    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.attendanceStatus != null) {
      updates['attendance_status'] = request.attendanceStatus;
    }
    if (request.lectureStatus != null) {
      updates['lecture_status'] = request.lectureStatus;
    }

    await db.transaction((txn) async {
      await txn.update(
        'lecture_instances',
        updates,
        where: 'lecture_instance_id = ?',
        whereArgs: [instanceId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'lecture_instances',
        where: 'lecture_instance_id = ?',
        whereArgs: [instanceId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'lecture_instance', instanceId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'lecture_instance',
        'entity_id': instanceId,
        'action_type': 'updated',
        'activity_message': 'Updated lecture instance attendance to ${request.attendanceStatus ?? request.lectureStatus}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return getInstanceById(instanceId);
  }

  @override
  Future<AttendanceStatsDto> getSubjectStats(String subjectId) async {
    final db = _dbHelper.database;
    
    // Fetch subject
    final List<Map<String, dynamic>> subjectRows = await db.query(
      'subjects',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    if (subjectRows.isEmpty) {
      throw Exception("Subject with ID $subjectId not found");
    }
    final semesterId = subjectRows.first['semester_id'] as String;
    final int defaultGoal = subjectRows.first['attendance_goal'] as int? ?? 75;

    // Fetch criteria mode from attendance_settings
    final List<Map<String, dynamic>> settingsRows = await db.query(
      'attendance_settings',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    final String criteriaMode = settingsRows.isNotEmpty ? (settingsRows.first['criteria_mode'] as String? ?? 'overall') : 'overall';
    final int overallGoal = settingsRows.isNotEmpty ? (settingsRows.first['overall_attendance_goal'] as int? ?? 75) : 75;

    int goal = defaultGoal;
    if (criteriaMode == 'overall' || criteriaMode == 'subject') {
      goal = overallGoal;
    }

    // Get instances for subject
    final List<Map<String, dynamic>> instances = await db.rawQuery('''
      SELECT li.lecture_date, li.lecture_status, li.attendance_status
      FROM lecture_instances li
      JOIN lecture_templates lt ON li.lecture_template_id = lt.lecture_template_id
      WHERE lt.subject_id = ?
    ''', [subjectId]);

    final scheduled = instances.where((inst) => inst['lecture_status'] == 'scheduled').toList();
    final present = scheduled.where((inst) => inst['attendance_status'] == 'present').length;
    final absent = scheduled.where((inst) => inst['attendance_status'] == 'absent').length;

    final pct = _calculateAttendancePercentage(present, absent);
    final rem = _calculateRemainingLectures(scheduled, DateTime.now());
    final skip = _calculateSafeSkip(present, absent, goal);
    final msg = _calculateStatusMessage(present, absent, goal);

    return AttendanceStatsDto(
      totalLectures: scheduled.length,
      presentLectures: present,
      absentLectures: absent,
      attendancePercentage: pct,
      remainingLectures: rem,
      safeSkipCount: skip,
      statusMessage: msg,
      criteriaMode: criteriaMode,
    );
  }

  @override
  Future<AttendanceStatsDto> getSemesterStats(String semesterId) async {
    final db = _dbHelper.database;

    // Fetch criteria mode from attendance_settings
    final List<Map<String, dynamic>> settingsRows = await db.query(
      'attendance_settings',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );
    final String criteriaMode = settingsRows.isNotEmpty ? (settingsRows.first['criteria_mode'] as String? ?? 'overall') : 'overall';
    final int overallGoal = settingsRows.isNotEmpty ? (settingsRows.first['overall_attendance_goal'] as int? ?? 75) : 75;

    if (criteriaMode == 'overall') {
      final List<Map<String, dynamic>> instances = await db.rawQuery('''
        SELECT li.lecture_date, li.lecture_status, li.attendance_status
        FROM lecture_instances li
        JOIN lecture_templates lt ON li.lecture_template_id = lt.lecture_template_id
        JOIN subjects s ON lt.subject_id = s.subject_id
        WHERE s.semester_id = ?
      ''', [semesterId]);

      final scheduled = instances.where((inst) => inst['lecture_status'] == 'scheduled').toList();
      final present = scheduled.where((inst) => inst['attendance_status'] == 'present').length;
      final absent = scheduled.where((inst) => inst['attendance_status'] == 'absent').length;

      final pct = _calculateAttendancePercentage(present, absent);
      final rem = _calculateRemainingLectures(scheduled, DateTime.now());
      final skip = _calculateSafeSkip(present, absent, overallGoal);
      final msg = _calculateStatusMessage(present, absent, overallGoal);

      return AttendanceStatsDto(
        totalLectures: scheduled.length,
        presentLectures: present,
        absentLectures: absent,
        attendancePercentage: pct,
        remainingLectures: rem,
        safeSkipCount: skip,
        statusMessage: msg,
        criteriaMode: criteriaMode,
      );
    } else {
      // Subject or Custom Mode: aggregate subject-level calculations
      final List<Map<String, dynamic>> subjects = await db.query(
        'subjects',
        where: 'semester_id = ?',
        whereArgs: [semesterId],
      );

      int totalLectures = 0;
      int presentLectures = 0;
      int absentLectures = 0;
      int remainingLectures = 0;
      List<double> subjectPercentages = [];
      int totalSafeSkips = 0;
      int totalNeedToAttend = 0;

      for (final subject in subjects) {
        final subjectId = subject['subject_id'] as String;
        final defaultGoal = subject['attendance_goal'] as int? ?? 75;
        final int subGoal = (criteriaMode == 'subject') ? overallGoal : defaultGoal;

        final List<Map<String, dynamic>> instances = await db.rawQuery('''
          SELECT li.lecture_date, li.lecture_status, li.attendance_status
          FROM lecture_instances li
          JOIN lecture_templates lt ON li.lecture_template_id = lt.lecture_template_id
          WHERE lt.subject_id = ?
        ''', [subjectId]);

        final scheduled = instances.where((inst) => inst['lecture_status'] == 'scheduled').toList();
        final subPresent = scheduled.where((inst) => inst['attendance_status'] == 'present').length;
        final subAbsent = scheduled.where((inst) => inst['attendance_status'] == 'absent').length;

        final subPct = _calculateAttendancePercentage(subPresent, subAbsent);
        final subRem = _calculateRemainingLectures(scheduled, DateTime.now());
        final subSkip = _calculateSafeSkip(subPresent, subAbsent, subGoal);
        final subNeed = _calculateNeedToAttend(subPresent, subAbsent, subGoal);

        totalLectures += scheduled.length;
        presentLectures += subPresent;
        absentLectures += subAbsent;
        remainingLectures += subRem;

        if (scheduled.isNotEmpty) {
          subjectPercentages.append(subPct);
        }

        totalSafeSkips += subSkip;
        totalNeedToAttend += subNeed;
      }

      double attendancePercentage = 100.0;
      if (subjectPercentages.isNotEmpty) {
        attendancePercentage = double.parse((subjectPercentages.reduce((a, b) => a + b) / subjectPercentages.length).toStringAsFixed(2));
      }

      String statusMessage = "can't skip next lecture";
      if (totalSafeSkips > 0) {
        statusMessage = "can skip $totalSafeSkips lectures";
      } else if (totalNeedToAttend > 0) {
        statusMessage = "need to attend next $totalNeedToAttend lectures";
      }

      return AttendanceStatsDto(
        totalLectures: totalLectures,
        presentLectures: presentLectures,
        absentLectures: absentLectures,
        attendancePercentage: attendancePercentage,
        remainingLectures: remainingLectures,
        safeSkipCount: totalSafeSkips,
        statusMessage: statusMessage,
        criteriaMode: criteriaMode,
      );
    }
  }
}

extension _ListDoubleExtension on List<double> {
  void append(double value) => add(value);
}
