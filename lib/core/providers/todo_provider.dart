import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/todo/todo_dto.dart';
import 'common_providers.dart';

// ==========================================
// 1. Todos List Provider (Read-Only)
// ==========================================
class TodosNotifier extends AsyncNotifier<List<TodoDto>> {
  @override
  Future<List<TodoDto>> build() async {
    final service = ref.watch(todoServiceProvider);
    return service.getTodos();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return ref.read(todoServiceProvider).getTodos();
    });
  }

  void addOptimistic(TodoDto todo) {
    if (state.value != null) {
      state = AsyncValue.data([...state.value!, todo]);
    }
  }

  void updateOptimistic(String id, TodoDto updated) {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.map((t) => t.todoId == id ? updated : t).toList(),
      );
    }
  }

  void deleteOptimistic(String id) {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.where((t) => t.todoId != id).toList(),
      );
    }
  }

  void setList(List<TodoDto> list) {
    state = AsyncValue.data(list);
  }
}

final todosProvider = AsyncNotifierProvider<TodosNotifier, List<TodoDto>>(TodosNotifier.new);

// ==========================================
// 2. Todo Actions Provider
// ==========================================
class TodoActions {
  final Ref _ref;
  TodoActions(this._ref);

  Future<TodoDto> createTodo(TodoCreateRequest request) async {
    final service = _ref.read(todoServiceProvider);

    // Generate optimistic temp Todo
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempTodo = TodoDto(
      todoId: tempId,
      title: request.title,
      priority: request.priority,
      status: request.status,
      dueDatetime: request.dueDatetime,
      createdBy: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Optimistic Add
    _ref.read(todosProvider.notifier).addOptimistic(tempTodo);

    try {
      final realTodo = await service.createTodo(request);

      // 2. Replace optimistic item with real item
      final currentList = _ref.read(todosProvider).value ?? [];
      final newList = currentList.map((t) => t.todoId == tempId ? realTodo : t).toList();
      _ref.read(todosProvider.notifier).setList(newList);

      // Trigger sync
      _ref.read(syncServiceProvider).sync();

      return realTodo;
    } catch (e) {
      // 3. Rollback
      _ref.read(todosProvider.notifier).refresh();
      rethrow;
    }
  }

  Future<TodoDto> updateTodo(String todoId, TodoUpdateRequest request) async {
    final service = _ref.read(todoServiceProvider);

    // Get existing to construct optimistic update
    final currentList = _ref.read(todosProvider).value ?? [];
    final originalIndex = currentList.indexWhere((t) => t.todoId == todoId);
    if (originalIndex == -1) {
      throw StateError('Todo with ID $todoId not found.');
    }
    final original = currentList[originalIndex];
    final optimistic = original.copyWith(
      title: request.title ?? original.title,
      priority: request.priority ?? original.priority,
      status: request.status ?? original.status,
      dueDatetime: request.dueDatetime ?? original.dueDatetime,
    );

    // 1. Optimistic Update
    _ref.read(todosProvider.notifier).updateOptimistic(todoId, optimistic);

    try {
      final result = await service.updateTodo(todoId, request);

      // Trigger sync
      _ref.read(syncServiceProvider).sync();

      return result;
    } catch (e) {
      // 2. Rollback
      _ref.read(todosProvider.notifier).refresh();
      rethrow;
    }
  }

  Future<void> toggleTodo(TodoDto todo) async {
    final nextStatus = todo.status == 'completed' ? 'pending' : 'completed';
    await updateTodo(
      todo.todoId,
      TodoUpdateRequest(status: nextStatus),
    );
  }

  Future<void> deleteTodo(String todoId) async {
    final service = _ref.read(todoServiceProvider);

    // 1. Optimistic Delete
    _ref.read(todosProvider.notifier).deleteOptimistic(todoId);

    try {
      await service.deleteTodo(todoId);

      // Trigger sync
      _ref.read(syncServiceProvider).sync();
    } catch (e) {
      // 2. Rollback
      _ref.read(todosProvider.notifier).refresh();
      rethrow;
    }
  }
}

final todoActionsProvider = Provider<TodoActions>((ref) => TodoActions(ref));
