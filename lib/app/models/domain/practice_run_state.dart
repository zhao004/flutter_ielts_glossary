import 'practice_session.dart';
import 'question_config.dart';
import 'question_session.dart';
import 'quiz_question.dart';
import '../../services/audio/audio_playback_service.dart';

enum PracticeRunPhase {
  idle,
  preparing,
  insufficientCandidates,
  answering,
  submitting,
  feedback,
  completing,
  completed,
  error,
}

/// 练习听音拼写的独立播放阶段，不影响答案提交状态。
enum PracticeAudioPhase { idle, playing, completed, unavailable, error }

/// 页面只消费稳定错误码，不展示底层数据库异常正文。
abstract final class PracticeRunErrorCodes {
  static const String preparationFailed = 'practice_preparation_failed';
  static const String answerPersistenceFailed =
      'practice_answer_persistence_failed';
  static const String completionFailed = 'practice_completion_failed';
  static const String wordFavoriteFailed = 'practice_word_favorite_failed';
  static const String audioFailed = 'practice_audio_failed';
  static const String audioUnavailable = 'practice_audio_unavailable';
}

/// 非法调用顺序属于 Logic 使用错误，不转换为普通业务失败状态。
final class PracticeSessionTransitionException implements Exception {
  const PracticeSessionTransitionException({
    required this.phase,
    required this.action,
  });

  final PracticeRunPhase phase;
  final String action;

  @override
  String toString() => 'invalid_practice_transition: ${phase.name}/$action';
}

/// 一道题已经持久化成功的作答反馈。
final class PracticeQuestionResponse {
  PracticeQuestionResponse({
    required String answerId,
    required String questionId,
    required this.wordId,
    required this.sentenceId,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTime,
    required this.similarity,
  }) : answerId = _requireId(answerId, 'answerId'),
       questionId = _requireId(questionId, 'questionId') {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    if (sentenceId != null && sentenceId! <= 0) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '例句 ID 必须为正整数');
    }
    if (responseTime.isNegative) {
      throw ArgumentError.value(responseTime, 'responseTime', '响应耗时不能为负数');
    }
    if (similarity != null && (similarity! < 0 || similarity! > 1)) {
      throw ArgumentError.value(similarity, 'similarity', '相似度必须在 0-1 之间');
    }
  }

  final String answerId;
  final String questionId;
  final int wordId;
  final int? sentenceId;
  final String userAnswer;
  final bool isCorrect;
  final Duration responseTime;
  final double? similarity;
}

