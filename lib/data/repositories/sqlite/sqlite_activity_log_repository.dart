import '../../local/database_helper.dart';
import '../activity_log_repository.dart';
import '../../dto/activity_log/activity_log_dto.dart';

class SqliteActivityLogRepository implements ActivityLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<ActivityLogDto>> getActivityLogs({
    String? actorType,
    String? entityType,
    String? actionType,
    String? entityId,
    String? correlationId,
    int? limit,
    int? offset,
  }) async {
    final db = _dbHelper.database;

    String query = 'SELECT * FROM activity_logs WHERE user_id = ?';
    final List<dynamic> args = [_dbHelper.currentUserId ?? ''];

    if (actorType != null) {
      query += ' AND actor_type = ?';
      args.add(actorType);
    }
    if (entityType != null) {
      query += ' AND entity_type = ?';
      args.add(entityType);
    }
    if (actionType != null) {
      query += ' AND action_type = ?';
      args.add(actionType);
    }
    if (entityId != null) {
      query += ' AND entity_id = ?';
      args.add(entityId);
    }
    if (correlationId != null) {
      query += ' AND correlation_id = ?';
      args.add(correlationId);
    }

    query += ' ORDER BY created_at DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }
    if (offset != null) {
      query += ' OFFSET ?';
      args.add(offset);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      // SQLite schema has no entity_summary, so we fallback to activity_message or empty string
      map['entity_summary'] = map['activity_message'] ?? '';
      return ActivityLogDto.fromJson(map);
    });
  }

  @override
  Future<ActivityLogDto> getActivityLog(String activityId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_logs',
      where: 'activity_id = ?',
      whereArgs: [activityId],
    );
    if (maps.isEmpty) {
      throw Exception("Activity log with ID $activityId not found");
    }
    final map = Map<String, dynamic>.from(maps.first);
    map['entity_summary'] = map['activity_message'] ?? '';
    return ActivityLogDto.fromJson(map);
  }
}
