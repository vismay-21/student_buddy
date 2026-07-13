import 'dart:async';
import '../../local/database_helper.dart';
import '../notes_repository.dart';
import '../../dto/notes/notes_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteNotesRepository implements NotesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<NotesSubjectDto>> getSubjects(String semesterId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes_subjects',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'notes_subject_name ASC',
    );
    return List.generate(maps.length, (i) => NotesSubjectDto.fromJson(maps[i]));
  }

  @override
  Future<NotesSubjectDto> getSubject(String notesSubjectId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes_subjects',
      where: 'notes_subject_id = ?',
      whereArgs: [notesSubjectId],
    );
    if (maps.isEmpty) {
      throw Exception("Notes subject with ID $notesSubjectId not found");
    }
    return NotesSubjectDto.fromJson(maps.first);
  }

  @override
  Future<List<NotesSectionDto>> getSections(String notesSubjectId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes_sections',
      where: 'notes_subject_id = ?',
      whereArgs: [notesSubjectId],
      orderBy: 'section_name ASC',
    );
    return List.generate(maps.length, (i) => NotesSectionDto.fromJson(maps[i]));
  }

  @override
  Future<NotesSectionDto> createSection(NotesSectionCreateRequest request) async {
    final db = _dbHelper.database;
    final sectionId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final newSection = {
      'section_id': sectionId,
      'notes_subject_id': request.notesSubjectId,
      'section_name': request.sectionName,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.insert('notes_sections', newSection);
      await _dbHelper.enqueueOperation(txn, 'notes_section', sectionId, 'create', newSection);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'notes_section',
        'entity_id': sectionId,
        'action_type': 'created',
        'activity_message': "Created notes section '${request.sectionName}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return NotesSectionDto.fromJson(newSection);
  }

  @override
  Future<NotesSectionDto> updateSection(String sectionId, NotesSectionUpdateRequest request) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final updates = {
      'section_name': request.sectionName,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.update(
        'notes_sections',
        updates,
        where: 'section_id = ?',
        whereArgs: [sectionId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'notes_sections',
        where: 'section_id = ?',
        whereArgs: [sectionId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'notes_section', sectionId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'notes_section',
        'entity_id': sectionId,
        'action_type': 'updated',
        'activity_message': "Updated notes section to '${request.sectionName}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'notes_sections',
      where: 'section_id = ?',
      whereArgs: [sectionId],
    );
    return NotesSectionDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'notes_sections',
        where: 'section_id = ?',
        whereArgs: [sectionId],
      );

      await _dbHelper.enqueueOperation(txn, 'notes_section', sectionId, 'delete', null);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'notes_section',
        'entity_id': sectionId,
        'action_type': 'deleted',
        'activity_message': "Deleted notes section.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }

  @override
  Future<List<NotesResourceDto>> getResources({
    String? sectionId,
    String? q,
    String? semesterId,
  }) async {
    final db = _dbHelper.database;
    
    String query = 'SELECT r.* FROM notes_resources r';
    final List<dynamic> args = [];
    
    if (semesterId != null) {
      query += '''
        JOIN notes_sections s ON r.section_id = s.section_id
        JOIN notes_subjects sub ON s.notes_subject_id = sub.notes_subject_id
        WHERE sub.semester_id = ?
      ''';
      args.add(semesterId);
    } else {
      query += ' WHERE 1=1';
    }

    if (sectionId != null) {
      query += ' AND r.section_id = ?';
      args.add(sectionId);
    }

    if (q != null && q.isNotEmpty) {
      query += ' AND (r.resource_name LIKE ? OR r.file_name LIKE ?)';
      args.add('%$q%');
      args.add('%$q%');
    }

    query += ' ORDER BY r.created_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => NotesResourceDto.fromJson(maps[i]));
  }

  @override
  Future<NotesResourceDto> createResource(NotesResourceCreateRequest request) async {
    final db = _dbHelper.database;
    final resourceId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final newResource = {
      'resource_id': resourceId,
      'section_id': request.sectionId,
      'resource_name': request.resourceName,
      'file_name': request.fileName,
      'mime_type': request.mimeType,
      'file_size_bytes': request.fileSizeLinesOrBytes,
      'storage_path': request.storagePath,
      'uploaded_via': request.uploadedVia,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.insert('notes_resources', newResource);
      await _dbHelper.enqueueOperation(txn, 'notes_resource', resourceId, 'create', newResource);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'notes_resource',
        'entity_id': resourceId,
        'action_type': 'created',
        'activity_message': "Uploaded note resource '${request.resourceName}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return NotesResourceDto.fromJson(newResource);
  }

  @override
  Future<NotesResourceDto> updateResource(String resourceId, NotesResourceUpdateRequest request) async {
    final db = _dbHelper.database;
    final res = await getResources(q: ''); // Dummy query to get resource
    final target = res.firstWhere((r) => r.resourceId == resourceId);
    
    final nowStr = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.resourceName != null) updates['resource_name'] = request.resourceName;
    if (request.fileName != null) updates['file_name'] = request.fileName;
    if (request.mimeType != null) updates['mime_type'] = request.mimeType;
    if (request.fileSizeLinesOrBytes != null) updates['file_size_bytes'] = request.fileSizeLinesOrBytes;
    if (request.storagePath != null) updates['storage_path'] = request.storagePath;
    if (request.uploadedVia != null) updates['uploaded_via'] = request.uploadedVia;

    await db.transaction((txn) async {
      await txn.update(
        'notes_resources',
        updates,
        where: 'resource_id = ?',
        whereArgs: [resourceId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'notes_resources',
        where: 'resource_id = ?',
        whereArgs: [resourceId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'notes_resource', resourceId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'notes_resource',
        'entity_id': resourceId,
        'action_type': 'updated',
        'activity_message': "Updated note resource '${request.resourceName ?? target.resourceName}'.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'notes_resources',
      where: 'resource_id = ?',
      whereArgs: [resourceId],
    );
    return NotesResourceDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteResource(String resourceId) async {
    final db = _dbHelper.database;
    final nowStr = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'notes_resources',
        where: 'resource_id = ?',
        whereArgs: [resourceId],
      );

      await _dbHelper.enqueueOperation(txn, 'notes_resource', resourceId, 'delete', null);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'notes_resource',
        'entity_id': resourceId,
        'action_type': 'deleted',
        'activity_message': "Deleted note resource.",
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }

  @override
  Future<List<NotesSubjectDetailDto>> getHierarchy(String semesterId) async {
    final db = _dbHelper.database;
    
    // 1. Get notes subjects
    final List<Map<String, dynamic>> subjectMaps = await db.query(
      'notes_subjects',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'notes_subject_name ASC',
    );

    final List<NotesSubjectDetailDto> result = [];

    for (final subRow in subjectMaps) {
      final String notesSubjectId = subRow['notes_subject_id'] as String;
      
      // 2. Get sections for subject
      final List<Map<String, dynamic>> sectionMaps = await db.query(
        'notes_sections',
        where: 'notes_subject_id = ?',
        whereArgs: [notesSubjectId],
        orderBy: 'section_name ASC',
      );

      final List<Map<String, dynamic>> sectionsWithResources = [];

      for (final secRow in sectionMaps) {
        final String sectionId = secRow['section_id'] as String;

        // 3. Get resources for section
        final List<Map<String, dynamic>> resourceMaps = await db.query(
          'notes_resources',
          where: 'section_id = ?',
          whereArgs: [sectionId],
          orderBy: 'resource_name ASC',
        );

        final secMap = Map<String, dynamic>.from(secRow);
        secMap['resources'] = resourceMaps;
        sectionsWithResources.add(secMap);
      }

      final subDetailMap = Map<String, dynamic>.from(subRow);
      subDetailMap['sections'] = sectionsWithResources;
      result.add(NotesSubjectDetailDto.fromJson(subDetailMap));
    }

    return result;
  }
}
