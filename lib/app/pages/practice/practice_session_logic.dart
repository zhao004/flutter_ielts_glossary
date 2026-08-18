import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/practice_run_state.dart';
import '../../models/domain/question_config.dart';
import '../../models/domain/quiz_question.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/question_candidate_repository.dart';
import '../../services/clock/monotonic_clock.dart';
import '../../services/clock/periodic_ticker.dart';
import '../../services/audio/audio_playback_service.dart';
import '../../services/question/practice_answer_evaluator.dart';
import '../../services/question/question_engine.dart';
import 'practice_session_starter.dart';

/// 统一协调候选加载、出题、答题持久化、单调计时和结果完成。
class PracticeSessionLogic extends GetxController
    implements PracticeSessionStarter {
  PracticeSessionLogic({
    required this.questionCandidateRepository,
    required this.questionEngine,
    required this.practiceRepository,
    required this.favoriteRepository,
    required this.answerEvaluator,
    required this.monotonicClock,
    this.pronunciationService,
    this.tickerFactory = const DartPeriodicTickerFactory(),
  });

  static const String contentUpdateId = 'practice_content';
  static const String timerUpdateId = 'practice_timer';
  static const Duration timerRefreshInterval = Duration(seconds: 1);

  final QuestionCandidateRepository questionCandidateRepository;
  final QuestionEngine questionEngine;
  final PracticeRepository practiceRepository;
  final FavoriteRepository favoriteRepository;
  final PracticeAnswerEvaluator answerEvaluator;
  final MonotonicClock monotonicClock;
  final PronunciationService? pronunciationService;
  final PeriodicTickerFactory tickerFactory;

  PracticeRunState _state = PracticeRunState.idle();
  @override
  PracticeRunState get state => _state;

  PeriodicTicker? _ticker;
  Duration? _sessionStartedAt;
  Duration? _questionStartedAt;
  Duration? _lastClockValue;
  bool _closed = false;
  int _sessionToken = 0;
  int _audioToken = 0;

  /// 只有空闲、准备失败、候选不足或已完成状态可以开始新会话。
  @override
  Future<void> start(QuestionConfig config) async {
    _requirePhase(const {
      PracticeRunPhase.idle,
      PracticeRunPhase.insufficientCandidates,
      PracticeRunPhase.completed,
      PracticeRunPhase.error,
    }, 'start');
    _cancelTicker();
    final sessionToken = ++_sessionToken;
    _invalidateAudio();
    _sessionStartedAt = null;
    _questionStartedAt = null;
    _replaceState(
      PracticeRunState.idle().copyWith(
        phase: PracticeRunPhase.preparing,
        config: config,
      ),
    );

    try {
      var batch = await questionCandidateRepository.loadCandidateBatch(config);
      if (!_isCurrentSession(sessionToken)) {
        return;
      }
      var availability = questionEngine.inspectAvailability(
        config: config,
        candidates: batch.candidates,
      );
      if (availability.availableCandidateCount < config.questionCount &&
          batch.isTruncated &&
          batch.poolLimit < QuestionCandidatePoolLimits.maximum) {
        batch = await questionCandidateRepository.loadCandidateBatch(
          config,
          minimumPoolLimit: QuestionCandidatePoolLimits.maximum,
        );
        if (!_isCurrentSession(sessionToken)) {
          return;
        }
        availability = questionEngine.inspectAvailability(
          config: config,
          candidates: batch.candidates,
        );
      }
      if (availability.availableCandidateCount < config.questionCount) {
        _replaceState(
          _state.copyWith(
            phase: PracticeRunPhase.insufficientCandidates,
            availability: availability,
            candidatePoolTruncated: batch.isTruncated,
          ),
        );
        return;
      }

      final questionSession = questionEngine.createSession(
        config: config,
        candidates: batch.candidates,
      );
      final sessionWordIds = questionSession.questions
          .map((question) => question.wordId)
          .toSet();
      final favoriteWordIds = await favoriteRepository.findFavoriteWordIds(
        sessionWordIds,
      );
      if (!_isCurrentSession(sessionToken)) {
        return;
      }
      if (!sessionWordIds.containsAll(favoriteWordIds)) {
        throw StateError('收藏 Repository 返回了练习会话外单词');
      }
      final practiceSession = await practiceRepository.startSession(config);
      if (!_isCurrentSession(sessionToken)) {
        return;
      }
      final startedAt = _readClock();
      _sessionStartedAt = startedAt;
      _questionStartedAt = startedAt;
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.answering,
          questionSession: questionSession,
          practiceSession: practiceSession,
          availability: availability,
          candidatePoolTruncated: batch.isTruncated,
          currentQuestionIndex: 0,
          responses: const [],
          favoriteWordIds: favoriteWordIds,
          updatingFavoriteWordIds: const {},
          elapsed: Duration.zero,
          currentQuestionElapsed: Duration.zero,
          favoriteErrorCode: null,
          errorCode: null,
        ),
      );
      if (config.timed) {
        _ticker = tickerFactory.start(
          interval: timerRefreshInterval,
          onTick: _onTimerTick,
        );
      }
    } on Exception {
      if (_closed) {
        return;
      }
      _cancelTicker();
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.error,
          errorCode: PracticeRunErrorCodes.preparationFailed,
        ),
      );
    }
  }

  /// 选择题提交稳定选项 ID，拒绝不存在的选项或错误题型。
  Future<void> submitChoice(String optionId) {
    final question = _requireAnsweringQuestion();
    if (question is! ChoiceQuestion) {
      throw ArgumentError('当前题目不是选择题');
    }
    final normalizedOptionId = optionId.trim();
    if (!question.options.any((option) => option.id == normalizedOptionId)) {
      throw ArgumentError.value(optionId, 'optionId', '所选答案不属于当前题目');
    }
    return _persistAnswer(
      question: question,
      userAnswer: normalizedOptionId,
      isCorrect: normalizedOptionId == question.correctOptionId,
      similarity: null,
    );
  }

  /// 拼写和填空统一使用完全匹配判分，相似度只进入反馈信息。
  Future<void> submitText(String userAnswer) {
    final question = _requireAnsweringQuestion();
    final expectedAnswer = switch (question) {
      SpellingQuestion() => question.expectedAnswer,
      ClozeQuestion() => question.expectedAnswer,
      _ => throw ArgumentError('当前题目不是文字输入题'),
    };
    final evaluation = answerEvaluator.evaluate(
      userAnswer: userAnswer,
      expectedAnswer: expectedAnswer,
    );
    return _persistAnswer(
      question: question,
      userAnswer: userAnswer,
      isCorrect: evaluation.isCorrect,
      similarity: evaluation.similarity,
    );
  }

  /// 答题反馈阶段幂等切换当前题目单词收藏，失败不覆盖作答结果。
  Future<void> toggleCurrentWordFavorite() async {
    _requirePhase(const {PracticeRunPhase.feedback}, 'toggle_word_favorite');
    final question = _state.currentQuestion;
    if (question == null) {
      throw StateError('当前练习没有可收藏的单词');
    }
    final wordId = question.wordId;
    if (_state.updatingFavoriteWordIds.contains(wordId)) {
      return;
    }
    final target = !_state.favoriteWordIds.contains(wordId);
    final sessionToken = _sessionToken;
    _replaceState(
      _state.copyWith(
        updatingFavoriteWordIds: {..._state.updatingFavoriteWordIds, wordId},
        favoriteErrorCode: null,
      ),
    );
    try {
      final record = await favoriteRepository.setWordFavorite(
        wordId: wordId,
        isFavorite: target,
      );
      if (!_isCurrentSession(sessionToken)) {
        return;
      }
      if ((target && (record == null || record.wordId != wordId)) ||
          (!target && record != null)) {
        throw StateError('练习单词收藏写入结果与目标状态不一致');
      }
      final favoriteWordIds = {..._state.favoriteWordIds};
      if (target) {
        favoriteWordIds.add(wordId);
      } else {
        favoriteWordIds.remove(wordId);
      }
      final updatingWordIds = {..._state.updatingFavoriteWordIds}
        ..remove(wordId);
      _replaceState(
        _state.copyWith(
          favoriteWordIds: favoriteWordIds,
          updatingFavoriteWordIds: updatingWordIds,
          favoriteErrorCode: _state.currentQuestion?.wordId == wordId
              ? null
              : _state.favoriteErrorCode,
        ),
      );
    } on Object {
      if (_isCurrentSession(sessionToken)) {
        final updatingWordIds = {..._state.updatingFavoriteWordIds}
          ..remove(wordId);
        _replaceState(
          _state.copyWith(
            updatingFavoriteWordIds: updatingWordIds,
            favoriteErrorCode: _state.currentQuestion?.wordId == wordId
                ? PracticeRunErrorCodes.wordFavoriteFailed
                : _state.favoriteErrorCode,
          ),
        );
      }
    }
  }

  /// 反馈页继续下一题；最后一题会先持久化完成统计再进入完成状态。
  Future<void> next() async {
    _requirePhase(const {PracticeRunPhase.feedback}, 'next');
    if (!_state.isLastQuestion) {
      _invalidateAudio();
      final now = _readClock();
      _questionStartedAt = now;
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.answering,
          currentQuestionIndex: _state.currentQuestionIndex + 1,
          elapsed: _sessionElapsedAt(now),
          currentQuestionElapsed: Duration.zero,
          audioPhase: PracticeAudioPhase.idle,
          audioQuestionId: null,
          audioSource: null,
          audioErrorCode: null,
          favoriteErrorCode: null,
          errorCode: null,
        ),
      );
      return;
    }
    _invalidateAudio();
    _replaceState(
      _state.copyWith(
        audioPhase: PracticeAudioPhase.idle,
        audioQuestionId: null,
        audioSource: null,
        audioErrorCode: null,
      ),
    );
    await _completeSession();
  }

  /// 播放当前听音拼写题的目标单词；其他题型不暴露播放入口。
  Future<void> playCurrentPronunciation({PronunciationAccent? accent}) async {
    _requirePhase(const {
      PracticeRunPhase.answering,
      PracticeRunPhase.feedback,
    }, 'play_pronunciation');
    final question = _state.currentQuestion;
    if (question is! SpellingQuestion ||
        question.promptType != SpellingPromptType.audio) {
      throw StateError('当前题目没有听音提示');
    }
    final service = pronunciationService;
    if (service == null) {
      _replaceState(
        _state.copyWith(
          audioPhase: PracticeAudioPhase.error,
          audioQuestionId: question.id,
          audioSource: null,
          audioErrorCode: PracticeRunErrorCodes.audioFailed,
        ),
      );
      return;
    }
    final selectedAccent =
        accent ??
        (question.audioUkAsset != null
            ? PronunciationAccent.uk
            : PronunciationAccent.us);
    final sessionToken = _sessionToken;
    final audioToken = ++_audioToken;
    _replaceState(
      _state.copyWith(
        audioPhase: PracticeAudioPhase.playing,
        audioQuestionId: question.id,
        audioSource: null,
        audioErrorCode: null,
      ),
    );
    try {
      final result = await service.play(
        word: question.expectedAnswer,
        accent: selectedAccent,
        audioUkAsset: question.audioUkAsset,
        audioUsAsset: question.audioUsAsset,
      );
      if (!_isCurrentAudio(
        sessionToken: sessionToken,
        audioToken: audioToken,
        questionId: question.id,
      )) {
        return;
      }
      final unavailable =
          result.source == PronunciationPlaybackSource.unavailable;
      _replaceState(
        _state.copyWith(
          audioPhase: unavailable
              ? PracticeAudioPhase.unavailable
              : PracticeAudioPhase.completed,
          audioSource: result.source,
          audioErrorCode: unavailable
              ? PracticeRunErrorCodes.audioUnavailable
              : null,
        ),
      );
    } on Object {
      if (_isCurrentAudio(
        sessionToken: sessionToken,
        audioToken: audioToken,
        questionId: question.id,
      )) {
        _replaceState(
          _state.copyWith(
            audioPhase: PracticeAudioPhase.error,
            audioSource: null,
            audioErrorCode: PracticeRunErrorCodes.audioFailed,
          ),
        );
      }
    }
  }

  /// 停止听音拼写播放并清除音频子状态。
  Future<void> stopPronunciation() async {
    _audioToken++;
    try {
      await pronunciationService?.stop();
    } on Object {
      // 停止失败不覆盖题目和答案状态。
    }
    if (!_closed && _state.questionSession != null) {
      _replaceState(
        _state.copyWith(
          audioPhase: PracticeAudioPhase.idle,
          audioQuestionId: null,
          audioSource: null,
          audioErrorCode: null,
        ),
      );
    }
  }

  /// 只允许清理未开始、准备失败、候选不足或已完成会话，避免静默遗留活动会话。
  void reset() {
    _requirePhase(const {
      PracticeRunPhase.idle,
      PracticeRunPhase.insufficientCandidates,
      PracticeRunPhase.completed,
      PracticeRunPhase.error,
    }, 'reset');
    _cancelTicker();
    _sessionStartedAt = null;
    _questionStartedAt = null;
    _replaceState(PracticeRunState.idle());
  }

  Future<void> _persistAnswer({
    required QuizQuestion question,
    required String userAnswer,
    required bool isCorrect,
    required double? similarity,
  }) async {
    final questionStartedAt = _questionStartedAt;
    if (questionStartedAt == null) {
      throw StateError('当前题目缺少单调计时起点');
    }
    final now = _readClock();
    final responseTime = _elapsedBetween(questionStartedAt, now);
    final practiceSession = _state.practiceSession;
    if (practiceSession == null) {
      throw StateError('当前练习缺少持久化会话');
    }
    _invalidateAudio();
    _replaceState(
      _state.copyWith(
        phase: PracticeRunPhase.submitting,
        audioPhase: PracticeAudioPhase.idle,
        audioQuestionId: null,
        audioSource: null,
        audioErrorCode: null,
        elapsed: _sessionElapsedAt(now),
        currentQuestionElapsed: responseTime,
        errorCode: null,
      ),
    );

    try {
      final answer = await practiceRepository.recordAnswer(
        sessionId: practiceSession.id,
        wordId: question.wordId,
        sentenceId: question.sentenceId,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        responseTime: responseTime,
      );
      if (_closed) {
        return;
      }
      if (answer.sessionId != practiceSession.id ||
          answer.wordId != question.wordId ||
          answer.sentenceId != question.sentenceId ||
          answer.isCorrect != isCorrect) {
        throw StateError('持久化答案与当前题目不一致');
      }
      _questionStartedAt = null;
      final response = PracticeQuestionResponse(
        answerId: answer.id,
        questionId: question.id,
        wordId: answer.wordId,
        sentenceId: answer.sentenceId,
        userAnswer: answer.userAnswer,
        isCorrect: answer.isCorrect,
        responseTime: answer.responseTime,
        similarity: similarity,
      );
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.feedback,
          responses: [..._state.responses, response],
          currentQuestionElapsed: answer.responseTime,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_closed) {
        return;
      }
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.answering,
          errorCode: PracticeRunErrorCodes.answerPersistenceFailed,
        ),
      );
    }
  }

  Future<void> _completeSession() async {
    final practiceSession = _state.practiceSession;
    if (practiceSession == null) {
      throw StateError('当前练习缺少持久化会话');
    }
    final now = _readClock();
    final elapsed = _sessionElapsedAt(now);
    _replaceState(
      _state.copyWith(
        phase: PracticeRunPhase.completing,
        elapsed: elapsed,
        errorCode: null,
      ),
    );
    try {
      final completed = await practiceRepository.finishSession(
        sessionId: practiceSession.id,
        elapsed: elapsed,
      );
      if (_closed) {
        return;
      }
      if (completed.id != practiceSession.id ||
          completed.answeredQuestionCount != _state.responses.length ||
          completed.correctCount != _state.correctCount) {
        throw StateError('持久化完成统计与当前会话不一致');
      }
      _cancelTicker();
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.completed,
          practiceSession: completed,
          elapsed: completed.elapsed,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_closed) {
        return;
      }
      _replaceState(
        _state.copyWith(
          phase: PracticeRunPhase.feedback,
          errorCode: PracticeRunErrorCodes.completionFailed,
        ),
      );
    }
  }

  QuizQuestion _requireAnsweringQuestion() {
    _requirePhase(const {PracticeRunPhase.answering}, 'submit_answer');
    final question = _state.currentQuestion;
    if (question == null || _state.currentResponse != null) {
      throw StateError('当前没有可提交的题目');
    }
    return question;
  }

  void _onTimerTick() {
    if (_closed || _sessionStartedAt == null) {
      return;
    }
    final now = _readClock();
    final questionElapsed =
        _state.phase == PracticeRunPhase.answering && _questionStartedAt != null
        ? _elapsedBetween(_questionStartedAt!, now)
        : _state.currentQuestionElapsed;
    _state = _state.copyWith(
      elapsed: _sessionElapsedAt(now),
      currentQuestionElapsed: questionElapsed,
    );
    update([timerUpdateId]);
  }

  Duration _readClock() {
    final current = monotonicClock.elapsed;
    if (current.isNegative ||
        (_lastClockValue != null && current < _lastClockValue!)) {
      throw StateError('单调时钟返回了倒退值');
    }
    _lastClockValue = current;
    return current;
  }

  Duration _sessionElapsedAt(Duration now) {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return Duration.zero;
    }
    return _elapsedBetween(startedAt, now);
  }

  Duration _elapsedBetween(Duration start, Duration end) {
    final elapsed = end - start;
    if (elapsed.isNegative) {
      throw StateError('单调时钟耗时不能为负数');
    }
    return elapsed;
  }

  void _requirePhase(Set<PracticeRunPhase> allowed, String action) {
    if (!allowed.contains(_state.phase)) {
      throw PracticeSessionTransitionException(
        phase: _state.phase,
        action: action,
      );
    }
  }

  bool _isCurrentAudio({
    required int sessionToken,
    required int audioToken,
    required String questionId,
  }) {
    return !_closed &&
        sessionToken == _sessionToken &&
        audioToken == _audioToken &&
        _state.currentQuestion?.id == questionId;
  }

  bool _isCurrentSession(int sessionToken) {
    return !_closed && sessionToken == _sessionToken;
  }

  void _invalidateAudio() {
    _audioToken++;
    final service = pronunciationService;
    if (service != null) {
      unawaited(service.stop().catchError((Object _) {}));
    }
  }

  void _replaceState(PracticeRunState nextState) {
    if (_closed) {
      return;
    }
    _state = nextState;
    update([contentUpdateId]);
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void onClose() {
    _closed = true;
    _sessionToken++;
    _invalidateAudio();
    _cancelTicker();
    super.onClose();
  }
}
