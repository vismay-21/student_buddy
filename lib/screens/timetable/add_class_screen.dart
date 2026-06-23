import 'package:flutter/material.dart';
import '../../core/models/subject_template.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';

/// Full-screen form for adding a lecture to the timetable.
/// Supports:
///  - Template: pick an existing subject to pre-fill Room/Teacher/Color
///  - Subject, Room, Teacher fields
///  - Day dropdown
///  - Begin / End time via system clock picker (dial mode)
///  - Color swatch popup
class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _roomController    = TextEditingController();
  final _teacherController = TextEditingController();

  String?  _selectedDay;
  TimeOfDay? _beginTime;
  TimeOfDay? _endTime;
  int      _selectedColor = 0xFF3B82F6; // default blue
  SubjectTemplate? _selectedTemplate;

  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  // Available swatch colors for lecture cards
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
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  // ── Template ──────────────────────────────────────────────────────────────

  void _applyTemplate(SubjectTemplate template) {
    setState(() {
      _selectedTemplate        = template;
      _subjectController.text  = template.name;
      _roomController.text     = template.room;
      _teacherController.text  = template.teacher;
      _selectedColor           = template.colorValue;
    });
  }

  // ── Time picker ───────────────────────────────────────────────────────────

  Future<void> _pickTime({required bool isBegin}) async {
    final initial = isBegin
        ? (_beginTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime   ?? const TimeOfDay(hour: 10, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dial,
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

  // ── Color picker ──────────────────────────────────────────────────────────

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

  // ── Submit ────────────────────────────────────────────────────────────────

  void _handleAdd() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDay == null) {
      _showError('Please select a day.');
      return;
    }
    if (_beginTime == null || _endTime == null) {
      _showError('Please set both begin and end times.');
      return;
    }

    // Save / update the subject as a template for future reuse
    AppState.instance.upsertSubjectTemplate(SubjectTemplate(
      name:       _subjectController.text.trim(),
      room:       _roomController.text.trim(),
      teacher:    _teacherController.text.trim(),
      colorValue: _selectedColor,
    ));

    final begin = _formatTime(_beginTime!);
    final end   = _formatTime(_endTime!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.accent,
        content: Text(
          '"${_subjectController.text.trim()}" added on $_selectedDay, $begin → $end (Mock)',
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppTheme.danger, content: Text(msg)),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Class'),
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
              child: const Text('ADD'),
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
            _SectionCard(
              label: 'TEMPLATE',
              children: [_buildTemplateRow()],
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Row builders ──────────────────────────────────────────────────────────

  Widget _buildTemplateRow() {
    return ValueListenableBuilder<List<SubjectTemplate>>(
      valueListenable: AppState.instance.subjectTemplates,
      builder: (context, templates, _) {
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
              if (templates.isEmpty)
                const Text('None yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
              else
                DropdownButton<SubjectTemplate>(
                  hint: const Text('Select', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                  value: _selectedTemplate,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  items: templates.map((t) {
                    return DropdownMenuItem<SubjectTemplate>(
                      value: t,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: Color(t.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(t.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) { if (val != null) _applyTemplate(val); },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlainTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
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
            items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) => setState(() => _selectedDay = val),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
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

// ── Helper widgets ─────────────────────────────────────────────────────────

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
