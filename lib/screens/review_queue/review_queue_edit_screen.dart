import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/review_queue/review_queue_dto.dart';
import '../../data/repositories/review_queue_repository.dart';

class ReviewQueueEditScreen extends StatefulWidget {
  final ReviewQueueDto item;
  const ReviewQueueEditScreen({super.key, required this.item});

  @override
  State<ReviewQueueEditScreen> createState() => _ReviewQueueEditScreenState();
}

class _ReviewQueueEditScreenState extends State<ReviewQueueEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReviewQueueRepository _repository = ReviewQueueRepository();
  bool _isLoading = false;

  // Finance Form State
  late TextEditingController _financeDescController;
  late TextEditingController _financeAmountController;
  String _selectedCategory = 'Other';
  String _selectedAccount = 'UPI';

  // Todo Form State
  late TextEditingController _todoTitleController;
  String _selectedTodoCategory = 'Academic';
  String _selectedTodoPriority = 'Medium';
  String _selectedTodoStatus = 'Pending';

  // Cancellation / Attendance Form State
  bool _confirmCancel = true;

  @override
  void initState() {
    super.initState();
    // Initialize state depending on item type
    if (widget.item.entityType == 'finance') {
      _financeDescController = TextEditingController(text: widget.item.reviewMessage);
      _financeAmountController = TextEditingController(text: '0.00');
    } else if (widget.item.entityType == 'todo') {
      _todoTitleController = TextEditingController(text: widget.item.reviewMessage);
    }
  }

  @override
  void dispose() {
    if (widget.item.entityType == 'finance') {
      _financeDescController.dispose();
      _financeAmountController.dispose();
    } else if (widget.item.entityType == 'todo') {
      _todoTitleController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveResolution() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> resolutionData = {};
    if (widget.item.entityType == 'finance') {
      resolutionData = {
        'description': _financeDescController.text.trim(),
        'amount': double.tryParse(_financeAmountController.text) ?? 0.0,
        'category': _selectedCategory.toLowerCase(),
        'account': _selectedAccount.toLowerCase(),
      };
    } else if (widget.item.entityType == 'todo') {
      resolutionData = {
        'title': _todoTitleController.text.trim(),
        'category': _selectedTodoCategory.toLowerCase(),
        'priority': _selectedTodoPriority.toLowerCase(),
        'status': _selectedTodoStatus.toLowerCase(),
      };
    } else {
      resolutionData = {
        'status': _confirmCancel ? 'cancelled' : 'attended',
      };
    }

    setState(() => _isLoading = true);

    try {
      await _repository.resolveReviewQueueItem(
        widget.item.reviewId,
        ReviewQueueResolveRequest(
          resolutionData: resolutionData,
          resolvedBy: 'user',
        ),
      );
      if (mounted) {
        AppSnackbar.success(context, 'Review item resolved!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to resolve item: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Review Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card about what is being reviewed
              Card(
                color: cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ENTITY TYPE: ${widget.item.entityType.toUpperCase()}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            widget.item.reviewStatus.toUpperCase(),
                            style: TextStyle(
                              color: widget.item.reviewStatus == 'pending' ? AppTheme.warning : AppTheme.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.reviewMessage,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (widget.item.entitySummary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.item.entitySummary,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'RESOLVE DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Render correct fields
              if (widget.item.entityType == 'finance') _buildFinanceFields(isDark),
              if (widget.item.entityType == 'todo') _buildTodoFields(isDark),
              if (widget.item.entityType != 'finance' && widget.item.entityType != 'todo') _buildCancellationFields(isDark),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: borderColor),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _saveResolution,
                      child: const Text('Save & Resolve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _financeDescController,
          label: 'Description',
          icon: Icons.description_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _financeAmountController,
          label: 'Amount (₹)',
          icon: Icons.attach_money_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (double.tryParse(v) == null) return 'Invalid amount';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Category',
          value: _selectedCategory,
          items: ['Academic', 'Personal', 'Event', 'Project', 'Finance', 'Other'],
          onChanged: (val) => setState(() => _selectedCategory = val!),
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Source Account',
          value: _selectedAccount,
          items: ['UPI', 'Cash', 'Bank'],
          onChanged: (val) => setState(() => _selectedAccount = val!),
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  Widget _buildTodoFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _todoTitleController,
          label: 'Title',
          icon: Icons.title_rounded,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Category',
          value: _selectedTodoCategory,
          items: ['Academic', 'Personal', 'Work', 'Health', 'Other'],
          onChanged: (val) => setState(() => _selectedTodoCategory = val!),
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Priority',
          value: _selectedTodoPriority,
          items: ['Low', 'Medium', 'High'],
          onChanged: (val) => setState(() => _selectedTodoPriority = val!),
          icon: Icons.priority_high_rounded,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Status',
          value: _selectedTodoStatus,
          items: ['Pending', 'Completed'],
          onChanged: (val) => setState(() => _selectedTodoStatus = val!),
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildCancellationFields(bool isDark) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkTheme ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.cancel_presentation_rounded, size: 20, color: AppTheme.danger),
                  SizedBox(width: 12),
                  Text(
                    'Confirm Cancellation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Switch(
                value: _confirmCancel,
                activeColor: AppTheme.danger,
                onChanged: (val) => setState(() => _confirmCancel = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}
