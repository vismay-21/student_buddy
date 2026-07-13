import '../dto/activity_log/activity_log_dto.dart';
import 'sqlite/sqlite_activity_log_repository.dart';

abstract class ActivityLogRepository {
  factory ActivityLogRepository() => SqliteActivityLogRepository();

  Future<List<ActivityLogDto>> getActivityLogs({
    String? actorType,
    String? entityType,
    String? actionType,
    String? entityId,
    String? correlationId,
    int? limit,
    int? offset,
  });

  Future<ActivityLogDto> getActivityLog(String activityId);
}
