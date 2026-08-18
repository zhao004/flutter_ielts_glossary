import '../models/domain/favorite_page.dart';
import '../models/domain/word_learning_state.dart';
import 'content_repository.dart';
import 'favorite_list_repository.dart';
import 'favorite_repository.dart';
import 'learning_repository.dart';

/// 分块扫描收藏关系并批量组合词库内容，避免一次性加载全部收藏或词库。
final class LocalFavoriteListRepository implements FavoriteListRepository {
  LocalFavoriteListRepository(
    this._favoriteRepository,
    this._contentRepository,
    this._learningRepository, {
    this.scanPageSize = 100,
  }) {
    if (scanPageSize <= 0 || scanPageSize > 100) {
      throw ArgumentError.value(
        scanPageSize,
        'scanPageSize',
        '收藏扫描分块大小必须在 1-100 之间',
      );
    }
  }

  final FavoriteRepository _favoriteRepository;
  final ContentRepository _contentRepository;
  final LearningRepository _learningRepository;
  final int scanPageSize;

  @override
  Future<FavoritePageResult> findPage(FavoriteFilter filter) {
    return switch (filter.type) {
      FavoriteCollectionType.words => _findWordPage(filter),
      FavoriteCollectionType.sentences => _findSentencePage(filter),
    };
  }

  Future<FavoritePageResult> _findWordPage(FavoriteFilter filter) async {
    final matched = <FavoriteWordItem>[];
    final missingIds = <int>{};
    var sourceOffset = 0;
    var reachedEnd = false;

    while (!reachedEnd) {
      final records = await _favoriteRepository.findFavoriteWords(
        limit: scanPageSize,
        offset: sourceOffset,
      );
      if (records.isEmpty) {
        reachedEnd = true;
        continue;
      }
      sourceOffset += records.length;
      final wordIds = records.map((record) => record.wordId).toSet();
      final words = await _contentRepository.findWordSummariesByIds(wordIds);
      final states = await _learningRepository.findWordStatesByIds(wordIds);
      final wordsById = {for (final word in words) word.id: word};
      final statesById = _statesById(states, wordIds);
      for (final record in records) {
        final word = wordsById[record.wordId];
        if (word == null) {
          missingIds.add(record.wordId);
          continue;
        }
        final learningState = statesById[record.wordId];
        if (filter.matchesWord(word, learningState)) {
          matched.add(
            FavoriteWordItem(
              favorite: record,
              word: word,
              learningState: learningState,
            ),
          );
        }
      }
      reachedEnd = records.length < scanPageSize;
    }

    matched.sort((left, right) => _compareWordItems(left, right, filter));
    final items = matched
        .skip(filter.offset)
        .take(filter.pageSize)
        .toList(growable: false);
    return FavoritePageResult(
      filter: filter,
      items: items,
      hasMore: filter.offset + items.length < matched.length,
      missingContentIds: missingIds.toList(growable: false)..sort(),
      totalCount: matched.length,
    );
  }

  Future<FavoritePageResult> _findSentencePage(FavoriteFilter filter) async {
    final matched = <FavoriteSentenceItem>[];
    final missingIds = <int>{};
    var sourceOffset = 0;
    var reachedEnd = false;

    while (!reachedEnd) {
      final records = await _favoriteRepository.findFavoriteSentences(
        limit: scanPageSize,
        offset: sourceOffset,
      );
      if (records.isEmpty) {
        reachedEnd = true;
        continue;
      }
      sourceOffset += records.length;
      final sentenceIds = records.map((record) => record.sentenceId).toSet();
      final sentences = await _contentRepository.findSentenceDetailsByIds(
        sentenceIds,
      );
      final sentencesById = {
        for (final sentence in sentences) sentence.id: sentence,
      };
      final wordIds = records.map((record) => record.wordId).toSet();
      final words = await _contentRepository.findWordSummariesByIds(wordIds);
      final states = await _learningRepository.findWordStatesByIds(wordIds);
      final wordsById = {for (final word in words) word.id: word};
      final statesById = _statesById(states, wordIds);
      for (final record in records) {
        final sentence = sentencesById[record.sentenceId];
        final word = wordsById[record.wordId];
        if (sentence == null || word == null || sentence.wordId != word.id) {
          missingIds.add(record.sentenceId);
          continue;
        }
        final learningState = statesById[record.wordId];
        if (filter.matchesSentence(sentence, word, learningState)) {
          matched.add(
            FavoriteSentenceItem(
              favorite: record,
              sentence: sentence,
              word: word,
              learningState: learningState,
            ),
          );
        }
      }
      reachedEnd = records.length < scanPageSize;
    }

    matched.sort((left, right) => _compareSentenceItems(left, right, filter));
    final items = matched
        .skip(filter.offset)
        .take(filter.pageSize)
        .toList(growable: false);
    return FavoritePageResult(
      filter: filter,
      items: items,
      hasMore: filter.offset + items.length < matched.length,
      missingContentIds: missingIds.toList(growable: false)..sort(),
      totalCount: matched.length,
    );
  }

  Map<int, WordLearningState> _statesById(
    List<WordLearningState> states,
    Set<int> requestedIds,
  ) {
    final result = <int, WordLearningState>{};
    for (final state in states) {
      if (!requestedIds.contains(state.wordId) ||
          result.containsKey(state.wordId)) {
        throw StateError('学习 Repository 返回了请求集合之外或重复的 ID');
      }
      result[state.wordId] = state;
    }
    return result;
  }

  int _compareWordItems(
    FavoriteWordItem left,
    FavoriteWordItem right,
    FavoriteFilter filter,
  ) {
    final wordComparison = left.word.word.toLowerCase().compareTo(
      right.word.word.toLowerCase(),
    );
    final ordered = wordComparison != 0
        ? wordComparison
        : left.contentId.compareTo(right.contentId);
    return filter.sortOrder == FavoriteSortOrder.alphabetAscending
        ? ordered
        : -ordered;
  }

  int _compareSentenceItems(
    FavoriteSentenceItem left,
    FavoriteSentenceItem right,
    FavoriteFilter filter,
  ) {
    var ordered = left.word.word.toLowerCase().compareTo(
      right.word.word.toLowerCase(),
    );
    if (ordered == 0) {
      ordered = left.sentence.sentenceEn.toLowerCase().compareTo(
        right.sentence.sentenceEn.toLowerCase(),
      );
    }
    if (ordered == 0) {
      ordered = left.contentId.compareTo(right.contentId);
    }
    return filter.sortOrder == FavoriteSortOrder.alphabetAscending
        ? ordered
        : -ordered;
  }
}
