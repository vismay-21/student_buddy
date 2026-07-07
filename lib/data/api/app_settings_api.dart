import '../../core/network/base_api.dart';
import '../../core/network/api_response.dart';
import '../dto/settings/app_settings_dto.dart';

class AppSettingsApi extends BaseApi {
  Future<ApiResponse<AppSettingsDto>> getSettings() async {
    return get<AppSettingsDto>(
      '/app-settings',
      parser: (json) => AppSettingsDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppSettingsDto>> updateSettings(AppSettingsUpdateRequest request) async {
    return put<AppSettingsDto>(
      '/app-settings',
      data: request.toJson(),
      parser: (json) => AppSettingsDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
