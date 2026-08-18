import 'dart:async';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_memory_rate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_candidate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_details.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_learning_state.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_session_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/study_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';

void main() {
  test('翻卡只记录一次，评级按 1/3/5 映射并完成会话', () async {
    final learning = _FakeLearningRepository();
    final logic = _createLogic(learning: learning);
    addTearDown(logic.onClose);

    await logic.start(StudyConfig(wordCount: 3));
    expect(logic.state.phase, StudyRunPhase.answering);

    await logic.flip();
    await logic.flip();
    await logic.flip();
    expect(learning.completionCalls, [1]);
    expect(logic.state.isFlipped, isTrue);

    await logic.rate(StudyRating.familiar);
    expect(logic.state.currentIndex, 1);
    expect(learning.ratingCalls, [(1, StudyRating.familiar)]);

    await logic.flip();
    logic.next();
    expect(logic.state.currentIndex, 2);
    expect(learning.completionCalls, [1, 2]);

    await logic.flip();
    await logic.rate(StudyRating.unknown);
    expect(logic.state.phase, StudyRunPhase.completed);
    expect(logic.state.ratings[1], StudyRating.familiar);
    expect(logic.state.ratings[2], isNull);
    expect(logic.state.ratings[3], StudyRating.unknown);
    expect(learning.completionCalls, [1, 2, 3]);
  });

  test('持久化期间拒绝重复翻卡，失败后可重试', () async {
    final learning = _FakeLearningRepository()..completionGate = Completer();
    final logic = _createLogic(learning: learning);
    addTearDown(logic.onClose);
    await logic.start(StudyConfig(wordCount: 3));

    final firstFlip = logic.flip();
    await Future<void>.delayed(Duration.zero);
    expect(logic.state.phase, StudyRunPhase.persisting);
    expect(() => logic.flip(), throwsA(isA<StudySessionTransitionException>()));
    learning.completionGate!.complete();
    await firstFlip;
    expect(logic.state.isFlipped, isTrue);

    learning.failCompletion = true;
    logic.next();
    await logic.flip();
    expect(
      logic.state.errorCode,
      StudyRunErrorCodes.completionPersistenceFailed,
    );
    learning.failCompletion = false;
    await logic.flip();
    expect(logic.state.recordedWordIds, contains(2));
  });

  test('评级失败保留翻开状态并可重试', () async {
    final learning = _FakeLearningRepository()..failRating = true;
    final logic = _createLogic(learning: learning);
    addTearDown(logic.onClose);
    await logic.start(StudyConfig(wordCount: 3));
    await logic.flip();

    await logic.rate(StudyRating.known);
    expect(logic.state.phase, StudyRunPhase.answering);
    expect(logic.state.isFlipped, isTrue);
    expect(logic.state.errorCode, StudyRunErrorCodes.ratingPersistenceFailed);

    learning.failRating = false;
    await logic.rate(StudyRating.known);
    expect(logic.state.currentIndex, 1);
  });

  test('候选不足和未翻卡跳过都返回明确状态或错误', () async {
    final logic = _createLogic(
      learning: _FakeLearningRepository(),
      candidateCount: 2,
    );
    addTearDown(logic.onClose);
    await logic.start(StudyConfig(wordCount: 3));
    expect(logic.state.phase, StudyRunPhase.insufficientCandidates);
    expect(logic.state.availableCount, 2);

    await logic.start(StudyConfig(wordCount: 2));
    expect(() => logic.next(), throwsA(isA<StateError>()));
  });

  test('启动时合并收藏，重复切换只写一次且失败不影响学习进度', () async {
    final favorites = _FakeFavoriteRepository(wordIds: {1})
      ..wordGate = Completer<void>();
    final logic = _createLogic(
      learning: _FakeLearningRepository(),
      favorites: favorites,
    );
    addTearDown(logic.onClose);
    await logic.start(StudyConfig(wordCount: 3));

    expect(logic.state.isCurrentWordFavorite, isTrue);
    final pending = logic.toggleCurrentWordFavorite();
    await Future<void>.delayed(Duration.zero);
    await logic.toggleCurrentWordFavorite();
    expect(favorites.wordCalls, [(1, false)]);
    expect(logic.state.isUpdatingCurrentWordFavorite, isTrue);

    favorites.wordGate!.complete();
    await pending;
    expect(logic.state.isCurrentWordFavorite, isFalse);

    favorites.failWord = true;
    await logic.toggleCurrentWordFavorite();
    expect(logic.state.isCurrentWordFavorite, isFalse);
    expect(
      logic.state.favoriteErrorCode,
      StudyRunErrorCodes.wordFavoriteFailed,
    );
    expect(logic.state.phase, StudyRunPhase.answering);
    expect(logic.state.currentIndex, 0);
  });

  test('自动播放词库音频，未配置第三方 TTS 时保留不可用状态', () async {
    final localPlayer = _FakeLocalAudioPlayer();
    final logic = _createLogic(
      learning: _FakeLearningRepository(),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
      audioUkAsset: 'assets/audio/uk/word-1.mp3',
    );
    addTearDown(logic.onClose);

    await logic.start(
      StudyConfig(
        wordCount: 3,
        pronunciationAccent: PronunciationAccent.uk,
        autoPlayPronunciation: true,
      ),
    );
    await _drainMicrotasks();
    expect(logic.state.audioPhase, StudyAudioPhase.completed);
    expect(logic.state.audioAccent, PronunciationAccent.uk);
    expect(logic.state.audioSource, PronunciationPlaybackSource.localAsset);
    expect(localPlayer.playedAssets, ['assets/audio/uk/word-1.mp3']);

    await logic.playCurrentPronunciation(accent: PronunciationAccent.us);
    expect(logic.state.audioPhase, StudyAudioPhase.unavailable);
    expect(logic.state.audioErrorCode, StudyRunErrorCodes.audioUnavailable);
    expect(logic.state.currentCandidate?.word.id, 1);

    await logic.flip();
    await logic.rate(StudyRating.known);
    await _drainMicrotasks();
    expect(logic.state.currentCandidate?.word.id, 2);
    expect(logic.state.audioWordId, 2);
  });

  test('关闭后忽略迟到发音结果并停止共享播放器', () async {
    final localPlayer = _FakeLocalAudioPlayer()..playGate = Completer<void>();
    final logic = _createLogic(
      learning: _FakeLearningRepository(),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
      audioUkAsset: 'assets/audio/uk/word-1.mp3',
    );
    await logic.start(StudyConfig(wordCount: 3));

    final pending = logic.playCurrentPronunciation();
    await localPlayer.playEntered.future;
    expect(logic.state.audioPhase, StudyAudioPhase.playing);
    logic.onClose();
    localPlayer.playGate!.complete();
    await pending;
    await _drainMicrotasks();

    expect(logic.state.audioPhase, StudyAudioPhase.playing);
    expect(localPlayer.stopCalls, greaterThan(0));
  });
}

