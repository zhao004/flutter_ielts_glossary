import '../../services/audio/audio_playback_service.dart';
import 'app_settings_state.dart';
import 'word_details.dart';
import 'word_learning_state.dart';

/// 单词详情查询的稳定阶段。
enum WordDetailsRunPhase { idle, loading, loaded, notFound, error }

/// 详情页发音子流程阶段，不影响已经加载的词条内容。
enum WordDetailsAudioPhase { idle, playing, completed, unavailable, error }

/// 详情页稳定错误码；页面不展示底层异常正文。
abstract final class WordDetailsErrorCodes {
  static const String loadFailed = 'word_details_load_failed';
  static const String wordFavoriteFailed = 'word_details_word_favorite_failed';
  static const String sentenceFavoriteFailed =
      'word_details_sentence_favorite_failed';
  static const String audioFailed = 'word_details_audio_failed';
  static const String audioUnavailable = 'word_details_audio_unavailable';
}

/// 单词详情页面的不可变状态快照。
final class WordDetailsRunState {
  WordDetailsRunState({
    required this.phase,
    required this.requestedWordId,
    required this.details,
    required this.learningState,
    required this.isWordFavorite,
    required Set<int> favoriteSentenceIds,
    required Set<int> updatingSentenceIds,
    required this.updatingWordFavorite,
    required this.pronunciationAccent,
    required this.audioPhase,
    required this.audioSource,
    required this.errorCode,
    required this.audioErrorCode,
  }) : favoriteSentenceIds = Set<int>.unmodifiable(favoriteSentenceIds),
       updatingSentenceIds = Set<int>.unmodifiable(updatingSentenceIds) {
    if (requestedWordId != null && requestedWordId! <= 0) {
      throw ArgumentError.value(
        requestedWordId,
        'requestedWordId',
        '单词 ID 必须为正整数',
      );
    }
    final wordDetails = details;
    if (wordDetails != null && wordDetails.id != requestedWordId) {
      throw ArgumentError('详情单词与请求 ID 不一致');
    }
    if (learningState != null && learningState!.wordId != requestedWordId) {
      throw ArgumentError('学习状态与请求 ID 不一致');
    }
    final sentenceIds = wordDetails?.sentences
        .map((sentence) => sentence.id)
        .toSet();
    if (sentenceIds != null &&
        (!sentenceIds.containsAll(this.favoriteSentenceIds) ||
            !sentenceIds.containsAll(this.updatingSentenceIds))) {
      throw ArgumentError('例句收藏状态包含详情之外的 ID');
    }
    if (wordDetails == null &&
        (this.favoriteSentenceIds.isNotEmpty ||
            this.updatingSentenceIds.isNotEmpty ||
            updatingWordFavorite)) {
      throw ArgumentError('没有详情时不能存在收藏操作状态');
    }
  }

  factory WordDetailsRunState.idle({int? wordId}) {
    return WordDetailsRunState(
      phase: WordDetailsRunPhase.idle,
      requestedWordId: wordId,
      details: null,
      learningState: null,
      isWordFavorite: false,
      favoriteSentenceIds: const {},
      updatingSentenceIds: const {},
      updatingWordFavorite: false,
      pronunciationAccent: PronunciationAccent.uk,
      audioPhase: WordDetailsAudioPhase.idle,
      audioSource: null,
      errorCode: null,
      audioErrorCode: null,
    );
  }

  final WordDetailsRunPhase phase;
  final int? requestedWordId;
  final WordDetails? details;
  final WordLearningState? learningState;
  final bool isWordFavorite;
  final Set<int> favoriteSentenceIds;
  final Set<int> updatingSentenceIds;
  final bool updatingWordFavorite;
  final PronunciationAccent pronunciationAccent;
  final WordDetailsAudioPhase audioPhase;
  final PronunciationPlaybackSource? audioSource;
  final String? errorCode;
  final String? audioErrorCode;

  bool isSentenceFavorite(int sentenceId) =>
      favoriteSentenceIds.contains(sentenceId);

  WordDetailsRunState copyWith({
    WordDetailsRunPhase? phase,
    int? requestedWordId,
    Object? details = _unset,
    Object? learningState = _unset,
    bool? isWordFavorite,
    Set<int>? favoriteSentenceIds,
    Set<int>? updatingSentenceIds,
    bool? updatingWordFavorite,
    PronunciationAccent? pronunciationAccent,
    WordDetailsAudioPhase? audioPhase,
    Object? audioSource = _unset,
    Object? errorCode = _unset,
    Object? audioErrorCode = _unset,
  }) {
    return WordDetailsRunState(
      phase: phase ?? this.phase,
      requestedWordId: requestedWordId ?? this.requestedWordId,
      details: identical(details, _unset)
          ? this.details
          : details as WordDetails?,
      learningState: identical(learningState, _unset)
          ? this.learningState
          : learningState as WordLearningState?,
      isWordFavorite: isWordFavorite ?? this.isWordFavorite,
      favoriteSentenceIds: favoriteSentenceIds ?? this.favoriteSentenceIds,
      updatingSentenceIds: updatingSentenceIds ?? this.updatingSentenceIds,
      updatingWordFavorite: updatingWordFavorite ?? this.updatingWordFavorite,
      pronunciationAccent: pronunciationAccent ?? this.pronunciationAccent,
      audioPhase: audioPhase ?? this.audioPhase,
      audioSource: identical(audioSource, _unset)
          ? this.audioSource
          : audioSource as PronunciationPlaybackSource?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      audioErrorCode: identical(audioErrorCode, _unset)
          ? this.audioErrorCode
          : audioErrorCode as String?,
    );
  }
}

const _unset = Object();
