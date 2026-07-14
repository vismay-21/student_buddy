import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/todo/todo_dto.dart';
import '../../data/repositories/todo_repository.dart';
import 'add_todo_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TodoRepository _todoRepository = TodoRepository();
  
  List<TodoDto> _todoItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTodos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    if (_todoItems.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final items = await _todoRepository.getTodos();
      setState(() {
        _todoItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackbar.error(context, 'Failed to load tasks: $e');
      }
    }
  }

  Future<void> _toggleTodoCompletion(TodoDto todo) async {
    final newStatus = todo.status == 'completed' ? 'pending' : 'completed';
    try {
      await _todoRepository.updateTodo(
        todo.todoId,
        TodoUpdateRequest(status: newStatus),
      );
      _loadTodos();
      if (mounted) {
        AppSnackbar.success(context, 'Task marked as $newStatus');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update task status: $e');
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.danger;
      case 'medium':
        return AppTheme.warning;
      case 'low':
      default:
        return AppTheme.accent;
    }
  }

  Future<void> _navigateToAddTodo() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );

    if (result == true) {
      _loadTodos();
    }
  }

  Future<void> _navigateToEditTodo(TodoDto todoItem) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => AddTodoScreen(todoToEdit: todoItem)),
    );

    if (result == true) {
      _loadTodos();
    }
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selected = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (selected == today) {
      dateStr = 'Today';
    } else if (selected == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = DateFormat('EEE, d MMM').format(date);
    }

    final timeStr = DateFormat('h:mm a').format(date.toLocal());
    return '$dateStr, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pending = _todoItems.where((a) => a.status != 'completed').toList();
    final completed = _todoItems.where((a) => a.status == 'completed').toList();

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Completed (${completed.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(pending, isPending: true),
                _buildTodoList(completed, isPending: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTodo,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodoList(List<TodoDto> list, {required bool isPending}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline_rounded : Icons.assignment_turned_in_outlined,
              size: 64,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending tasks!' : 'No completed tasks yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPending ? 'Great job staying on top of things!' : 'Check off tasks to complete them.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final todoItem = list[index];
        final isCompleted = todoItem.status == 'completed';
        final loadColor = _getPriorityColor(todoItem.priority);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Completed Checkbox
                Checkbox(
                  activeColor: AppTheme.primary,
                  checkColor: Colors.white,
                  value: isCompleted,
                  onChanged: (_) => _toggleTodoCompletion(todoItem),
                ),
                const SizedBox(width: 8),
                
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToEditTodo(todoItem),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todoItem.title,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Due Date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: isPending ? AppTheme.warning : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDueDate(todoItem.dueDatetime),
                                      style: TextStyle(
                                        color: isPending ? AppTheme.warning : AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Cognitive Load Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: loadColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: loadColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              todoItem.priority[0].toUpperCase() + todoItem.priority.substring(1),
                              style: TextStyle(
                                color: loadColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
