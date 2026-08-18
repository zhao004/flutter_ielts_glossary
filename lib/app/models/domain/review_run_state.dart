import '../../services/audio/audio_playback_service.dart';
import 'app_settings_state.dart';
import 'review_memory_rate.dart';
import 'review_queue.dart';
import 'review_rating.dart';
import 'word_learning_state.dart';

/// 到期复习会话的稳定阶段。
enum ReviewRunPhase {
  idle,
  preparing,
  empty,
  reviewing,
  submitting,
  completing,
  completed,
  error,
}

/// 复习卡片发音子流程，不影响复习结果提交。
enum ReviewAudioPhase { idle, playing, completed, unavailable, error }

/// 页面只消费稳定错误码，不展示数据库异常正文或用户学习记录。
abstract final class ReviewRunErrorCodes {
  static const String preparationFailed = 'review_preparation_failed';
  static const String persistenceFailed = 'review_persistence_failed';
  static const String memoryRateFailed = 'review_memory_rate_failed';
  static const String wordFavoriteFailed = 'review_word_favorite_failed';
  static const String audioFailed = 'review_audio_failed';
  static const String audioUnavailable = 'review_audio_unavailable';
}

/// 非法复习会话调用顺序属于页面集成错误。
final class ReviewSessionTransitionException implements Exception {
  const ReviewSessionTransitionException({
    required this.phase,
    required this.action,
  });

  final ReviewRunPhase phase;
  final String action;

  @override
  String toString() => 'invalid_review_transition: ${phase.name}/$action';
}

/// 一张复习卡已经事务化写入的结果。
final class ReviewCardResponse {
  ReviewCardResponse({
    required this.wordId,
    required this.rating,
    required this.previousMasteryLevel,
    required this.learningState,
  }) {
    if (wordId <= 0 || learningState.wordId != wordId) {
      throw ArgumentError('复习结果与单词学习状态 ID 必须一致');
    }
    if (previousMasteryLevel < 0 || previousMasteryLevel > 5) {
      throw ArgumentError.value(
        previousMasteryLevel,
        'previousMasteryLevel',
        '原掌握等级必须在 0-5 之间',
      );
    }
    if (learningState.masteryLevel < 0 ||
        learningState.masteryLevel > 5 ||
        learningState.studiedCount <= 0 ||
        learningState.correctCount < 0 ||
        learningState.wrongCount < 0 ||
        learningState.correctStreak < 0 ||
        learningState.consecutiveForgottenCount < 0) {
      throw ArgumentError.value(learningState, 'learningState', '复习后的学习状态无效');
    }
  }

  final int wordId;
  final ReviewRating rating;
  final int previousMasteryLevel;
  final WordLearningState learningState;

  bool get remembered => rating.recalled;
  bool get forgotten => rating == ReviewRating.again;
  int get masteryLevelChange =>
      learningState.masteryLevel - previousMasteryLevel;
}

/// 连续遗忘后向页面提供的非强制拼写巩固请求。
final class ReviewReinforcementPrompt {
  ReviewReinforcementPrompt({required this.wordId, required this.word}) {
    if (wordId <= 0 || word.trim().isEmpty) {
      throw ArgumentError('专项巩固单词信息无效');
    }
  }

  final int wordId;
  final String word;
}

