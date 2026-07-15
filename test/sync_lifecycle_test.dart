import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:student_buddy/core/services/sync_service.dart';
import 'package:student_buddy/core/services/auth_service.dart';
import 'package:student_buddy/data/local/database_helper.dart';

// Use Fake class from flutter_test to avoid implementing every single member
class FakeDatabase extends Fake implements Database {
  final List<String> executedStatements = [];
  final List<Map<String, dynamic>> queryResult;
  List<Map<String, dynamic>> Function(String sql, List<Object?>? arguments)? rawQueryCallback;

  FakeDatabase({this.queryResult = const [], this.rawQueryCallback});

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    executedStatements.add('rawQuery:$sql args:$arguments');
    if (rawQueryCallback != null) {
      return rawQueryCallback!(sql, arguments);
    }
    return queryResult;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    final fakeTxn = FakeTransaction(this);
    return await action(fakeTxn);
  }
}

class FakeTransaction extends Fake implements Transaction {
  final FakeDatabase db;
  FakeTransaction(this.db);

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    db.executedStatements.add('query:$table where:$where args:$whereArgs');
    return db.queryResult;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    db.executedStatements.add('insert:$table values:$values');
    return 1;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    db.executedStatements.add('update:$table values:$values where:$where args:$whereArgs');
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    db.executedStatements.add('delete:$table where:$where args:$whereArgs');
    return 1;
  }
}

class FakeDatabaseHelper extends Fake implements DatabaseHelper {
  final List<Map<String, dynamic>> pendingOperations = [];
  String? lastSuccessfulSync;
  final FakeDatabase fakeDatabase;

  FakeDatabaseHelper(this.fakeDatabase);

  @override
  Database get database => fakeDatabase;

  @override
  String? get currentUserId => 'test_user';

  @override
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    return List.from(pendingOperations);
  }

  @override
  Future<void> removePendingOperation(String uuid) async {
    pendingOperations.removeWhere((op) => op['operation_uuid'] == uuid);
  }

  @override
  Future<void> removePendingOperations(List<String> uuids) async {
    pendingOperations.removeWhere((op) => uuids.contains(op['operation_uuid']));
  }

  @override
  Future<void> incrementRetryCount(String uuid) async {
    for (var i = 0; i < pendingOperations.length; i++) {
      final op = pendingOperations[i];
      if (op['operation_uuid'] == uuid) {
        final current = op['retry_count'] as int? ?? 0;
        final newOp = Map<String, dynamic>.from(op);
        newOp['retry_count'] = current + 1;
        pendingOperations[i] = newOp;
        break;
      }
    }
  }

  @override
  Future<String?> getLastSuccessfulSync() async {
    return lastSuccessfulSync;
  }

  @override
  Future<void> setLastSuccessfulSync(String timestamp) async {
    lastSuccessfulSync = timestamp;
  }
}

class FakeDio extends Fake implements Dio {
  final List<String> requests = [];
  final Map<String, dynamic> responses;
  int requestCount = 0;
  DioException? Function(String path, String operationType, dynamic data)? errorGenerator;

  FakeDio({this.responses = const {}});

  @override
  BaseOptions options = BaseOptions();

  @override
  HttpClientAdapter httpClientAdapter = HttpClientAdapter();

  @override
  Interceptors interceptors = Interceptors();

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    requests.add('POST:$path data:$data');
    requestCount++;
    if (errorGenerator != null) {
      final err = errorGenerator!(path, 'create', data);
      if (err != null) throw err;
    }
    final respData = responses[path] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: respData as T,
      statusCode: 201,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    requests.add('PUT:$path data:$data');
    requestCount++;
    if (errorGenerator != null) {
      final err = errorGenerator!(path, 'update', data);
      if (err != null) throw err;
    }
    final respData = responses[path] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: respData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    requests.add('DELETE:$path');
    requestCount++;
    if (errorGenerator != null) {
      final err = errorGenerator!(path, 'delete', null);
      if (err != null) throw err;
    }
    final respData = responses[path] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: respData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    requests.add('GET:$path query:$queryParameters');
    requestCount++;
    final respData = responses[path] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: respData as T,
      statusCode: 200,
    );
  }
}

class FakeAuthService extends Fake implements AuthService {
  @override
  bool get isSignedIn => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService - Complete Lifecycle & Hardening Tests', () {
    late FakeDatabase fakeDb;
    late FakeDatabaseHelper fakeDbHelper;
    late FakeDio fakeDio;
    late FakeAuthService fakeAuthService;
    late SyncService syncService;

