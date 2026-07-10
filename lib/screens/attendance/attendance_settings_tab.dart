import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceSettingsTab extends StatelessWidget {
  final String criteriaMode; // 'overall', 'subject_wise', 'custom'
  final int targetPercentage;
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final List<Map<String, dynamic>> holidays;
  final Map<String, int> subjectCustomTargets;
  
  final Function(String mode) onCriteriaModeChanged;
  final Function(int percentage) onTargetPercentageChanged;
  final Function(DateTime date) onSemesterStartDateChanged;
  final Function(DateTime date) onSemesterEndDateChanged;
  final Function(String name, DateTime date) onHolidayAdded;
  final Function(String holidayId) onHolidayDeleted;
  final Function(String subjectName, int target) onSubjectCustomTargetChanged;

  const AttendanceSettingsTab({
    super.key,
    required this.criteriaMode,
    required this.targetPercentage,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.holidays,
    required this.subjectCustomTargets,
    required this.onCriteriaModeChanged,
    required this.onTargetPercentageChanged,
    required this.onSemesterStartDateChanged,
    required this.onSemesterEndDateChanged,
    required this.onHolidayAdded,
    required this.onHolidayDeleted,
    required this.onSubjectCustomTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Goal Section
            _buildSectionHeader('ATTENDANCE CRITERIA CONFIGURATION'),
            const SizedBox(height: 10),
            Card(
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Criteria Mode',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surface.withOpacity(0.5) : AppTheme.lightSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          // Overall Average Segment
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onCriteriaModeChanged('overall'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: criteriaMode == 'overall' ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Overall',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: criteriaMode == 'overall'
                                        ? Colors.white
                                        : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Subject-Wise Segment
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onCriteriaModeChanged('subject_wise'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: criteriaMode == 'subject_wise' ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Subject-Wise',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: criteriaMode == 'subject_wise'
                                        ? Colors.white
                                        : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Custom Segment
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onCriteriaModeChanged('custom'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: criteriaMode == 'custom' ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Custom',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: criteriaMode == 'custom'
                                        ? Colors.white
                                        : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (criteriaMode == 'custom') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.settings_suggest_rounded, size: 18, color: AppTheme.primary),
                          label: const Text('Configure Subject Criteria', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          onPressed: () => _showCustomCriteriaDialog(context),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    IgnorePointer(
                      ignoring: criteriaMode == 'custom',
                      child: Opacity(
                        opacity: criteriaMode == 'custom' ? 0.38 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Criteria Percentage',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                ),
                                Text(
                                  '$targetPercentage%',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ],
                            ),
                            Slider(
                              value: targetPercentage.toDouble(),
                              min: 50,
                              max: 100,
                              divisions: 10,
                              label: '$targetPercentage%',
                              onChanged: (val) {
                                onTargetPercentageChanged(val.toInt());
                              },
                            ),
                            if (criteriaMode == 'custom')
                              const Padding(
                                padding: EdgeInsets.only(top: 2, bottom: 4),
                                child: Text(
                                  'Not used in Custom mode — configure individual targets below.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),



            // Semester Duration
            _buildSectionHeader('SEMESTER DURATION'),
            const SizedBox(height: 10),
            Card(
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDateItem(
                        context,
                        'Start Date',
                        semesterStartDate,
                        (date) => onSemesterStartDateChanged(date),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 36,
                      color: borderColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateItem(
                        context,
                        'End Date',
                        semesterEndDate,
                        (date) => onSemesterEndDateChanged(date),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // University Holidays
            _buildSectionHeader('UNIVERSITY HOLIDAYS'),
            const SizedBox(height: 10),
            Card(
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Holiday', style: TextStyle(fontSize: 13)),
                            onPressed: () => _showAddHolidayDialog(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Import OCR', style: TextStyle(fontSize: 13, color: AppTheme.primary)),
                            onPressed: () => _showOcrPlaceholderDialog(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: borderColor),
                    const SizedBox(height: 10),
                    if (holidays.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No holidays added yet',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: holidays.length,
                        itemBuilder: (context, index) {
                          final hol = holidays[index];
                          final dateStr = DateFormat('EEE, d MMM yyyy').format(hol['date']);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              hol['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            subtitle: Text(
                              dateStr,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.beach_access_rounded, color: AppTheme.warning, size: 18),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                              onPressed: () {
                                if (hol['id'] != null) {
                                  onHolidayDeleted(hol['id'] as String);
                                }
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDateItem(BuildContext context, String label, DateTime date, Function(DateTime) onPicked) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('d MMM yyyy').format(date);

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2025),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isDark ? AppTheme.primary : AppTheme.primary.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomCriteriaDialog(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color textCol = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text(
                'Custom Subject Criteria',
                style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 16),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subjectCustomTargets.keys.length,
                  itemBuilder: (context, index) {
                    final subjectName = subjectCustomTargets.keys.elementAt(index);
                    final currentVal = subjectCustomTargets[subjectName] ?? targetPercentage;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subjectName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textCol,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade700, width: 1),
                            ),
                            child: DropdownButton<int>(
                              value: currentVal,
                              dropdownColor: dialogBg,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                              style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 13),
                              items: List.generate(11, (i) => 50 + i * 5).map((val) {
                                return DropdownMenuItem<int>(
                                  value: val,
                                  child: Text('$val%'),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setDialogState(() {
                                    onSubjectCustomTargetChanged(subjectName, newVal);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddHolidayDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add University Holiday'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Holiday Name',
                      hintText: 'e.g. Christmas Day',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      onHolidayAdded(nameController.text.trim(), selectedDate);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOcrPlaceholderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('OCR Import Placeholder'),
            ],
          ),
          content: const Text(
            'OCR Timetable & Holiday Calendar extraction will be implemented in Phase 12 as per the product roadmap.\n\n'
            'Currently, this is a placeholder illustrating the layout.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