/// 复习页面的不可变状态快照。
final class ReviewRunState {
  ReviewRunState({
    required this.phase,
    required this.queue,
    required this.currentIndex,
    required this.isFlipped,
    required List<ReviewCardResponse> responses,
    required this.reinforcementPrompt,
    required this.memoryRate,
    required Set<int> favoriteWordIds,
    required Set<int> updatingFavoriteWordIds,
    required this.pronunciationAccent,
    required this.audioPhase,
    required this.audioWordId,
    required this.audioSource,
    required this.favoriteErrorCode,
    required this.audioErrorCode,
    required this.errorCode,
  }) : responses = List<ReviewCardResponse>.unmodifiable(responses),
       favoriteWordIds = Set<int>.unmodifiable(favoriteWordIds),
       updatingFavoriteWordIds = Set<int>.unmodifiable(
         updatingFavoriteWordIds,
       ) {
    if (currentIndex < 0) {
      throw ArgumentError.value(currentIndex, 'currentIndex', '当前索引不能为负数');
    }
    final snapshot = queue;
    if (snapshot == null) {
      if (currentIndex != 0 || this.responses.isNotEmpty) {
        throw ArgumentError('队列未加载时不能存在当前卡片或复习结果');
      }
    } else if (snapshot.items.isEmpty) {
      if (currentIndex != 0 || this.responses.isNotEmpty) {
        throw ArgumentError('空队列不能存在当前卡片或复习结果');
      }
    } else {
      if (currentIndex >= snapshot.items.length ||
          this.responses.length > snapshot.items.length) {
        throw ArgumentError('复习索引或结果数量超出队列范围');
      }
      for (var index = 0; index < this.responses.length; index++) {
        if (this.responses[index].wordId != snapshot.items[index].word.id) {
          throw ArgumentError('复习结果顺序必须与队列一致');
        }
      }
    }
    final wordIds = snapshot?.items.map((item) => item.word.id).toSet() ?? {};
    if (!this.favoriteWordIds.every(wordIds.contains) ||
        !this.updatingFavoriteWordIds.every(wordIds.contains)) {
      throw ArgumentError('复习收藏状态包含队列外单词');
    }
    final prompt = reinforcementPrompt;
    if (prompt != null && !wordIds.contains(prompt.wordId)) {
      throw ArgumentError('专项巩固提示包含队列外单词');
    }
    if (audioWordId != null && !wordIds.contains(audioWordId)) {
      throw ArgumentError('复习发音状态包含队列外单词');
    }
    if (favoriteErrorCode != null && favoriteErrorCode!.trim().isEmpty) {
      throw ArgumentError('复习收藏错误码不能为空');
    }
    _validateAudioState();
  }

  factory ReviewRunState.idle() {
    return ReviewRunState(
      phase: ReviewRunPhase.idle,
      queue: null,
      currentIndex: 0,
      isFlipped: false,
      responses: const [],
      reinforcementPrompt: null,
      memoryRate: null,
      favoriteWordIds: const {},
      updatingFavoriteWordIds: const {},
      pronunciationAccent: PronunciationAccent.uk,
      audioPhase: ReviewAudioPhase.idle,
      audioWordId: null,
      audioSource: null,
      favoriteErrorCode: null,
      audioErrorCode: null,
      errorCode: null,
    );
  }

  final ReviewRunPhase phase;
  final ReviewQueueSnapshot? queue;
  final int currentIndex;
  final bool isFlipped;
  final List<ReviewCardResponse> responses;
  final ReviewReinforcementPrompt? reinforcementPrompt;
  final ReviewMemoryRate? memoryRate;
  final Set<int> favoriteWordIds;
  final Set<int> updatingFavoriteWordIds;
  final PronunciationAccent pronunciationAccent;
  final ReviewAudioPhase audioPhase;
  final int? audioWordId;
  final PronunciationPlaybackSource? audioSource;
  final String? favoriteErrorCode;
  final String? audioErrorCode;
  final String? errorCode;

  ReviewQueueItem? get currentItem {
    final snapshot = queue;
    return snapshot == null || snapshot.items.isEmpty
        ? null
        : snapshot.items[currentIndex];
  }

  List<int> get missingWordIds => queue?.missingWordIds ?? const [];
  int get totalCount => queue?.items.length ?? 0;
  int get completedCount => responses.length;
  int get rememberedCount =>
      responses.where((response) => response.remembered).length;
  int get againCount => responses
      .where((response) => response.rating == ReviewRating.again)
      .length;
  int get hardCount => responses
      .where((response) => response.rating == ReviewRating.hard)
      .length;
  int get goodCount => responses
      .where((response) => response.rating == ReviewRating.good)
      .length;
  int get easyCount => responses
      .where((response) => response.rating == ReviewRating.easy)
      .length;
  int get forgottenCount => againCount;
  double get sessionAccuracy =>
      completedCount == 0 ? 0 : rememberedCount / completedCount;
  bool get isLastItem => totalCount > 0 && currentIndex == totalCount - 1;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
  bool get isCurrentWordFavorite {
    final item = currentItem;
    return item != null && favoriteWordIds.contains(item.word.id);
  }

