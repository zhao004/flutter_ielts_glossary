import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/word_details.dart';
import '../../models/domain/word_details_run_state.dart';
import '../../models/domain/word_learning_state.dart';
import '../../repositories/content_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../services/audio/audio_playback_service.dart';

/// 协调单词详情、单词/例句收藏和发音服务，不直接操作 DAO 或平台插件。
final class WordDetailsLogic extends GetxController {
  WordDetailsLogic({
    required this.contentRepository,
    required this.favoriteRepository,
    required this.pronunciationService,
    required this.learningRepository,
    this.defaultAccent = PronunciationAccent.uk,
  });

  static const String contentUpdateId = 'word_details_content';

  final ContentRepository contentRepository;
  final FavoriteRepository favoriteRepository;
  final PronunciationService pronunciationService;
  final LearningRepository learningRepository;
  final PronunciationAccent defaultAccent;

  WordDetailsRunState _state = WordDetailsRunState.idle();
  WordDetailsRunState get state => _state;

  bool _closed = false;
  int _loadToken = 0;
  int _audioToken = 0;

  /// 加载单词、例句和当前收藏状态；不存在的稳定 ID 进入 notFound。
  Future<void> load(int wordId) async {
    _validateWordId(wordId);
    final loadToken = ++_loadToken;
    _audioToken++;
    _replaceState(
      WordDetailsRunState.idle(wordId: wordId).copyWith(
        phase: WordDetailsRunPhase.loading,
        pronunciationAccent: defaultAccent,
      ),
    );
    try {
      final details = await contentRepository.findWordDetails(wordId);
      if (!_isCurrentLoad(loadToken)) {
        return;
      }
      if (details == null) {
        _replaceState(
          _state.copyWith(phase: WordDetailsRunPhase.notFound, errorCode: null),
        );
        return;
      }
      final sentenceIds = details.sentences
          .map((sentence) => sentence.id)
          .toSet();
      final wordFavoriteFuture = favoriteRepository.findFavoriteWordIds({
        wordId,
      });
      final sentenceFavoriteFuture = favoriteRepository.findFavoriteSentenceIds(
        sentenceIds,
      );
      final learningStateFuture = learningRepository.findWordState(wordId);
      final results = await Future.wait<Object?>([
        wordFavoriteFuture,
        sentenceFavoriteFuture,
        learningStateFuture,
      ]);
      if (!_isCurrentLoad(loadToken)) {
        return;
      }
      final favoriteWordIds = results[0] as Set<int>;
      final favoriteSentenceIds = results[1] as Set<int>;
      final learningState = results[2] as WordLearningState?;
      if (!favoriteWordIds.every((id) => id == wordId) ||
          !sentenceIds.containsAll(favoriteSentenceIds)) {
        throw StateError('收藏 Repository 返回了详情之外的 ID');
      }
      _replaceState(
        _state.copyWith(
          phase: WordDetailsRunPhase.loaded,
          details: details,
          learningState: learningState,
          isWordFavorite: favoriteWordIds.contains(wordId),
          favoriteSentenceIds: favoriteSentenceIds,
          updatingSentenceIds: const {},
          updatingWordFavorite: false,
          audioPhase: WordDetailsAudioPhase.idle,
          audioSource: null,
          errorCode: null,
          audioErrorCode: null,
        ),
      );
    } on Object {
      if (_isCurrentLoad(loadToken)) {
        _replaceState(
          _state.copyWith(
            phase: WordDetailsRunPhase.error,
            errorCode: WordDetailsErrorCodes.loadFailed,
          ),
        );
      }
    }
  }

  /// 复用当前单词 ID 重试详情查询。
  Future<void> retry() async {
    final wordId = _state.requestedWordId;
    if (wordId == null || _state.phase != WordDetailsRunPhase.error) {
      return;
    }
    await load(wordId);
  }

  /// 幂等切换单词收藏，快速重复操作只保留一次写入。
  Future<void> toggleWordFavorite() async {
    final details = _requireLoaded();
    if (_state.updatingWordFavorite) {
      return;
    }
    final target = !_state.isWordFavorite;
    final loadToken = _loadToken;
    _replaceState(_state.copyWith(updatingWordFavorite: true, errorCode: null));
    try {
      final record = await favoriteRepository.setWordFavorite(
        wordId: details.id,
        isFavorite: target,
      );
      if (!_isCurrentLoad(loadToken)) {
        return;
      }
      if ((target && (record == null || record.wordId != details.id)) ||
          (!target && record != null)) {
        throw StateError('单词收藏写入结果与目标状态不一致');
      }
      _replaceState(
        _state.copyWith(isWordFavorite: target, updatingWordFavorite: false),
      );
    } on Object {
      if (_isCurrentLoad(loadToken)) {
        _replaceState(
          _state.copyWith(
            updatingWordFavorite: false,
            errorCode: WordDetailsErrorCodes.wordFavoriteFailed,
          ),
        );
      }
    }
  }

