import '../dto/todo/todo_dto.dart';
import 'sqlite/sqlite_todo_repository.dart';

abstract class TodoRepository {
  factory TodoRepository() => SqliteTodoRepository();

  Future<TodoDto> createTodo(TodoCreateRequest request);
  Future<List<TodoDto>> getTodos({
    String? status,
    String? priority,
    String? q,
  });
  Future<TodoDto> getTodo(String todoId);
  Future<TodoDto> updateTodo(String todoId, TodoUpdateRequest request);
  Future<void> deleteTodo(String todoId);
}
