import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Local state to simulate toggling completion status
  late List<AssignmentMock> _localAssignments;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _localAssignments = List.from(DummyData.assignments);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleAssignmentCompletion(String id) {
    setState(() {
      final index = _localAssignments.indexWhere((a) => a.id == id);
      if (index != -1) {
        final current = _localAssignments[index];
        _localAssignments[index] = AssignmentMock(
          id: current.id,
          title: current.title,
          subject: current.subject,
          dueDateString: current.dueDateString,
          cognitiveLoad: current.cognitiveLoad,
          isCompleted: !current.isCompleted,
        );
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 1),
        content: Text('Assignment status updated! (Mock Simulation)'),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final pending = _localAssignments.where((a) => !a.isCompleted).toList();
    final completed = _localAssignments.where((a) => a.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments Tracker'),
        bottom: TabBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentsList(pending, isPending: true),
          _buildAssignmentsList(completed, isPending: false),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(List<AssignmentMock> list, {required bool isPending}) {
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
              isPending ? 'No pending assignments!' : 'No completed assignments yet',
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
        final asg = list[index];
        final loadColor = _getCognitiveColor(asg.cognitiveLoad);

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
                  value: asg.isCompleted,
                  onChanged: (_) => _toggleAssignmentCompletion(asg.id),
                ),
                const SizedBox(width: 8),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asg.title,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: asg.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asg.subject,
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
                            asg.dueDateString,
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
                    '${asg.cognitiveLoad} Load',
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
        );
      },
    );
  }
}
