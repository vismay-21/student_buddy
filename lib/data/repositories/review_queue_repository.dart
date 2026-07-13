import '../dto/review_queue/review_queue_dto.dart';
import 'sqlite/sqlite_review_queue_repository.dart';

abstract class ReviewQueueRepository {
  factory ReviewQueueRepository() => SqliteReviewQueueRepository();

  Future<List<ReviewQueueDto>> getReviewQueue({
    String? status,
    String? q,
  });

  Future<ReviewQueueDto> getReviewQueueItem(String reviewId);

  Future<ReviewQueueDto> resolveReviewQueueItem(
    String reviewId,
    ReviewQueueResolveRequest request,
  );
}
