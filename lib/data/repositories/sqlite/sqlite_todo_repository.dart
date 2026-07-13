import '../../local/database_helper.dart';
import '../todo_repository.dart';
import '../../dto/todo/todo_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteTodoRepository implements TodoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<TodoDto> createTodo(TodoCreateRequest request) async {
    final db = _dbHelper.database;
    final todoId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final newTodo = {
      'todo_id': todoId,
      'user_id': _dbHelper.currentUserId ?? '',
      'title': request.title,
      'priority': request.priority,
      'status': request.status,
      'created_by': 'user',
      'due_datetime': request.dueDatetime?.toIso8601String(),
      'completed_at': request.status == 'completed' ? nowStr : null,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.insert('todos', newTodo);
      await _dbHelper.enqueueOperation(txn, 'todo', todoId, 'create', newTodo);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'todo',
        'entity_id': todoId,
        'action_type': 'created',
        'activity_message': "Created todo '${request.title}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return TodoDto.fromJson(newTodo);
  }

  @override
  Future<List<TodoDto>> getTodos({
    String? status,
    String? priority,
    String? q,
  }) async {
    final db = _dbHelper.database;
    
    String query = 'SELECT * FROM todos WHERE user_id = ?';
    final List<dynamic> args = [_dbHelper.currentUserId ?? ''];

    if (status != null) {
      query += ' AND status = ?';
      args.add(status);
    }
    if (priority != null) {
      query += ' AND priority = ?';
      args.add(priority);
    }
    if (q != null && q.isNotEmpty) {
      query += ' AND title LIKE ?';
      args.add('%$q%');
    }

    query += ' ORDER BY created_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => TodoDto.fromJson(maps[i]));
  }

  @override
  Future<TodoDto> getTodo(String todoId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
    if (maps.isEmpty) {
      throw Exception("Todo with ID $todoId not found");
    }
    return TodoDto.fromJson(maps.first);
  }

  @override
  Future<TodoDto> updateTodo(String todoId, TodoUpdateRequest request) async {
    final db = _dbHelper.database;
    final todo = await getTodo(todoId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.title != null) updates['title'] = request.title;
    if (request.priority != null) updates['priority'] = request.priority;
    if (request.status != null) {
      updates['status'] = request.status;
      if (request.status == 'completed' && todo.status != 'completed') {
        updates['completed_at'] = nowStr;
      } else if (request.status == 'pending') {
        updates['completed_at'] = null;
      }
    }
    if (request.dueDatetime != null) {
      updates['due_datetime'] = request.dueDatetime!.toIso8601String();
    }

    await db.transaction((txn) async {
      await txn.update(
        'todos',
        updates,
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'todos',
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'todo', todoId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'todo',
        'entity_id': todoId,
        'action_type': 'updated',
        'activity_message': "Updated todo '${request.title ?? todo.title}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'todos',
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
    return TodoDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteTodo(String todoId) async {
    final db = _dbHelper.database;
    final todo = await getTodo(todoId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'todos',
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );

      await _dbHelper.enqueueOperation(txn, 'todo', todoId, 'delete', null);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'todo',
        'entity_id': todoId,
        'action_type': 'deleted',
        'activity_message': "Deleted todo '${todo.title}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }
}
