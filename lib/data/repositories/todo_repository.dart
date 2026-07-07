import '../api/todo_api.dart';
import '../dto/todo/todo_dto.dart';

class TodoRepository {
  final TodoApi _api = TodoApi();

  Future<TodoDto> createTodo(TodoCreateRequest request) async {
    final response = await _api.createTodo(request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<List<TodoDto>> getTodos({
    String? status,
    String? category,
    String? priority,
    String? q,
  }) async {
    final response = await _api.getTodos(
      status: status,
      category: category,
      priority: priority,
      q: q,
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<TodoDto> getTodo(String todoId) async {
    final response = await _api.getTodo(todoId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<TodoDto> updateTodo(String todoId, TodoUpdateRequest request) async {
    final response = await _api.updateTodo(todoId, request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<void> deleteTodo(String todoId) async {
    final response = await _api.deleteTodo(todoId);
    if (!response.success) {
      throw Exception(response.message);
    }
  }
}
