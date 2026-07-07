import '../api/activity_log_api.dart';
import '../dto/activity_log/activity_log_dto.dart';

class ActivityLogRepository {
  final ActivityLogApi _api = ActivityLogApi();

  Future<List<ActivityLogDto>> getActivityLogs({
    String? actorType,
    String? entityType,
    String? actionType,
    String? entityId,
    String? correlationId,
    int? limit,
    int? offset,
  }) async {
    final response = await _api.getActivityLogs(
      actorType: actorType,
      entityType: entityType,
      actionType: actionType,
      entityId: entityId,
      correlationId: correlationId,
      limit: limit,
      offset: offset,
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<ActivityLogDto> getActivityLog(String activityId) async {
    final response = await _api.getActivityLog(activityId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }
}
