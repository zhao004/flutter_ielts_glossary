import '../database/content/daos/content_dao.dart';
import '../database/content/content_database.dart';
import '../database/user/daos/user_data_dao.dart';
import '../database/user/user_database.dart';
import '../models/domain/frequency_group_summary.dart';
import '../models/domain/vocabulary_page.dart';
import '../models/domain/word_filter.dart';
import '../models/domain/word_learning_state.dart';
import '../models/domain/word_summary.dart';
import 'vocabulary_repository.dart';

/// 按当前页受限 ID 集合批量组合只读词库和用户状态，避免逐行查询。
final class LocalVocabularyRepository implements VocabularyRepository {
  const LocalVocabularyRepository(this._contentDao, this._userDataDao);

  final ContentDao _contentDao;
  final UserDataDao _userDataDao;

  @override
  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups() async {
    final groups = await _contentDao.findActiveFrequencyGroups();
    return groups
        .map(
          (group) => FrequencyGroupSummary(
            id: group.id,
            name: group.name,
            rank: group.rank,
            minOccurrences: group.minOccurrences,
            maxOccurrences: group.maxOccurrences,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<VocabularyPageResult> findPage(WordFilter filter) async {
    final results = await Future.wait<Object>([
      _contentDao.findWords(filter, lookahead: 1),
      _contentDao.countWords(filter),
    ]);
    final records = results[0] as List<Word>;
    final totalCount = results[1] as int;
    final hasMore = records.length > filter.pageSize;
    final pageRecords = hasMore ? records.sublist(0, filter.pageSize) : records;
    final wordIds = pageRecords.map((word) => word.id).toSet();
    final favoriteWordIdsFuture = _userDataDao.findFavoriteWordIds(wordIds);
    final learningStatesFuture = _userDataDao.findWordStatesByIds(wordIds);
    final favoriteWordIds = await favoriteWordIdsFuture;
    final learningStates = await learningStatesFuture;
    final statesByWordId = {
      for (final state in learningStates) state.wordId: state,
    };
    return VocabularyPageResult(
      filter: filter,
      items: pageRecords
          .map(
            (word) => VocabularyWordItem(
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
              isFavorite: favoriteWordIds.contains(word.id),
              learningState: _toLearningState(statesByWordId[word.id]),
            ),
          )
          .toList(growable: false),
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }

  WordLearningState? _toLearningState(UserWordState? state) {
    if (state == null) {
      return null;
    }
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
