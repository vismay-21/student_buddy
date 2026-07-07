class ActivityLogDto {
  final String activityId;
  final String actorType;
  final String entityType;
  final String entityId;
  final String actionType;
  final String activityMessage;
  final String? correlationId;
  final DateTime createdAt;
  final String entitySummary;

  ActivityLogDto({
    required this.activityId,
    required this.actorType,
    required this.entityType,
    required this.entityId,
    required this.actionType,
    required this.activityMessage,
    this.correlationId,
    required this.createdAt,
    required this.entitySummary,
  });

  factory ActivityLogDto.fromJson(Map<String, dynamic> json) {
    return ActivityLogDto(
      activityId: json['activity_id'] as String,
      actorType: json['actor_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      actionType: json['action_type'] as String,
      activityMessage: json['activity_message'] as String,
      correlationId: json['correlation_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      entitySummary: json['entity_summary'] as String? ?? '',
    );
  }
}
