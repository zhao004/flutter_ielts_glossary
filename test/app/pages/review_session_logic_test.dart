import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_memory_rate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_queue.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_learning_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_summary.dart';
import 'package:flutter_ielts_glossary/app/pages/review/review_session_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/review_queue_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/settings_repository.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';

void main() {
  test('空队列保留内容缺失 ID 并进入 empty', () async {
    final queue = _FakeReviewQueueRepository(
      ReviewQueueSnapshot(items: const [], missingWordIds: const [999]),
    );
    final logic = _createLogic(queue: queue);
    addTearDown(logic.onClose);

    await logic.start();

    expect(logic.state.phase, ReviewRunPhase.empty);
    expect(logic.state.totalCount, 0);
    expect(logic.state.missingWordIds, [999]);
  });

  test('翻卡后依次提交记得和重学并汇总会话结果', () async {
    final learning = _FakeLearningRepository();
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(2)),
      learning: learning,
    );
    addTearDown(logic.onClose);

    await logic.start(limit: 2);
    expect(logic.state.phase, ReviewRunPhase.reviewing);
    expect(logic.state.currentItem?.word.id, 1);
    expect(() => logic.submit(ReviewRating.good), throwsA(isA<StateError>()));

    logic.flip();
    await logic.submit(ReviewRating.good);
    expect(logic.state.currentIndex, 1);
    expect(logic.state.completedCount, 1);
    expect(logic.state.responses.single.masteryLevelChange, 1);
    expect(logic.state.progress, 0.5);

    logic.flip();
    await logic.submit(ReviewRating.again);
    expect(logic.state.phase, ReviewRunPhase.completed);
    expect(logic.state.completedCount, 2);
    expect(logic.state.rememberedCount, 1);
    expect(logic.state.forgottenCount, 1);
    expect(logic.state.sessionAccuracy, 0.5);
    expect(logic.state.progress, 1);
    expect(logic.state.memoryRate?.completedReviews, 2);
    expect(learning.reviewCalls, [
      (1, ReviewRating.good),
      (2, ReviewRating.again),
    ]);
  });

  test('提交期间拒绝重复操作，写入失败后保留翻卡并可重试', () async {
    final learning = _FakeLearningRepository()
      ..reviewGate = Completer<void>()
      ..failReview = true;
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(1)),
      learning: learning,
    );
    addTearDown(logic.onClose);
    await logic.start();
    logic.flip();

    final pending = logic.submit(ReviewRating.good);
    await Future<void>.delayed(Duration.zero);
    expect(logic.state.phase, ReviewRunPhase.submitting);
    expect(
      () => logic.submit(ReviewRating.good),
      throwsA(isA<ReviewSessionTransitionException>()),
    );
    learning.reviewGate!.complete();
    await pending;

    expect(logic.state.phase, ReviewRunPhase.reviewing);
    expect(logic.state.isFlipped, isTrue);
    expect(logic.state.errorCode, ReviewRunErrorCodes.persistenceFailed);

    learning.failReview = false;
    await logic.submit(ReviewRating.good);
    expect(logic.state.phase, ReviewRunPhase.completed);
    expect(logic.state.completedCount, 1);
  });

  test('同一单词连续两次重学时提供可选拼写巩固提示', () async {
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(1)),
    );
    addTearDown(logic.onClose);

    await logic.start();
    logic.flip();
    await logic.submit(ReviewRating.again);
    expect(logic.state.reinforcementPrompt, isNull);

    logic.reset();
    await logic.start();
    logic.flip();
    await logic.submit(ReviewRating.again);

    expect(logic.state.reinforcementPrompt?.wordId, 1);
    expect(logic.state.reinforcementPrompt?.word, 'word-1');
    logic.dismissReinforcement();
    expect(logic.state.reinforcementPrompt, isNull);
  });

  test('队列加载失败进入 error，重新开始后恢复', () async {
    final queue = _FakeReviewQueueRepository(_queueSnapshot(1))..fail = true;
    final logic = _createLogic(queue: queue);
    addTearDown(logic.onClose);

    await logic.start();
    expect(logic.state.phase, ReviewRunPhase.error);
    expect(logic.state.errorCode, ReviewRunErrorCodes.preparationFailed);

    queue.fail = false;
    await logic.start();
    expect(logic.state.phase, ReviewRunPhase.reviewing);
  });

  test('记忆率失败不丢失已保存结果，重试只查询统计', () async {
    final learning = _FakeLearningRepository()..failMemoryRate = true;
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(1)),
      learning: learning,
    );
    addTearDown(logic.onClose);
    await logic.start();
    logic.flip();
    await logic.submit(ReviewRating.good);

    expect(logic.state.phase, ReviewRunPhase.completed);
    expect(logic.state.completedCount, 1);
    expect(logic.state.memoryRate, isNull);
    expect(logic.state.errorCode, ReviewRunErrorCodes.memoryRateFailed);

    learning.failMemoryRate = false;
    await logic.retryMemoryRate();
    expect(logic.state.memoryRate?.value, 1);
    expect(logic.state.errorCode, isNull);
    expect(learning.reviewCalls, hasLength(1));
    expect(learning.memoryRateCalls, 2);
  });

  test('关闭后忽略晚返回队列快照', () async {
    final queue = _FakeReviewQueueRepository(_queueSnapshot(1))
      ..gate = Completer<void>();
    final logic = _createLogic(queue: queue);

    final pending = logic.start();
    await Future<void>.delayed(Duration.zero);
    expect(logic.state.phase, ReviewRunPhase.preparing);
    logic.onClose();
    queue.gate!.complete();
    await pending;

    expect(logic.state.phase, ReviewRunPhase.preparing);
  });

  test('复习数量边界在查询前拒绝', () async {
    final queue = _FakeReviewQueueRepository(_queueSnapshot(1));
    final logic = _createLogic(queue: queue);
    addTearDown(logic.onClose);

    await expectLater(logic.start(limit: 0), throwsA(isA<ArgumentError>()));
    await expectLater(
      logic.start(limit: ReviewSessionLogic.maximumReviewLimit + 1),
      throwsA(isA<ArgumentError>()),
    );
    expect(queue.calls, 0);
  });

  test('启动忽略旧默认口音并合并收藏，切换失败不影响翻卡状态', () async {
    final favorites = _FakeFavoriteRepository(wordIds: {1})
      ..wordGate = Completer<void>();
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(1)),
      favorites: favorites,
      settings: _FakeSettingsRepository(
        _settings(accent: PronunciationAccent.us),
      ),
    );
    addTearDown(logic.onClose);
    await logic.start();

    expect(logic.state.pronunciationAccent, PronunciationAccent.uk);
    expect(logic.state.isCurrentWordFavorite, isTrue);
    logic.flip();

    final pending = logic.toggleCurrentWordFavorite();
    await Future<void>.delayed(Duration.zero);
    await logic.toggleCurrentWordFavorite();
    expect(favorites.wordCalls, [(1, false)]);
    expect(logic.state.isUpdatingCurrentWordFavorite, isTrue);
    favorites.wordGate!.complete();
    await pending;
    expect(logic.state.isCurrentWordFavorite, isFalse);
    expect(logic.state.isFlipped, isTrue);

    favorites.failWord = true;
    await logic.toggleCurrentWordFavorite();
    expect(logic.state.isCurrentWordFavorite, isFalse);
    expect(
      logic.state.favoriteErrorCode,
      ReviewRunErrorCodes.wordFavoriteFailed,
    );
    expect(logic.state.phase, ReviewRunPhase.reviewing);
    expect(logic.state.isFlipped, isTrue);
  });

  test('参考发音支持词库资源和未配置状态，切卡后清理', () async {
    final localPlayer = _FakeLocalAudioPlayer();
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(2)),
      settings: _FakeSettingsRepository(
        _settings(accent: PronunciationAccent.us),
      ),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
    );
    addTearDown(logic.onClose);
    await logic.start();

    await logic.playCurrentPronunciation(accent: PronunciationAccent.us);
    expect(logic.state.audioPhase, ReviewAudioPhase.unavailable);
    expect(logic.state.audioErrorCode, ReviewRunErrorCodes.audioUnavailable);

    await logic.playCurrentPronunciation(accent: PronunciationAccent.uk);
    expect(logic.state.audioSource, PronunciationPlaybackSource.localAsset);
    expect(localPlayer.playedAssets, ['assets/audio/uk/word-1.mp3']);

    logic.flip();
    await logic.submit(ReviewRating.good);
    expect(logic.state.currentIndex, 1);
    expect(logic.state.audioPhase, ReviewAudioPhase.idle);
    expect(logic.state.audioWordId, isNull);
  });

  test('关闭后忽略迟到发音结果并停止共享播放器', () async {
    final localPlayer = _FakeLocalAudioPlayer()..playGate = Completer<void>();
    final logic = _createLogic(
      queue: _FakeReviewQueueRepository(_queueSnapshot(1)),
      settings: _FakeSettingsRepository(
        _settings(accent: PronunciationAccent.uk),
      ),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
    );
    await logic.start();

    final pending = logic.playCurrentPronunciation();
    await localPlayer.playEntered.future;
    expect(logic.state.audioPhase, ReviewAudioPhase.playing);
    logic.onClose();
    localPlayer.playGate!.complete();
    await pending;
    await Future<void>.delayed(Duration.zero);

    expect(logic.state.audioPhase, ReviewAudioPhase.playing);
    expect(localPlayer.stopCalls, greaterThan(0));
  });
}

