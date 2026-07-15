import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/utils/color_helper.dart';
import '../../data/dto/subject/subject_dto.dart';
import '../../data/dto/lecture/lecture_template_dto.dart';
import '../../core/providers/semester_provider.dart';
import '../../core/providers/subject_provider.dart';
import '../../core/providers/timetable_provider.dart';

/// Full-screen form for adding a lecture to the timetable.
class AddClassScreen extends ConsumerStatefulWidget {
  final LectureTemplateDto? template;
  final SubjectDto? subject;

  const AddClassScreen({super.key, this.template, this.subject});

  @override
  ConsumerState<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends ConsumerState<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _roomController    = TextEditingController();
  final _teacherController = TextEditingController();

  String?  _selectedDay;
  TimeOfDay? _beginTime;
  TimeOfDay? _endTime;
  int      _selectedColor = 0xFF3B82F6; // default blue

  SubjectDto? _selectedSubject;
  bool _isSaving = false;

  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const List<_ColorOption> _colorOptions = [
    _ColorOption(0xFF3B82F6, 'Blue'),
    _ColorOption(0xFF8B5CF6, 'Violet'),
    _ColorOption(0xFF10B981, 'Emerald'),
    _ColorOption(0xFFF59E0B, 'Amber'),
    _ColorOption(0xFFEF4444, 'Red'),
    _ColorOption(0xFFEC4899, 'Pink'),
    _ColorOption(0xFF06B6D4, 'Cyan'),
    _ColorOption(0xFF84CC16, 'Lime'),
    _ColorOption(0xFFF97316, 'Orange'),
    _ColorOption(0xFF6366F1, 'Indigo'),
    _ColorOption(0xFF14B8A6, 'Teal'),
    _ColorOption(0xFFE11D48, 'Rose'),
  ];

  @override
  void initState() {
    super.initState();
    _initEditFields();
  }

