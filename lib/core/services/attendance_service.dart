import '../../data/dto/lecture/lecture_instance_dto.dart';
import '../../data/dto/lecture/lecture_template_dto.dart';
import '../../data/dto/attendance/attendance_settings_dto.dart';
import '../../data/dto/holiday/holiday_dto.dart';
import '../../data/repositories/lecture_instance_repository.dart';
import '../../data/repositories/lecture_template_repository.dart';
import '../../data/repositories/attendance_settings_repository.dart';
import '../../data/repositories/holiday_repository.dart';

class AttendanceService {
  final LectureInstanceRepository _instanceRepo = LectureInstanceRepository();
  final LectureTemplateRepository _templateRepo = LectureTemplateRepository();
  final AttendanceSettingsRepository _settingsRepo = AttendanceSettingsRepository();
  final HolidayRepository _holidayRepo = HolidayRepository();

  // Lecture Instances
  Future<List<LectureInstanceDto>> getTodayLectures({required String date, required String semesterId}) =>
      _instanceRepo.getTodayLectures(date: date, semesterId: semesterId);

  Future<List<LectureInstanceDto>> getInstances({
    String? semesterId,
    String? subjectId,
    String? startDate,
    String? endDate,
    String? attendanceStatus,
    String? lectureStatus,
  }) =>
      _instanceRepo.getInstances(
        semesterId: semesterId,
        subjectId: subjectId,
        startDate: startDate,
        endDate: endDate,
        attendanceStatus: attendanceStatus,
        lectureStatus: lectureStatus,
      );
      
  Future<LectureInstanceDto> updateAttendance(String instanceId, LectureInstanceUpdateRequest request) =>
      _instanceRepo.updateAttendance(instanceId, request);
      
  Future<void> markWholeDay(LectureInstanceBulkUpdateRequest request) =>
      _instanceRepo.markWholeDay(request);
      
  Future<AttendanceStatsDto> getSemesterStats(String semesterId) =>
      _instanceRepo.getSemesterStats(semesterId);
      
  Future<AttendanceStatsDto> getSubjectStats(String subjectId) =>
      _instanceRepo.getSubjectStats(subjectId);

  // Lecture Templates
  Future<LectureTemplateDto> createTemplate(LectureTemplateCreateRequest request) =>
      _templateRepo.createTemplate(request);
      
  Future<List<LectureTemplateDto>> getTemplates(String subjectId) =>
      _templateRepo.getTemplates(subjectId);
      
  Future<LectureTemplateDto> updateTemplate(String templateId, LectureTemplateUpdateRequest request) =>
      _templateRepo.updateTemplate(templateId, request);
      
  Future<void> deleteTemplate(String templateId) =>
      _templateRepo.deleteTemplate(templateId);

  // Attendance Settings
  Future<AttendanceSettingsDto> getSettings(String semesterId) =>
      _settingsRepo.getSettings(semesterId);
      
  Future<AttendanceSettingsDto> updateSettings(String semesterId, AttendanceSettingsUpdateRequest request) =>
      _settingsRepo.updateSettings(semesterId, request);

  // Holidays
  Future<HolidayDto> createHoliday(HolidayCreateRequest request) =>
      _holidayRepo.createHoliday(request);
      
  Future<List<HolidayDto>> getHolidays({required String semesterId}) =>
      _holidayRepo.getHolidays(semesterId: semesterId);
      
  Future<void> deleteHoliday(String holidayId) =>
      _holidayRepo.deleteHoliday(holidayId);
}
