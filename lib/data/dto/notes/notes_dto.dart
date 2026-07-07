class NotesSubjectDto {
  final String notesSubjectId;
  final String semesterId;
  final String notesSubjectName;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotesSubjectDto({
    required this.notesSubjectId,
    required this.semesterId,
    required this.notesSubjectName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotesSubjectDto.fromJson(Map<String, dynamic> json) {
    return NotesSubjectDto(
      notesSubjectId: json['notes_subject_id'] as String,
      semesterId: json['semester_id'] as String,
      notesSubjectName: json['notes_subject_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class NotesSectionDto {
  final String sectionId;
  final String notesSubjectId;
  final String sectionName;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotesSectionDto({
    required this.sectionId,
    required this.notesSubjectId,
    required this.sectionName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotesSectionDto.fromJson(Map<String, dynamic> json) {
    return NotesSectionDto(
      sectionId: json['section_id'] as String,
      notesSubjectId: json['notes_subject_id'] as String,
      sectionName: json['section_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class NotesSectionCreateRequest {
  final String notesSubjectId;
  final String sectionName;

  NotesSectionCreateRequest({
    required this.notesSubjectId,
    required this.sectionName,
  });

  Map<String, dynamic> toJson() {
    return {
      'notes_subject_id': notesSubjectId,
      'section_name': sectionName,
    };
  }
}

class NotesSectionUpdateRequest {
  final String sectionName;

  NotesSectionUpdateRequest({
    required this.sectionName,
  });

  Map<String, dynamic> toJson() {
    return {
      'section_name': sectionName,
    };
  }
}

class NotesResourceDto {
  final String resourceId;
  final String sectionId;
  final String resourceName;
  final String fileName;
  final String mimeType;
  final int fileSizeLinesOrBytes;
  final String storagePath;
  final String uploadedVia; // 'app', 'whatsapp', 'ocr', 'review_queue', 'api'
  final DateTime createdAt;
  final DateTime updatedAt;

  NotesResourceDto({
    required this.resourceId,
    required this.sectionId,
    required this.resourceName,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeLinesOrBytes,
    required this.storagePath,
    required this.uploadedVia,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotesResourceDto.fromJson(Map<String, dynamic> json) {
    return NotesResourceDto(
      resourceId: json['resource_id'] as String,
      sectionId: json['section_id'] as String,
      resourceName: json['resource_name'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSizeLinesOrBytes: json['file_size_bytes'] as int,
      storagePath: json['storage_path'] as String,
      uploadedVia: json['uploaded_via'] as String? ?? 'app',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class NotesResourceCreateRequest {
  final String sectionId;
  final String resourceName;
  final String fileName;
  final String mimeType;
  final int fileSizeLinesOrBytes;
  final String storagePath;
  final String uploadedVia;

  NotesResourceCreateRequest({
    required this.sectionId,
    required this.resourceName,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeLinesOrBytes,
    required this.storagePath,
    this.uploadedVia = 'app',
  });

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'resource_name': resourceName,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeLinesOrBytes,
      'storage_path': storagePath,
      'uploaded_via': uploadedVia,
    };
  }
}

class NotesResourceUpdateRequest {
  final String? resourceName;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeLinesOrBytes;
  final String? storagePath;
  final String? uploadedVia;

  NotesResourceUpdateRequest({
    this.resourceName,
    this.fileName,
    this.mimeType,
    this.fileSizeLinesOrBytes,
    this.storagePath,
    this.uploadedVia,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (resourceName != null) data['resource_name'] = resourceName;
    if (fileName != null) data['file_name'] = fileName;
    if (mimeType != null) data['mime_type'] = mimeType;
    if (fileSizeLinesOrBytes != null) data['file_size_bytes'] = fileSizeLinesOrBytes;
    if (storagePath != null) data['storage_path'] = storagePath;
    if (uploadedVia != null) data['uploaded_via'] = uploadedVia;
    return data;
  }
}

class NotesSectionDetailDto {
  final String sectionId;
  final String notesSubjectId;
  final String sectionName;
  final List<NotesResourceDto> resources;

  NotesSectionDetailDto({
    required this.sectionId,
    required this.notesSubjectId,
    required this.sectionName,
    required this.resources,
  });

  factory NotesSectionDetailDto.fromJson(Map<String, dynamic> json) {
    final resList = json['resources'] as List<dynamic>? ?? [];
    return NotesSectionDetailDto(
      sectionId: json['section_id'] as String,
      notesSubjectId: json['notes_subject_id'] as String,
      sectionName: json['section_name'] as String,
      resources: resList.map((item) => NotesResourceDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class NotesSubjectDetailDto {
  final String notesSubjectId;
  final String semesterId;
  final String notesSubjectName;
  final List<NotesSectionDetailDto> sections;

  NotesSubjectDetailDto({
    required this.notesSubjectId,
    required this.semesterId,
    required this.notesSubjectName,
    required this.sections,
  });

  factory NotesSubjectDetailDto.fromJson(Map<String, dynamic> json) {
    final secList = json['sections'] as List<dynamic>? ?? [];
    return NotesSubjectDetailDto(
      notesSubjectId: json['notes_subject_id'] as String,
      semesterId: json['semester_id'] as String,
      notesSubjectName: json['notes_subject_name'] as String,
      sections: secList.map((item) => NotesSectionDetailDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
