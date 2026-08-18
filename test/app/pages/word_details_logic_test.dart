import 'dart:async';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/frequency_group_summary.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_memory_rate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_details.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_details_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_learning_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_summary.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/content_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/learning_repository.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';

void main() {
  test('加载详情并合并单词与例句收藏状态', () async {
    final content = _FakeContentRepository(details: _details());
    final favorites = _FakeFavoriteRepository(wordIds: {1}, sentenceIds: {11});
    final logic = _createLogic(content: content, favorites: favorites);
    addTearDown(logic.onClose);

    await logic.load(1);

    expect(logic.state.phase, WordDetailsRunPhase.loaded);
    expect(logic.state.details?.word, 'alpha');
    expect(logic.state.isWordFavorite, isTrue);
    expect(logic.state.favoriteSentenceIds, {11});
    expect(logic.state.pronunciationAccent, PronunciationAccent.uk);
  });

  test('加载详情时合并用户库掌握等级和下次复习时间', () async {
    final now = DateTime.utc(2026, 8, 15);
    final learning = _FakeLearningRepository(
      state: WordLearningState(
        wordId: 1,
        masteryLevel: 3,
        studiedCount: 4,
        correctCount: 3,
        wrongCount: 1,
        correctStreak: 2,
        consecutiveForgottenCount: 0,
        lastStudiedAt: now,
        lastReviewedAt: now,
        nextReviewAt: now.add(const Duration(days: 3)),
        updatedAt: now,
      ),
    );
    final logic = _createLogic(
      content: _FakeContentRepository(details: _details()),
      learning: learning,
    );
    addTearDown(logic.onClose);

    await logic.load(1);

    expect(logic.state.learningState?.masteryLevel, 3);
    expect(
      logic.state.learningState?.nextReviewAt,
      now.add(const Duration(days: 3)),
    );
  });

  test('无效 ID 在查询前拒绝，不存在详情进入 notFound', () async {
    final content = _FakeContentRepository(details: null);
    final logic = _createLogic(content: content);
    addTearDown(logic.onClose);

    await expectLater(logic.load(0), throwsA(isA<ArgumentError>()));
    expect(content.calls, 0);
    await logic.load(1);
    expect(logic.state.phase, WordDetailsRunPhase.notFound);
    expect(logic.state.requestedWordId, 1);
  });

  test('详情加载失败后可按当前 ID 重试', () async {
    final content = _FakeContentRepository(details: _details())..fail = true;
    final logic = _createLogic(content: content);
    addTearDown(logic.onClose);

    await logic.load(1);
    expect(logic.state.phase, WordDetailsRunPhase.error);
    expect(logic.state.errorCode, WordDetailsErrorCodes.loadFailed);

    content.fail = false;
    await logic.retry();
    expect(logic.state.phase, WordDetailsRunPhase.loaded);
    expect(content.calls, 2);
  });

  test('收藏写入拒绝重复操作，失败保留原状态并可再次尝试', () async {
    final content = _FakeContentRepository(details: _details());
    final favorites = _FakeFavoriteRepository()..wordGate = Completer<void>();
    final logic = _createLogic(content: content, favorites: favorites);
    addTearDown(logic.onClose);
    await logic.load(1);

    final firstWordToggle = logic.toggleWordFavorite();
    await Future<void>.delayed(Duration.zero);
    await logic.toggleWordFavorite();
    expect(favorites.wordCalls, [(1, true)]);
    expect(logic.state.updatingWordFavorite, isTrue);
    favorites.wordGate!.complete();
    await firstWordToggle;
    expect(logic.state.isWordFavorite, isTrue);

    favorites.failWord = true;
    await logic.toggleWordFavorite();
    expect(logic.state.isWordFavorite, isTrue);
    expect(logic.state.errorCode, WordDetailsErrorCodes.wordFavoriteFailed);

    favorites.failWord = false;
    await logic.toggleWordFavorite();
    expect(logic.state.isWordFavorite, isFalse);

    favorites.failSentenceIds.add(11);
    await logic.toggleSentenceFavorite(11);
    expect(logic.state.favoriteSentenceIds, isEmpty);
    expect(logic.state.errorCode, WordDetailsErrorCodes.sentenceFavoriteFailed);

    favorites.failSentenceIds.clear();
    await logic.toggleSentenceFavorite(11);
    expect(logic.state.favoriteSentenceIds, {11});
  });

  test('单词详情之外的例句 ID 在写入前拒绝', () async {
    final logic = _createLogic(
      content: _FakeContentRepository(details: _details()),
    );
    addTearDown(logic.onClose);
    await logic.load(1);

    await expectLater(
      logic.toggleSentenceFavorite(999),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('发音按词库资源和未配置状态更新独立子状态', () async {
    final localPlayer = _FakeLocalAudioPlayer();
    final logic = _createLogic(
      content: _FakeContentRepository(details: _details()),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
    );
    addTearDown(logic.onClose);
    await logic.load(1);

    await logic.playPronunciation();
    expect(logic.state.audioPhase, WordDetailsAudioPhase.completed);
    expect(logic.state.audioSource, PronunciationPlaybackSource.localAsset);

    await logic.playPronunciation(accent: PronunciationAccent.us);
    expect(logic.state.audioPhase, WordDetailsAudioPhase.unavailable);
    expect(logic.state.audioErrorCode, WordDetailsErrorCodes.audioUnavailable);
  });

  test('发音服务异常只更新音频错误，不覆盖已加载详情', () async {
    final logic = _createLogic(
      content: _FakeContentRepository(details: _details(audioUkAsset: null)),
      pronunciationService: PronunciationService(
        localPlayer: _FakeLocalAudioPlayer(failStop: true),
      ),
    );
    addTearDown(logic.onClose);
    await logic.load(1);

    await logic.playPronunciation();

    expect(logic.state.phase, WordDetailsRunPhase.loaded);
    expect(logic.state.details?.id, 1);
    expect(logic.state.audioPhase, WordDetailsAudioPhase.error);
    expect(logic.state.audioErrorCode, WordDetailsErrorCodes.audioFailed);
  });

  test('关闭后忽略晚返回的发音结果', () async {
    final localPlayer = _FakeLocalAudioPlayer()..playGate = Completer<void>();
    final logic = _createLogic(
      content: _FakeContentRepository(details: _details()),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
    );
    await logic.load(1);

    final pending = logic.playPronunciation();
    await localPlayer.playEntered.future;
    expect(logic.state.audioPhase, WordDetailsAudioPhase.playing);

    logic.onClose();
    localPlayer.playGate!.complete();
    await pending;

    expect(logic.state.audioPhase, WordDetailsAudioPhase.playing);
  });
}

WordDetailsLogic _createLogic({
  required _FakeContentRepository content,
  _FakeFavoriteRepository? favorites,
  _FakeLearningRepository? learning,
  PronunciationService? pronunciationService,
}) {
  return WordDetailsLogic(
    contentRepository: content,
    favoriteRepository: favorites ?? _FakeFavoriteRepository(),
    learningRepository: learning ?? _FakeLearningRepository(),
    pronunciationService:
        pronunciationService ??
        PronunciationService(localPlayer: _FakeLocalAudioPlayer()),
  );
}

final class _FakeLearningRepository implements LearningRepository {
  _FakeLearningRepository({this.state});

  final WordLearningState? state;

  @override
  Future<WordLearningState?> findWordState(int wordId) async => state;

  @override
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds) async =>
      state == null ? const [] : [state!];

  @override
  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window}) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordLearningState>> findDueReviews({int limit = 100}) {
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

WordDetails _details({String? audioUkAsset = 'assets/audio/uk/alpha.mp3'}) {
  return WordDetails(
    id: 1,
    word: 'alpha',
    phoneticUk: '/ˈælfə/',
    phoneticUs: '/ˈælfə/',
    translationZh: '首字母',
    definitionEn: 'the first letter',
    mnemonic: 'A 开头',
    occurrences: 120,
    frequencyGroupId: 1,
    firstLetter: 'A',
    audioUkAsset: audioUkAsset,
    audioUsAsset: null,
    sentences: [
      SentenceDetails(
        id: 11,
        wordId: 1,
        targetForm: 'alpha',
        sentenceEn: 'Alpha comes first.',
        translationZh: 'Alpha 排在第一位。',
        source: 'test',
        location: null,
      ),
      SentenceDetails(
        id: 12,
        wordId: 1,
        targetForm: 'alpha',
        sentenceEn: 'The alpha release is ready.',
        translationZh: 'alpha 版本已经准备好。',
        source: 'test',
        location: null,
      ),
    ],
  );
}

final class _FakeContentRepository implements ContentRepository {
  _FakeContentRepository({required this.details});

  WordDetails? details;
  bool fail = false;
  int calls = 0;

  @override
  Future<WordDetails?> findWordDetails(int wordId) async {
    calls++;
    if (fail) {
      throw Exception('content failed');
    }
    if (details?.id != wordId) {
      return null;
    }
    return details;
  }

  @override
  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups() {
    throw UnimplementedError();
  }

  @override
  Future<List<SentenceDetails>> findSentenceDetailsByIds(Set<int> sentenceIds) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordSummary>> findWordSummariesByIds(Set<int> wordIds) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordSummary>> findWords(WordFilter filter) {
    throw UnimplementedError();
  }
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({Set<int>? wordIds, Set<int>? sentenceIds})
    : wordIds = {...?wordIds},
      sentenceIds = {...?sentenceIds};

  final Set<int> wordIds;
  final Set<int> sentenceIds;
  final List<(int, bool)> wordCalls = [];
  final List<(int, bool)> sentenceCalls = [];
  final Set<int> failSentenceIds = {};
  Completer<void>? wordGate;
  bool failWord = false;

  @override
  Future<Set<int>> findFavoriteWordIds(Set<int> ids) async {
    return wordIds.intersection(ids);
  }

  @override
  Future<Set<int>> findFavoriteSentenceIds(Set<int> ids) async {
    return sentenceIds.intersection(ids);
  }

  @override
  Future<FavoriteWordRecord?> setWordFavorite({
    required int wordId,
    required bool isFavorite,
  }) async {
    wordCalls.add((wordId, isFavorite));
    final gate = wordGate;
    if (gate != null && !gate.isCompleted) {
      await gate.future;
    }
    if (failWord) {
      throw Exception('word favorite failed');
    }
    if (isFavorite) {
      wordIds.add(wordId);
      return _wordRecord(wordId);
    }
    wordIds.remove(wordId);
    return null;
  }

  @override
  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  }) async {
    sentenceCalls.add((sentenceId, isFavorite));
    if (failSentenceIds.contains(sentenceId)) {
      throw Exception('sentence favorite failed');
    }
    if (isFavorite) {
      sentenceIds.add(sentenceId);
      return _sentenceRecord(sentenceId);
    }
    sentenceIds.remove(sentenceId);
    return null;
  }

  @override
  Future<List<FavoriteSentenceRecord>> findFavoriteSentences({
    int limit = 100,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isSentenceFavorite(int sentenceId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isWordFavorite(int wordId) {
    throw UnimplementedError();
  }
}

FavoriteWordRecord _wordRecord(int wordId) {
  final now = DateTime.utc(2026, 8, 15);
  return FavoriteWordRecord(
    id: 'word-favorite-$wordId',
    wordId: wordId,
    createdAt: now,
    updatedAt: now,
  );
}

FavoriteSentenceRecord _sentenceRecord(int sentenceId) {
  final now = DateTime.utc(2026, 8, 15);
  return FavoriteSentenceRecord(
    id: 'sentence-favorite-$sentenceId',
    sentenceId: sentenceId,
    wordId: 1,
    createdAt: now,
    updatedAt: now,
  );
}

final class _FakeLocalAudioPlayer implements LocalAudioPlayer {
  _FakeLocalAudioPlayer({this.failStop = false});

  final bool failStop;
  final List<String> playedAssets = [];
  Completer<void>? playGate;
  final Completer<void> playEntered = Completer<void>();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
    if (!playEntered.isCompleted) {
      playEntered.complete();
    }
    final gate = playGate;
    if (gate != null && !gate.isCompleted) {
      await gate.future;
    }
  }

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {}

  @override
  Future<void> stop() async {
    if (failStop) {
      throw Exception('stop failed');
    }
  }
}
