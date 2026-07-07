import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import '../attendance/widgets/lecture_card.dart';
import 'add_class_screen.dart';

import 'package:student_buddy/core/utils/color_helper.dart';
import 'package:student_buddy/data/dto/subject/subject_dto.dart';
import 'package:student_buddy/data/dto/lecture/lecture_template_dto.dart';
import 'package:student_buddy/data/repositories/subject_repository.dart';
import 'package:student_buddy/data/repositories/lecture_template_repository.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/utils/app_state.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedDayIndex = 0;
  late PageController _pageController;

  final List<String> _daysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _subjectRepo = SubjectRepository();
  final _templateRepo = LectureTemplateRepository();

  bool _isLoading = false;
  List<LectureTemplateDto> _allTemplates = [];
  Map<String, SubjectDto> _subjectsMap = {};

  @override
  void initState() {
    super.initState();
    final int todayIndex = (DateTime.now().weekday - 1) % 7;
    _selectedDayIndex = todayIndex;
    _pageController = PageController(initialPage: _selectedDayIndex);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      setState(() {
        _allTemplates = [];
        _subjectsMap = {};
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final subjects = await _subjectRepo.getSubjects(activeSem.semesterId);
      final Map<String, SubjectDto> subMap = {};
      final List<LectureTemplateDto> templates = [];

      for (final sub in subjects) {
        subMap[sub.subjectId] = sub;
        final temps = await _templateRepo.getTemplates(sub.subjectId);
        templates.addAll(temps);
      }

      setState(() {
        _subjectsMap = subMap;
        _allTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackbar.error(context, 'Failed to load timetable: $e');
      }
    }
  }

  String _getFullDayName() {
    final now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return DateFormat('EEEE').format(startOfWeek.add(Duration(days: _selectedDayIndex)));
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = AppState.instance.activeSemesterDto.value;
    if (activeSem == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: AppTheme.textMuted.withAlpha(100),
              ),
              const SizedBox(height: 16),
              const Text(
                'No active semester',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure a semester in settings first.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Day header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getFullDayName(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Lecture list pager ─────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 7,
              onPageChanged: (index) => setState(() => _selectedDayIndex = index),
              itemBuilder: (context, dayIndex) {
                final templatesForDay = _allTemplates.where((t) => t.dayOfWeek == (dayIndex + 1)).toList();
                templatesForDay.sort((a, b) => a.startTime.compareTo(b.startTime));

                if (templatesForDay.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 64,
                          color: AppTheme.textMuted.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No classes scheduled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enjoy your free day!',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: templatesForDay.length,
                  itemBuilder: (context, index) {
                    final template = templatesForDay[index];
                    final subject = _subjectsMap[template.subjectId];
                    final lectureMock = LectureMock(
                      id: template.lectureTemplateId,
                      name: subject?.subjectName ?? 'Unknown Subject',
                      startTime: template.startTime.substring(0, 5),
                      endTime: template.endTime.substring(0, 5),
                      teacher: subject?.facultyName ?? 'N/A',
                      room: template.room ?? 'N/A',
                      colorValue: parseHexColor(subject?.themeColor).value,
                    );
                    return LectureCard(
                      lecture: lectureMock,
                      showAttendance: false,
                    );
                  },
                );
              },
            ),
          ),

          // ── Day selector bar ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_daysShort.length, (index) {
                final bool isSelected = index == _selectedDayIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : const Color(0xFF1E293B),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(60),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                          child: Text(_daysShort[index]),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),

      // Navigate to full-screen AddClassScreen
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: FloatingActionButton(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddClassScreen()),
            );
            _loadData();
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
