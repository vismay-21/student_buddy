import '../dto/settings/app_settings_dto.dart';
import 'sqlite/sqlite_app_settings_repository.dart';

abstract class AppSettingsRepository {
  factory AppSettingsRepository() => SqliteAppSettingsRepository();

  Future<AppSettingsDto> getSettings();
  Future<AppSettingsDto> updateSettings(AppSettingsUpdateRequest request);
}
