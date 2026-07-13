import '../../local/database_helper.dart';
import '../review_queue_repository.dart';
import '../../dto/review_queue/review_queue_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteReviewQueueRepository implements ReviewQueueRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<ReviewQueueDto>> getReviewQueue({
    String? status,
    String? q,
  }) async {
    final db = _dbHelper.database;
    
    String query = 'SELECT * FROM review_queue WHERE user_id = ?';
    final List<dynamic> args = [_dbHelper.currentUserId ?? ''];

    if (status != null) {
      query += ' AND review_status = ?';
      args.add(status);
    }
    if (q != null && q.isNotEmpty) {
      query += ' AND review_message LIKE ?';
      args.add('%$q%');
    }

    query += ' ORDER BY created_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      // SQLite schema has no entity_summary, so we fallback
      map['entity_summary'] = map['review_message'];
      return ReviewQueueDto.fromJson(map);
    });
  }

  @override
  Future<ReviewQueueDto> getReviewQueueItem(String reviewId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'review_queue',
      where: 'review_id = ?',
      whereArgs: [reviewId],
    );
    if (maps.isEmpty) {
      throw Exception("Review queue item with ID $reviewId not found");
    }
    final map = Map<String, dynamic>.from(maps.first);
    map['entity_summary'] = map['review_message'];
    return ReviewQueueDto.fromJson(map);
  }

  @override
  Future<ReviewQueueDto> resolveReviewQueueItem(
    String reviewId,
    ReviewQueueResolveRequest request,
  ) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final updates = {
      'review_status': 'resolved',
      'resolved_by': request.resolvedBy,
      'resolved_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.update(
        'review_queue',
        updates,
        where: 'review_id = ?',
        whereArgs: [reviewId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'review_queue',
        where: 'review_id = ?',
        whereArgs: [reviewId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'review_queue', reviewId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'review_queue',
        'entity_id': reviewId,
        'action_type': 'updated',
        'activity_message': 'Resolved review queue item.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return getReviewQueueItem(reviewId);
  }
}
