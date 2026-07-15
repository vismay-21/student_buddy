import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/review_queue/review_queue_dto.dart';
import '../../core/providers/review_queue_provider.dart';
import 'review_queue_edit_screen.dart';

class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'missing_information':
        return AppTheme.warning;
      case 'confirmation_required':
        return AppTheme.accent;
      case 'manual_review':
      default:
        return AppTheme.primary;
    }
  }

  String _formatType(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(pendingReviewQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: queueAsync.maybeWhen(
          data: (items) => Text('Review Queue (${items.length})'),
          orElse: () => const Text('Review Queue'),
        ),
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load review items: $err')),
        data: (queueItems) {
          if (queueItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.done_all_rounded, size: 64, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Clear!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No ambiguous data needs manual review.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: queueItems.length,
            itemBuilder: (context, index) {
              final item = queueItems[index];
              final typeColor = _getTypeColor(item.reviewType);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatType(item.reviewType),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, h:mm a').format(item.createdAt.toLocal()),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Description/Message
                      Text(
                        item.reviewMessage,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      if (item.entitySummary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.entitySummary,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF1E293B)),
                      const SizedBox(height: 8),

                      // Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final bool? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewQueueEditScreen(item: item),
                                ),
                              );
                              if (result == true) {
                                ref.invalidate(pendingReviewQueueProvider);
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.warning),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await ref.read(reviewQueueActionsProvider).resolveItem(
                                      item.reviewId,
                                      ReviewQueueResolveRequest(
                                        resolutionData: {},
                                        resolvedBy: 'user',
                                      ),
                                    );
                                if (context.mounted) {
                                  AppSnackbar.success(context, 'Item approved successfully!');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackbar.error(context, 'Failed to approve item: $e');
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent.withOpacity(0.12),
                              foregroundColor: AppTheme.accent,
                              elevation: 0,
                              side: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