/// 练习页面的不可变状态快照，题目和计时不会散落在 Widget 局部变量中。
final class PracticeRunState {
  PracticeRunState({
    required this.phase,
    required this.config,
    required this.questionSession,
    required this.practiceSession,
    required this.currentQuestionIndex,
    required List<PracticeQuestionResponse> responses,
    required this.elapsed,
    required this.currentQuestionElapsed,
    required this.availability,
    required this.candidatePoolTruncated,
    required Set<int> favoriteWordIds,
    required Set<int> updatingFavoriteWordIds,
    required this.audioPhase,
    required this.audioQuestionId,
    required this.audioSource,
    required this.audioErrorCode,
    required this.favoriteErrorCode,
    required this.errorCode,
  }) : responses = List<PracticeQuestionResponse>.unmodifiable(responses),
       favoriteWordIds = Set<int>.unmodifiable(favoriteWordIds),
       updatingFavoriteWordIds = Set<int>.unmodifiable(
         updatingFavoriteWordIds,
       ) {
    if (currentQuestionIndex < 0) {
      throw ArgumentError.value(
        currentQuestionIndex,
        'currentQuestionIndex',
        '题目索引不能为负数',
      );
    }
    if (elapsed.isNegative || currentQuestionElapsed.isNegative) {
      throw ArgumentError('练习耗时不能为负数');
    }
    final session = questionSession;
    if (session == null && currentQuestionIndex != 0) {
      throw ArgumentError('尚未生成题目时索引必须为 0');
    }
    if (session != null && currentQuestionIndex >= session.questions.length) {
      throw ArgumentError.value(
        currentQuestionIndex,
        'currentQuestionIndex',
        '题目索引超出会话范围',
      );
    }
    final responseQuestionIds = this.responses
        .map((response) => response.questionId)
        .toSet();
    if (responseQuestionIds.length != this.responses.length) {
      throw ArgumentError.value(responses, 'responses', '同一道题不能存在重复反馈');
    }
    if (session != null &&
        responseQuestionIds.any(
          (id) => !session.questions.any((question) => question.id == id),
        )) {
      throw ArgumentError.value(responses, 'responses', '反馈包含会话外题目');
    }
    final questionIds =
        session?.questions.map((question) => question.id).toSet() ?? {};
    final wordIds =
        session?.questions.map((question) => question.wordId).toSet() ?? {};
    if (!this.favoriteWordIds.every(wordIds.contains) ||
        !this.updatingFavoriteWordIds.every(wordIds.contains)) {
      throw ArgumentError('练习收藏状态包含会话外单词');
    }
    if (favoriteErrorCode != null && favoriteErrorCode!.trim().isEmpty) {
      throw ArgumentError('练习收藏错误码不能为空');
    }
    if (audioQuestionId != null && !questionIds.contains(audioQuestionId)) {
      throw ArgumentError('练习发音状态包含会话外题目');
    }
    if (audioErrorCode != null && audioErrorCode!.trim().isEmpty) {
      throw ArgumentError('练习发音错误码不能为空');
    }
    switch (audioPhase) {
      case PracticeAudioPhase.idle:
        if (audioQuestionId != null ||
            audioSource != null ||
            audioErrorCode != null) {
          throw ArgumentError('空闲练习发音状态不能携带播放信息');
        }
      case PracticeAudioPhase.playing:
        if (audioQuestionId == null ||
            audioSource != null ||
            audioErrorCode != null) {
          throw ArgumentError('练习发音播放中必须只包含目标题目');
        }
      case PracticeAudioPhase.completed:
        if (audioQuestionId == null ||
            audioSource == null ||
            audioSource == PronunciationPlaybackSource.unavailable ||
            audioErrorCode != null) {
          throw ArgumentError('练习发音完成状态必须包含可用来源');
        }
      case PracticeAudioPhase.unavailable:
        if (audioQuestionId == null ||
            audioSource != PronunciationPlaybackSource.unavailable ||
            audioErrorCode != PracticeRunErrorCodes.audioUnavailable) {
          throw ArgumentError('练习发音不可用状态必须包含稳定来源和错误码');
        }
      case PracticeAudioPhase.error:
        if (audioQuestionId == null ||
            audioSource != null ||
            audioErrorCode == null) {
          throw ArgumentError('练习发音错误状态必须包含目标和稳定错误码');
        }
    }
  }

  factory PracticeRunState.idle() {
    return PracticeRunState(
      phase: PracticeRunPhase.idle,
      config: null,
      questionSession: null,
      practiceSession: null,
      currentQuestionIndex: 0,
      responses: const [],
      elapsed: Duration.zero,
      currentQuestionElapsed: Duration.zero,
      availability: null,
      candidatePoolTruncated: false,
      favoriteWordIds: const {},
      updatingFavoriteWordIds: const {},
      audioPhase: PracticeAudioPhase.idle,
      audioQuestionId: null,
      audioSource: null,
      audioErrorCode: null,
      favoriteErrorCode: null,
      errorCode: null,
    );
  }

  final PracticeRunPhase phase;
  final QuestionConfig? config;
  final QuestionSession? questionSession;
  final PracticeSessionRecord? practiceSession;
  final int currentQuestionIndex;
  final List<PracticeQuestionResponse> responses;
  final Duration elapsed;
  final Duration currentQuestionElapsed;
  final QuestionAvailability? availability;
  final bool candidatePoolTruncated;
  final Set<int> favoriteWordIds;
  final Set<int> updatingFavoriteWordIds;
  final PracticeAudioPhase audioPhase;
  final String? audioQuestionId;
  final PronunciationPlaybackSource? audioSource;
  final String? audioErrorCode;
  final String? favoriteErrorCode;
  final String? errorCode;

