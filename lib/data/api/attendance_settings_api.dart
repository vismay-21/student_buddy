import 'package:student_buddy/core/network/base_api.dart';
import '../../core/network/api_constants.dart';
import '../dto/attendance/attendance_settings_dto.dart';

class AttendanceSettingsApi extends BaseApi {
  Future<AttendanceSettingsDto> getSettings(String semesterId) async {
    final response = await get<AttendanceSettingsDto>(
      '${ApiConstants.attendanceSettings}/$semesterId',
      parser: (json) => AttendanceSettingsDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<AttendanceSettingsDto> updateSettings(
    String semesterId,
    AttendanceSettingsUpdateRequest request,
  ) async {
    final response = await put<AttendanceSettingsDto>(
      '${ApiConstants.attendanceSettings}/$semesterId',
      data: request.toJson(),
      parser: (json) => AttendanceSettingsDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
