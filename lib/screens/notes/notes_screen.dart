import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Store downloading files list to show progress indicators
  final Set<String> _downloadingFiles = {};

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
            content: Text('"${filename}" downloaded successfully to local storage! (Mock)'),
          ),
        );
      }
    });
  }

  IconData _getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'PPT':
        return Icons.slideshow_rounded;
      case 'DOCX':
      default:
        return Icons.description_rounded;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return AppTheme.danger;
      case 'PPT':
        return AppTheme.warning;
      case 'DOCX':
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Repository'),
      ),
      body: Column(
        children: [
          // Semester selector at the top (synced with AppState)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Semester:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: AppState.instance.activeSemester,
                  builder: (context, activeSem, _) {
                    return DropdownButton<String>(
                      dropdownColor: AppTheme.surface,
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
          
          const Divider(color: Color(0xFF1E293B), height: 1),

          // File directory view
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: DummyData.notesRepo.length,
              itemBuilder: (context, index) {
                final subject = DummyData.notesRepo[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      subject.subjectName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
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
                          '${unit.unitNumber}: ${unit.unitTitle}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        leading: const Icon(Icons.subdirectory_arrow_right_rounded, color: AppTheme.textMuted, size: 18),
                        shape: const Border(),
                        children: unit.files.map((file) {
                          final isDownloading = _downloadingFiles.contains(file.name);
                          final fileColor = _getFileColor(file.type);
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Icon(
                              _getFileIcon(file.type),
                              color: fileColor,
                              size: 22,
                            ),
                            title: Text(
                              file.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${file.type} • ${file.size}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                            trailing: isDownloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.download_for_offline_outlined, color: AppTheme.textSecondary),
                                    tooltip: 'Download file offline',
                                    onPressed: () => _simulateDownload(file.name),
                                  ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
