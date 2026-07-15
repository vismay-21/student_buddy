import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dto/review_queue/review_queue_dto.dart';
import 'common_providers.dart';
import 'auth_provider.dart';

// ==========================================
// 1. Pending Review Queue Provider (Read Provider)
// ==========================================
final pendingReviewQueueProvider = FutureProvider<List<ReviewQueueDto>>((ref) async {
  final bootstrapAsync = ref.watch(bootstrapStatusProvider);
  if (bootstrapAsync.isLoading) {
    return Completer<List<ReviewQueueDto>>().future;
  }
  if (bootstrapAsync.hasError) {
    throw bootstrapAsync.error!;
  }
  final bootstrapState = bootstrapAsync.value;
  if (bootstrapState != BootstrapState.success) {
    return Completer<List<ReviewQueueDto>>().future;
  }
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
