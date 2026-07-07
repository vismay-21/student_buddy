import '../api/holiday_api.dart';
import '../dto/holiday/holiday_dto.dart';

class HolidayRepository {
  final HolidayApi _api = HolidayApi();

  Future<HolidayDto> createHoliday(HolidayCreateRequest request) async {
    final response = await _api.createHoliday(request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<List<HolidayDto>> getHolidays({String? semesterId}) async {
    final response = await _api.getHolidays(semesterId: semesterId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<HolidayDto> getHoliday(String holidayId) async {
    final response = await _api.getHoliday(holidayId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<HolidayDto> updateHoliday(String holidayId, HolidayUpdateRequest request) async {
    final response = await _api.updateHoliday(holidayId, request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<void> deleteHoliday(String holidayId) async {
    final response = await _api.deleteHoliday(holidayId);
    if (!response.success) {
      throw Exception(response.message);
    }
  }
}