ReviewSessionLogic _createLogic({
  required _FakeReviewQueueRepository queue,
  _FakeLearningRepository? learning,
  _FakeFavoriteRepository? favorites,
  _FakeSettingsRepository? settings,
  PronunciationService? pronunciationService,
}) {
  return ReviewSessionLogic(
    reviewQueueRepository: queue,
    learningRepository: learning ?? _FakeLearningRepository(),
    favoriteRepository: favorites ?? _FakeFavoriteRepository(),
    settingsRepository: settings ?? _FakeSettingsRepository(_settings()),
    pronunciationService:
        pronunciationService ??
        PronunciationService(localPlayer: _FakeLocalAudioPlayer()),
  );
}

ReviewQueueSnapshot _queueSnapshot(int count) {
  final now = DateTime.utc(2026, 8, 15, 12);
  return ReviewQueueSnapshot(
    items: List.generate(
      count,
      (index) => ReviewQueueItem(
        word: WordSummary(
          id: index + 1,
          word: 'word-${index + 1}',
          phoneticUk: null,
          phoneticUs: null,
          translationZh: '释义 ${index + 1}',
          occurrences: 100 - index,
          frequencyGroupId: 1,
          audioUkAsset: index == 0 ? 'assets/audio/uk/word-1.mp3' : null,
          audioUsAsset: null,
        ),
        learningState: WordLearningState(
          wordId: index + 1,
          masteryLevel: index == 0 ? 2 : 1,
          studiedCount: 1,
          correctCount: 0,
          wrongCount: 0,
          correctStreak: 0,
          consecutiveForgottenCount: 0,
          lastStudiedAt: now.subtract(const Duration(days: 1)),
          lastReviewedAt: null,
          nextReviewAt: now.subtract(Duration(hours: index + 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ),
    ),
    missingWordIds: const [],
  );
}

final class _FakeReviewQueueRepository implements ReviewQueueRepository {
  _FakeReviewQueueRepository(this.snapshot);

  final ReviewQueueSnapshot snapshot;
  bool fail = false;
  int calls = 0;
  Completer<void>? gate;

  @override
  Future<ReviewQueueSnapshot> findDueItems({int limit = 100}) async {
    calls++;
    final currentGate = gate;
    if (currentGate != null && !currentGate.isCompleted) {
      await currentGate.future;
    }
    if (fail) {
      throw Exception('queue failed');
    }
    return snapshot;
  }
}

final class _FakeLearningRepository implements LearningRepository {
  final List<(int, ReviewRating)> reviewCalls = [];
  final Map<int, int> _consecutiveForgottenCounts = {};
  bool failReview = false;
  bool failMemoryRate = false;
  int memoryRateCalls = 0;
  Completer<void>? reviewGate;

  @override
  Future<WordLearningState?> findWordState(int wordId) async => null;

  @override
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds) async =>
      const [];

  @override
  Future<WordLearningState> recordReview({
    required int wordId,
    required ReviewRating rating,
    String? sessionId,
  }) async {
    final currentGate = reviewGate;
    if (currentGate != null && !currentGate.isCompleted) {
      await currentGate.future;
    }
    if (failReview) {
      throw Exception('review failed');
    }
    reviewCalls.add((wordId, rating));
    final previousMastery = wordId == 1 ? 2 : 1;
    final mastery = switch (rating) {
      ReviewRating.again => previousMastery > 0 ? previousMastery - 1 : 0,
      ReviewRating.hard => previousMastery,
      ReviewRating.good => previousMastery < 5 ? previousMastery + 1 : 5,
      ReviewRating.easy => previousMastery + 2 > 5 ? 5 : previousMastery + 2,
    };
    final consecutiveForgottenCount = rating == ReviewRating.again
        ? (_consecutiveForgottenCounts[wordId] ?? 0) + 1
        : 0;
    _consecutiveForgottenCounts[wordId] = consecutiveForgottenCount;
    final now = DateTime.utc(2026, 8, 15, 12);
    return WordLearningState(
      wordId: wordId,
      masteryLevel: mastery,
      studiedCount: 2,
      correctCount: rating.recalled ? 1 : 0,
      wrongCount: rating == ReviewRating.again ? 1 : 0,
      correctStreak: rating.recalled ? 1 : 0,
      consecutiveForgottenCount: consecutiveForgottenCount,
      lastStudiedAt: now,
      lastReviewedAt: now,
      nextReviewAt: now.add(const Duration(hours: 12)),
      updatedAt: now,
    );
  }

  @override
  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window}) async {
    memoryRateCalls++;
    if (failMemoryRate) {
      throw Exception('memory rate failed');
    }
    final remembered = reviewCalls.where((call) => call.$2.recalled).length;
    return ReviewMemoryRate(
      correctReviews: remembered,
      completedReviews: reviewCalls.length,
    );
  }

  @override
  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordLearningState>> findDueReviews({int limit = 100}) async => [];

  @override
  Future<WordLearningState> recordStudyCompletion({
    required int wordId,
    String? sessionId,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({Set<int>? wordIds}) : wordIds = {...?wordIds};

  final Set<int> wordIds;
  final List<(int, bool)> wordCalls = [];
  Completer<void>? wordGate;
  bool failWord = false;

  @override
  Future<Set<int>> findFavoriteWordIds(Set<int> ids) async {
    return wordIds.intersection(ids);
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
      return FavoriteWordRecord(
        id: 'review-favorite-$wordId',
        wordId: wordId,
        createdAt: DateTime.utc(2026, 8, 15),
        updatedAt: DateTime.utc(2026, 8, 15),
      );
    }
    wordIds.remove(wordId);
    return null;
  }

  @override
  Future<Set<int>> findFavoriteSentenceIds(Set<int> sentenceIds) async => {};

  @override
  Future<List<FavoriteSentenceRecord>> findFavoriteSentences({
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<bool> isSentenceFavorite(int sentenceId) => throw UnimplementedError();

  @override
  Future<bool> isWordFavorite(int wordId) => throw UnimplementedError();

  @override
  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  }) => throw UnimplementedError();
}

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.settings);

  final AppSettingsState settings;

  @override
  Future<AppSettingsState> load() async => settings;

  @override
  Future<AppSettingsState> update({
    int? dailyGoal,
    PronunciationAccent? pronunciationAccent,
    bool? autoPlayPronunciation,
    AppThemePreference? themePreference,
    FlexScheme? accentPreference,
  }) => throw UnimplementedError();
}

AppSettingsState _settings({
  PronunciationAccent accent = PronunciationAccent.uk,
}) {
  return AppSettingsState(
    dailyGoal: AppSettingsState.defaultDailyGoal,
    pronunciationAccent: accent,
    autoPlayPronunciation: false,
    themePreference: AppThemePreference.system,
    updatedAt: null,
  );
}

final class _FakeLocalAudioPlayer implements LocalAudioPlayer {
  final List<String> playedAssets = [];
  var stopCalls = 0;
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
    stopCalls++;
  }
}
