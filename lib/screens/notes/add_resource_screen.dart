import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';

class AddResourceScreen extends StatefulWidget {
  final NotesFileMock? resourceToEdit;
  final String? initialSubject;
  final String? initialSubsection;
  final String? initialSemester;
  final List<String> existingSubjects;
  final Map<String, List<String>> subjectToSubsections;

  const AddResourceScreen({
    super.key,
    this.resourceToEdit,
    this.initialSubject,
    this.initialSubsection,
    this.initialSemester,
    required this.existingSubjects,
    required this.subjectToSubsections,
  });

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late List<String> _subjects;
  late Map<String, List<String>> _subsectionsMap;

  String? _selectedSemester;
  String? _selectedSubject;
  String? _selectedSubsection;

  @override
  void initState() {
    super.initState();
    _subjects = List.from(widget.existingSubjects);
    _subsectionsMap = Map.from(widget.subjectToSubsections);

    _selectedSemester = widget.initialSemester ?? AppState.instance.activeSemester.value;

    if (widget.resourceToEdit != null) {
      _nameController.text = widget.resourceToEdit!.name;
    }

    if (widget.resourceToEdit != null || widget.initialSubject != null) {
      _selectedSubject = widget.initialSubject;
      if (_selectedSubject != null && !_subjects.contains(_selectedSubject)) {
        if (_subjects.isNotEmpty) {
          _selectedSubject = _subjects.first;
        }
      }
    } else {
      _selectedSubject = null;
    }

    // Load subsections for current subject
    _updateSubsectionsList();

    if (widget.resourceToEdit != null || widget.initialSubsection != null) {
      _selectedSubsection = widget.initialSubsection;
      final currentSubsections = _selectedSubject != null ? (_subsectionsMap[_selectedSubject!] ?? []) : <String>[];
      if (_selectedSubsection != null && !currentSubsections.contains(_selectedSubsection)) {
        if (currentSubsections.isNotEmpty) {
          _selectedSubsection = currentSubsections.first;
        }
      }
    } else {
      _selectedSubsection = null;
    }
  }

  void _updateSubsectionsList() {
    if (_selectedSubject != null && !_subsectionsMap.containsKey(_selectedSubject)) {
      _subsectionsMap[_selectedSubject!] = [];
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
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    if (!_subjects.contains(name)) {
                      _subjects.add(name);
                      _subsectionsMap[name] = ['Unit 1']; // Default initial unit
                    }
                    _selectedSubject = name;
                    _updateSubsectionsList();
                    _selectedSubsection = _subsectionsMap[name]?.first;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSubsectionDialog() {
    if (_selectedSubject == null) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Create New Subsection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    final currentSubs = _subsectionsMap[_selectedSubject!] ?? [];
                    if (!currentSubs.contains(name)) {
                      currentSubs.add(name);
                      _subsectionsMap[_selectedSubject!] = currentSubs;
                    }
                    _selectedSubsection = name;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _saveResource() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubject == null || _selectedSubsection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Subject and Subsection first')),
      );
      return;
    }

    // Size placeholder based on type
    String sizeStr = '2.0 MB';
    if (widget.resourceToEdit != null) {
      sizeStr = widget.resourceToEdit!.size;
    }

    // Detect file type from name extension
    final name = _nameController.text.trim();
    String detectedType = 'Other';
    if (name.contains('.')) {
      final ext = name.split('.').last.toUpperCase();
      if (ext.isNotEmpty && ext.length <= 4) {
        detectedType = ext;
      }
    }

    final newResource = NotesFileMock(
      name: name,
      type: detectedType,
      size: sizeStr,
    );

    // Return the resulting resource plus routing info to parent screen
    Navigator.of(context).pop({
      'action': 'save',
      'resource': newResource,
      'subject': _selectedSubject,
      'subsection': _selectedSubsection,
      'semester': _selectedSemester,
      'oldResource': widget.resourceToEdit,
      'oldSubject': widget.initialSubject,
      'oldSubsection': widget.initialSubsection,
    });
  }

  void _deleteResource() {
    if (widget.resourceToEdit == null) return;
    
    // Prompt confirmation
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Resource', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${widget.resourceToEdit!.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss Dialog
                Navigator.of(context).pop({
                  'action': 'delete',
                  'resource': widget.resourceToEdit,
                  'subject': widget.initialSubject,
                  'subsection': widget.initialSubsection,
                }); // Dismiss AddResourceScreen
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
    final currentSubsections = _selectedSubject != null ? (_subsectionsMap[_selectedSubject!] ?? []) : <String>[];

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
              // Semester Field
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
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        dropdownColor: isDark ? AppTheme.surface : Colors.white,
                        value: _selectedSemester,
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey)),
                        ),
                        items: ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSemester = val;
                            });
                          }
                        },
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
                        value: _selectedSubject,
                        hint: const Text('Select Subject'),
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey)),
                        ),
                        items: _subjects
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        validator: (value) => value == null ? 'Subject is required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSubject = val;
                              _updateSubsectionsList();
                              _selectedSubsection = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subsection Field
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
                                'Unit / Subsection',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showCreateSubsectionDialog,
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
                                SizedBox(width: 2),
                                Text(
                                  'Create New Subsection',
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
                        value: _selectedSubsection,
                        hint: const Text('Select Unit / Subsection'),
                        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey)),
                        ),
                        items: currentSubsections
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        validator: (value) => value == null ? 'Subsection is required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSubsection = val;
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
