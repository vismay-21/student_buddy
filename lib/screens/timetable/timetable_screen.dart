import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../attendance/widgets/lecture_card.dart';
import 'add_class_screen.dart';
import '../../core/utils/dummy_data.dart';

import 'package:student_buddy/core/utils/color_helper.dart';
import 'package:student_buddy/data/dto/subject/subject_dto.dart';
import 'package:student_buddy/core/providers/semester_provider.dart';
import 'package:student_buddy/core/providers/timetable_provider.dart';
import 'package:student_buddy/core/providers/subject_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedDayIndex = 0;
  late PageController _pageController;

  final List<String> _daysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final int todayIndex = (DateTime.now().weekday - 1) % 7;
    _selectedDayIndex = todayIndex;
    _pageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getFullDayName() {
    final now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return DateFormat('EEEE').format(startOfWeek.add(Duration(days: _selectedDayIndex)));
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
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

    final templatesAsync = ref.watch(allLectureTemplatesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    if (templatesAsync.isLoading || subjectsAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allTemplates = templatesAsync.value ?? [];
    final subjects = subjectsAsync.value ?? [];

    final Map<String, SubjectDto> subjectsMap = {
      for (final sub in subjects) sub.subjectId: sub
    };

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
                final templatesForDay = allTemplates.where((t) => t.dayOfWeek == (dayIndex + 1)).toList();
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
                    final subject = subjectsMap[template.subjectId];
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
                      onEdit: () async {
                        final result = await Navigator.of(context).push<int>(
                          MaterialPageRoute(
                            builder: (_) => AddClassScreen(
                              template: template,
                              subject: subject,
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _selectedDayIndex = result;
                          });
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(result);
                          }
                        }
                      },
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
            final result = await Navigator.of(context).push<int>(
              MaterialPageRoute(builder: (_) => const AddClassScreen()),
            );
            if (result != null && mounted) {
              setState(() {
                _selectedDayIndex = result;
              });
              if (_pageController.hasClients) {
                _pageController.jumpToPage(result);
              }
            }
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
