import 'package:flutter/material.dart';
import 'widgets/attendance_overview_card.dart';
import 'widgets/attendance_subject_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dummy_data.dart';
import 'subject_history_screen.dart';

class SubjectsTab extends StatelessWidget {
  final double overallPercentage;
  final int targetPercentage;
  final String criteriaMode;
  final List<Map<String, dynamic>> belowTargetSubjects;
  final List<Map<String, dynamic>> subjectsList; // list of subject metrics
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final List<Map<String, dynamic>> holidays;
  final Map<String, Map<String, String>> dateActions;
  final Function(DateTime date, LectureMock lecture, String action) onLectureActionChanged;

  const SubjectsTab({
    super.key,
    required this.overallPercentage,
    required this.targetPercentage,
    required this.criteriaMode,
    required this.belowTargetSubjects,
    required this.subjectsList,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.holidays,
    required this.dateActions,
    required this.onLectureActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Overall Attendance Card
          AttendanceOverviewCard(
            overallPercentage: overallPercentage,
            targetPercentage: targetPercentage,
            isSubjectWise: criteriaMode == 'subject_wise',
            belowTargetSubjects: belowTargetSubjects,
          ),
          const SizedBox(height: 20),

          // Subjects Title
          const Text(
            'SEMESTER SUBJECTS ANALYTICS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // List of Subject Cards (Clickable)
          ...subjectsList.map((sub) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.transparent,
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectHistoryScreen(
                        subjectName: sub['name'],
                        semesterStartDate: semesterStartDate,
                        semesterEndDate: semesterEndDate,
                        holidays: holidays,
                        dateActions: dateActions,
                        criteriaPercentage: sub['target'] as int,
                        onLectureActionChanged: onLectureActionChanged,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: IgnorePointer(
                    child: AttendanceSubjectCard(
                      subjectName: sub['name'],
                      attendancePercent: sub['percent'],
                      targetPercent: sub['target'],
                      attended: sub['attended'],
                      total: sub['total'],
                      statusMessage: sub['statusMessage'],
                      isAboveTarget: sub['isAboveTarget'],
                      showActions: false,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
