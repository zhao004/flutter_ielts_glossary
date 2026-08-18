import '../../services/audio/audio_playback_service.dart';
import 'app_settings_state.dart';
import 'study_candidate.dart';
import 'study_config.dart';
import 'study_rating.dart';

/// 随机学习会话的稳定状态阶段。
enum StudyRunPhase {
  idle,
  preparing,
  insufficientCandidates,
  answering,
  persisting,
  rating,
  completed,
  error,
}

/// 学习卡片发音子流程，不影响翻卡、评级和导航状态。
enum StudyAudioPhase { idle, playing, completed, unavailable, error }

/// 页面只消费稳定错误码，不展示底层数据库异常正文。
abstract final class StudyRunErrorCodes {
  static const String preparationFailed = 'study_preparation_failed';
  static const String completionPersistenceFailed =
      'study_completion_persistence_failed';
  static const String ratingPersistenceFailed =
      'study_rating_persistence_failed';
  static const String wordFavoriteFailed = 'study_word_favorite_failed';
  static const String audioFailed = 'study_audio_failed';
  static const String audioUnavailable = 'study_audio_unavailable';
}

/// 非法学习会话调用顺序。
final class StudySessionTransitionException implements Exception {
  const StudySessionTransitionException({
    required this.phase,
    required this.action,
  });

  final StudyRunPhase phase;
  final String action;

  @override
  String toString() => 'invalid_study_transition: ${phase.name}/$action';
}

/// 随机学习页面的不可变状态快照。
final class StudyRunState {
  StudyRunState({
    required this.phase,
    required this.config,
    required List<StudyCandidate> candidates,
    required this.currentIndex,
    required this.isFlipped,
    required Set<int> recordedWordIds,
    required Map<int, StudyRating> ratings,
    required this.availableCount,
    required Set<int> favoriteWordIds,
    required Set<int> updatingFavoriteWordIds,
    required this.audioPhase,
    required this.audioWordId,
    required this.audioAccent,
    required this.audioSource,
    required this.favoriteErrorCode,
    required this.audioErrorCode,
    required this.errorCode,
  }) : candidates = List<StudyCandidate>.unmodifiable(candidates),
       recordedWordIds = Set<int>.unmodifiable(recordedWordIds),
       ratings = Map<int, StudyRating>.unmodifiable(ratings),
       favoriteWordIds = Set<int>.unmodifiable(favoriteWordIds),
       updatingFavoriteWordIds = Set<int>.unmodifiable(
         updatingFavoriteWordIds,
       ) {
    if (currentIndex < 0 || availableCount < 0) {
      throw ArgumentError('学习状态索引或候选数量无效');
    }
    if (this.candidates.isEmpty && currentIndex != 0) {
      throw ArgumentError('没有候选时当前索引必须为 0');
    }
    if (this.candidates.isNotEmpty && currentIndex >= this.candidates.length) {
      throw ArgumentError('当前索引超出学习候选范围');
    }
    final wordIds = this.candidates
        .map((candidate) => candidate.word.id)
        .toSet();
    if (wordIds.length != this.candidates.length ||
        !this.recordedWordIds.every(wordIds.contains) ||
        !this.ratings.keys.every(wordIds.contains) ||
        !this.favoriteWordIds.every(wordIds.contains) ||
        !this.updatingFavoriteWordIds.every(wordIds.contains)) {
      throw ArgumentError('学习状态包含会话外或重复单词');
    }
    if (this.ratings.keys.any(
      (wordId) => !this.recordedWordIds.contains(wordId),
    )) {
      throw ArgumentError('未记录学习事件的单词不能有评级');
    }
    if (audioWordId != null && !wordIds.contains(audioWordId)) {
      throw ArgumentError('发音状态包含会话外单词');
    }
    _validateAudioState();
    if (favoriteErrorCode != null && favoriteErrorCode!.trim().isEmpty) {
      throw ArgumentError('收藏错误码不能为空');
    }
  }

  factory StudyRunState.idle() {
    return StudyRunState(
      phase: StudyRunPhase.idle,
      config: null,
      candidates: const [],
      currentIndex: 0,
      isFlipped: false,
      recordedWordIds: const {},
      ratings: const {},
      availableCount: 0,
      favoriteWordIds: const {},
      updatingFavoriteWordIds: const {},
      audioPhase: StudyAudioPhase.idle,
      audioWordId: null,
      audioAccent: null,
      audioSource: null,
      favoriteErrorCode: null,
      audioErrorCode: null,
      errorCode: null,
    );
  }

