import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';

class AddTodoScreen extends StatefulWidget {
  final TodoMock? todoToEdit;
  const AddTodoScreen({super.key, this.todoToEdit});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final List<String> _categories = ['Academic', 'Personal', 'Event', 'Project', 'Finance', 'Other'];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPriority = 'Medium'; // Default
  String _selectedCategory = 'Academic'; // Default

  // Collapsible section state
  bool _isAdvancedExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.todoToEdit != null) {
      final todo = widget.todoToEdit!;
      _titleController.text = todo.title;
      
      // Handle Priority
      final priority = todo.cognitiveLoad;
      if (['low', 'medium', 'high'].contains(priority.toLowerCase())) {
        _selectedPriority = priority[0].toUpperCase() + priority.substring(1).toLowerCase();
      }

      // Handle Category
      if (_categories.contains(todo.subject)) {
        _selectedCategory = todo.subject;
      } else {
        // If custom category, insert before 'Other'
        final otherIndex = _categories.indexOf('Other');
        if (otherIndex != -1) {
          _categories.insert(otherIndex, todo.subject);
        } else {
          _categories.add(todo.subject);
        }
        _selectedCategory = todo.subject;
      }

      // Handle Time & Date parsing
      if (todo.dueTime != null) {
        _selectedTime = _parseTimeOfDay(todo.dueTime!);
      }
      _selectedDate = _parseDueDateString(todo.dueDateString);
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length < 2) return null;
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts[1].toLowerCase() == 'pm';
      if (isPm && hour != 12) {
        hour += 12;
      } else if (!isPm && hour == 12) {
        hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDueDateString(String dateStr) {
    if (dateStr.toLowerCase() == 'no due date') return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (dateStr.startsWith('Today')) return today;
    if (dateStr.startsWith('Tomorrow')) return today.add(const Duration(days: 1));

    try {
      final parts = dateStr.split(',');
      if (parts.length < 2) return null;
      final datePart = parts[1].trim();
      final dateSubParts = datePart.split(' ');
      if (dateSubParts.length < 2) return null;
      final day = int.parse(dateSubParts[0]);
      final monthStr = dateSubParts[1].toLowerCase();

      final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final monthIndex = months.indexOf(monthStr.substring(0, 3));
      if (monthIndex == -1) return null;

      return DateTime(now.year, monthIndex + 1, day);
    } catch (_) {
      return null;
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Category name...',
              hintStyle: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    if (!_categories.contains(text)) {
                      final otherIndex = _categories.indexOf('Other');
                      if (otherIndex != -1) {
                        _categories.insert(otherIndex, text);
                      } else {
                        _categories.add(text);
                      }
                    }
                    _selectedCategory = text;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Delete Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete the "$category" category?',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _categories.remove(category);
                  if (_selectedCategory == category) {
                    _selectedCategory = 'Other';
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _titleController.dispose();
    _customCategoryController.dispose();
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

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Format final due date string (optional)
    String finalDueDate = 'No due date';
    if (_selectedDate != null) {
      finalDueDate = _formatDateForDisplay(_selectedDate!);
      if (_selectedTime != null) {
        finalDueDate += ', ${_formatTimeOfDay(_selectedTime!)}';
      }
    }

    final String categoryToSave = _selectedCategory == 'Other'
        ? (_customCategoryController.text.trim().isNotEmpty ? _customCategoryController.text.trim() : 'Other')
        : _selectedCategory;

    final newTodo = TodoMock(
      id: widget.todoToEdit?.id ?? 'todo_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subject: categoryToSave,
      dueDateString: finalDueDate,
      cognitiveLoad: _selectedPriority,
      isCompleted: widget.todoToEdit?.isCompleted ?? false,
      description: null, // Description removed completely
      dueTime: _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : null,
      repeatTask: false, // Default placeholder state
      createdBy: widget.todoToEdit?.createdBy ?? 'Manual', // Default placeholder state
    );

    Navigator.of(context).pop(newTodo);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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

              // Category Selector Card
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
                              const Icon(Icons.folder_open_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showAddCategoryDialog,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
                                  SizedBox(width: 2),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          final canDelete = category != 'Other';

                          return GestureDetector(
                            onLongPress: canDelete ? () => _confirmDeleteCategory(category) : null,
                            child: ChoiceChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primary,
                              backgroundColor: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
                              checkmarkColor: Colors.white,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedCategory == 'Other') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _customCategoryController,
                          style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter custom category...',
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
                            if (_selectedCategory == 'Other' && (value == null || value.trim().isEmpty)) {
                              return 'Custom category is required';
                            }
                            return null;
                          },
                        ),
                      ],
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
