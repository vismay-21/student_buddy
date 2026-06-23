import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';
import 'add_class_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
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

  String _getFormattedDate() {
    final now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
    DateTime selectedDate = startOfWeek.add(Duration(days: _selectedDayIndex));

    final day = selectedDate.day;
    String suffix = 'th';
    if (day < 11 || day > 13) {
      switch (day % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
      }
    }
    return '$day$suffix ${DateFormat('MMMM').format(selectedDate)}';
  }

  String _getFullDayName() {
    final now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return DateFormat('EEEE').format(startOfWeek.add(Duration(days: _selectedDayIndex)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Day / Date header ──────────────────────────────────────────────
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
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
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
                final lectures = DummyData.getLecturesForDay(dayIndex);

                if (lectures.isEmpty) {
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
                  itemCount: lectures.length,
                  itemBuilder: (context, index) => _buildLectureCard(lectures[index]),
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
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddClassScreen()),
            );
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  // ── Lecture card ──────────────────────────────────────────────────────────
  //
  // Layout:
  //   [colored bar] | [start↑ end↓] | [divider] | [Subject | Room | Teacher]
  //
  Widget _buildLectureCard(LectureMock lecture) {
    final cardColor = Color(lecture.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Stronger gradient — 0.28 opacity gives a clear wash without being
          // too heavy on the dark background.
          gradient: LinearGradient(
            colors: [
              cardColor.withAlpha(72),   // ≈ 0.28 opacity
              cardColor.withAlpha(18),   // ≈ 0.07 fade out
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Colored accent bar
            Container(
              width: 5,
              height: 60,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),

            // Time column (start & end)
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lecture.startTime,
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lecture.endTime,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            // Thin vertical separator
            Container(
              width: 1,
              height: 50,
              color: cardColor.withAlpha(80),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),

            // Subject details: name → room → teacher
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        lecture.room,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lecture.teacher,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
