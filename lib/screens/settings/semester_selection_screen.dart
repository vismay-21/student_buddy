import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../../data/dto/semester/semester_dto.dart';
import '../../core/providers/semester_provider.dart';

class SemesterSelectionScreen extends ConsumerStatefulWidget {
  const SemesterSelectionScreen({super.key});

  @override
  ConsumerState<SemesterSelectionScreen> createState() => _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends ConsumerState<SemesterSelectionScreen> {
  SemesterDto? _selectedSemester;
  bool _isInit = true;

  void _applySelection() {
    if (_selectedSemester != null) {
      ref.read(semesterActionsProvider).selectActiveSemester(_selectedSemester);
      AppSnackbar.success(context, 'Active semester changed to Semester ${_selectedSemester!.semesterNumber}!');
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAddSemesterDialog() async {
    final formKey = GlobalKey<FormState>();
    int? semesterNumber;
    DateTime? startDate = DateTime.now();
    DateTime? endDate = DateTime.now().add(const Duration(days: 180));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Semester'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Semester Number',
                          hintText: 'e.g. 5',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter semester number';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                        onSaved: (value) => semesterNumber = int.parse(value!),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start Date', style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Select Date',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                            });
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End Date', style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : 'Select Date',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now().add(const Duration(days: 180)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      if (startDate!.isAfter(endDate!)) {
                        AppSnackbar.warning(context, 'Start date must be before end date.');
                        return;
                      }

                      Navigator.of(context).pop(); // Close dialog

                      try {
                        final created = await ref.read(semesterActionsProvider).createSemester(
                              SemesterCreateRequest(
                                semesterNumber: semesterNumber!,
                                startDate: startDate!,
                                endDate: endDate!,
                              ),
                            );
                        if (context.mounted) {
                          AppSnackbar.success(context, 'Semester ${created.semesterNumber} created successfully!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackbar.error(context, 'Failed to create semester: $e');
                        }
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semestersProvider);
    final activeSem = ref.watch(activeSemesterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Semester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Semester',
            onPressed: _showAddSemesterDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Active Semester',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecting a semester changes the active lectures, attendance goals, tasks, and notes displayed across the entire app.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: semestersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Failed to load semesters: $err',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  data: (semesters) {
                    if (semesters.isEmpty) {
                      return const Center(
                        child: Text(
                          'No semesters available. Click "+" to add one!',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    if (_isInit) {
                      _selectedSemester = activeSem ?? semesters.first;
                      _isInit = false;
                    }

                    return ListView.builder(
                      itemCount: semesters.length,
                      itemBuilder: (context, index) {
                        final sem = semesters[index];
                        final isSelected = _selectedSemester?.semesterId == sem.semesterId;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSemester = sem;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : const Color(0xFF1E293B),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primary.withOpacity(0.12) : AppTheme.surfaceLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.school_rounded,
                                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Semester ${sem.semesterNumber}',
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormat('MMM yyyy').format(sem.startDate)} - ${DateFormat('MMM yyyy').format(sem.endDate)}',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Apply button
              semestersAsync.maybeWhen(
                data: (semesters) {
                  if (semesters.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _applySelection,
                      child: const Text('Apply Selection'),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
