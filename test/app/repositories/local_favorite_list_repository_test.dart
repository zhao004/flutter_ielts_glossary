import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/favorite_page.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/frequency_group_summary.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_memory_rate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_details.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_learning_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_summary.dart';
import 'package:flutter_ielts_glossary/app/repositories/content_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_list_repository.dart';

void main() {
  test('单词收藏分页扫描筛选并报告缺失内容', () async {
    final repository = LocalFavoriteListRepository(
      _FakeFavoriteRepository(
        wordRecords: [_wordFavorite(1), _wordFavorite(99), _wordFavorite(2)],
      ),
      _FakeContentRepository(
        words: [_word(1, 'alpha', 1), _word(2, 'beta', 2)],
      ),
      _FakeLearningRepository(
        states: [_learningState(1, 2), _learningState(2, 4)],
      ),
      scanPageSize: 2,
    );

    final result = await repository.findPage(
      FavoriteFilter(pageSize: 1, masteryLevel: 4),
    );

    expect(result.items, hasLength(1));
    expect((result.items.single as FavoriteWordItem).word.word, 'beta');
    expect(result.missingContentIds, [99]);
    expect(result.hasMore, isFalse);
  });

  test('例句收藏组合关联单词并应用首字母和词频筛选', () async {
    final repository = LocalFavoriteListRepository(
      _FakeFavoriteRepository(
        sentenceRecords: [_sentenceFavorite(11, 1), _sentenceFavorite(12, 2)],
      ),
      _FakeContentRepository(
        words: [_word(1, 'alpha', 1), _word(2, 'beta', 2)],
        sentences: [_sentence(11, 1), _sentence(12, 2)],
      ),
      _FakeLearningRepository(states: [_learningState(1, 0)]),
    );

    final result = await repository.findPage(
      FavoriteFilter(
        type: FavoriteCollectionType.sentences,
        frequencyGroupIds: {1},
        firstLetter: 'a',
      ),
    );

    expect(result.items, hasLength(1));
    final item = result.items.single as FavoriteSentenceItem;
    expect(item.sentence.id, 11);
    expect(item.word.word, 'alpha');
    expect(item.learningState, isNotNull);
  });

  test('缺失关联单词的例句不会伪造列表项', () async {
    final repository = LocalFavoriteListRepository(
      _FakeFavoriteRepository(sentenceRecords: [_sentenceFavorite(11, 9)]),
      _FakeContentRepository(sentences: [_sentence(11, 9)]),
      _FakeLearningRepository(),
    );

    final result = await repository.findPage(
      FavoriteFilter(type: FavoriteCollectionType.sentences),
    );

    expect(result.items, isEmpty);
    expect(result.missingContentIds, [11]);
  });
}

WordSummary _word(int id, String value, int groupId) {
  return WordSummary(
    id: id,
    word: value,
    phoneticUk: null,
    translationZh: '释义 $value',
    occurrences: 100,
    frequencyGroupId: groupId,
  );
}

SentenceDetails _sentence(int id, int wordId) {
  return SentenceDetails(
    id: id,
    wordId: wordId,
    targetForm: 'word',
    sentenceEn: 'A sentence for $wordId.',
    translationZh: null,
    source: null,
    location: null,
  );
}

FavoriteWordRecord _wordFavorite(int wordId) {
  final now = DateTime.utc(2026, 8, 15);
  return FavoriteWordRecord(
    id: 'favorite-word-$wordId',
    wordId: wordId,
    createdAt: now,
    updatedAt: now,
  );
}

FavoriteSentenceRecord _sentenceFavorite(int sentenceId, int wordId) {
  final now = DateTime.utc(2026, 8, 15);
  return FavoriteSentenceRecord(
    id: 'favorite-sentence-$sentenceId',
    sentenceId: sentenceId,
    wordId: wordId,
    createdAt: now,
    updatedAt: now,
  );
}

WordLearningState _learningState(int wordId, int masteryLevel) {
  final now = DateTime.utc(2026, 8, 15);
  return WordLearningState(
    wordId: wordId,
    masteryLevel: masteryLevel,
    studiedCount: 1,
    correctCount: 0,
    wrongCount: 0,
    correctStreak: 0,
    consecutiveForgottenCount: 0,
    lastStudiedAt: now,
    lastReviewedAt: null,
    nextReviewAt: now.add(const Duration(days: 1)),
    updatedAt: now,
  );
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({
    this.wordRecords = const [],
    this.sentenceRecords = const [],
  });

  final List<FavoriteWordRecord> wordRecords;
  final List<FavoriteSentenceRecord> sentenceRecords;

  @override
  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  }) async => wordRecords.skip(offset).take(limit).toList(growable: false);

  @override
  Future<List<FavoriteSentenceRecord>> findFavoriteSentences({
    int limit = 100,
    int offset = 0,
  }) async => sentenceRecords.skip(offset).take(limit).toList(growable: false);

  @override
  Future<Set<int>> findFavoriteWordIds(Set<int> wordIds) async => {};

  @override
  Future<Set<int>> findFavoriteSentenceIds(Set<int> sentenceIds) async => {};

  @override
  Future<bool> isWordFavorite(int wordId) async => false;

  @override
  Future<bool> isSentenceFavorite(int sentenceId) async => false;

  @override
  Future<FavoriteWordRecord?> setWordFavorite({
    required int wordId,
    required bool isFavorite,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeContentRepository implements ContentRepository {
  _FakeContentRepository({this.words = const [], this.sentences = const []});

  final List<WordSummary> words;
  final List<SentenceDetails> sentences;

  @override
  Future<List<WordSummary>> findWordSummariesByIds(Set<int> wordIds) async {
    return words.where((word) => wordIds.contains(word.id)).toList();
  }

  @override
  Future<List<SentenceDetails>> findSentenceDetailsByIds(
    Set<int> sentenceIds,
  ) async {
    return sentences
        .where((sentence) => sentenceIds.contains(sentence.id))
        .toList();
  }

  @override
  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups() {
    throw UnimplementedError();
  }

  @override
  Future<WordDetails?> findWordDetails(int wordId) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordSummary>> findWords(WordFilter filter) {
    throw UnimplementedError();
  }
}

final class _FakeLearningRepository implements LearningRepository {
  _FakeLearningRepository({this.states = const []});

  final List<WordLearningState> states;

  @override
  Future<WordLearningState?> findWordState(int wordId) async {
    return states.where((state) => state.wordId == wordId).firstOrNull;
  }

  @override
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds) async {
    return states.where((state) => wordIds.contains(state.wordId)).toList();
  }

  @override
  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordLearningState>> findDueReviews({int limit = 100}) {
    throw UnimplementedError();
  }

  @override
  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window}) {
    throw UnimplementedError();
  }

  @override
  Future<WordLearningState> recordReview({
    required int wordId,
    required ReviewRating rating,
    String? sessionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WordLearningState> recordStudyCompletion({
    required int wordId,
    String? sessionId,
  }) {
    throw UnimplementedError();
  }
}
