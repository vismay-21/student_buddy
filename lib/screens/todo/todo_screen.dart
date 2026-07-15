import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/todo/todo_dto.dart';
import '../../core/providers/todo_provider.dart';
import 'add_todo_screen.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleTodoCompletion(TodoDto todo) async {
    try {
      await ref.read(todoActionsProvider).toggleTodo(todo);
      if (mounted) {
        final nextStatus = todo.status == 'completed' ? 'pending' : 'completed';
        AppSnackbar.success(context, 'Task marked as $nextStatus');
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

  void _navigateToAddTodo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );
  }

  void _navigateToEditTodo(TodoDto todoItem) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddTodoScreen(todoToEdit: todoItem)),
    );
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
    final todosAsync = ref.watch(todosProvider);

    return todosAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading tasks: $err')),
      ),
      data: (todos) {
        final pending = todos.where((a) => a.status != 'completed').toList();
        final completed = todos.where((a) => a.status == 'completed').toList();

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
      },
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
