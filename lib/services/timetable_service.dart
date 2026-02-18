import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../models/subject.dart';
import '../models/class_session.dart';

class TimetableService {
  final dbHelper = DatabaseHelper.instance;

  // Insert Subject
  Future<int> insertSubject(Subject subject) async {
    final db = await dbHelper.database;
    return await db.insert('subjects', subject.toMap());
  }

  // Insert Class Session
  Future<int> insertClassSession(ClassSession session) async {
    final db = await dbHelper.database;
    return await db.insert('class_sessions', session.toMap());
  }

  // Get classes for a specific day (with subject details)
  Future<List<Map<String, dynamic>>> getClassesForDay(int dayIndex) async {
    final db = await dbHelper.database;

    return await db.rawQuery('''
      SELECT 
        cs.id,
        cs.start_time,
        cs.end_time,
        s.name,
        s.teacher,
        s.room,
        s.color
      FROM class_sessions cs
      JOIN subjects s ON cs.subject_id = s.id
      WHERE cs.day_index = ?
      ORDER BY cs.start_time
    ''', [dayIndex]);
  }
}
