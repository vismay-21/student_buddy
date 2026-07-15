import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/notes/notes_dto.dart';
import '../../core/providers/semester_provider.dart';
import '../../core/providers/notes_provider.dart';
import 'add_resource_screen.dart';
import 'resource_card.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final Set<String> _downloadingFiles = {};

  void _simulateDownload(String filename) {
    if (_downloadingFiles.contains(filename)) return;

    setState(() {
      _downloadingFiles.add(filename);
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _downloadingFiles.remove(filename);
        });
        AppSnackbar.success(context, '"$filename" downloaded successfully to local storage! (Mock)');
      }
    });
  }

  Future<void> _navigateToAddResource({
    NotesResourceDto? resourceToEdit,
    String? initialSubjectId,
    String? initialSectionId,
  }) async {
    final activeSem = ref.read(activeSemesterProvider);
    if (activeSem == null) {
      AppSnackbar.warning(context, 'Please select or create a semester first');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddResourceScreen(
          semesterId: activeSem.semesterId,
          resourceToEdit: resourceToEdit,
          initialSubjectId: initialSubjectId,
          initialSectionId: initialSectionId,
        ),
      ),
    );

    if (result == true) {
      ref.invalidate(notesHierarchyProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSem = ref.watch(activeSemesterProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final hierarchyAsync = ref.watch(notesHierarchyProvider);

    if (activeSem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notes Repository')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted).withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Semester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select or create a semester from Settings first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Repository'),
      ),
      body: Column(
        children: [
          // Semester selector at the top (synced with ActiveSemesterProvider)
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
                semestersAsync.maybeWhen(
                  data: (sems) {
                    if (sems.isEmpty) return const SizedBox.shrink();
                    return DropdownButton<String>(
                      dropdownColor: isDark ? AppTheme.surface : Colors.white,
                      value: activeSem.semesterId,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      items: sems
                          .map((s) => DropdownMenuItem(
                                value: s.semesterId,
                                child: Text('Semester ${s.semesterNumber}'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selectedSem = sems.firstWhere((s) => s.semesterId == val);
                          ref.read(semesterActionsProvider).selectActiveSemester(selectedSem);
                        }
                      },
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          Divider(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1), height: 1),

          // File directory view
          Expanded(
            child: hierarchyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load notes: $err')),
              data: (hierarchy) {
                if (hierarchy.isEmpty) {
                  return Center(
                    child: Text(
                      'No resources found for Semester ${activeSem.semesterNumber}.',
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hierarchy.length,
                  itemBuilder: (context, index) {
                    final subject = hierarchy[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          subject.notesSubjectName,
                          style: TextStyle(
                            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        leading: const Icon(Icons.folder_open_rounded, color: AppTheme.primary),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: const Border(),
                        children: subject.sections.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    'No sections in this subject.',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              ]
                            : subject.sections.map((unit) {
                                return ExpansionTile(
                                  title: Text(
                                    unit.sectionName,
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
                                  children: unit.resources.isEmpty
                                      ? [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              'No resources in this section.',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        ]
                                      : unit.resources.map((file) {
                                          final isDownloading = _downloadingFiles.contains(file.fileName);

                                          return ResourceCard(
                                            file: file,
                                            isDownloading: isDownloading,
                                            onDownload: () => _simulateDownload(file.fileName),
                                            onEdit: () {
                                              _navigateToAddResource(
                                                resourceToEdit: file,
                                                initialSubjectId: subject.notesSubjectId,
                                                initialSectionId: unit.sectionId,
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
        heroTag: 'notes_fab',
        backgroundColor: AppTheme.primary,
        onPressed: () => _navigateToAddResource(),
        tooltip: 'Add Resource',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
