import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/subject_provider.dart';
import '../../../data/dto/attendance/attendance_settings_dto.dart';
import '../../../data/dto/holiday/holiday_dto.dart';
import '../../../data/dto/subject/subject_dto.dart';
import '../../../data/dto/semester/semester_dto.dart';
import '../../../core/widgets/app_snackbar.dart';

class AttendanceSettingsTab extends ConsumerWidget {
  const AttendanceSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final activeSem = ref.watch(activeSemesterProvider);
    if (activeSem == null) {
      return const Scaffold(
        body: Center(child: Text('No active semester', style: TextStyle(color: AppTheme.textMuted))),
      );
    }

    final settingsAsync = ref.watch(attendanceSettingsProvider);
    final holidaysAsync = ref.watch(holidaysProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final bool hasData = settingsAsync.hasValue && holidaysAsync.hasValue && subjectsAsync.hasValue;

    return Scaffold(
      body: hasData
          ? Builder(
              builder: (context) {
                final settings = settingsAsync.value!;
                final holidays = holidaysAsync.value!;
                final subjects = subjectsAsync.value!;

                final criteriaMode = settings.criteriaMode == 'subject' ? 'subject_wise' : settings.criteriaMode;
                final targetPercentage = settings.overallAttendanceGoal;

                final subjectCustomTargets = {
                  for (var s in subjects) s.subjectName: s.attendanceGoal
                };

                return SingleChildScrollView(
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
                                  color: isDark
                                      ? AppTheme.surface.withOpacity(0.5)
                                      : AppTheme.lightSurface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    // Overall Average Segment
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _updateCriteriaMode(ref, 'overall', subjects),
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
                                        onTap: () => _updateCriteriaMode(ref, 'subject_wise', subjects),
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
                                        onTap: () => _updateCriteriaMode(ref, 'custom', subjects),
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
                                    label: const Text('Configure Subject Criteria',
                                        style: TextStyle(
                                            fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    onPressed: () =>
                                        _showCustomCriteriaDialog(context, ref, subjectCustomTargets, subjects),
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
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textMuted),
                                          ),
                                          Text(
                                            '$targetPercentage%',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary),
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
                                          _updateTargetPercentage(ref, val.toInt());
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
                                  activeSem.startDate,
                                  (date) => _updateSemesterStartDate(context, ref, activeSem.semesterId, date),
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
                                  activeSem.endDate,
                                  (date) => _updateSemesterEndDate(context, ref, activeSem.semesterId, date),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Holidays (${holidays.length})',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Holidays exclude all lectures on those dates from attendance calculations.',
                                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 24),
                                    onPressed: () => _showAddHolidayDialog(context, ref, activeSem.semesterId),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                                    final dateStr = DateFormat('EEE, d MMM yyyy').format(hol.holidayDate);
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        hol.holidayName,
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
                                        child:
                                            const Icon(Icons.beach_access_rounded, color: AppTheme.warning, size: 18),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            color: AppTheme.danger, size: 20),
                                        onPressed: () {
                                          ref
                                              .read(attendanceActionsProvider)
                                              .deleteHoliday(hol.holidayId);
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
                );
              },
            )
          : (settingsAsync.isLoading || holidaysAsync.isLoading || subjectsAsync.isLoading)
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Text(
                    'Error loading settings: ${settingsAsync.error ?? holidaysAsync.error ?? subjectsAsync.error}',
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

  Widget _buildDateItem(BuildContext context, String label, DateTime date, Function(DateTime) onDatePicked) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String dateStr = DateFormat('EEE, d MMM yyyy').format(date);

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onDatePicked(picked);
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

  void _updateCriteriaMode(WidgetRef ref, String val, List<SubjectDto> subjects) async {
    final backendMode = val == 'subject_wise' ? 'subject' : val;
    await ref
        .read(attendanceSettingsProvider.notifier)
        .updateSettings(AttendanceSettingsUpdateRequest(criteriaMode: backendMode));

    if (val == 'custom') {
      final settings = ref.read(attendanceSettingsProvider).value;
      final seedTarget = settings?.overallAttendanceGoal ?? 75;
      for (final s in subjects) {
        await ref
            .read(subjectActionsProvider)
            .updateSubject(s.subjectId, SubjectUpdateRequest(attendanceGoal: seedTarget));
      }
    }
  }

  void _updateTargetPercentage(WidgetRef ref, int val) {
    ref
        .read(attendanceSettingsProvider.notifier)
        .updateSettings(AttendanceSettingsUpdateRequest(overallAttendanceGoal: val));
  }

  void _updateSemesterStartDate(BuildContext context, WidgetRef ref, String semesterId, DateTime date) async {
    try {
      await ref.read(semesterActionsProvider).updateSemester(semesterId, SemesterUpdateRequest(startDate: date));
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to update start date: $e');
      }
    }
  }

  void _updateSemesterEndDate(BuildContext context, WidgetRef ref, String semesterId, DateTime date) async {
    try {
      await ref.read(semesterActionsProvider).updateSemester(semesterId, SemesterUpdateRequest(endDate: date));
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to update end date: $e');
      }
    }
  }

  void _showCustomCriteriaDialog(
      BuildContext context, WidgetRef ref, Map<String, int> subjectCustomTargets, List<SubjectDto> subjects) {
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
                    final currentVal = subjectCustomTargets[subjectName] ?? 75;

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
                              onChanged: (newVal) async {
                                if (newVal != null) {
                                  final sub = subjects.firstWhere((s) => s.subjectName == subjectName);
                                  await ref
                                      .read(subjectActionsProvider)
                                      .updateSubject(sub.subjectId, SubjectUpdateRequest(attendanceGoal: newVal));
                                  setDialogState(() {
                                    subjectCustomTargets[subjectName] = newVal;
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

  void _showAddHolidayDialog(BuildContext context, WidgetRef ref, String semesterId) {
    final TextEditingController nameController = TextEditingController();
    DateTime? selectedDate;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textCol = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
              title: Text('Add Holiday',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Holiday Name',
                      hintText: 'e.g. Christmas',
                    ),
                    style: TextStyle(color: textCol),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? 'Select Date'
                                : DateFormat('d MMMM yyyy').format(selectedDate!),
                            style: TextStyle(color: textCol),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && selectedDate != null) {
                      await ref.read(attendanceActionsProvider).createHoliday(
                            HolidayCreateRequest(
                              semesterId: semesterId,
                              holidayDate: selectedDate!,
                              holidayName: nameController.text,
                            ),
                          );
                      if (context.mounted) Navigator.pop(ctx);
                    } else {
                      AppSnackbar.error(context, 'Please enter name and date');
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
  }}
