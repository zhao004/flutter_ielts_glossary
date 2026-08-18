import 'dart:async';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/practice_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/practice_session.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_candidate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/quiz_question.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_session_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/practice_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/question_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/monotonic_clock.dart';
import 'package:flutter_ielts_glossary/app/services/clock/periodic_ticker.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';
import 'package:flutter_ielts_glossary/app/services/question/practice_answer_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_engine.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  test('计时练习完成完整状态转换并只在最后一步完成会话', () async {
    final clock = _FakeMonotonicClock();
    final tickerFactory = _FakeTickerFactory();
    final practiceRepository = _FakePracticeRepository();
    final logic = _createLogic(
      clock: clock,
      tickerFactory: tickerFactory,
      practiceRepository: practiceRepository,
    );
    addTearDown(logic.onClose);

    await logic.start(_choiceConfig(timed: true));

    expect(logic.state.phase, PracticeRunPhase.answering);
    expect(logic.state.currentQuestionIndex, 0);
    expect(tickerFactory.ticker?.isActive, isTrue);

    clock.advance(const Duration(seconds: 2));
    tickerFactory.ticker!.tick();
    expect(logic.state.elapsed, const Duration(seconds: 2));
    expect(logic.state.currentQuestionElapsed, const Duration(seconds: 2));

    for (var index = 0; index < 5; index++) {
      final question = logic.state.currentQuestion! as ChoiceQuestion;
      clock.advance(const Duration(seconds: 2));
      final selectedOption = index.isEven
          ? question.correctOptionId
          : question.options
                .firstWhere((option) => option.id != question.correctOptionId)
                .id;
      await logic.submitChoice(selectedOption);
      expect(logic.state.phase, PracticeRunPhase.feedback);
      expect(logic.state.currentResponse?.isCorrect, index.isEven);
      if (index < 4) {
        clock.advance(const Duration(seconds: 1));
        await logic.next();
        expect(logic.state.phase, PracticeRunPhase.answering);
        expect(logic.state.currentQuestionElapsed, Duration.zero);
      }
    }

    clock.advance(const Duration(seconds: 1));
    await logic.next();

    expect(logic.state.phase, PracticeRunPhase.completed);
    expect(logic.state.correctCount, 3);
    expect(logic.state.answeredQuestionCount, 5);
    expect(logic.state.practiceSession?.isFinished, isTrue);
    expect(tickerFactory.ticker?.isActive, isFalse);
    expect(practiceRepository.finishCalls, 1);
  });

  test('文本题使用完全匹配和相似度反馈，不把近似答案判为正确', () async {
    final clock = _FakeMonotonicClock();
    final practiceRepository = _FakePracticeRepository();
    final logic = _createLogic(
      clock: clock,
      practiceRepository: practiceRepository,
      candidates: _candidates(5),
    );
    addTearDown(logic.onClose);

    await logic.start(
      QuestionConfig(
        type: QuestionType.spelling,
        spellingPromptType: SpellingPromptType.translation,
        questionCount: 5,
      ),
    );
    final question = logic.state.currentQuestion! as SpellingQuestion;
    clock.advance(const Duration(seconds: 3));
    await logic.submitText(' ${question.expectedAnswer.toUpperCase()} ');

    expect(logic.state.phase, PracticeRunPhase.feedback);
    expect(logic.state.currentResponse?.isCorrect, isTrue);
    expect(logic.state.currentResponse?.similarity, 1);

    await logic.next();
    final nextQuestion = logic.state.currentQuestion! as SpellingQuestion;
    await logic.submitText('${nextQuestion.expectedAnswer}x');
    expect(logic.state.currentResponse?.isCorrect, isFalse);
    expect(logic.state.currentResponse?.similarity, lessThan(1));
  });

  test('填空题把真实关联例句 ID 写入答案记录', () async {
    final clock = _FakeMonotonicClock();
    final practiceRepository = _FakePracticeRepository();
    final logic = _createLogic(
      clock: clock,
      practiceRepository: practiceRepository,
    );
    addTearDown(logic.onClose);

    await logic.start(
      QuestionConfig(type: QuestionType.cloze, questionCount: 5),
    );
    final question = logic.state.currentQuestion! as ClozeQuestion;
    await logic.submitText(question.expectedAnswer);

    expect(practiceRepository.answers.single.sentenceId, question.sentenceId);
    expect(logic.state.currentResponse?.sentenceId, question.sentenceId);
  });

  test('听音拼写保留播放结果，并在提交答案时清理音频状态', () async {
    final localPlayer = _FakeLocalAudioPlayer();
    final logic = _createLogic(
      clock: _FakeMonotonicClock(),
      candidates: _candidates(5, withAudio: true),
      pronunciationService: PronunciationService(localPlayer: localPlayer),
    );
    addTearDown(logic.onClose);

    await logic.start(
      QuestionConfig(
        type: QuestionType.spelling,
        questionCount: 5,
        spellingPromptType: SpellingPromptType.audio,
      ),
    );
    final question = logic.state.currentQuestion! as SpellingQuestion;

    await logic.playCurrentPronunciation();
    expect(logic.state.audioPhase, PracticeAudioPhase.completed);
    expect(logic.state.audioQuestionId, question.id);
    expect(logic.state.audioSource, PronunciationPlaybackSource.localAsset);
    expect(localPlayer.playedAssets, contains(question.audioUkAsset));

    await logic.playCurrentPronunciation(accent: PronunciationAccent.us);
    expect(logic.state.audioPhase, PracticeAudioPhase.unavailable);
    expect(logic.state.audioErrorCode, PracticeRunErrorCodes.audioUnavailable);

    await logic.submitText(question.expectedAnswer);
    expect(logic.state.phase, PracticeRunPhase.feedback);
    expect(logic.state.audioPhase, PracticeAudioPhase.idle);
    expect(logic.state.audioQuestionId, isNull);
    expect(logic.state.audioSource, isNull);
    expect(logic.state.audioErrorCode, isNull);
  });

  test('练习反馈合并并幂等切换当前单词收藏，失败不覆盖答题结果', () async {
    final favorites = _FakeFavoriteRepository(
      wordIds: _candidates(8).map((candidate) => candidate.wordId).toSet(),
    );
    final logic = _createLogic(
      clock: _FakeMonotonicClock(),
      favoriteRepository: favorites,
    );
    addTearDown(logic.onClose);

    await logic.start(_choiceConfig());
    final question = logic.state.currentQuestion! as ChoiceQuestion;
    await logic.submitChoice(question.correctOptionId);

    expect(logic.state.phase, PracticeRunPhase.feedback);
    expect(logic.state.isCurrentWordFavorite, isTrue);
    await logic.toggleCurrentWordFavorite();
    expect(logic.state.isCurrentWordFavorite, isFalse);
    expect(favorites.wordCalls.last, (question.wordId, false));

    favorites.failWord = true;
    await logic.toggleCurrentWordFavorite();
    expect(logic.state.isCurrentWordFavorite, isFalse);
    expect(
      logic.state.favoriteErrorCode,
      PracticeRunErrorCodes.wordFavoriteFailed,
    );
    expect(logic.state.currentResponse?.isCorrect, isTrue);
  });

  test('答案持久化失败回到当前题并可重试，快速重复提交被拒绝', () async {
    final clock = _FakeMonotonicClock();
    final practiceRepository = _FakePracticeRepository()..failAnswers = true;
    final gate = Completer<void>();
    practiceRepository.answerGate = gate;
    final logic = _createLogic(
      clock: clock,
      practiceRepository: practiceRepository,
    );
    addTearDown(logic.onClose);
    await logic.start(_choiceConfig());
    final question = logic.state.currentQuestion! as ChoiceQuestion;

    final pending = logic.submitChoice(question.correctOptionId);
    expect(logic.state.phase, PracticeRunPhase.submitting);
    expect(
      () => logic.submitChoice(question.correctOptionId),
      throwsA(isA<PracticeSessionTransitionException>()),
    );
    gate.complete();
    await pending;

    expect(logic.state.phase, PracticeRunPhase.answering);
    expect(
      logic.state.errorCode,
      PracticeRunErrorCodes.answerPersistenceFailed,
    );
    expect(logic.state.responses, isEmpty);

    practiceRepository.failAnswers = false;
    clock.advance(const Duration(seconds: 1));
    await logic.submitChoice(question.correctOptionId);
    expect(logic.state.phase, PracticeRunPhase.feedback);
    expect(logic.state.responses, hasLength(1));
  });

  test('候选池截断且不足时自动扩容一次', () async {
    final candidateRepository = _FakeCandidateRepository([
      _batch(_candidates(4), databaseCount: 200, poolLimit: 100),
      _batch(_candidates(5), databaseCount: 200, poolLimit: 500),
    ]);
    final practiceRepository = _FakePracticeRepository();
    final logic = _createLogic(
      clock: _FakeMonotonicClock(),
      candidateRepository: candidateRepository,
      practiceRepository: practiceRepository,
    );
    addTearDown(logic.onClose);

    await logic.start(_choiceConfig());

    expect(logic.state.phase, PracticeRunPhase.answering);
    expect(candidateRepository.requestedPoolLimits, [null, 500]);
    expect(practiceRepository.startCalls, 1);
  });

  test('未截断候选不足时不创建持久化会话', () async {
    final candidateRepository = _FakeCandidateRepository([
      _batch(_candidates(4), databaseCount: 4, poolLimit: 100),
    ]);
    final practiceRepository = _FakePracticeRepository();
    final logic = _createLogic(
      clock: _FakeMonotonicClock(),
      candidateRepository: candidateRepository,
      practiceRepository: practiceRepository,
    );
    addTearDown(logic.onClose);

    await logic.start(_choiceConfig());

    expect(logic.state.phase, PracticeRunPhase.insufficientCandidates);
    expect(logic.state.availability?.availableCandidateCount, 4);
    expect(logic.state.candidatePoolTruncated, isFalse);
    expect(practiceRepository.startCalls, 0);
  });

  test('完成统计写入失败时停留在末题反馈并允许重试', () async {
    final practiceRepository = _FakePracticeRepository()..failFinish = true;
    final logic = _createLogic(
      clock: _FakeMonotonicClock(),
      practiceRepository: practiceRepository,
    );
    addTearDown(logic.onClose);
    await logic.start(_choiceConfig());

    for (var index = 0; index < 5; index++) {
      final question = logic.state.currentQuestion! as ChoiceQuestion;
      await logic.submitChoice(question.correctOptionId);
      await logic.next();
    }

    expect(logic.state.phase, PracticeRunPhase.feedback);
    expect(logic.state.errorCode, PracticeRunErrorCodes.completionFailed);
    practiceRepository.failFinish = false;
    await logic.next();
    expect(logic.state.phase, PracticeRunPhase.completed);
    expect(practiceRepository.finishCalls, 2);
  });

  test('关闭 Logic 会取消计时刷新器', () async {
    final tickerFactory = _FakeTickerFactory();
    final logic = _createLogic(
      clock: _FakeMonotonicClock(),
      tickerFactory: tickerFactory,
    );
    await logic.start(_choiceConfig(timed: true));

    logic.onClose();

    expect(tickerFactory.ticker?.isActive, isFalse);
  });
}