    setUp(() {
      fakeDb = FakeDatabase();
      fakeDbHelper = FakeDatabaseHelper(fakeDb);
      fakeDb.rawQueryCallback = (sql, args) {
        if (sql.contains('COUNT(*)')) {
          return [{'count': fakeDbHelper.pendingOperations.length}];
        }
        return [];
      };
      fakeDio = FakeDio(responses: {
        '/users/me/bootstrap': {
          'success': true,
          'sync_version': 1,
          'generated_at': DateTime.now().toUtc().toIso8601String(),
          'data': {
            'deletions': [],
            'app_settings': null,
            'semesters': [],
            'subjects': [],
            'lecture_templates': [],
            'lecture_instances': [],
          }
        }
      });
      fakeAuthService = FakeAuthService();
      syncService = SyncService.instance;
      syncService.setMockDependencies(fakeDbHelper, fakeDio, fakeAuthService);
    });

    test('1. Sequenced execution of synchronization (Upload first, then Download)', () async {
      // Setup one pending upload operation
      fakeDbHelper.pendingOperations.add({
        'id': 1,
        'operation_uuid': 'uuid-1',
        'entity_type': 'todo',
        'entity_id': 'todo-1',
        'operation_type': 'create',
        'payload': '{"title": "Test Todo"}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'retry_count': 0,
      });

      await syncService.sync();

      // Verify execution order:
      // First request should be upload POST /todos
      // Second request should be download GET /users/me/bootstrap
      expect(fakeDio.requests.length, equals(2));
      expect(fakeDio.requests[0], startsWith('POST:/todos'));
      expect(fakeDio.requests[1], startsWith('GET:/users/me/bootstrap'));

      // Check that queue is clean
      expect(fakeDbHelper.pendingOperations.isEmpty, isTrue);
    });

    test('2. Crash/Failure Recovery: network failures halt the pipeline, keeping the rest of the queue intact', () async {
      // Setup three operations in the queue
      fakeDbHelper.pendingOperations.addAll([
        {
          'id': 1,
          'operation_uuid': 'uuid-1',
          'entity_type': 'todo',
          'entity_id': 'todo-1',
          'operation_type': 'create',
          'payload': '{"title": "Todo 1"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid-2',
          'entity_type': 'todo',
          'entity_id': 'todo-2',
          'operation_type': 'create',
          'payload': '{"title": "Todo 2"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 3,
          'operation_uuid': 'uuid-3',
          'entity_type': 'todo',
          'entity_id': 'todo-3',
          'operation_type': 'create',
          'payload': '{"title": "Todo 3"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ]);

      // Mock a connection timeout on the second request
      fakeDio.errorGenerator = (path, opType, data) {
        if (path == '/todos' && data != null && (data as Map)['title'] == 'Todo 2') {
          return DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timeout',
          );
        }
        return null;
      };

      await syncService.sync();

      // Verify requests: Todo 1 POSTed, Todo 2 POST failed, Todo 3 never POSTed, download never called
      expect(fakeDio.requests.length, equals(2));
      expect(fakeDio.requests[0], contains('Todo 1'));
      expect(fakeDio.requests[1], contains('Todo 2'));

      // Check remaining queue: Todo 1 removed, Todo 2 (retry count incremented) and Todo 3 still exist
      expect(fakeDbHelper.pendingOperations.length, equals(2));
      expect(fakeDbHelper.pendingOperations[0]['operation_uuid'], equals('uuid-2'));
      expect(fakeDbHelper.pendingOperations[0]['retry_count'], equals(1));
      expect(fakeDbHelper.pendingOperations[1]['operation_uuid'], equals('uuid-3'));
    });

    test('3. Server Idempotency: 409 Conflict on create is discarded safely', () async {
      fakeDbHelper.pendingOperations.add({
        'id': 1,
        'operation_uuid': 'uuid-1',
        'entity_type': 'todo',
        'entity_id': 'todo-1',
        'operation_type': 'create',
        'payload': '{"title": "Duplicate Todo"}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'retry_count': 0,
      });

      // Mock 409 Conflict response
      fakeDio.errorGenerator = (path, opType, data) {
        return DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 409,
            data: {'success': false, 'message': 'Already exists'},
          ),
          type: DioExceptionType.badResponse,
        );
      };

      await syncService.sync();

      // Check that the queue is cleared (idempotently discarded!)
      expect(fakeDbHelper.pendingOperations.isEmpty, isTrue);
    });

    test('4. Server Idempotency: 404 Not Found on delete is discarded safely', () async {
      fakeDbHelper.pendingOperations.add({
        'id': 1,
        'operation_uuid': 'uuid-1',
        'entity_type': 'todo',
        'entity_id': 'todo-1',
        'operation_type': 'delete',
        'payload': null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'retry_count': 0,
      });

      // Mock 404 Not Found response
      fakeDio.errorGenerator = (path, opType, data) {
        return DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 404,
            data: {'success': false, 'message': 'Not found'},
          ),
          type: DioExceptionType.badResponse,
        );
      };

