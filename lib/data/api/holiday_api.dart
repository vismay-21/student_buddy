import '../../core/network/base_api.dart';
import '../../core/network/api_response.dart';
import '../dto/holiday/holiday_dto.dart';

class HolidayApi extends BaseApi {
  Future<ApiResponse<HolidayDto>> createHoliday(HolidayCreateRequest request) async {
    return post<HolidayDto>(
      '/academic/holidays',
      data: request.toJson(),
      parser: (json) => HolidayDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<HolidayDto>>> getHolidays({String? semesterId}) async {
    final Map<String, dynamic> params = {};
    if (semesterId != null) {
      params['semester_id'] = semesterId;
    }
    return get<List<HolidayDto>>(
      '/academic/holidays',
      queryParameters: params,
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => HolidayDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<HolidayDto>> getHoliday(String holidayId) async {
    return get<HolidayDto>(
      '/academic/holidays/$holidayId',
      parser: (json) => HolidayDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<HolidayDto>> updateHoliday(String holidayId, HolidayUpdateRequest request) async {
    return put<HolidayDto>(
      '/academic/holidays/$holidayId',
      data: request.toJson(),
      parser: (json) => HolidayDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteHoliday(String holidayId) async {
    return delete('/academic/holidays/$holidayId');
  }
}
