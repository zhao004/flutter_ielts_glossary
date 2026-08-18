import '../database/content/daos/content_dao.dart';
import '../database/user/daos/user_data_dao.dart';
import '../database/user/user_database.dart';
import '../models/domain/review_queue.dart';
import '../models/domain/word_learning_state.dart';
import '../models/domain/word_summary.dart';
import '../services/clock/app_clock.dart';
import 'review_queue_repository.dart';

/// 将用户库到期状态与只读词库单词按稳定 ID 合并，保留到期顺序。
final class LocalReviewQueueRepository implements ReviewQueueRepository {
  LocalReviewQueueRepository(
    this._contentDao,
    this._userDataDao, {
    this.clock = const SystemAppClock(),
  });

  static const int maximumQueueLimit = 500;

  final ContentDao _contentDao;
  final UserDataDao _userDataDao;
  final AppClock clock;

  @override
  Future<ReviewQueueSnapshot> findDueItems({int limit = 100}) async {
    if (limit <= 0 || limit > maximumQueueLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        '复习队列数量必须在 1-$maximumQueueLimit 之间',
      );
    }
    final states = await _userDataDao.findDueWordStates(
      now: clock.nowUtc(),
      limit: limit,
    );
    if (states.isEmpty) {
      return ReviewQueueSnapshot(items: const [], missingWordIds: const []);
    }
    final words = await _contentDao.findWordsByIds(
      states.map((state) => state.wordId).toSet(),
    );
    final wordsById = {for (final word in words) word.id: word};
    final items = <ReviewQueueItem>[];
    final missing = <int>[];
    for (final state in states) {
      final word = wordsById[state.wordId];
      if (word == null) {
        missing.add(state.wordId);
        continue;
      }
      items.add(
        ReviewQueueItem(
          word: WordSummary(
            id: word.id,
            word: word.word,
            phoneticUk: word.phoneticUk,
            phoneticUs: word.phoneticUs,
            translationZh: word.translationZh,
            occurrences: word.occurrences,
            frequencyGroupId: word.frequencyGroupId,
            audioUkAsset: word.audioUkAsset,
            audioUsAsset: word.audioUsAsset,
          ),
          learningState: _toDomain(state),
        ),
      );
    }
    return ReviewQueueSnapshot(items: items, missingWordIds: missing);
  }

  WordLearningState _toDomain(UserWordState state) {
    return WordLearningState(
      wordId: state.wordId,
      masteryLevel: state.masteryLevel,
      studiedCount: state.studiedCount,
      correctCount: state.correctCount,
      wrongCount: state.wrongCount,
      correctStreak: state.correctStreak,
      consecutiveForgottenCount: state.consecutiveForgottenCount,
      lastStudiedAt: state.lastStudiedAt,
      lastReviewedAt: state.lastReviewedAt,
      nextReviewAt: state.nextReviewAt,
      updatedAt: state.updatedAt,
    );
  }
}
