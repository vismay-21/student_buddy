import '../api/review_queue_api.dart';
import '../dto/review_queue/review_queue_dto.dart';

class ReviewQueueRepository {
  final ReviewQueueApi _api = ReviewQueueApi();

  Future<List<ReviewQueueDto>> getReviewQueue({
    String? status,
    String? q,
  }) async {
    final response = await _api.getReviewQueue(status: status, q: q);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<ReviewQueueDto> getReviewQueueItem(String reviewId) async {
    final response = await _api.getReviewQueueItem(reviewId);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<ReviewQueueDto> resolveReviewQueueItem(
    String reviewId,
    ReviewQueueResolveRequest request,
  ) async {
    final response = await _api.resolveReviewQueueItem(reviewId, request);
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }
}
