import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/dto/notes/notes_dto.dart';
import '../../data/dto/subject/subject_dto.dart';
import '../../core/providers/notes_provider.dart';
import '../../core/providers/subject_provider.dart';

class AddResourceScreen extends ConsumerStatefulWidget {
  final NotesResourceDto? resourceToEdit;
  final String? initialSubjectId;
  final String? initialSectionId;
  final String semesterId;

  const AddResourceScreen({
    super.key,
    this.resourceToEdit,
    this.initialSubjectId,
    this.initialSectionId,
    required this.semesterId,
  });

  @override
  ConsumerState<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends ConsumerState<AddResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<NotesSubjectDto> _subjects = [];
  List<NotesSectionDto> _sections = [];

  String? _selectedSubjectId;
  String? _selectedSectionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.resourceToEdit != null) {
      _nameController.text = widget.resourceToEdit!.resourceName;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final subs = await ref.read(notesSubjectsProvider(widget.semesterId).future);
      setState(() {
        _subjects = subs;
      });

      // Handle initial/edit subject ID
      final targetSubId = widget.resourceToEdit != null
          ? widget.initialSubjectId
          : widget.initialSubjectId;

      if (targetSubId != null && subs.any((s) => s.notesSubjectId == targetSubId)) {
        setState(() {
          _selectedSubjectId = targetSubId;
        });
        await _loadSections(targetSubId);

        // Handle initial/edit section ID
        final targetSecId = widget.resourceToEdit != null
            ? widget.initialSectionId
            : widget.initialSectionId;

        if (targetSecId != null && _sections.any((s) => s.sectionId == targetSecId)) {
          setState(() {
            _selectedSectionId = targetSecId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to load subjects: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSections(String subjectId) async {
    try {
      final secs = await ref.read(notesSectionsProvider(subjectId).future);
      setState(() {
        _sections = secs;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to load sections: $e');
      }
    }
  }

  void _showCreateSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Create New Subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'e.g., Computer Networks, Placements...',
              hintStyle: TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                Navigator.of(context).pop();
                if (name.isNotEmpty) {
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(subjectActionsProvider).createSubject(
                          SubjectCreateRequest(
                            semesterId: widget.semesterId,
                            subjectName: name,
                          ),
                        );
                    ref.invalidate(notesSubjectsProvider(widget.semesterId));
                    final subs = await ref.read(notesSubjectsProvider(widget.semesterId).future);
                    final newSub = subs.firstWhere((s) => s.notesSubjectName.toLowerCase() == name.toLowerCase());
                    setState(() {
                      _subjects = subs;
                      _selectedSubjectId = newSub.notesSubjectId;
                      _sections = [];
                      _selectedSectionId = null;
                    });
                    if (mounted) {
                      AppSnackbar.success(context, 'Subject "$name" created.');
                    }
                  } catch (e) {
                    if (mounted) {
                      AppSnackbar.error(context, 'Failed to create subject: $e');
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSubsectionDialog() {
    if (_selectedSubjectId == null) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Create New Section / Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'e.g., Unit 5, Circulars, Exam Notes...',
              hintStyle: TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                Navigator.of(context).pop();
                if (name.isNotEmpty) {
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(notesActionsProvider).createSection(
                          NotesSectionCreateRequest(
                            notesSubjectId: _selectedSubjectId!,
                            sectionName: name,
                          ),
                        );
                    ref.invalidate(notesSectionsProvider(_selectedSubjectId!));
                    final secs = await ref.read(notesSectionsProvider(_selectedSubjectId!).future);
                    final newSec = secs.firstWhere((s) => s.sectionName.toLowerCase() == name.toLowerCase());
                    setState(() {
                      _sections = secs;
                      _selectedSectionId = newSec.sectionId;
                    });
                    if (mounted) {
                      AppSnackbar.success(context, 'Section "$name" created.');
                    }
                  } catch (e) {
                    if (mounted) {
                      AppSnackbar.error(context, 'Failed to create section: $e');
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveResource() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjectId == null || _selectedSectionId == null) {
      AppSnackbar.warning(context, 'Please select a Subject and Section first');
      return;
    }

    final name = _nameController.text.trim();
    String detectedType = 'PDF';
    String mimeType = 'application/pdf';
    if (name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      if (ext == 'pdf') {
        detectedType = 'PDF';
        mimeType = 'application/pdf';
      } else if (ext == 'ppt' || ext == 'pptx') {
        detectedType = 'PPT';
        mimeType = 'application/vnd.ms-powerpoint';
      } else if (ext == 'doc' || ext == 'docx') {
        detectedType = 'DOCX';
        mimeType = 'application/msword';
      } else if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        detectedType = 'IMAGE';
        mimeType = 'image/png';
      } else if (ext.startsWith('http') || ext.contains('pointer')) {
        detectedType = 'LINK';
        mimeType = 'text/html';
      }
    }

    setState(() => _isLoading = true);

    try {
      if (widget.resourceToEdit != null) {
        // Edit existing resource
        await ref.read(notesActionsProvider).updateResource(
              widget.resourceToEdit!.resourceId,
              NotesResourceUpdateRequest(
                resourceName: name,
                fileName: name.contains('.') ? name : '$name.${detectedType.toLowerCase()}',
                mimeType: mimeType,
              ),
            );
      } else {
        // Create new resource
        await ref.read(notesActionsProvider).createResource(
              NotesResourceCreateRequest(
                sectionId: _selectedSectionId!,
                resourceName: name,
                fileName: name.contains('.') ? name : '$name.${detectedType.toLowerCase()}',
                mimeType: mimeType,
                fileSizeLinesOrBytes: 2048 * 1024, // 2MB default
                storagePath: '/notes/$name',
                uploadedVia: 'app',
              ),
            );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to save resource: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteResource() {
    if (widget.resourceToEdit == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Resource', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${widget.resourceToEdit!.resourceName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss Dialog
                setState(() => _isLoading = true);
                try {
                  await ref.read(notesActionsProvider).deleteResource(widget.resourceToEdit!.resourceId);
                  if (mounted) {
                    Navigator.of(context).pop(true); // Dismiss Screen
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackbar.error(context, 'Failed to delete resource: $e');
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.resourceToEdit != null ? 'Edit Resource' : 'Add Resource'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resourceToEdit != null ? 'Edit Resource' : 'Add Resource'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Semester Field (Read-only)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Semester',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active Academic Semester',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subject Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder_open_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Subject',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showCreateSubjectDialog,
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
                                SizedBox(width: 2),
                                Text(
                                  'Create New Subject',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        dropdownColor: isDark ? AppTheme.surface : Colors.white,
                        value: _selectedSubjectId,
                        hint: const Text('Select Subject'),
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey)),
                        ),
                        items: _subjects
                            .map((s) => DropdownMenuItem(value: s.notesSubjectId, child: Text(s.notesSubjectName)))
                            .toList(),
                        validator: (value) => value == null ? 'Subject is required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSubjectId = val;
                              _selectedSectionId = null;
                              _sections = [];
                            });
                            _loadSections(val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Section Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.subdirectory_arrow_right_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Unit / Section',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedSubjectId != null)
                            GestureDetector(
                              onTap: _showCreateSubsectionDialog,
                              child: const Row(
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
                                  SizedBox(width: 2),
                                  Text(
                                    'Create New Section',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        dropdownColor: isDark ? AppTheme.surface : Colors.white,
                        value: _selectedSectionId,
                        hint: const Text('Select Unit / Section'),
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey)),
                        ),
                        items: _sections
                            .map((s) => DropdownMenuItem(value: s.sectionId, child: Text(s.sectionName)))
                            .toList(),
                        validator: (value) => value == null ? 'Section is required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSectionId = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Resource Name Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Resource Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const Text(' *', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. Normalization Notes, SE Unit 3 PPT...',
                          hintStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Resource name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Upload Button Placeholder
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: null, // Disabled placeholder
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text(
                      'Select Resource (Coming Soon)',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Action Buttons
              Row(
                children: [
                  if (widget.resourceToEdit != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _deleteResource,
                        child: const Text(
                          'Delete Resource',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _saveResource,
                      child: Text(
                        widget.resourceToEdit != null ? 'Save Changes' : 'Add Resource',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
