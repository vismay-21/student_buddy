import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_buddy/core/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService Coalescing Rules', () {
    final syncService = SyncService.instance;

    test('Rule 1: CREATE + UPDATE + UPDATE -> CREATE with latest payload', () {
      final List<Map<String, dynamic>> ops = [
        {
          'id': 1,
          'operation_uuid': 'uuid1',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'create',
          'payload': '{"todo_title": "Original Title", "is_completed": 0}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid2',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'update',
          'payload': '{"todo_title": "Updated Title"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 3,
          'operation_uuid': 'uuid3',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'update',
          'payload': '{"is_completed": 1}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ];

      final coalesced = syncService.coalesceQueue(ops);
      expect(coalesced.length, equals(1));
      expect(coalesced.first['operation_type'], equals('create'));
      expect(coalesced.first['entity_id'], equals('todo_1'));
      
      final payload = coalesced.first['payload'];
      expect(payload, isNotNull);
      
      final payloadMap = jsonDecode(payload as String);
      expect(payloadMap['todo_title'], equals('Updated Title'));
      expect(payloadMap['is_completed'], equals(1));
    });

    test('Rule 2: UPDATE + UPDATE -> UPDATE with latest payload', () {
      final List<Map<String, dynamic>> ops = [
        {
          'id': 1,
          'operation_uuid': 'uuid1',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'update',
          'payload': '{"todo_title": "Title 1"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid2',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'update',
          'payload': '{"todo_title": "Title 2", "is_completed": 1}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ];

      final coalesced = syncService.coalesceQueue(ops);
      expect(coalesced.length, equals(1));
      expect(coalesced.first['operation_type'], equals('update'));
      
      final payloadMap = jsonDecode(coalesced.first['payload'] as String);
      expect(payloadMap['todo_title'], equals('Title 2'));
      expect(payloadMap['is_completed'], equals(1));
    });

    test('Rule 3: UPDATE + DELETE -> DELETE', () {
      final List<Map<String, dynamic>> ops = [
        {
          'id': 1,
          'operation_uuid': 'uuid1',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'update',
          'payload': '{"todo_title": "Title 1"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid2',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'delete',
          'payload': null,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ];

      final coalesced = syncService.coalesceQueue(ops);
      expect(coalesced.length, equals(1));
      expect(coalesced.first['operation_type'], equals('delete'));
    });

    test('Rule 4: CREATE + DELETE -> Discard both completely', () {
      final List<Map<String, dynamic>> ops = [
        {
          'id': 1,
          'operation_uuid': 'uuid1',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'create',
          'payload': '{"todo_title": "Original Title"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 2,
          'operation_uuid': 'uuid2',
          'entity_type': 'todo',
          'entity_id': 'todo_1',
          'operation_type': 'delete',
          'payload': null,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ];

      final coalesced = syncService.coalesceQueue(ops);
      expect(coalesced.isEmpty, isTrue);
    });
  group('Chronological ordering preservation', () {
    final syncService = SyncService.instance;
    test('Should preserve chronological sorting across different entities based on original earliest id', () {
      final List<Map<String, dynamic>> ops = [
        {
          'id': 10,
          'operation_uuid': 'uuid1',
          'entity_type': 'semester',
          'entity_id': 'sem_1',
          'operation_type': 'create',
          'payload': '{"semester_name": "S1"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 11,
          'operation_uuid': 'uuid2',
          'entity_type': 'subject',
          'entity_id': 'sub_1',
          'operation_type': 'create',
          'payload': '{"subject_name": "Math"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
        {
          'id': 12,
          'operation_uuid': 'uuid3',
          'entity_type': 'semester',
          'entity_id': 'sem_1',
          'operation_type': 'update',
          'payload': '{"semester_name": "S1 Updated"}',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'retry_count': 0,
        },
      ];

      final coalesced = syncService.coalesceQueue(ops);
      expect(coalesced.length, equals(2));
      
      // The first should be semester (since id 10 < id 11)
      expect(coalesced[0]['entity_type'], equals('semester'));
      expect(coalesced[0]['operation_type'], equals('create'));
      expect(jsonDecode(coalesced[0]['payload'] as String)['semester_name'], equals('S1 Updated'));

      // The second should be subject (since id 11)
      expect(coalesced[1]['entity_type'], equals('subject'));
      expect(coalesced[1]['operation_type'], equals('create'));
    });
  });
  });
}
