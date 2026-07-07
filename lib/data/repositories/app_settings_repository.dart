import '../api/app_settings_api.dart';
import '../dto/settings/app_settings_dto.dart';

class AppSettingsRepository {
  final AppSettingsApi _api = AppSettingsApi();

  Future<AppSettingsDto> getSettings() async {
    final response = await _api.getSettings();
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<AppSettingsDto> updateSettings(AppSettingsUpdateRequest request) async {
    final response = await _api.updateSettings(request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }
}
