import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';

class ReviewQueueEditScreen extends StatefulWidget {
  final ReviewItemMock item;
  const ReviewQueueEditScreen({super.key, required this.item});

  @override
  State<ReviewQueueEditScreen> createState() => _ReviewQueueEditScreenState();
}

class _ReviewQueueEditScreenState extends State<ReviewQueueEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Finance Form State
  late TextEditingController _financeDescController;
  late TextEditingController _financeAmountController;
  String _selectedCategory = 'Other';
  String _selectedAccount = 'UPI';

  // OCR Form State
  late TextEditingController _ocrSubjectController;
  String _selectedOcrDay = 'Friday';
  late TextEditingController _ocrStartTimeController;
  late TextEditingController _ocrEndTimeController;
  late TextEditingController _ocrRoomController;

  // Cancellation Form State
  String _selectedCancelClass = 'DBMS';
  bool _confirmCancel = true;

  @override
  void initState() {
    super.initState();
    // Initialize state depending on item type
    if (widget.item.id == 'rev1') {
      _financeDescController = TextEditingController(text: 'Dinner with friends');
      _financeAmountController = TextEditingController(text: '500.00');
    } else if (widget.item.id == 'rev2') {
      _ocrSubjectController = TextEditingController(text: 'DAA Lab');
      _ocrStartTimeController = TextEditingController(text: '14:00');
      _ocrEndTimeController = TextEditingController(text: '16:00');
      _ocrRoomController = TextEditingController(text: 'Lab 2');
    }
  }

  @override
  void dispose() {
    if (widget.item.id == 'rev1') {
      _financeDescController.dispose();
      _financeAmountController.dispose();
    } else if (widget.item.id == 'rev2') {
      _ocrSubjectController.dispose();
      _ocrStartTimeController.dispose();
      _ocrEndTimeController.dispose();
      _ocrRoomController.dispose();
    }
    super.dispose();
  }

  void _saveResolution() {
    if (!_formKey.currentState!.validate()) return;

    String msg = '';
    if (widget.item.id == 'rev1') {
      msg = 'Expense of ₹${_financeAmountController.text} saved under Category "$_selectedCategory" (${_selectedAccount})';
    } else if (widget.item.id == 'rev2') {
      msg = 'Timetable updated: ${_ocrSubjectController.text} on $_selectedOcrDay at ${_ocrStartTimeController.text} in Room ${_ocrRoomController.text}';
    } else if (widget.item.id == 'rev3') {
      msg = 'Class ${_selectedCancelClass} marked as ${(_confirmCancel ? "CANCELLED" : "ACTIVE")}';
    }

    AppSnackbar.success(context, msg);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

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
                            'SOURCE: ${widget.item.source.toUpperCase()}',
                            style: TextStyle(
                              color: widget.item.source.toLowerCase() == 'whatsapp' ? const Color(0xFF10B981) : AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            widget.item.dateString,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
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
              if (widget.item.id == 'rev1') _buildFinanceFields(isDark),
              if (widget.item.id == 'rev2') _buildOcrFields(isDark),
              if (widget.item.id == 'rev3') _buildCancellationFields(isDark),

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

  Widget _buildOcrFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _ocrSubjectController,
          label: 'Subject Name',
          icon: Icons.book_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Day of Week',
          value: _selectedOcrDay,
          items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
          onChanged: (val) => setState(() => _selectedOcrDay = val!),
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ocrStartTimeController,
                label: 'Start Time',
                icon: Icons.access_time,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _ocrEndTimeController,
                label: 'End Time',
                icon: Icons.access_time,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ocrRoomController,
          label: 'Room Number',
          icon: Icons.meeting_room_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildCancellationFields(bool isDark) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildDropdown(
          label: 'Select Class',
          value: _selectedCancelClass,
          items: ['DBMS', 'DAA', 'OS', 'CN'],
          onChanged: (val) => setState(() => _selectedCancelClass = val!),
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
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
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
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