  bool get isUpdatingCurrentWordFavorite {
    final item = currentItem;
    return item != null && updatingFavoriteWordIds.contains(item.word.id);
  }

  ReviewRunState copyWith({
    ReviewRunPhase? phase,
    Object? queue = _unset,
    int? currentIndex,
    bool? isFlipped,
    List<ReviewCardResponse>? responses,
    Object? reinforcementPrompt = _unset,
    Object? memoryRate = _unset,
    Set<int>? favoriteWordIds,
    Set<int>? updatingFavoriteWordIds,
    PronunciationAccent? pronunciationAccent,
    ReviewAudioPhase? audioPhase,
    Object? audioWordId = _unset,
    Object? audioSource = _unset,
    Object? favoriteErrorCode = _unset,
    Object? audioErrorCode = _unset,
    Object? errorCode = _unset,
  }) {
    return ReviewRunState(
      phase: phase ?? this.phase,
      queue: identical(queue, _unset)
          ? this.queue
          : queue as ReviewQueueSnapshot?,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      responses: responses ?? this.responses,
      reinforcementPrompt: identical(reinforcementPrompt, _unset)
          ? this.reinforcementPrompt
          : reinforcementPrompt as ReviewReinforcementPrompt?,
      memoryRate: identical(memoryRate, _unset)
          ? this.memoryRate
          : memoryRate as ReviewMemoryRate?,
      favoriteWordIds: favoriteWordIds ?? this.favoriteWordIds,
      updatingFavoriteWordIds:
          updatingFavoriteWordIds ?? this.updatingFavoriteWordIds,
      pronunciationAccent: pronunciationAccent ?? this.pronunciationAccent,
      audioPhase: audioPhase ?? this.audioPhase,
      audioWordId: identical(audioWordId, _unset)
          ? this.audioWordId
          : audioWordId as int?,
      audioSource: identical(audioSource, _unset)
          ? this.audioSource
          : audioSource as PronunciationPlaybackSource?,
      favoriteErrorCode: identical(favoriteErrorCode, _unset)
          ? this.favoriteErrorCode
          : favoriteErrorCode as String?,
      audioErrorCode: identical(audioErrorCode, _unset)
          ? this.audioErrorCode
          : audioErrorCode as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }

  void _validateAudioState() {
    switch (audioPhase) {
      case ReviewAudioPhase.idle:
        if (audioWordId != null ||
            audioSource != null ||
            audioErrorCode != null) {
          throw ArgumentError('空闲复习发音状态不能携带播放信息');
        }
      case ReviewAudioPhase.playing:
        if (audioWordId == null ||
            audioSource != null ||
            audioErrorCode != null) {
          throw ArgumentError('复习发音播放中必须只包含目标单词');
        }
      case ReviewAudioPhase.completed:
        if (audioWordId == null ||
            audioSource == null ||
            audioSource == PronunciationPlaybackSource.unavailable ||
            audioErrorCode != null) {
          throw ArgumentError('复习发音完成状态必须包含可用来源');
        }
      case ReviewAudioPhase.unavailable:
        if (audioWordId == null ||
            audioSource != PronunciationPlaybackSource.unavailable ||
            audioErrorCode != ReviewRunErrorCodes.audioUnavailable) {
          throw ArgumentError('复习发音不可用状态必须包含稳定来源和错误码');
        }
      case ReviewAudioPhase.error:
        if (audioWordId == null ||
            audioSource != null ||
            audioErrorCode == null ||
            audioErrorCode!.trim().isEmpty) {
          throw ArgumentError('复习发音错误状态必须包含目标和稳定错误码');
        }
    }
  }
}

const _unset = Object();
