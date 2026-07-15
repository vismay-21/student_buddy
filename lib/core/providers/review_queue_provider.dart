import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/review_queue/review_queue_dto.dart';
import 'common_providers.dart';

// ==========================================
// 1. Pending Review Queue Provider (Read Provider)
// ==========================================
final pendingReviewQueueProvider = FutureProvider<List<ReviewQueueDto>>((ref) async {
  final service = ref.watch(reviewQueueServiceProvider);
  return service.getReviewQueue(status: 'pending');
});

// ==========================================
// 2. Review Queue Actions Provider (CQRS Action Provider)
// ==========================================
class ReviewQueueActions {
  final Ref _ref;
  ReviewQueueActions(this._ref);

  Future<ReviewQueueDto> resolveItem(
    String reviewId,
    ReviewQueueResolveRequest request,
  ) async {
    final service = _ref.read(reviewQueueServiceProvider);
    final result = await service.resolveReviewQueueItem(reviewId, request);
    _ref.invalidate(pendingReviewQueueProvider);
    return result;
  }
}

final reviewQueueActionsProvider =
    Provider<ReviewQueueActions>((ref) => ReviewQueueActions(ref));