  QuizQuestion? get currentQuestion {
    final session = questionSession;
    return session == null ? null : session.questions[currentQuestionIndex];
  }

  PracticeQuestionResponse? get currentResponse {
    final question = currentQuestion;
    if (question == null) {
      return null;
    }
    for (final response in responses.reversed) {
      if (response.questionId == question.id) {
        return response;
      }
    }
    return null;
  }

  int get answeredQuestionCount => responses.length;
  int get correctCount =>
      responses.where((response) => response.isCorrect).length;

  bool get isLastQuestion {
    final session = questionSession;
    return session != null &&
        currentQuestionIndex == session.questions.length - 1;
  }

  bool get isCurrentWordFavorite {
    final question = currentQuestion;
    return question != null && favoriteWordIds.contains(question.wordId);
  }

  bool get isUpdatingCurrentWordFavorite {
    final question = currentQuestion;
    return question != null &&
        updatingFavoriteWordIds.contains(question.wordId);
  }

  double get progress {
    final session = questionSession;
    if (session == null) {
      return 0;
    }
    if (phase == PracticeRunPhase.completed) {
      return 1;
    }
    return (currentQuestionIndex + 1) / session.questions.length;
  }

  PracticeRunState copyWith({
    PracticeRunPhase? phase,
    Object? config = _unchanged,
    Object? questionSession = _unchanged,
    Object? practiceSession = _unchanged,
    int? currentQuestionIndex,
    List<PracticeQuestionResponse>? responses,
    Duration? elapsed,
    Duration? currentQuestionElapsed,
    Object? availability = _unchanged,
    bool? candidatePoolTruncated,
    Set<int>? favoriteWordIds,
    Set<int>? updatingFavoriteWordIds,
    PracticeAudioPhase? audioPhase,
    Object? audioQuestionId = _unchanged,
    Object? audioSource = _unchanged,
    Object? audioErrorCode = _unchanged,
    Object? favoriteErrorCode = _unchanged,
    Object? errorCode = _unchanged,
  }) {
    return PracticeRunState(
      phase: phase ?? this.phase,
      config: identical(config, _unchanged)
          ? this.config
          : config as QuestionConfig?,
      questionSession: identical(questionSession, _unchanged)
          ? this.questionSession
          : questionSession as QuestionSession?,
      practiceSession: identical(practiceSession, _unchanged)
          ? this.practiceSession
          : practiceSession as PracticeSessionRecord?,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      responses: responses ?? this.responses,
      elapsed: elapsed ?? this.elapsed,
      currentQuestionElapsed:
          currentQuestionElapsed ?? this.currentQuestionElapsed,
      availability: identical(availability, _unchanged)
          ? this.availability
          : availability as QuestionAvailability?,
      candidatePoolTruncated:
          candidatePoolTruncated ?? this.candidatePoolTruncated,
      favoriteWordIds: favoriteWordIds ?? this.favoriteWordIds,
      updatingFavoriteWordIds:
          updatingFavoriteWordIds ?? this.updatingFavoriteWordIds,
      audioPhase: audioPhase ?? this.audioPhase,
      audioQuestionId: identical(audioQuestionId, _unchanged)
          ? this.audioQuestionId
          : audioQuestionId as String?,
      audioSource: identical(audioSource, _unchanged)
          ? this.audioSource
          : audioSource as PronunciationPlaybackSource?,
      audioErrorCode: identical(audioErrorCode, _unchanged)
          ? this.audioErrorCode
          : audioErrorCode as String?,
      favoriteErrorCode: identical(favoriteErrorCode, _unchanged)
          ? this.favoriteErrorCode
          : favoriteErrorCode as String?,
      errorCode: identical(errorCode, _unchanged)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const Object _unchanged = Object();

String _requireId(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 64) {
    throw ArgumentError.value(value, name, 'ID 长度必须在 1-64 之间');
  }
  return normalized;
}
