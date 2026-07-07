import '../../core/network/base_api.dart';
import '../../core/network/api_response.dart';
import '../dto/activity_log/activity_log_dto.dart';

class ActivityLogApi extends BaseApi {
  Future<ApiResponse<List<ActivityLogDto>>> getActivityLogs({
    String? actorType,
    String? entityType,
    String? actionType,
    String? entityId,
    String? correlationId,
    int? limit,
    int? offset,
  }) async {
    final Map<String, dynamic> params = {};
    if (actorType != null) params['actor_type'] = actorType;
    if (entityType != null) params['entity_type'] = entityType;
    if (actionType != null) params['action_type'] = actionType;
    if (entityId != null) params['entity_id'] = entityId;
    if (correlationId != null) params['correlation_id'] = correlationId;
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;

    return get<List<ActivityLogDto>>(
      '/activity-logs',
      queryParameters: params,
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => ActivityLogDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<ActivityLogDto>> getActivityLog(String activityId) async {
    return get<ActivityLogDto>(
      '/activity-logs/$activityId',
      parser: (json) => ActivityLogDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