StudySessionLogic _createLogic({
  required _FakeLearningRepository learning,
  int candidateCount = 3,
  _FakeFavoriteRepository? favorites,
  PronunciationService? pronunciationService,
  String? audioUkAsset,
}) {
  final candidates = List.generate(
    candidateCount,
    (index) => StudyCandidate(
      WordDetails(
        id: index + 1,
        word: 'word-${index + 1}',
        phoneticUk: null,
        phoneticUs: null,
        translationZh: '释义 ${index + 1}',
        definitionEn: null,
        mnemonic: null,
        occurrences: 100 - index,
        frequencyGroupId: 1,
        firstLetter: 'W',
        audioUkAsset: index == 0 ? audioUkAsset : null,
        audioUsAsset: null,
        sentences: const [],
      ),
    ),
  );
  return StudySessionLogic(
    studyCandidateRepository: _FakeStudyCandidateRepository(
      StudyCandidateBatch(
        candidates: candidates,
        availableCount: candidateCount,
        requestedCount: candidateCount,
      ),
    ),
    learningRepository: learning,
    favoriteRepository: favorites ?? _FakeFavoriteRepository(),
    pronunciationService:
        pronunciationService ??
        PronunciationService(localPlayer: _FakeLocalAudioPlayer()),
  );
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeStudyCandidateRepository implements StudyCandidateRepository {
  _FakeStudyCandidateRepository(this.batch);

  final StudyCandidateBatch batch;

  @override
  Future<StudyCandidateBatch> loadCandidates(StudyConfig config) async {
    return StudyCandidateBatch(
      candidates: batch.candidates,
      availableCount: batch.availableCount,
      requestedCount: config.wordCount,
    );
  }
}

final class _FakeLearningRepository implements LearningRepository {
  final List<int> completionCalls = [];
  final List<(int, StudyRating)> ratingCalls = [];
  bool failCompletion = false;
  bool failRating = false;
  Completer<void>? completionGate;

  @override
  Future<WordLearningState?> findWordState(int wordId) async => null;

  @override
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds) async =>
      const [];

  @override
  Future<WordLearningState> recordStudyCompletion({
    required int wordId,
    String? sessionId,
  }) async {
    if (completionGate != null && !completionGate!.isCompleted) {
      await completionGate!.future;
    }
    if (failCompletion) {
      throw Exception('completion failed');
    }
    completionCalls.add(wordId);
    return _state(wordId, 0);
  }

  @override
  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  }) async {
    if (failRating) {
      throw Exception('rating failed');
    }
    ratingCalls.add((wordId, rating));
    final mastery = switch (rating) {
      StudyRating.unknown => 1,
      StudyRating.familiar => 3,
      StudyRating.known => 5,
    };
    return _state(wordId, mastery);
  }

  @override
  Future<WordLearningState> recordReview({
    required int wordId,
    required ReviewRating rating,
    String? sessionId,
  }) => throw UnimplementedError();

  @override
  Future<List<WordLearningState>> findDueReviews({int limit = 100}) async => [];

  @override
  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window}) async =>
      const ReviewMemoryRate(correctReviews: 0, completedReviews: 0);

  WordLearningState _state(int wordId, int mastery) {
    final now = DateTime.utc(2026, 8, 15);
    return WordLearningState(
      wordId: wordId,
      masteryLevel: mastery,
      studiedCount: 1,
      correctCount: 0,
      wrongCount: 0,
      correctStreak: 0,
      consecutiveForgottenCount: 0,
      lastStudiedAt: now,
      lastReviewedAt: null,
      nextReviewAt: now.add(const Duration(hours: 4)),
      updatedAt: now,
    );
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
        id: 'favorite-$wordId',
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