  void _initEditFields() {
    if (widget.template != null && widget.subject != null) {
      _subjectController.text = widget.subject!.subjectName;
      _roomController.text = widget.template!.room ?? '';
      _teacherController.text = widget.subject!.facultyName ?? '';
      _selectedColor = parseHexColor(widget.subject!.themeColor).value;
      _selectedDay = _days[widget.template!.dayOfWeek - 1];
      
      final startParts = widget.template!.startTime.split(':');
      final endParts = widget.template!.endTime.split(':');
      if (startParts.length >= 2) {
        _beginTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
      }
      if (endParts.length >= 2) {
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }
      _selectedSubject = widget.subject;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  void _applySubject(SubjectDto subject) {
    setState(() {
      _selectedSubject = subject;
      _subjectController.text = subject.subjectName;
      _teacherController.text = subject.facultyName ?? '';
      _selectedColor = parseHexColor(subject.themeColor).value;
    });
    _fetchDetailsForSubject(subject);
  }

  void _fetchDetailsForSubject(SubjectDto subject) async {
    try {
      final templates = ref.read(timetableTemplatesProvider(subject.subjectId)).value ?? [];
      if (templates.isNotEmpty) {
        setState(() {
          _roomController.text = templates.first.room ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _pickTime({required bool isBegin}) async {
    final initial = isBegin
        ? (_beginTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime   ?? const TimeOfDay(hour: 10, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (BuildContext context, Widget? child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: dark ? Brightness.dark : Brightness.light,
            colorScheme: dark
                ? const ColorScheme.dark(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    secondary: AppTheme.secondary,
                    surface: AppTheme.surface,
                    onSurface: AppTheme.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    secondary: AppTheme.secondary,
                    surface: AppTheme.lightSurface,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
            timePickerTheme: TimePickerThemeData(
              hourMinuteShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primary;
                }
                return dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return dark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
              }),
              hourMinuteTextStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              dayPeriodTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              dayPeriodShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primary.withAlpha(50);
                }
                return Colors.transparent;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primary;
                }
                return dark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
              }),
              dayPeriodBorderSide: BorderSide(
                color: dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              dialBackgroundColor: dark ? const Color(0xFF121824) : const Color(0xFFF1F5F9),
              dialHandColor: AppTheme.primary,
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return dark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
              }),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: Transform.scale(
            scale: 1.15,
            child: child!,
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isBegin) {
          _beginTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _showColorPicker() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SizedBox(
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _colorOptions.length,
            itemBuilder: (_, i) {
              final opt       = _colorOptions[i];
              final isSelected = opt.value == _selectedColor;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedColor = opt.value);
                  Navigator.of(ctx).pop();
                },
                child: Tooltip(
                  message: opt.label,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Color(opt.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Color(opt.value).withAlpha(130), blurRadius: 10, spreadRadius: 2)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDay == null) {
      _showError('Please select a day.');
      return;
    }
    if (_beginTime == null || _endTime == null) {
      _showError('Please set both begin and end times.');
      return;
    }

    final activeSem = ref.read(activeSemesterProvider);
    if (activeSem == null) {
      _showError('No active semester configured.');
      return;
    }

    final dayIndex = _days.indexOf(_selectedDay!) + 1;
    final startStr = '${_beginTime!.hour.toString().padLeft(2, '0')}:${_beginTime!.minute.toString().padLeft(2, '0')}';
    final endStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

    setState(() => _isSaving = true);

    try {
      final typedName = _subjectController.text.trim();
      if (widget.template != null && widget.subject != null) {
        // 1. Update Subject Details
        await ref.read(subjectActionsProvider).updateSubject(
          widget.subject!.subjectId,
          SubjectUpdateRequest(
            subjectName: typedName,
            facultyName: _teacherController.text.trim().isEmpty ? null : _teacherController.text.trim(),
            themeColor: toHexColor(_selectedColor),
          ),
        );

        // 2. Update Template Details
        await ref.read(timetableActionsProvider).updateTemplate(
          widget.template!.lectureTemplateId,
          LectureTemplateUpdateRequest(
            dayOfWeek: dayIndex,
            startTime: startStr,
            endTime: endStr,
            room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
          ),
          widget.subject!.subjectId,
        );

        if (mounted) {
          AppSnackbar.success(
            context,
            '"$typedName" updated successfully.',
          );
          Navigator.of(context).pop(dayIndex - 1);
        }
      } else {
        // Add mode
        final existingSubjects = ref.read(subjectsProvider).value ?? [];
        SubjectDto? match;
        for (final s in existingSubjects) {
          if (s.subjectName.toLowerCase() == typedName.toLowerCase()) {
            match = s;
            break;
          }
        }

        String subjectId;
        if (match != null) {
          subjectId = match.subjectId;
        } else {
          final newSub = await ref.read(subjectActionsProvider).createSubject(SubjectCreateRequest(
            semesterId: activeSem.semesterId,
            subjectName: typedName,
            facultyName: _teacherController.text.trim().isEmpty ? null : _teacherController.text.trim(),
            themeColor: toHexColor(_selectedColor),
          ));
          subjectId = newSub.subjectId;
        }

        await ref.read(timetableActionsProvider).createTemplate(LectureTemplateCreateRequest(
          subjectId: subjectId,
          dayOfWeek: dayIndex,
          startTime: startStr,
          endTime: endStr,
          room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        ));

        if (mounted) {
          AppSnackbar.success(
            context,
            '"$typedName" added successfully.',
          );
          Navigator.of(context).pop(dayIndex - 1);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save class: $e');
    }
  }

  void _showDeleteConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class?'),
        content: const Text(
          'Are you sure you want to delete this class template from your timetable? '
          'This will remove all future attendance instances of this class.',
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleDelete();
            },
          ),
        ],
      ),
    );
  }

  void _handleDelete() async {
    if (widget.template == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(timetableActionsProvider).deleteTemplate(
        widget.template!.lectureTemplateId,
        widget.template!.subjectId,
      );
      if (mounted) {
        AppSnackbar.success(context, 'Class deleted successfully.');
        Navigator.of(context).pop(widget.template!.dayOfWeek - 1);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to delete class: $e');
    }
  }

  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final existingSubjects = ref.watch(subjectsProvider).value ?? [];

    if (_isSaving) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.template != null ? 'Edit Class' : 'Add Class'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.template != null ? 'Edit Class' : 'Add Class'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _handleAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              child: Text(widget.template != null ? 'SAVE' : 'ADD'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Template section ────────────────────────────────────────────
            if (widget.template == null) ...[
              _SectionCard(
                label: 'TEMPLATE',
                children: [_buildTemplateRow(existingSubjects)],
              ),
              const SizedBox(height: 16),
            ],

            // ── Subject / Room / Teacher ────────────────────────────────────
            _SectionCard(
              label: 'SUBJECT DETAILS',
              children: [
                _buildPlainTextField(
                  controller: _subjectController,
                  hint: 'Subject name',
                  required: true,
                  icon: Icons.book_outlined,
                ),
                _buildDivider(cs),
                _buildPlainTextField(
                  controller: _roomController,
                  hint: 'Classroom / Room no.',
                  icon: Icons.meeting_room_outlined,
                ),
                _buildDivider(cs),
                _buildPlainTextField(
                  controller: _teacherController,
                  hint: 'Faculty / Teacher name',
                  icon: Icons.person_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Day & Time ──────────────────────────────────────────────────
            _SectionCard(
              label: 'SCHEDULE',
              children: [
                _buildDayRow(),
                _buildDivider(cs),
                _buildTimeRow(),
              ],
            ),
            const SizedBox(height: 16),

            // ── Color ───────────────────────────────────────────────────────
            _SectionCard(
              label: 'APPEARANCE',
              children: [_buildColorRow()],
            ),
            if (widget.template != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'DELETE CLASS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
                onPressed: _showDeleteConfirmation,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateRow(List<SubjectDto> existingSubjects) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.copy_all_rounded, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Use Template',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (existingSubjects.isEmpty)
            const Text('None yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
          else
            DropdownButton<SubjectDto>(
              hint: const Text('Select', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
              value: _selectedSubject,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Theme.of(context).cardColor,
              items: existingSubjects.map((s) {
                return DropdownMenuItem<SubjectDto>(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: parseHexColor(s.themeColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(s.subjectName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) { if (val != null) _applySubject(val); },
            ),
        ],
      ),
    );
  }

  Widget _buildPlainTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool required = false,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildDayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Day', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          DropdownButton<String>(
            hint: const Text('Select day', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            value: _selectedDay,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Theme.of(context).cardColor,
            items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) => setState(() => _selectedDay = val),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTimeTile(
              label: 'Begin',
              time: _beginTime,
              onTap: () => _pickTime(isBegin: true),
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.textMuted.withAlpha(60)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTimeTile(
              label: 'End',
              time: _endTime,
              onTap: () => _pickTime(isBegin: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? _formatTime(time) : 'Tap to set',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: time != null ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow() {
    return InkWell(
      onTap: _showColorPicker,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Mini gradient preview
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(_selectedColor), Color(_selectedColor).withAlpha(180)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(_selectedColor).withAlpha(100), blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Lecture card color',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const Text('Change', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(
      height: 1,
      color: cs.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SectionCard({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ColorOption {
  final int value;
  final String label;
  const _ColorOption(this.value, this.label);
}
