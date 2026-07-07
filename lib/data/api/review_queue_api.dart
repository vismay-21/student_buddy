import '../../core/network/base_api.dart';
import '../../core/network/api_response.dart';
import '../dto/review_queue/review_queue_dto.dart';

class ReviewQueueApi extends BaseApi {
  Future<ApiResponse<List<ReviewQueueDto>>> getReviewQueue({
    String? status,
    String? q,
  }) async {
    final Map<String, dynamic> params = {};
    if (status != null) params['status'] = status;
    if (q != null) params['q'] = q;

    return get<List<ReviewQueueDto>>(
      '/review-queue',
      queryParameters: params,
      parser: (json) {
        final list = json as List<dynamic>;
        return list.map((item) => ReviewQueueDto.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<ReviewQueueDto>> getReviewQueueItem(String reviewId) async {
    return get<ReviewQueueDto>(
      '/review-queue/$reviewId',
      parser: (json) => ReviewQueueDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ReviewQueueDto>> resolveReviewQueueItem(
    String reviewId,
    ReviewQueueResolveRequest request,
  ) async {
    return put<ReviewQueueDto>(
      '/review-queue/$reviewId',
      data: request.toJson(),
      parser: (json) => ReviewQueueDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
