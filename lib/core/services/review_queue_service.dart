import '../../data/dto/review_queue/review_queue_dto.dart';
import '../../data/repositories/review_queue_repository.dart';

class ReviewQueueService {
  final ReviewQueueRepository _repository = ReviewQueueRepository();

  Future<List<ReviewQueueDto>> getReviewQueue({String? status, String? q}) =>
      _repository.getReviewQueue(status: status, q: q);
      
  Future<ReviewQueueDto> getReviewQueueItem(String reviewId) =>
      _repository.getReviewQueueItem(reviewId);

  Future<ReviewQueueDto> resolveReviewQueueItem(
    String reviewId,
    ReviewQueueResolveRequest request,
  ) =>
      _repository.resolveReviewQueueItem(reviewId, request);
}