PracticeSessionLogic _createLogic({
  required _FakeMonotonicClock clock,
  _FakeTickerFactory? tickerFactory,
  _FakeCandidateRepository? candidateRepository,
  _FakePracticeRepository? practiceRepository,
  _FakeFavoriteRepository? favoriteRepository,
  List<QuestionCandidate>? candidates,
  PronunciationService? pronunciationService,
}) {
  final resolvedCandidateRepository =
      candidateRepository ??
      _FakeCandidateRepository([
        _batch(candidates ?? _candidates(8), databaseCount: 8, poolLimit: 100),
      ]);
  return PracticeSessionLogic(
    questionCandidateRepository: resolvedCandidateRepository,
    questionEngine: QuestionEngine(
      randomSource: DartQuestionRandomSource(seed: 12),
    ),
    practiceRepository: practiceRepository ?? _FakePracticeRepository(),
    favoriteRepository: favoriteRepository ?? _FakeFavoriteRepository(),
    answerEvaluator: const PracticeAnswerEvaluator(),
    monotonicClock: clock,
    pronunciationService: pronunciationService,
    tickerFactory: tickerFactory ?? _FakeTickerFactory(),
  );
}

QuestionConfig _choiceConfig({bool timed = false}) {
  return QuestionConfig(
    type: QuestionType.choiceEnglishToChinese,
    questionCount: 5,
    timed: timed,
  );
}

