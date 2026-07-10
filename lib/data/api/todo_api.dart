import '../../core/network/base_api.dart';
import '../../core/network/api_response.dart';
import '../dto/todo/todo_dto.dart';

class TodoApi extends BaseApi {
  Future<ApiResponse<TodoDto>> createTodo(TodoCreateRequest request) async {
    return post<TodoDto>(
      '/todos',
      data: request.toJson(),
      parser: (json) => TodoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<TodoDto>>> getTodos({
    String? status,
    String? priority,
    String? q,
  }) async {
    final Map<String, dynamic> params = {};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (q != null) params['q'] = q;

    return get<List<TodoDto>>(
      '/todos',
      queryParameters: params,
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => TodoDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<TodoDto>> getTodo(String todoId) async {
    return get<TodoDto>(
      '/todos/$todoId',
      parser: (json) => TodoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<TodoDto>> updateTodo(String todoId, TodoUpdateRequest request) async {
    return put<TodoDto>(
      '/todos/$todoId',
      data: request.toJson(),
      parser: (json) => TodoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteTodo(String todoId) async {
    return delete('/todos/$todoId');
  }
}
