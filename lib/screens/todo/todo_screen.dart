import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';
import 'add_todo_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Local state to simulate toggling completion status
  late List<TodoMock> _localTodoItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _localTodoItems = List.from(DummyData.todoItems);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTodoCompletion(String id) {
    setState(() {
      final index = _localTodoItems.indexWhere((a) => a.id == id);
      if (index != -1) {
        final current = _localTodoItems[index];
        _localTodoItems[index] = TodoMock(
          id: current.id,
          title: current.title,
          subject: current.subject,
          dueDateString: current.dueDateString,
          cognitiveLoad: current.cognitiveLoad,
          isCompleted: !current.isCompleted,
        );
      }
    });

    AppSnackbar.success(context, 'Task status updated! (Mock Simulation)');
  }

  Color _getCognitiveColor(String load) {
    switch (load.toLowerCase()) {
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
    final result = await Navigator.of(context).push<TodoMock>(
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );

    if (result != null) {
      setState(() {
        _localTodoItems.insert(0, result);
      });
    }
  }

  Future<void> _navigateToEditTodo(TodoMock todoItem) async {
    final result = await Navigator.of(context).push<TodoMock>(
      MaterialPageRoute(builder: (context) => AddTodoScreen(todoToEdit: todoItem)),
    );

    if (result != null) {
      setState(() {
        final index = _localTodoItems.indexWhere((a) => a.id == todoItem.id);
        if (index != -1) {
          _localTodoItems[index] = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _localTodoItems.where((a) => !a.isCompleted).toList();
    final completed = _localTodoItems.where((a) => a.isCompleted).toList();

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

  Widget _buildTodoList(List<TodoMock> list, {required bool isPending}) {
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
        final loadColor = _getCognitiveColor(todoItem.cognitiveLoad);

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
                  value: todoItem.isCompleted,
                  onChanged: (_) => _toggleTodoCompletion(todoItem.id),
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
                                    decoration: todoItem.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  todoItem.subject,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
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
                                      todoItem.dueDateString,
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
                              '${todoItem.cognitiveLoad} Load',
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