  /// 幂等切换详情中某条例句的收藏。
  Future<void> toggleSentenceFavorite(int sentenceId) async {
    final details = _requireLoaded();
    if (!details.sentences.any((sentence) => sentence.id == sentenceId)) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '当前详情不存在该例句');
    }
    if (_state.updatingSentenceIds.contains(sentenceId)) {
      return;
    }
    final target = !_state.favoriteSentenceIds.contains(sentenceId);
    final loadToken = _loadToken;
    _replaceState(
      _state.copyWith(
        updatingSentenceIds: {..._state.updatingSentenceIds, sentenceId},
        errorCode: null,
      ),
    );
    try {
      final record = await favoriteRepository.setSentenceFavorite(
        sentenceId: sentenceId,
        isFavorite: target,
      );
      if (!_isCurrentLoad(loadToken)) {
        return;
      }
      if ((target && (record == null || record.sentenceId != sentenceId)) ||
          (!target && record != null)) {
        throw StateError('例句收藏写入结果与目标状态不一致');
      }
      final favoriteSentenceIds = {..._state.favoriteSentenceIds};
      if (target) {
        favoriteSentenceIds.add(sentenceId);
      } else {
        favoriteSentenceIds.remove(sentenceId);
      }
      final updatingIds = {..._state.updatingSentenceIds}..remove(sentenceId);
      _replaceState(
        _state.copyWith(
          favoriteSentenceIds: favoriteSentenceIds,
          updatingSentenceIds: updatingIds,
        ),
      );
    } on Object {
      if (_isCurrentLoad(loadToken)) {
        final updatingIds = {..._state.updatingSentenceIds}..remove(sentenceId);
        _replaceState(
          _state.copyWith(
            updatingSentenceIds: updatingIds,
            errorCode: WordDetailsErrorCodes.sentenceFavoriteFailed,
          ),
        );
      }
    }
  }

  /// 播放指定口音；词库音频、第三方 TTS 和不可用状态由服务决定。
  Future<void> playPronunciation({PronunciationAccent? accent}) async {
    final details = _requireLoaded();
    final audioToken = ++_audioToken;
    final selectedAccent = accent ?? _state.pronunciationAccent;
    _replaceState(
      _state.copyWith(
        pronunciationAccent: selectedAccent,
        audioPhase: WordDetailsAudioPhase.playing,
        audioSource: null,
        audioErrorCode: null,
      ),
    );
    try {
      final result = await pronunciationService.play(
        word: details.word,
        accent: selectedAccent,
        audioUkAsset: details.audioUkAsset,
        audioUsAsset: details.audioUsAsset,
      );
      if (!_isCurrentAudio(audioToken)) {
        return;
      }
      final unavailable =
          result.source == PronunciationPlaybackSource.unavailable;
      _replaceState(
        _state.copyWith(
          audioPhase: unavailable
              ? WordDetailsAudioPhase.unavailable
              : WordDetailsAudioPhase.completed,
          audioSource: result.source,
          audioErrorCode: unavailable
              ? WordDetailsErrorCodes.audioUnavailable
              : null,
        ),
      );
    } on Object {
      if (_isCurrentAudio(audioToken)) {
        _replaceState(
          _state.copyWith(
            audioPhase: WordDetailsAudioPhase.error,
            audioSource: null,
            audioErrorCode: WordDetailsErrorCodes.audioFailed,
          ),
        );
      }
    }
  }

  /// 停止当前音频并清除播放子状态。
  Future<void> stopPronunciation() async {
    _audioToken++;
    try {
      await pronunciationService.stop();
    } on Object {
      // 停止失败不覆盖已经加载的详情状态。
    }
    if (!_closed && _state.details != null) {
      _replaceState(
        _state.copyWith(
          audioPhase: WordDetailsAudioPhase.idle,
          audioSource: null,
          audioErrorCode: null,
        ),
      );
    }
  }

  WordDetails _requireLoaded() {
    if (_closed || _state.phase != WordDetailsRunPhase.loaded) {
      throw StateError('当前单词详情尚未加载');
    }
    final details = _state.details;
    if (details == null) {
      throw StateError('当前单词详情为空');
    }
    return details;
  }

  void _validateWordId(int wordId) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
  }

  bool _isCurrentLoad(int token) => !_closed && token == _loadToken;

  bool _isCurrentAudio(int token) =>
      !_closed && token == _audioToken && _state.details != null;

  void _replaceState(WordDetailsRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([contentUpdateId]);
  }

  @override
  void onClose() {
    _closed = true;
    _loadToken++;
    _audioToken++;
    unawaited(pronunciationService.stop().catchError((Object _) {}));
    super.onClose();
  }
}
