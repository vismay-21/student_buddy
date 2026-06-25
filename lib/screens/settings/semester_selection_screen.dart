import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';

class SemesterSelectionScreen extends StatefulWidget {
  const SemesterSelectionScreen({super.key});

  @override
  State<SemesterSelectionScreen> createState() => _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  late String _selectedSemester;

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSemester = AppState.instance.activeSemester.value;
  }

  void _applySelection() {
    AppState.instance.activeSemester.value = _selectedSemester;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.accent,
        content: Text('Active semester changed to $_selectedSemester!'),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Semester'),
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

              // Semesters list
              Expanded(
                child: ListView.builder(
                  itemCount: _semesters.length,
                  itemBuilder: (context, index) {
                    final sem = _semesters[index];
                    final isSelected = _selectedSemester == sem;

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
                                Text(
                                  sem,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
                ),
              ),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _applySelection,
                  child: const Text('Apply Selection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
