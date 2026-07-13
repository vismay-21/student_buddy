import '../dto/holiday/holiday_dto.dart';
import 'sqlite/sqlite_holiday_repository.dart';

abstract class HolidayRepository {
  factory HolidayRepository() => SqliteHolidayRepository();

  Future<HolidayDto> createHoliday(HolidayCreateRequest request);
  Future<List<HolidayDto>> getHolidays({String? semesterId});
  Future<HolidayDto> getHoliday(String holidayId);
  Future<HolidayDto> updateHoliday(String holidayId, HolidayUpdateRequest request);
  Future<void> deleteHoliday(String holidayId);
}
