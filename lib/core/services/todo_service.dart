import '../../data/dto/todo/todo_dto.dart';
import '../../data/repositories/todo_repository.dart';

class TodoService {
  final TodoRepository _repository = TodoRepository();

  Future<TodoDto> createTodo(TodoCreateRequest request) => _repository.createTodo(request);
  
  Future<List<TodoDto>> getTodos({
    String? status,
    String? priority,
    String? q,
  }) => _repository.getTodos(status: status, priority: priority, q: q);
  
  Future<TodoDto> getTodo(String todoId) => _repository.getTodo(todoId);
  
  Future<TodoDto> updateTodo(String todoId, TodoUpdateRequest request) => _repository.updateTodo(todoId, request);
  
  Future<void> deleteTodo(String todoId) => _repository.deleteTodo(todoId);
}