      await syncService.sync();

      // Queue is cleared
      expect(fakeDbHelper.pendingOperations.isEmpty, isTrue);
    });

    test('5. Sync Protocol Versioning: Matching version proceeds normally', () async {
      // Mock bootstrap response with matching version (1)
      fakeDio.responses['/users/me/bootstrap'] = {
        'success': true,
        'sync_version': 1,
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'deletions': [],
          'app_settings': null,
          'semesters': [],
          'subjects': [],
          'lecture_templates': [],
          'lecture_instances': [],
        }
      };

      await syncService.sync();

      expect(syncService.stateNotifier.value.status, equals(SyncStatus.success));
      final lastSync = await fakeDbHelper.getLastSuccessfulSync();
      expect(lastSync, isNotNull);
    });

    test('6. Sync Protocol Versioning: Mismatched version throws exception, halts sync, and database remains untouched', () async {
      // Clear last successful sync first
      fakeDbHelper.lastSuccessfulSync = null;

      // Mock bootstrap response with incompatible version (2)
      fakeDio.responses['/users/me/bootstrap'] = {
        'success': true,
        'sync_version': 2,
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'deletions': [],
          'app_settings': null,
          'semesters': [],
          'subjects': [],
          'lecture_templates': [],
          'lecture_instances': [],
        }
      };

      await syncService.sync();

      // Verify sync state is error and contains the friendly message
      expect(syncService.stateNotifier.value.status, equals(SyncStatus.error));
      expect(
        syncService.stateNotifier.value.errorMessage,
        contains('This version of Student Buddy is no longer compatible with the server.'),
      );

      // Verify database remains untouched (last_successful_sync is not written)
      final lastSync = await fakeDbHelper.getLastSuccessfulSync();
      expect(lastSync, isNull);
    });

    test('7. Queue Cleanliness: Coalesced multiple updates removes all contributing source operation UUIDs', () async {
      // Setup three pending updates for the same todo
      fakeDbHelper.pendingOperations.addAll([
        {
          'id': 1,
          'operation_uuid': 'uuid-update-1',
          'entity_type': 'todo',
          'entity_id': 'todo-1',
          'operation_type': 'update',
          'payload': '{"title": "Title A"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid-update-2',
          'entity_type': 'todo',
          'entity_id': 'todo-1',
          'operation_type': 'update',
          'payload': '{"is_completed": true}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ]);

      await syncService.sync();

      // Check that the queue is fully cleared (both uuid-update-1 and uuid-update-2 are deleted)
      expect(fakeDbHelper.pendingOperations.isEmpty, isTrue);
    });

    test('8. Queue Cleanliness: Immediate discard of CREATE + DELETE removes them from queue without hitting API', () async {
      // Setup pending CREATE and DELETE for the same todo
      fakeDbHelper.pendingOperations.addAll([
        {
          'id': 1,
          'operation_uuid': 'uuid-create',
          'entity_type': 'todo',
          'entity_id': 'todo-1',
          'operation_type': 'create',
          'payload': '{"title": "Temporary Todo"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid-delete',
          'entity_type': 'todo',
          'entity_id': 'todo-1',
          'operation_type': 'delete',
          'payload': null,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ]);

      await syncService.sync();

      // Verify no API requests were made to /todos (only GET for bootstrap runs)
      expect(fakeDio.requests.any((r) => r.contains('POST:/todos') || r.contains('DELETE:/todos')), isFalse);

      // Verify the queue is completely cleared
      expect(fakeDbHelper.pendingOperations.isEmpty, isTrue);
    });

    test('9. Sync status is set to error if operations are skipped/pending due to backoff', () async {
      // Setup a pending operation with retry_count > 0 so that it is skipped (cooldown backoff)
      final nowStr = DateTime.now().toUtc().toIso8601String();
      fakeDbHelper.pendingOperations.add({
        'id': 1,
        'operation_uuid': 'uuid-retry',
        'entity_type': 'todo',
        'entity_id': 'todo-1',
        'operation_type': 'update',
        'payload': '{"title": "Retry Todo"}',
        'created_at': nowStr,
        'retry_count': 2,
      });

      await syncService.sync();

      // Check that syncState is set to error because of the skipped pending operation
      expect(syncService.stateNotifier.value.status, equals(SyncStatus.error));
      expect(syncService.stateNotifier.value.errorMessage, contains('Some operations are pending retry due to previous failures.'));
      expect(syncService.stateNotifier.value.pendingCount, equals(1));
    });
  });
}
