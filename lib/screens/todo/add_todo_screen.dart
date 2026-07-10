import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/todo/todo_dto.dart';
import '../../data/repositories/todo_repository.dart';

class AddTodoScreen extends StatefulWidget {
  final TodoDto? todoToEdit;
  const AddTodoScreen({super.key, this.todoToEdit});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final TodoRepository _todoRepository = TodoRepository();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPriority = 'Medium'; // Default

  // Collapsible section state
  bool _isAdvancedExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.todoToEdit != null) {
      final todo = widget.todoToEdit!;
      _titleController.text = todo.title;
      
      // Handle Priority
      final priority = todo.priority;
      if (['low', 'medium', 'high'].contains(priority.toLowerCase())) {
        _selectedPriority = priority[0].toUpperCase() + priority.substring(1).toLowerCase();
      }

      // Handle Time & Date
      _selectedDate = todo.dueDatetime;
      if (todo.dueDatetime != null) {
        _selectedTime = TimeOfDay.fromDateTime(todo.dueDatetime!);
      }
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: AppTheme.surface,
                    onSurface: AppTheme.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: AppTheme.surface,
                    onSurface: AppTheme.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final priorityToSave = _selectedPriority.toLowerCase();

    DateTime? dueDatetime;
    if (_selectedDate != null) {
      if (_selectedTime != null) {
        dueDatetime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else {
        dueDatetime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          12, // Default to noon
          0,
        );
      }
    }

    setState(() => _isLoading = true);

    try {
      if (widget.todoToEdit != null) {
        await _todoRepository.updateTodo(
          widget.todoToEdit!.todoId,
          TodoUpdateRequest(
            title: _titleController.text.trim(),
            priority: priorityToSave,
            dueDatetime: dueDatetime,
          ),
        );
      } else {
        await _todoRepository.createTodo(
          TodoCreateRequest(
            title: _titleController.text.trim(),
            priority: priorityToSave,
            dueDatetime: dueDatetime,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to save task: $e');
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.todoToEdit != null ? 'Edit To Do' : 'Add To Do'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todoToEdit != null ? 'Edit To Do' : 'Add To Do'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Task Title',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const Text(' *', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter task description or name...',
                          hintStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Task title is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Priority Selector Card (Shifted Above Due Schedule)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Task Priority',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: ['Low', 'Medium', 'High'].map((priority) {
                          final color = _getPriorityColor(priority);
                          final isSelected = _selectedPriority == priority;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPriority = priority;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? color : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 6,
                                          color: color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          priority,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected
                                                ? (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)
                                                : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Due Date & Time Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Due Schedule',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedDate != null || _selectedTime != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = null;
                                  _selectedTime = null;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Date Button
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedDate != null
                                        ? AppTheme.primary.withOpacity(0.5)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                      color: _selectedDate != null ? AppTheme.primary : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _selectedDate == null
                                            ? 'Select Date'
                                            : _formatDateForDisplay(_selectedDate!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                                          color: _selectedDate == null
                                              ? (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted)
                                              : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time Button
                          Expanded(
                            child: InkWell(
                              onTap: _selectedDate == null
                                  ? () {
                                      AppSnackbar.warning(context, 'Please select a date first');
                                    }
                                  : () => _selectTime(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedTime != null
                                        ? AppTheme.primary.withOpacity(0.5)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: _selectedTime != null ? AppTheme.primary : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _selectedTime == null
                                            ? 'Select Time'
                                            : _formatTimeOfDay(_selectedTime!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _selectedTime != null ? FontWeight.bold : FontWeight.normal,
                                          color: _selectedTime == null
                                              ? (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted)
                                              : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Collapsible Advanced section
              Card(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isAdvancedExpanded = !_isAdvancedExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.settings_suggest_rounded, color: AppTheme.secondary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Advanced (Future Features)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isAdvancedExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isAdvancedExpanded)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                        child: Opacity(
                          opacity: 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Repeat Task Switch
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.sync_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Repeat Task',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: false,
                                      onChanged: null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Created By Dropdown
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.psychology_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Created By',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Manual',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.lock_rounded, size: 10, color: AppTheme.textMuted),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    widget.todoToEdit != null ? 'Save Changes' : 'Create To Do',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
