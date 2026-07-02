import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';
import 'review_queue_edit_screen.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  // Local list to simulate queue operations
  late List<ReviewItemMock> _localQueue;

  @override
  void initState() {
    super.initState();
    _localQueue = List.from(DummyData.reviewQueue);
  }

  void _approveItem(ReviewItemMock item) {
    setState(() {
      _localQueue.removeWhere((x) => x.id == item.id);
      DummyData.reviewQueue.removeWhere((x) => x.id == item.id);
    });

    String msg = 'Item approved successfully!';
    if (item.id == 'rev1') {
      msg = 'Approved expense: Category set to "Other", Account set to "UPI"';
    } else if (item.id == 'rev2') {
      msg = 'Approved OCR Timetable: DAA Lab added to Friday';
    } else if (item.id == 'rev3') {
      msg = 'DBMS class cancellation confirmed';
    }

    AppSnackbar.success(context, msg);
  }

  void _editItem(ReviewItemMock item) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewQueueEditScreen(item: item),
      ),
    );

    if (result == true) {
      setState(() {
        _localQueue.removeWhere((x) => x.id == item.id);
        DummyData.reviewQueue.removeWhere((x) => x.id == item.id);
      });
    }
  }

  Color _getSourceColor(String source) {
    return source.toLowerCase() == 'whatsapp' ? const Color(0xFF10B981) : AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Queue (${_localQueue.length})'),
      ),
      body: _localQueue.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.done_all_rounded, size: 64, color: AppTheme.accent),
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _localQueue.length,
              itemBuilder: (context, index) {
                final item = _localQueue[index];
                final sourceColor = _getSourceColor(item.source);

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
                                color: sourceColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.source.toUpperCase(),
                                style: TextStyle(
                                  color: sourceColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              item.dateString,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Description
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF1E293B)),
                        const SizedBox(height: 10),

                        // Details grid/table
                        Column(
                          children: item.details.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      '${entry.key}:',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF1E293B)),
                        const SizedBox(height: 8),

                        // Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _editItem(item),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(foregroundColor: AppTheme.warning),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _approveItem(item),
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
            ),
    );
  }
}
