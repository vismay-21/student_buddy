import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_buddy.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {

    await db.execute('''
    CREATE TABLE subjects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      teacher TEXT NOT NULL,
      room TEXT NOT NULL,
      color INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE class_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject_id INTEGER NOT NULL,
      day_index INTEGER NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      FOREIGN KEY (subject_id) REFERENCES subjects(id)
    )
    ''');

    await db.execute('''
    CREATE TABLE attendance_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      class_session_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      status INTEGER NOT NULL,
      FOREIGN KEY (class_session_id) REFERENCES class_sessions(id)
    )
    ''');
  }
}