QuestionCandidateBatch _batch(
  List<QuestionCandidate> candidates, {
  required int databaseCount,
  required int poolLimit,
}) {
  return QuestionCandidateBatch(
    candidates: candidates,
    databaseQualifiedWordCount: databaseCount,
    poolLimit: poolLimit,
  );
}

List<QuestionCandidate> _candidates(int count, {bool withAudio = false}) {
  return List.generate(count, (index) {
    final id = index + 1;
    final word = _word(id);
    return QuestionCandidate(
      wordId: id,
      word: word,
      frequencyGroupId: 1,
      translationZh: '释义$id',
      phoneticUk: '/$word/',
      audioUkAsset: withAudio ? 'assets/audio/uk/$word.mp3' : null,
      sentences: [
        QuestionSentenceCandidate(
          id: id * 10,
          targetForm: word,
          sentenceEn: 'We use $word here.',
        ),
      ],
    );
  }, growable: false);
}

String _word(int id) {
  const words = [
    'apple',
    'banana',
    'cedar',
    'delta',
    'eagle',
    'forest',
    'garden',
    'harbor',
    'island',
    'jungle',
  ];
  return words[(id - 1) % words.length];
}

final class _FakeMonotonicClock implements MonotonicClock {
  Duration value = Duration.zero;

