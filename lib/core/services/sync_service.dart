import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/local/database_helper.dart';
import '../network/dio_client.dart';
import '../network/api_constants.dart';
import '../exceptions/sync_exceptions.dart';
import 'auth_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? lastSyncTime;
  final int pendingCount;
  final String? errorMessage;

  SyncState({
    required this.status,
    this.lastSyncTime,
    required this.pendingCount,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? lastSyncTime,
    int? pendingCount,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingCount: pendingCount ?? this.pendingCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Dio _dio = DioClient().dio;
  AuthService? _customAuthService;

  AuthService get _authService => _customAuthService ?? AuthService.instance;

  @visibleForTesting
  void setMockDependencies(DatabaseHelper dbHelper, Dio dio, [AuthService? authService]) {
    _dbHelper = dbHelper;
    _dio = dio;
    _customAuthService = authService;
  }

  final ValueNotifier<SyncState> stateNotifier = ValueNotifier<SyncState>(
    SyncState(status: SyncStatus.idle, pendingCount: 0),
  );

  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;

  // Initialize connectivity monitoring
  void initialize() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        debugPrint('[SyncService] Online connectivity detected, triggering sync...');
        sync();
      }
    });
    // Set initial stats
    _updateState();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }

  Future<void> _updateState({SyncStatus? status, String? errorMessage}) async {
    if (!_authService.isSignedIn || _dbHelper.currentUserId == null) {
      stateNotifier.value = SyncState(
        status: status ?? SyncStatus.idle,
        lastSyncTime: null,
        pendingCount: 0,
        errorMessage: errorMessage,
      );
      return;
    }

    final count = await _getPendingCount();
    final lastSync = await _dbHelper.getLastSuccessfulSync();

    final newStatus = status ?? stateNotifier.value.status;
    String? newErrorMessage;
    if (newStatus == SyncStatus.syncing || newStatus == SyncStatus.success) {
      newErrorMessage = null;
    } else {
      newErrorMessage = errorMessage ?? (newStatus == SyncStatus.error ? stateNotifier.value.errorMessage : null);
    }

    stateNotifier.value = SyncState(
      status: newStatus,
      lastSyncTime: lastSync,
      pendingCount: count,
      errorMessage: newErrorMessage,
    );
  }

  Future<int> _getPendingCount() async {
    try {
      final db = _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_sync_operations');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Coalesce operations grouped by (entityType, entityId)
  List<Map<String, dynamic>> coalesceQueue(List<Map<String, dynamic>> rawOps) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final op in rawOps) {
      final key = '${op['entity_type']}:${op['entity_id']}';
      groups.putIfAbsent(key, () => []).add(op);
    }

    final List<Map<String, dynamic>> coalesced = [];

    for (final key in groups.keys) {
      final ops = groups[key]!;
      final hasCreate = ops.any((o) => o['operation_type'] == 'create');
      final isDeleted = ops.last['operation_type'] == 'delete';
      final List<String> sourceUuids = ops.map((o) => o['operation_uuid'] as String).toList();

      if (hasCreate) {
        if (isDeleted) {
          // Discard both CREATE and DELETE entirely
          continue;
        } else {
          // Keep as CREATE, with merged/latest payload
          final firstCreate = ops.firstWhere((o) => o['operation_type'] == 'create');
          final Map<String, dynamic> mergedPayload = {};
          for (final op in ops) {
            if (op['payload'] != null) {
              final decoded = jsonDecode(op['payload'] as String);
              if (decoded is Map<String, dynamic>) {
                mergedPayload.addAll(decoded);
              }
            }
          }
          final updatedOp = Map<String, dynamic>.from(firstCreate);
          updatedOp['payload'] = jsonEncode(mergedPayload);
          updatedOp['source_uuids'] = sourceUuids;
          coalesced.add(updatedOp);
        }
      } else {
        if (isDeleted) {
          // Keep only the DELETE operation
          final lastDelete = ops.lastWhere((o) => o['operation_type'] == 'delete');
          final updatedOp = Map<String, dynamic>.from(lastDelete);
          updatedOp['source_uuids'] = sourceUuids;
          coalesced.add(updatedOp);
        } else {
          // Keep as UPDATE, with merged/latest payload
          final firstUpdate = ops.firstWhere((o) => o['operation_type'] == 'update');
          final Map<String, dynamic> mergedPayload = {};
          for (final op in ops) {
            if (op['payload'] != null) {
              final decoded = jsonDecode(op['payload'] as String);
              if (decoded is Map<String, dynamic>) {
                mergedPayload.addAll(decoded);
              }
            }
          }
          final updatedOp = Map<String, dynamic>.from(firstUpdate);
          updatedOp['payload'] = jsonEncode(mergedPayload);
          updatedOp['source_uuids'] = sourceUuids;
          coalesced.add(updatedOp);
        }
      }
    }

    // Sort by chronological order using the auto-increment ID
    coalesced.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return coalesced;
  }

  // Main synchronization function
  Future<void> sync() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Sync already in progress. Exiting.');
      return;
    }
    if (!_authService.isSignedIn) {
      debugPrint('[SyncService] User is not signed in. Exiting.');
      return;
    }

    _isSyncing = true;
    await _updateState(status: SyncStatus.syncing);

    try {
      // 1. UPLOAD local changes
      final bool uploadSuccess = await _uploadPendingOperations();
      if (!uploadSuccess) {
        throw Exception('Upload pipeline failed due to server or network errors.');
      }

      // 2. DOWNLOAD remote changes
      await _downloadRemoteChanges();

      await _dbHelper.setLastSuccessfulSync(DateTime.now().toUtc().toIso8601String());
      final pendingCount = await _getPendingCount();
      if (pendingCount > 0) {
        await _updateState(
          status: SyncStatus.error,
          errorMessage: 'Some operations are pending retry due to previous failures.',
        );
      } else {
        await _updateState(status: SyncStatus.success);
      }
      debugPrint('[SyncService] Sync completed successfully.');
    } on UnsupportedSyncProtocolException catch (e) {
      debugPrint('[SyncService] Sync aborted due to protocol mismatch: $e');
      await _updateState(
        status: SyncStatus.error,
        errorMessage: 'This version of Student Buddy is no longer compatible with the server. Please update the application.',
      );
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
      await _updateState(status: SyncStatus.error, errorMessage: e.toString());
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 5), () {
      debugPrint('[SyncService] Retrying scheduled sync...');
      sync();
    });
  }

  // Upload local changes sequentially in chronological order
  Future<bool> _uploadPendingOperations() async {
    final rawOps = await _dbHelper.getPendingOperations();
    if (rawOps.isEmpty) return true;

    // First: identify and discard any entities that have both a CREATE and a DELETE operation in the queue.
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final op in rawOps) {
      final key = '${op['entity_type']}:${op['entity_id']}';
      groups.putIfAbsent(key, () => []).add(op);
    }

    final List<String> discardedUuids = [];
    final List<Map<String, dynamic>> nonDiscardedOps = [];

    for (final key in groups.keys) {
      final ops = groups[key]!;
      final hasCreate = ops.any((o) => o['operation_type'] == 'create');
      final isDeleted = ops.last['operation_type'] == 'delete';

      if (hasCreate && isDeleted) {
        discardedUuids.addAll(ops.map((o) => o['operation_uuid'] as String));
      } else {
        nonDiscardedOps.addAll(ops);
      }
    }

    if (discardedUuids.isNotEmpty) {
      debugPrint('[SyncService] Discarding ${discardedUuids.length} operations from queue because they were created and then deleted offline.');
      await _dbHelper.removePendingOperations(discardedUuids);
    }

    if (nonDiscardedOps.isEmpty) return true;

    final coalesced = coalesceQueue(nonDiscardedOps);

    for (final op in coalesced) {
      final String uuid = op['operation_uuid'];
      final String entityType = op['entity_type'];
      final String entityId = op['entity_id'];
      final String operationType = op['operation_type'];
      final int retryCount = op['retry_count'] ?? 0;
      final List<String> sourceUuids = List<String>.from(op['source_uuids'] ?? [uuid]);

      // Exponential backoff logic based on retry count
      if (retryCount > 0) {
        final backoffDuration = Duration(seconds: 1 << retryCount);
        final createdAt = DateTime.parse(op['created_at']);
        if (DateTime.now().difference(createdAt) < backoffDuration) {
          debugPrint('[SyncService] Skipping operation $uuid due to backoff cooldown.');
          continue;
        }
      }

      Map<String, dynamic>? payload;
      if (op['payload'] != null) {
        payload = _normalizeForApi(entityType, jsonDecode(op['payload'] as String));
      }

      try {
        await _sendApiRequest(entityType, entityId, operationType, payload);
        // Remove all coalesced source operations from db queue upon success
        await _dbHelper.removePendingOperations(sourceUuids);
      } catch (e) {
        debugPrint('[SyncService] Failed to upload operation $uuid: $e');
        
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 409 || 
              (statusCode == 404 && (operationType == 'delete' || operationType == 'update'))) {
            debugPrint('[SyncService] Idempotent ignore: Server returned $statusCode for operation $operationType of $entityType ($entityId). Discarding operation from queue.');
            await _dbHelper.removePendingOperations(sourceUuids);
            continue;
          }
        }

        // Increment retry count for all source operations in the group
        for (final u in sourceUuids) {
          await _dbHelper.incrementRetryCount(u);
        }
        
        // If it's a network error (no connection), abort the rest of the queue to keep order
        if (_isNetworkError(e)) {
          debugPrint('[SyncService] Network error encountered. Suspending upload queue.');
          return false;
        }
        // For other server validation errors, we can log and continue or abort. Let's abort to ensure consistency.
        return false;
      }
    }
    return true;
  }

  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.connectionError;
    }
    return false;
  }

  Future<void> _sendApiRequest(
    String entityType,
    String entityId,
    String operationType,
    Map<String, dynamic>? payload,
  ) async {
    final String path;
    switch (entityType) {
      case 'semester':
        path = '/academic/semesters';
        break;
      case 'subject':
        path = '/academic/subjects';
        break;
      case 'holiday':
        path = '/academic/holidays';
        break;
      case 'lecture_template':
        path = '/academic/lecture-templates';
        break;
      case 'lecture_instance':
        path = '/academic/lecture-instances';
        break;
      case 'attendance_settings':
        path = '/academic/attendance-settings';
        break;
      case 'app_settings':
        path = '/app-settings';
        break;
      case 'todo':
        path = '/todos';
        break;
      case 'notes_section':
        path = '/notes/sections';
        break;
      case 'notes_resource':
        path = '/notes/resources';
        break;
      case 'review_queue':
        path = '/review-queue';
        break;
      default:
        throw Exception('Unsupported entity type: $entityType');
    }

    if (operationType == 'create') {
      await _dio.post(path, data: payload);
    } else if (operationType == 'update') {
      if (entityType == 'app_settings') {
        await _dio.put(path, data: payload);
      } else if (entityType == 'attendance_settings') {
        await _dio.put('$path/$entityId', data: payload);
      } else {
        await _dio.put('$path/$entityId', data: payload);
      }
    } else if (operationType == 'delete') {
      await _dio.delete('$path/$entityId');
    }
  }

  // Download remote changes since last sync
  Future<void> _downloadRemoteChanges() async {
    final lastSync = await _dbHelper.getLastSuccessfulSync();
    final Map<String, dynamic> queryParams = {};
    if (lastSync != null) {
      queryParams['since'] = lastSync;
    }

    final response = await _dio.get('/users/me/bootstrap', queryParameters: queryParams);
    final data = response.data;
    if (data == null || data['success'] != true) {
      throw Exception('Failed to fetch remote bootstrap changes.');
    }

    final serverVersion = data['sync_version'] as int?;
    if (serverVersion == null ||
        serverVersion < ApiConstants.minSupportedSyncVersion ||
        serverVersion > ApiConstants.maxSupportedSyncVersion) {
      print('Synchronization aborted.');
      print('Client protocol version : ${ApiConstants.minSupportedSyncVersion}-${ApiConstants.maxSupportedSyncVersion}');
      print('Server protocol version : $serverVersion');
      throw UnsupportedSyncProtocolException(
        minExpectedVersion: ApiConstants.minSupportedSyncVersion,
        maxExpectedVersion: ApiConstants.maxSupportedSyncVersion,
        receivedVersion: serverVersion,
      );
    }

    final bootstrap = data['data'];
    if (bootstrap == null) return;

    final db = _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Process Deletions
      final deletions = bootstrap['deletions'] as List?;
      if (deletions != null) {
        for (final del in deletions) {
          final type = del['entity_type'] as String;
          final id = del['entity_id'] as String;
          await _applyLocalDeletion(txn, type, id);
        }
      }

      // 2. Process App Settings
      final appSettings = bootstrap['app_settings'];
      if (appSettings != null) {
        await _mergeEntity(txn, 'app_settings', 'settings_id', appSettings);
      }

      // 3. Semesters
      final semesters = bootstrap['semesters'] as List?;
      if (semesters != null) {
        for (final sem in semesters) {
          await _mergeEntity(txn, 'semesters', 'semester_id', sem);
        }
      }

      // 4. Subjects
      final subjects = bootstrap['subjects'] as List?;
      if (subjects != null) {
        for (final sub in subjects) {
          await _mergeEntity(txn, 'subjects', 'subject_id', sub);
        }
      }

      // 5. Lecture Templates
      final templates = bootstrap['lecture_templates'] as List?;
      if (templates != null) {
        for (final temp in templates) {
          await _mergeEntity(txn, 'lecture_templates', 'lecture_template_id', temp);
        }
      }

      // 6. Lecture Instances
      final instances = bootstrap['lecture_instances'] as List?;
      if (instances != null) {
        for (final inst in instances) {
          // Reconcile instances based on (lecture_template_id, lecture_date) to prevent duplicates
          final tempId = inst['lecture_template_id'] as String;
          final dateStr = inst['lecture_date'] as String;

          final existing = await txn.query(
            'lecture_instances',
            where: 'lecture_template_id = ? AND lecture_date = ?',
            whereArgs: [tempId, dateStr],
          );

          if (existing.isNotEmpty) {
            final localItem = existing.first;
            final localUpdatedAt = DateTime.parse(localItem['updated_at'] as String);
            final remoteUpdatedAt = DateTime.parse(inst['updated_at'] as String);

            if (remoteUpdatedAt.isAfter(localUpdatedAt) || remoteUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
              // Delete the old local record to avoid conflict if instance IDs are different, and insert remote
              await txn.delete(
                'lecture_instances',
                where: 'lecture_instance_id = ?',
                whereArgs: [localItem['lecture_instance_id']],
              );
              await txn.insert('lecture_instances', _normalizeForSqlite('lecture_instances', inst));
            }
          } else {
            await txn.insert('lecture_instances', _normalizeForSqlite('lecture_instances', inst));
          }
        }
      }

      // 7. Holidays
      final holidays = bootstrap['holidays'] as List?;
      if (holidays != null) {
        for (final hol in holidays) {
          await _mergeEntity(txn, 'holidays', 'holiday_id', hol);
        }
      }

      // 8. Attendance Settings
      final attendanceSettingsList = bootstrap['attendance_settings'] as List?;
      if (attendanceSettingsList != null) {
        for (final att in attendanceSettingsList) {
          await _mergeEntity(txn, 'attendance_settings', 'attendance_settings_id', att);
        }
      }

      // 9. Todos
      final todos = bootstrap['todos'] as List?;
      if (todos != null) {
        for (final todo in todos) {
          await _mergeEntity(txn, 'todos', 'todo_id', todo);
        }
      }

      // 10. Notes subjects, sections, and resources
      final notesSubjects = bootstrap['notes_subjects'] as List?;
      if (notesSubjects != null) {
        for (final subDetail in notesSubjects) {
          final subMap = {
            'notes_subject_id': subDetail['notes_subject_id'],
            'user_id': subDetail['user_id'],
            'semester_id': subDetail['semester_id'],
            'notes_subject_name': subDetail['notes_subject_name'],
            'created_at': subDetail['created_at'],
            'updated_at': subDetail['updated_at'],
          };
          await _mergeEntity(txn, 'notes_subjects', 'notes_subject_id', subMap);

          final sections = subDetail['sections'] as List?;
          if (sections != null) {
            for (final secDetail in sections) {
              final secMap = {
                'section_id': secDetail['section_id'],
                'notes_subject_id': secDetail['notes_subject_id'],
                'section_name': secDetail['section_name'],
                'created_at': secDetail['created_at'],
                'updated_at': secDetail['updated_at'],
              };
              await _mergeEntity(txn, 'notes_sections', 'section_id', secMap);

              final resources = secDetail['resources'] as List?;
              if (resources != null) {
                for (final res in resources) {
                  final resMap = {
                    'resource_id': res['resource_id'],
                    'section_id': res['section_id'],
                    'resource_name': res['resource_name'],
                    'file_name': res['file_name'],
                    'mime_type': res['mime_type'],
                    'file_size_bytes': res['file_size_bytes'],
                    'storage_path': res['storage_path'],
                    'uploaded_via': res['uploaded_via'],
                    'created_at': res['created_at'],
                    'updated_at': res['updated_at'],
                  };
                  await _mergeEntity(txn, 'notes_resources', 'resource_id', resMap);
                }
              }
            }
          }
        }
      }

      // 11. Review Queue
      final reviewQueue = bootstrap['review_queue'] as List?;
      if (reviewQueue != null) {
        for (final req in reviewQueue) {
          await _mergeEntity(txn, 'review_queue', 'review_id', req);
        }
      }

      // 12. Activity Logs
      final activityLogs = bootstrap['activity_logs'] as List?;
      if (activityLogs != null) {
        for (final log in activityLogs) {
          await _mergeEntity(txn, 'activity_logs', 'activity_id', log);
        }
      }
    });
  }

  Future<void> _applyLocalDeletion(Transaction txn, String type, String id) async {
    final String table;
    final String pkColumn;

    switch (type) {
      case 'semester':
        table = 'semesters';
        pkColumn = 'semester_id';
        break;
      case 'subject':
        table = 'subjects';
        pkColumn = 'subject_id';
        break;
      case 'lecture_template':
        table = 'lecture_templates';
        pkColumn = 'lecture_template_id';
        break;
      case 'holiday':
        table = 'holidays';
        pkColumn = 'holiday_id';
        break;
      case 'todo':
        table = 'todos';
        pkColumn = 'todo_id';
        break;
      case 'notes_section':
        table = 'notes_sections';
        pkColumn = 'section_id';
        break;
      case 'notes_resource':
        table = 'notes_resources';
        pkColumn = 'resource_id';
        break;
      case 'notes_subject':
        table = 'notes_subjects';
        pkColumn = 'notes_subject_id';
        break;
      default:
        return; // ignore unsupported deletions
    }

    await txn.delete(table, where: '$pkColumn = ?', whereArgs: [id]);
  }

  // Merge record using Last Write Wins logic
  Future<void> _mergeEntity(
    Transaction txn,
    String table,
    String pkColumn,
    Map<String, dynamic> remoteData,
  ) async {
    final id = remoteData[pkColumn];
    if (id == null) return;

    if (table == 'app_settings') {
      // Handle active_semester_id by storing it in local_metadata
      final activeSemId = remoteData['active_semester_id'];
      if (activeSemId != null) {
        await txn.insert(
          'local_metadata',
          {
            'key': 'active_semester_id',
            'value': activeSemId.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await txn.delete(
          'local_metadata',
          where: 'key = ?',
          whereArgs: ['active_semester_id'],
        );
      }
    }


    if (table == 'activity_logs') {
      final String? entityType = remoteData['entity_type'];
      final String? entityId = remoteData['entity_id'];
      final String? actionType = remoteData['action_type'];
      if (entityType != null && entityId != null && actionType != null) {
        await txn.delete(
          'activity_logs',
          where: 'entity_type = ? AND entity_id = ? AND action_type = ? AND activity_id != ?',
          whereArgs: [entityType, entityId, actionType, id],
        );
      }
    }

    final existing = await txn.query(table, where: '$pkColumn = ?', whereArgs: [id]);
    final normalizedRemote = _normalizeForSqlite(table, remoteData);

    if (existing.isEmpty) {
      await txn.insert(table, normalizedRemote);
    } else {
      final localItem = existing.first;
      final localUpdatedAtStr = localItem['updated_at'] ?? localItem['created_at'];
      final remoteUpdatedAtStr = remoteData['updated_at'] ?? remoteData['created_at'];

      if (localUpdatedAtStr != null && remoteUpdatedAtStr != null) {
        final localUpdatedAt = DateTime.parse(localUpdatedAtStr as String);
        final remoteUpdatedAt = DateTime.parse(remoteUpdatedAtStr as String);

        if (remoteUpdatedAt.isAfter(localUpdatedAt) || remoteUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
          await txn.update(
            table,
            normalizedRemote,
            where: '$pkColumn = ?',
            whereArgs: [id],
          );
        }
      } else {
        // Fallback: overwrite if no timestamps to compare
        await txn.update(
          table,
          normalizedRemote,
          where: '$pkColumn = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Map<String, dynamic> _normalizeForSqlite(String table, Map<String, dynamic> remoteData) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(remoteData);

    // Schema whitelist for each table to prevent column mismatch exceptions
    const Map<String, Set<String>> tableSchemas = {
      'semesters': {
        'semester_id',
        'user_id',
        'semester_number',
        'start_date',
        'end_date',
        'created_at',
        'updated_at',
      },
      'subjects': {
        'subject_id',
        'semester_id',
        'subject_name',
        'faculty_name',
        'theme_color',
        'attendance_goal',
        'created_at',
        'updated_at',
      },
      'lecture_templates': {
        'lecture_template_id',
        'subject_id',
        'day_of_week',
        'start_time',
        'end_time',
        'room',
        'created_at',
        'updated_at',
      },
      'lecture_instances': {
        'lecture_instance_id',
        'lecture_template_id',
        'lecture_date',
        'lecture_status',
        'attendance_status',
        'created_at',
        'updated_at',
      },
      'holidays': {
        'holiday_id',
        'semester_id',
        'holiday_date',
        'holiday_name',
        'created_at',
        'updated_at',
      },
      'attendance_settings': {
        'attendance_settings_id',
        'semester_id',
        'criteria_mode',
        'overall_attendance_goal',
        'created_at',
        'updated_at',
      },
      'todos': {
        'todo_id',
        'user_id',
        'title',
        'priority',
        'status',
        'created_by',
        'due_datetime',
        'completed_at',
        'created_at',
        'updated_at',
      },
      'app_settings': {
        'settings_id',
        'user_id',
        'theme_mode',
        'finance_enabled',
        'morning_digest_enabled',
        'night_digest_enabled',
        'attendance_prompt_enabled',
        'notes_download_directory',
        'created_at',
        'updated_at',
      },
      'notes_subjects': {
        'notes_subject_id',
        'user_id',
        'semester_id',
        'notes_subject_name',
        'created_at',
        'updated_at',
      },
      'notes_sections': {
        'section_id',
        'notes_subject_id',
        'section_name',
        'created_at',
        'updated_at',
      },
      'notes_resources': {
        'resource_id',
        'section_id',
        'resource_name',
        'file_name',
        'mime_type',
        'file_size_bytes',
        'storage_path',
        'uploaded_via',
        'created_at',
        'updated_at',
      },
      'review_queue': {
        'review_id',
        'user_id',
        'review_type',
        'entity_type',
        'entity_id',
        'review_message',
        'review_status',
        'resolved_by',
        'created_at',
        'resolved_at',
      },
      'activity_logs': {
        'activity_id',
        'user_id',
        'actor_type',
        'entity_type',
        'entity_id',
        'action_type',
        'activity_message',
        'correlation_id',
        'created_at',
      },
    };

    final currentUserId = _dbHelper.currentUserId;

    if (tableSchemas.containsKey(table)) {
      final allowedKeys = tableSchemas[table]!;
      normalized.removeWhere((key, _) => !allowedKeys.contains(key));
      
      // If table requires user_id but remote data lacks it or it is null, populate it
      if (allowedKeys.contains('user_id') && (normalized['user_id'] == null) && currentUserId != null) {
        normalized['user_id'] = currentUserId;
      }
    }

    if (table == 'app_settings') {
      if (normalized['finance_enabled'] is bool) {
        normalized['finance_enabled'] = (normalized['finance_enabled'] as bool) ? 1 : 0;
      }
      if (normalized['morning_digest_enabled'] is bool) {
        normalized['morning_digest_enabled'] = (normalized['morning_digest_enabled'] as bool) ? 1 : 0;
      }
      if (normalized['night_digest_enabled'] is bool) {
        normalized['night_digest_enabled'] = (normalized['night_digest_enabled'] as bool) ? 1 : 0;
      }
      if (normalized['attendance_prompt_enabled'] is bool) {
        normalized['attendance_prompt_enabled'] = (normalized['attendance_prompt_enabled'] as bool) ? 1 : 0;
      }
    }

    return normalized;
  }

  Map<String, dynamic> _normalizeForApi(String entityType, Map<String, dynamic> localData) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(localData);
    if (entityType == 'app_settings') {
      if (normalized['finance_enabled'] is int) {
        normalized['finance_enabled'] = normalized['finance_enabled'] == 1;
      }
      if (normalized['morning_digest_enabled'] is int) {
        normalized['morning_digest_enabled'] = normalized['morning_digest_enabled'] == 1;
      }
      if (normalized['night_digest_enabled'] is int) {
        normalized['night_digest_enabled'] = normalized['night_digest_enabled'] == 1;
      }
      if (normalized['attendance_prompt_enabled'] is int) {
        normalized['attendance_prompt_enabled'] = normalized['attendance_prompt_enabled'] == 1;
      }
    } else if (entityType == 'todo') {
      if (normalized['is_completed'] is int) {
        normalized['is_completed'] = normalized['is_completed'] == 1;
      }
    }
    return normalized;
  }
}
