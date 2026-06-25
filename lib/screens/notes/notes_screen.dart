import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';
import 'add_resource_screen.dart';
import 'resource_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Store downloading files list to show progress indicators
  final Set<String> _downloadingFiles = {};
  late Map<String, List<NotesSubjectMock>> _semesterNotesRepo;

  @override
  void initState() {
    super.initState();
    _semesterNotesRepo = {
      'Semester 1': [
        NotesSubjectMock(
          subjectName: 'Mathematics I',
          units: [
            NotesUnitMock(
              unitNumber: 'Unit 1',
              unitTitle: 'Calculus & Matrices',
              files: [
                NotesFileMock(name: 'Calculus_Limits.pdf', type: 'PDF', size: '1.8 MB'),
              ],
            ),
          ],
        ),
      ],
      'Semester 2': [
        NotesSubjectMock(
          subjectName: 'Data Structures & Algorithms',
          units: [
            NotesUnitMock(
              unitNumber: 'Unit 1',
              unitTitle: 'Arrays & Linked Lists',
              files: [
                NotesFileMock(name: 'LinkedList_Implementation.pdf', type: 'PDF', size: '2.2 MB'),
              ],
            ),
          ],
        ),
      ],
      'Semester 3': [
        NotesSubjectMock(
          subjectName: 'Operating Systems',
          units: [
            NotesUnitMock(
              unitNumber: 'Unit 1',
              unitTitle: 'Processes & Threads',
              files: [
                NotesFileMock(name: 'Process_Scheduling.pdf', type: 'PDF', size: '2.5 MB'),
              ],
            ),
          ],
        ),
      ],
      'Semester 4': List.from(DummyData.notesRepo),
    };
  }

  void _simulateDownload(String filename) {
    if (_downloadingFiles.contains(filename)) return;

    setState(() {
      _downloadingFiles.add(filename);
    });

    // Simulate download progress
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _downloadingFiles.remove(filename);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accent,
            content: Text('"$filename" downloaded successfully to local storage! (Mock)'),
          ),
        );
      }
    });
  }

  void _removeResourceFromSemester(NotesFileMock file, String semester, String? subjectName, String? subsectionName) {
    if (subjectName == null || subsectionName == null) return;
    final repo = _semesterNotesRepo[semester];
    if (repo == null) return;

    int subIdx = repo.indexWhere((s) => s.subjectName == subjectName);
    if (subIdx == -1) return;

    final existingSubject = repo[subIdx];
    final unitsList = List<NotesUnitMock>.from(existingSubject.units);
    int unitIdx = unitsList.indexWhere((u) => u.unitNumber == subsectionName || '${u.unitNumber}: ${u.unitTitle}' == subsectionName);
    if (unitIdx == -1) return;

    final existingUnit = unitsList[unitIdx];
    final filesList = List<NotesFileMock>.from(existingUnit.files);
    filesList.removeWhere((f) => f.name == file.name);

    unitsList[unitIdx] = NotesUnitMock(
      unitNumber: existingUnit.unitNumber,
      unitTitle: existingUnit.unitTitle,
      files: filesList,
    );

    repo[subIdx] = NotesSubjectMock(
      subjectName: existingSubject.subjectName,
      units: unitsList,
    );
  }

  void _navigateToAddResource({
    NotesFileMock? resourceToEdit,
    String? initialSubject,
    String? initialSubsection,
  }) async {
    final activeSem = AppState.instance.activeSemester.value;
    final List<NotesSubjectMock> currentRepo = _semesterNotesRepo[activeSem] ?? [];

    final List<String> subjects = currentRepo.map((s) => s.subjectName).toList();
    final Map<String, List<String>> subToSub = {};
    for (var subject in currentRepo) {
      subToSub[subject.subjectName] = subject.units.map((u) {
        if (u.unitTitle.isEmpty) return u.unitNumber;
        return '${u.unitNumber}: ${u.unitTitle}';
      }).toList();
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddResourceScreen(
          resourceToEdit: resourceToEdit,
          initialSubject: initialSubject,
          initialSubsection: initialSubsection,
          initialSemester: activeSem,
          existingSubjects: subjects,
          subjectToSubsections: subToSub,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      final action = result['action'] as String;
      final file = result['resource'] as NotesFileMock;
      final subjectName = result['subject'] as String;
      final subsectionName = result['subsection'] as String;
      final targetSemester = result['semester'] as String;

      if (action == 'save') {
        final oldResource = result['oldResource'] as NotesFileMock?;
        final oldSubject = result['oldSubject'] as String?;
        final oldSubsection = result['oldSubsection'] as String?;

        String unitNumber = subsectionName;
        String unitTitle = '';
        if (subsectionName.contains(':')) {
          final parts = subsectionName.split(':');
          unitNumber = parts[0].trim();
          unitTitle = parts.sublist(1).join(':').trim();
        }

        setState(() {
          if (oldResource != null) {
            _removeResourceFromSemester(oldResource, activeSem, oldSubject, oldSubsection);
          }

          if (!_semesterNotesRepo.containsKey(targetSemester)) {
            _semesterNotesRepo[targetSemester] = [];
          }
          final targetRepo = _semesterNotesRepo[targetSemester]!;

          int subIdx = targetRepo.indexWhere((s) => s.subjectName == subjectName);
          if (subIdx == -1) {
            targetRepo.add(NotesSubjectMock(
              subjectName: subjectName,
              units: [
                NotesUnitMock(unitNumber: unitNumber, unitTitle: unitTitle, files: [file]),
              ],
            ));
          } else {
            final existingSubject = targetRepo[subIdx];
            final unitsList = List<NotesUnitMock>.from(existingSubject.units);
            int unitIdx = unitsList.indexWhere((u) => u.unitNumber == unitNumber || '${u.unitNumber}: ${u.unitTitle}' == subsectionName);

            if (unitIdx == -1) {
              unitsList.add(NotesUnitMock(unitNumber: unitNumber, unitTitle: unitTitle, files: [file]));
            } else {
              final existingUnit = unitsList[unitIdx];
              final filesList = List<NotesFileMock>.from(existingUnit.files);
              filesList.add(file);
              unitsList[unitIdx] = NotesUnitMock(
                unitNumber: existingUnit.unitNumber,
                unitTitle: existingUnit.unitTitle,
                files: filesList,
              );
            }

            targetRepo[subIdx] = NotesSubjectMock(
              subjectName: existingSubject.subjectName,
              units: unitsList,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accent,
            content: Text('"${file.name}" saved successfully under $targetSemester.'),
          ),
        );
      } else if (action == 'delete') {
        setState(() {
          _removeResourceFromSemester(file, activeSem, subjectName, subsectionName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accent,
            content: Text('"${file.name}" deleted successfully.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Repository'),
      ),
      body: Column(
        children: [
          // Semester selector at the top (synced with AppState)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppTheme.surface : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Semester:',
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: AppState.instance.activeSemester,
                  builder: (context, activeSem, _) {
                    return DropdownButton<String>(
                      dropdownColor: isDark ? AppTheme.surface : Colors.white,
                      value: activeSem,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      items: ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          AppState.instance.activeSemester.value = val;
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          Divider(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1), height: 1),

          // File directory view
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: AppState.instance.activeSemester,
              builder: (context, activeSem, _) {
                final currentRepo = _semesterNotesRepo[activeSem] ?? [];

                if (currentRepo.isEmpty) {
                  return Center(
                    child: Text(
                      'No resources found for $activeSem.',
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentRepo.length,
                  itemBuilder: (context, index) {
                    final subject = currentRepo[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          subject.subjectName,
                          style: TextStyle(
                            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        leading: const Icon(Icons.folder_open_rounded, color: AppTheme.primary),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: const Border(),
                        children: subject.units.map((unit) {
                          return ExpansionTile(
                            title: Text(
                              unit.unitTitle.isEmpty ? unit.unitNumber : '${unit.unitNumber}: ${unit.unitTitle}',
                              style: TextStyle(
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            leading: Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                              size: 18,
                            ),
                            shape: const Border(),
                            children: unit.files.map((file) {
                              final isDownloading = _downloadingFiles.contains(file.name);

                              return ResourceCard(
                                file: file,
                                isDownloading: isDownloading,
                                onDownload: () => _simulateDownload(file.name),
                                onEdit: () {
                                  final subName = unit.unitTitle.isEmpty ? unit.unitNumber : '${unit.unitNumber}: ${unit.unitTitle}';
                                  _navigateToAddResource(
                                    resourceToEdit: file,
                                    initialSubject: subject.subjectName,
                                    initialSubsection: subName,
                                  );
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _navigateToAddResource(),
        tooltip: 'Add Resource',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
