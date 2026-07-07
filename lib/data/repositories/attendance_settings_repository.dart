import '../api/attendance_settings_api.dart';
import '../dto/attendance/attendance_settings_dto.dart';

class AttendanceSettingsRepository {
  final AttendanceSettingsApi _settingsApi;

  AttendanceSettingsRepository({AttendanceSettingsApi? settingsApi})
      : _settingsApi = settingsApi ?? AttendanceSettingsApi();

  Future<AttendanceSettingsDto> getSettings(String semesterId) async {
    return _settingsApi.getSettings(semesterId);
  }

  Future<AttendanceSettingsDto> updateSettings(
    String semesterId,
    AttendanceSettingsUpdateRequest request,
  ) async {
    return _settingsApi.updateSettings(semesterId, request);
  }
}
