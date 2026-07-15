import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/uuid_generator.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  Database? _database;
  String? _currentUserId;

  DatabaseHelper._init();

  Database get database {
    if (_database == null) {
      throw StateError("Database has not been initialized. Call initDatabase(userId) first.");
    }
    return _database!;
  }

  String? get currentUserId => _currentUserId;

  Future<void> initDatabase(String userId) async {
    // If the database is already initialized for the SAME user, do nothing.
    if (_database != null && _currentUserId == userId) {
      return;
    }

    // If database was opened for another user, close it first.
    if (_database != null) {
      await closeDatabase();
    }

    _currentUserId = userId;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "student_buddy_$userId.db");

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute("PRAGMA foreign_keys = ON;");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_sync_operations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation_uuid TEXT UNIQUE NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          operation_type TEXT NOT NULL,
          payload TEXT,
          created_at TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0
        );
      ''');
    }
  }

  Future<void> _createDb(Database db, int version) async {
    // Create local_metadata
    await db.execute('''
      CREATE TABLE local_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    // Create pending_sync_operations
    await db.execute('''
      CREATE TABLE pending_sync_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_uuid TEXT UNIQUE NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Create app_settings
    await db.execute('''
      CREATE TABLE app_settings (
        settings_id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        theme_mode TEXT NOT NULL DEFAULT 'system',
        finance_enabled INTEGER NOT NULL DEFAULT 0,
        morning_digest_enabled INTEGER NOT NULL DEFAULT 1,
        night_digest_enabled INTEGER NOT NULL DEFAULT 1,
        attendance_prompt_enabled INTEGER NOT NULL DEFAULT 1,
        notes_download_directory TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    // Create semesters
    await db.execute('''
      CREATE TABLE semesters (
        semester_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        semester_number INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    // Create attendance_settings
    await db.execute('''
      CREATE TABLE attendance_settings (
        attendance_settings_id TEXT PRIMARY KEY,
        semester_id TEXT NOT NULL UNIQUE,
        criteria_mode TEXT NOT NULL DEFAULT 'overall',
        overall_attendance_goal INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES semesters (semester_id) ON DELETE CASCADE
      );
    ''');

    // Create subjects
    await db.execute('''
      CREATE TABLE subjects (
        subject_id TEXT PRIMARY KEY,
        semester_id TEXT NOT NULL,
        subject_name TEXT NOT NULL,
        faculty_name TEXT,
        theme_color TEXT NOT NULL,
        attendance_goal INTEGER NOT NULL DEFAULT 75,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES semesters (semester_id) ON DELETE CASCADE
      );
    ''');

    // Create lecture_templates
    await db.execute('''
      CREATE TABLE lecture_templates (
        lecture_template_id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        room TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (subject_id) ON DELETE CASCADE
      );
    ''');

    // Create lecture_instances
    await db.execute('''
      CREATE TABLE lecture_instances (
        lecture_instance_id TEXT PRIMARY KEY,
        lecture_template_id TEXT NOT NULL,
        lecture_date TEXT NOT NULL,
        lecture_status TEXT NOT NULL,
        attendance_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (lecture_template_id) REFERENCES lecture_templates (lecture_template_id) ON DELETE CASCADE
      );
    ''');

    // Create holidays
    await db.execute('''
      CREATE TABLE holidays (
        holiday_id TEXT PRIMARY KEY,
        semester_id TEXT NOT NULL,
        holiday_date TEXT NOT NULL,
        holiday_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES semesters (semester_id) ON DELETE CASCADE
      );
    ''');

    // Create todos
    await db.execute('''
      CREATE TABLE todos (
        todo_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_by TEXT NOT NULL,
        due_datetime TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    // Create notes_subjects
    await db.execute('''
      CREATE TABLE notes_subjects (
        notes_subject_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        semester_id TEXT NOT NULL,
        notes_subject_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES semesters (semester_id) ON DELETE CASCADE,
        UNIQUE (semester_id, notes_subject_name)
      );
    ''');

    // Create notes_sections
    await db.execute('''
      CREATE TABLE notes_sections (
        section_id TEXT PRIMARY KEY,
        notes_subject_id TEXT NOT NULL,
        section_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (notes_subject_id) REFERENCES notes_subjects (notes_subject_id) ON DELETE CASCADE,
        UNIQUE (notes_subject_id, section_name)
      );
    ''');

    // Create notes_resources
    await db.execute('''
      CREATE TABLE notes_resources (
        resource_id TEXT PRIMARY KEY,
        section_id TEXT NOT NULL,
        resource_name TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        storage_path TEXT NOT NULL,
        uploaded_via TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (section_id) REFERENCES notes_sections (section_id) ON DELETE CASCADE,
        UNIQUE (section_id, file_name)
      );
    ''');

    // Create review_queue
    await db.execute('''
      CREATE TABLE review_queue (
        review_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        review_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        review_message TEXT NOT NULL,
        review_status TEXT NOT NULL,
        resolved_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        resolved_at TEXT
      );
    ''');

    // Create activity_logs
    await db.execute('''
      CREATE TABLE activity_logs (
        activity_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        actor_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        activity_message TEXT NOT NULL,
        correlation_id TEXT,
        created_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> wipeDatabase() async {
    final db = database;
    await db.transaction((txn) async {
      await txn.delete('local_metadata');
      await txn.delete('app_settings');
      await txn.delete('semesters');
      await txn.delete('attendance_settings');
      await txn.delete('subjects');
      await txn.delete('lecture_templates');
      await txn.delete('lecture_instances');
      await txn.delete('holidays');
      await txn.delete('todos');
      await txn.delete('notes_subjects');
      await txn.delete('notes_sections');
      await txn.delete('notes_resources');
      await txn.delete('review_queue');
      await txn.delete('activity_logs');
      await txn.delete('pending_sync_operations');
    });
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _currentUserId = null;
  }

  // Helper getters/setters for metadata
  Future<bool> isBootstrapped() async {
    final db = database;
    final results = await db.query(
      'local_metadata',
      where: 'key = ?',
      whereArgs: ['bootstrap_completed'],
    );
    if (results.isEmpty) return false;
    return results.first['value'] == 'true';
  }

  Future<void> setBootstrapped(bool value) async {
    final db = database;
    await db.insert(
      'local_metadata',
      {
        'key': 'bootstrap_completed',
        'value': value ? 'true' : 'false',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> enqueueOperation(
    DatabaseExecutor txn,
    String entityType,
    String entityId,
    String operationType,
    Map<String, dynamic>? payload,
  ) async {
    final uuid = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();
    String? payloadStr;
    if (payload != null) {
      payloadStr = jsonEncode(payload);
    }

    await txn.insert('pending_sync_operations', {
      'operation_uuid': uuid,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation_type': operationType,
      'payload': payloadStr,
      'created_at': nowStr,
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = database;
    return await db.query('pending_sync_operations', orderBy: 'id ASC');
  }

  Future<void> removePendingOperation(String operationUuid) async {
    final db = database;
    await db.delete(
      'pending_sync_operations',
      where: 'operation_uuid = ?',
      whereArgs: [operationUuid],
    );
  }

  Future<void> removePendingOperations(List<String> uuids) async {
    if (uuids.isEmpty) return;
    final db = database;
    final placeholders = List.filled(uuids.length, '?').join(',');
    await db.delete(
      'pending_sync_operations',
      where: 'operation_uuid IN ($placeholders)',
      whereArgs: uuids,
    );
  }

  Future<void> incrementRetryCount(String operationUuid) async {
    final db = database;
    await db.rawUpdate(
      'UPDATE pending_sync_operations SET retry_count = retry_count + 1 WHERE operation_uuid = ?',
      [operationUuid],
    );
  }

  Future<String?> getLastSuccessfulSync() async {
    final db = database;
    final results = await db.query(
      'local_metadata',
      where: 'key = ?',
      whereArgs: ['last_successful_sync'],
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  Future<void> setLastSuccessfulSync(String timestamp) async {
    final db = database;
    await db.insert(
      'local_metadata',
      {
        'key': 'last_successful_sync',
        'value': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
