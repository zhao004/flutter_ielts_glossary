import '../models/domain/review_memory_rate.dart';
import '../models/domain/review_rating.dart';
import '../models/domain/study_rating.dart';
import '../models/domain/word_learning_state.dart';

/// 学习、复习队列和记忆率的领域接口。
abstract interface class LearningRepository {
  /// 读取指定单词的学习状态；尚未学习时返回空值。
  Future<WordLearningState?> findWordState(int wordId);

  /// 按受限稳定 ID 批量读取学习状态，缺失状态不返回记录。
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds);

  Future<WordLearningState> recordStudyCompletion({
    required int wordId,
    String? sessionId,
  });

  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  });

  Future<WordLearningState> recordReview({
    required int wordId,
    required ReviewRating rating,
    String? sessionId,
  });

  Future<List<WordLearningState>> findDueReviews({int limit = 100});

  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window});
}
