import '../models/domain/review_queue.dart';

/// 到期复习队列的跨库聚合接口。
abstract interface class ReviewQueueRepository {
  Future<ReviewQueueSnapshot> findDueItems({int limit = 100});
}
