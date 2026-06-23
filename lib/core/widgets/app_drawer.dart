import 'package:flutter/material.dart';
import '../../screens/assignments/assignments_screen.dart';
import '../../screens/notes/notes_screen.dart';
import '../../screens/review_queue/review_queue_screen.dart';
import '../theme/app_theme.dart';
import '../utils/dummy_data.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Get count of items in review queue to show on the badge
    final int reviewCount = DummyData.reviewQueue.length;
    final int pendingAssignments = DummyData.assignments.where((a) => !a.isCompleted).length;

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STUDENT BUDDY',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Internal Assistant',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Items
            _buildDrawerItem(
              context: context,
              icon: Icons.assignment_rounded,
              title: 'Assignments Tracker',
              subtitle: 'Due dates & submission statuses',
              badgeCount: pendingAssignments,
              badgeColor: AppTheme.secondary,
              destination: const AssignmentsScreen(),
            ),
            
            _buildDrawerItem(
              context: context,
              icon: Icons.folder_shared_rounded,
              title: 'Notes Repository',
              subtitle: 'Semester lectures, PDFs & slides',
              destination: const NotesScreen(),
            ),

            _buildDrawerItem(
              context: context,
              icon: Icons.rate_review_rounded,
              title: 'Review Queue',
              subtitle: 'Verify chatbot & OCR ambiguities',
              badgeCount: reviewCount,
              badgeColor: AppTheme.danger,
              destination: const ReviewQueueScreen(),
            ),

            const Spacer(),

            // Footer Information
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student Buddy v1.0.0',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FRONTEND ONLY',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    int badgeCount = 0,
    Color? badgeColor,
    required Widget destination,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor ?? AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
      onTap: () {
        // Close the drawer first
        Navigator.of(context).pop();
        
        // Push the screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }
}
