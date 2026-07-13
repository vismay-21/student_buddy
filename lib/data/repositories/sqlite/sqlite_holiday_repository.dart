import '../../local/database_helper.dart';
import '../holiday_repository.dart';
import '../../dto/holiday/holiday_dto.dart';
import '../../../core/utils/uuid_generator.dart';

class SqliteHolidayRepository implements HolidayRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<HolidayDto> createHoliday(HolidayCreateRequest request) async {
    final db = _dbHelper.database;
    final holidayId = generateUuid();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final newHoliday = {
      'holiday_id': holidayId,
      'semester_id': request.semesterId,
      'holiday_date': request.holidayDate.toIso8601String().substring(0, 10),
      'holiday_name': request.holidayName,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    await db.transaction((txn) async {
      await txn.insert('holidays', newHoliday);
      await _dbHelper.enqueueOperation(txn, 'holiday', holidayId, 'create', newHoliday);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'holiday',
        'entity_id': holidayId,
        'action_type': 'created',
        'activity_message': 'Created holiday ${request.holidayName}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    return HolidayDto.fromJson(newHoliday);
  }

  @override
  Future<List<HolidayDto>> getHolidays({String? semesterId}) async {
    final db = _dbHelper.database;
    List<Map<String, dynamic>> maps;
    if (semesterId != null) {
      maps = await db.query(
        'holidays',
        where: 'semester_id = ?',
        whereArgs: [semesterId],
        orderBy: 'holiday_date ASC',
      );
    } else {
      maps = await db.query(
        'holidays',
        orderBy: 'holiday_date ASC',
      );
    }
    return List.generate(maps.length, (i) => HolidayDto.fromJson(maps[i]));
  }

  @override
  Future<HolidayDto> getHoliday(String holidayId) async {
    final db = _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'holidays',
      where: 'holiday_id = ?',
      whereArgs: [holidayId],
    );
    if (maps.isEmpty) {
      throw Exception("Holiday with ID $holidayId not found");
    }
    return HolidayDto.fromJson(maps.first);
  }

  @override
  Future<HolidayDto> updateHoliday(String holidayId, HolidayUpdateRequest request) async {
    final db = _dbHelper.database;
    final hol = await getHoliday(holidayId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    final Map<String, dynamic> updates = {
      'updated_at': nowStr,
    };
    if (request.holidayDate != null) {
      updates['holiday_date'] = request.holidayDate!.toIso8601String().substring(0, 10);
    }
    if (request.holidayName != null) {
      updates['holiday_name'] = request.holidayName;
    }

    await db.transaction((txn) async {
      await txn.update(
        'holidays',
        updates,
        where: 'holiday_id = ?',
        whereArgs: [holidayId],
      );

      final List<Map<String, dynamic>> updatedMaps = await txn.query(
        'holidays',
        where: 'holiday_id = ?',
        whereArgs: [holidayId],
      );
      if (updatedMaps.isNotEmpty) {
        await _dbHelper.enqueueOperation(txn, 'holiday', holidayId, 'update', updatedMaps.first);
      }

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'holiday',
        'entity_id': holidayId,
        'action_type': 'updated',
        'activity_message': 'Updated holiday ${request.holidayName ?? hol.holidayName}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });

    final maps = await db.query(
      'holidays',
      where: 'holiday_id = ?',
      whereArgs: [holidayId],
    );
    return HolidayDto.fromJson(maps.first);
  }

  @override
  Future<void> deleteHoliday(String holidayId) async {
    final db = _dbHelper.database;
    final hol = await getHoliday(holidayId);
    final nowStr = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'holidays',
        where: 'holiday_id = ?',
        whereArgs: [holidayId],
      );

      await _dbHelper.enqueueOperation(txn, 'holiday', holidayId, 'delete', null);

      // Log activity
      final activityId = generateUuid();
      await txn.insert('activity_logs', {
        'activity_id': activityId,
        'user_id': _dbHelper.currentUserId ?? '',
        'actor_type': 'user',
        'entity_type': 'holiday',
        'entity_id': holidayId,
        'action_type': 'deleted',
        'activity_message': 'Deleted holiday ${hol.holidayName}.',
        'correlation_id': null,
        'created_at': nowStr,
      });
    });
  }
}
