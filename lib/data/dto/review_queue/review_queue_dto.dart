class ReviewQueueDto {
  final String reviewId;
  final String reviewType; // 'missing_information', 'confirmation_required', 'manual_review'
  final String entityType; // 'attendance', 'todo', 'finance'
  final String entityId;
  final String reviewMessage;
  final String reviewStatus; // 'pending', 'resolved', 'ignored'
  final String resolvedBy; // 'user', 'system', 'admin'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String entitySummary;

  ReviewQueueDto({
    required this.reviewId,
    required this.reviewType,
    required this.entityType,
    required this.entityId,
    required this.reviewMessage,
    required this.reviewStatus,
    required this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
    required this.entitySummary,
  });

  factory ReviewQueueDto.fromJson(Map<String, dynamic> json) {
    return ReviewQueueDto(
      reviewId: json['review_id'] as String,
      reviewType: json['review_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      reviewMessage: json['review_message'] as String,
      reviewStatus: json['review_status'] as String? ?? 'pending',
      resolvedBy: json['resolved_by'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      entitySummary: json['entity_summary'] as String? ?? '',
    );
  }
}

class ReviewQueueResolveRequest {
  final Map<String, dynamic> resolutionData;
  final String resolvedBy; // 'user', 'system', 'admin'

  ReviewQueueResolveRequest({
    required this.resolutionData,
    this.resolvedBy = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      'resolution_data': resolutionData,
      'resolved_by': resolvedBy,
    };
  }
}