  @override
  Duration get elapsed => value;

  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', '测试时钟不能倒退');
    }
    value += duration;
  }
}

final class _FakeTickerFactory implements PeriodicTickerFactory {
  _FakeTicker? ticker;

  @override
  PeriodicTicker start({
    required Duration interval,
    required void Function() onTick,
  }) {
    ticker = _FakeTicker(onTick);
    return ticker!;
  }
}

final class _FakeTicker implements PeriodicTicker {
  _FakeTicker(this._onTick);

  final void Function() _onTick;
  var _active = true;

  @override
  bool get isActive => _active;

  @override
  void cancel() {
    _active = false;
  }

  void tick() {
    if (_active) {
      _onTick();
    }
  }
}

final class _FakeCandidateRepository implements QuestionCandidateRepository {
  _FakeCandidateRepository(this._batches);

  final List<QuestionCandidateBatch> _batches;
  final List<int?> requestedPoolLimits = [];

  @override
  Future<QuestionCandidateBatch> loadCandidateBatch(
    QuestionConfig config, {
    int? minimumPoolLimit,
  }) async {
    requestedPoolLimits.add(minimumPoolLimit);
    if (_batches.length > 1) {
      return _batches.removeAt(0);
    }
    return _batches.single;
  }
}

final class _FakePracticeRepository implements PracticeRepository {
  var startCalls = 0;
  var finishCalls = 0;
  var failAnswers = false;
  var failFinish = false;
  Completer<void>? answerGate;
  final answers = <PracticeAnswerRecord>[];
  PracticeSessionRecord? session;

  @override
  Future<PracticeSessionRecord> startSession(QuestionConfig config) async {
    startCalls++;
    final result = PracticeSessionRecord(
      id: 'session-1',
      config: config,
      startedAt: DateTime.utc(2026, 8, 15, 12),
      finishedAt: null,
      answeredQuestionCount: 0,
      correctCount: 0,
      elapsed: Duration.zero,
    );
    session = result;
    return result;
  }

  @override
  Future<PracticeAnswerRecord> recordAnswer({
    required String sessionId,
    required int wordId,
    int? sentenceId,
    required String userAnswer,
    required bool isCorrect,
    required Duration responseTime,
  }) async {
    final gate = answerGate;
    if (gate != null) {
      await gate.future;
      answerGate = null;
    }
    if (failAnswers) {
      throw Exception('test answer failure');
    }
    final answer = PracticeAnswerRecord(
      id: 'answer-${answers.length + 1}',
      sessionId: sessionId,
      wordId: wordId,
      sentenceId: sentenceId,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      responseTime: responseTime,
      answeredAt: DateTime.utc(2026, 8, 15, 12),
    );
    answers.add(answer);
    return answer;
  }

  @override
  Future<PracticeSessionRecord> finishSession({
    required String sessionId,
    required Duration elapsed,
  }) async {
    finishCalls++;
    if (failFinish) {
      throw Exception('test completion failure');
    }
    final current = session!;
    final completed = PracticeSessionRecord(
      id: current.id,
      config: current.config,
      startedAt: current.startedAt,
      finishedAt: DateTime.utc(2026, 8, 15, 12),
      answeredQuestionCount: answers.length,
      correctCount: answers.where((answer) => answer.isCorrect).length,
      elapsed: elapsed,
    );
    session = completed;
    return completed;
  }

  @override
  Future<PracticeSessionRecord?> findSession(String sessionId) async => session;
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({Set<int>? wordIds}) : wordIds = {...?wordIds};

  final Set<int> wordIds;
  final List<(int, bool)> wordCalls = [];
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
    if (failWord) {
      throw Exception('test favorite failure');
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
  }) async => [];

  @override
  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  }) async => [];

  @override
  Future<bool> isSentenceFavorite(int sentenceId) async => false;

  @override
  Future<bool> isWordFavorite(int wordId) async => wordIds.contains(wordId);

  @override
  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  }) async => null;
}

final class _FakeLocalAudioPlayer implements LocalAudioPlayer {
  final List<String> playedAssets = [];

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