  final StudyRunPhase phase;
  final StudyConfig? config;
  final List<StudyCandidate> candidates;
  final int currentIndex;
  final bool isFlipped;
  final Set<int> recordedWordIds;
  final Map<int, StudyRating> ratings;
  final int availableCount;
  final Set<int> favoriteWordIds;
  final Set<int> updatingFavoriteWordIds;
  final StudyAudioPhase audioPhase;
  final int? audioWordId;
  final PronunciationAccent? audioAccent;
  final PronunciationPlaybackSource? audioSource;
  final String? favoriteErrorCode;
  final String? audioErrorCode;
  final String? errorCode;

  StudyCandidate? get currentCandidate =>
      candidates.isEmpty ? null : candidates[currentIndex];

  bool get isLastCandidate =>
      candidates.isNotEmpty && currentIndex == candidates.length - 1;

  bool get isCurrentWordFavorite {
    final candidate = currentCandidate;
    return candidate != null && favoriteWordIds.contains(candidate.word.id);
  }

  bool get isUpdatingCurrentWordFavorite {
    final candidate = currentCandidate;
    return candidate != null &&
        updatingFavoriteWordIds.contains(candidate.word.id);
  }

  double get progress => candidates.isEmpty
      ? 0
      : phase == StudyRunPhase.completed
      ? 1
      : (currentIndex + 1) / candidates.length;

  StudyRunState copyWith({
    StudyRunPhase? phase,
    Object? config = _unchanged,
    List<StudyCandidate>? candidates,
    int? currentIndex,
    bool? isFlipped,
    Set<int>? recordedWordIds,
    Map<int, StudyRating>? ratings,
    int? availableCount,
    Set<int>? favoriteWordIds,
    Set<int>? updatingFavoriteWordIds,
    StudyAudioPhase? audioPhase,
    Object? audioWordId = _unchanged,
    Object? audioAccent = _unchanged,
    Object? audioSource = _unchanged,
    Object? favoriteErrorCode = _unchanged,
    Object? audioErrorCode = _unchanged,
    Object? errorCode = _unchanged,
  }) {
    return StudyRunState(
      phase: phase ?? this.phase,
      config: identical(config, _unchanged)
          ? this.config
          : config as StudyConfig?,
      candidates: candidates ?? this.candidates,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      recordedWordIds: recordedWordIds ?? this.recordedWordIds,
      ratings: ratings ?? this.ratings,
      availableCount: availableCount ?? this.availableCount,
      favoriteWordIds: favoriteWordIds ?? this.favoriteWordIds,
      updatingFavoriteWordIds:
          updatingFavoriteWordIds ?? this.updatingFavoriteWordIds,
      audioPhase: audioPhase ?? this.audioPhase,
      audioWordId: identical(audioWordId, _unchanged)
          ? this.audioWordId
          : audioWordId as int?,
      audioAccent: identical(audioAccent, _unchanged)
          ? this.audioAccent
          : audioAccent as PronunciationAccent?,
      audioSource: identical(audioSource, _unchanged)
          ? this.audioSource
          : audioSource as PronunciationPlaybackSource?,
      favoriteErrorCode: identical(favoriteErrorCode, _unchanged)
          ? this.favoriteErrorCode
          : favoriteErrorCode as String?,
      audioErrorCode: identical(audioErrorCode, _unchanged)
          ? this.audioErrorCode
          : audioErrorCode as String?,
      errorCode: identical(errorCode, _unchanged)
          ? this.errorCode
          : errorCode as String?,
    );
  }

  void _validateAudioState() {
    final hasTarget = audioWordId != null && audioAccent != null;
    switch (audioPhase) {
      case StudyAudioPhase.idle:
        if (audioWordId != null ||
            audioAccent != null ||
            audioSource != null ||
            audioErrorCode != null) {
          throw ArgumentError('空闲发音状态不能携带播放信息');
        }
      case StudyAudioPhase.playing:
        if (!hasTarget || audioSource != null || audioErrorCode != null) {
          throw ArgumentError('播放中状态必须只包含目标单词和口音');
        }
      case StudyAudioPhase.completed:
        if (!hasTarget ||
            audioSource == null ||
            audioSource == PronunciationPlaybackSource.unavailable ||
            audioErrorCode != null) {
          throw ArgumentError('完成发音状态必须包含可用播放来源');
        }
      case StudyAudioPhase.unavailable:
        if (!hasTarget ||
            audioSource != PronunciationPlaybackSource.unavailable ||
            audioErrorCode != StudyRunErrorCodes.audioUnavailable) {
          throw ArgumentError('不可用发音状态必须包含稳定来源和错误码');
        }
      case StudyAudioPhase.error:
        if (!hasTarget ||
            audioSource != null ||
            audioErrorCode == null ||
            audioErrorCode!.trim().isEmpty) {
          throw ArgumentError('发音错误状态必须包含目标和稳定错误码');
        }
    }
  }
}

const Object _unchanged = Object();
