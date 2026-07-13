import '../dto/attendance/attendance_settings_dto.dart';
import 'sqlite/sqlite_attendance_settings_repository.dart';

abstract class AttendanceSettingsRepository {
  factory AttendanceSettingsRepository() => SqliteAttendanceSettingsRepository();

  Future<AttendanceSettingsDto> getSettings(String semesterId);
  Future<AttendanceSettingsDto> updateSettings(
    String semesterId,
    AttendanceSettingsUpdateRequest request,
  );
}
