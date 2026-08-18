import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/study_candidate.dart';
import '../../models/domain/study_config.dart';
import '../../models/domain/study_rating.dart';
import '../../models/domain/study_run_state.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../repositories/study_candidate_repository.dart';
import '../../services/audio/audio_playback_service.dart';
import 'study_session_starter.dart';

/// 协调随机学习候选、翻卡学习事件、评级和前后导航。
class StudySessionLogic extends GetxController implements StudySessionStarter {
  StudySessionLogic({
    required this.studyCandidateRepository,
    required this.learningRepository,
    required this.favoriteRepository,
    required this.pronunciationService,
  });

  static const String contentUpdateId = 'study_content';

  final StudyCandidateRepository studyCandidateRepository;
  final LearningRepository learningRepository;
  final FavoriteRepository favoriteRepository;
  final PronunciationService pronunciationService;

  StudyRunState _state = StudyRunState.idle();
  @override
  StudyRunState get state => _state;

  bool _closed = false;
  int _sessionToken = 0;
  int _audioToken = 0;

  /// 只允许从空闲、候选不足、错误或完成状态开始新的学习批次。
  @override
  Future<void> start(StudyConfig config) async {
    _requirePhase(const {
      StudyRunPhase.idle,
      StudyRunPhase.insufficientCandidates,
      StudyRunPhase.completed,
      StudyRunPhase.error,
    }, 'start');
    final sessionToken = ++_sessionToken;
    _invalidateAudio();
    _replaceState(
      StudyRunState.idle().copyWith(
        phase: StudyRunPhase.preparing,
        config: config,
      ),
    );
    try {
      final batch = await studyCandidateRepository.loadCandidates(config);
      if (_closed) {
        return;
      }
      if (!batch.hasEnoughCandidates) {
        _replaceState(
          _state.copyWith(
            phase: StudyRunPhase.insufficientCandidates,
            availableCount: batch.availableCount,
            errorCode: null,
          ),
        );
        return;
      }
      final candidateWordIds = batch.candidates
          .map((candidate) => candidate.word.id)
          .toSet();
      final favoriteWordIds = await favoriteRepository.findFavoriteWordIds(
        candidateWordIds,
      );
      if (!_isCurrentSession(sessionToken)) {
        return;
      }
      if (!candidateWordIds.containsAll(favoriteWordIds)) {
        throw StateError('收藏 Repository 返回了会话外单词');
      }
      _replaceState(
        _state.copyWith(
          phase: StudyRunPhase.answering,
          candidates: batch.candidates,
          currentIndex: 0,
          isFlipped: false,
          recordedWordIds: const {},
          ratings: const {},
          availableCount: batch.availableCount,
          favoriteWordIds: favoriteWordIds,
          updatingFavoriteWordIds: const {},
          audioPhase: StudyAudioPhase.idle,
          audioWordId: null,
          audioAccent: null,
          audioSource: null,
          favoriteErrorCode: null,
          audioErrorCode: null,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_closed) {
        return;
      }
      _replaceState(
        _state.copyWith(
          phase: StudyRunPhase.error,
          errorCode: StudyRunErrorCodes.preparationFailed,
        ),
      );
    }
  }

  /// 翻开当前卡片；同一会话内同一单词只记录一次学习事件。
  Future<void> flip() async {
    _requirePhase(const {StudyRunPhase.answering}, 'flip');
    final candidate = _requireCurrentCandidate();
    if (_state.isFlipped) {
      _replaceState(_state.copyWith(isFlipped: false, errorCode: null));
      return;
    }
    if (_state.recordedWordIds.contains(candidate.word.id)) {
      _replaceState(_state.copyWith(isFlipped: true, errorCode: null));
      return;
    }
    _replaceState(
      _state.copyWith(phase: StudyRunPhase.persisting, errorCode: null),
    );
    try {
      await learningRepository.recordStudyCompletion(wordId: candidate.word.id);
      if (_closed) {
        return;
      }
      final recorded = {..._state.recordedWordIds, candidate.word.id};
      _replaceState(
        _state.copyWith(
          phase: StudyRunPhase.answering,
          isFlipped: true,
          recordedWordIds: recorded,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_closed) {
        return;
      }
      _replaceState(
        _state.copyWith(
          phase: StudyRunPhase.answering,
          isFlipped: false,
          errorCode: StudyRunErrorCodes.completionPersistenceFailed,
        ),
      );
    }
  }

  /// 将当前卡片评级为不熟、熟悉或掌握，并自动进入下一张。
  Future<void> rate(StudyRating rating) async {
    _requirePhase(const {StudyRunPhase.answering}, 'rate');
    final candidate = _requireCurrentCandidate();
    if (!_state.isFlipped ||
        !_state.recordedWordIds.contains(candidate.word.id)) {
      throw StateError('评级前必须先翻开当前学习卡片');
    }
    _replaceState(
      _state.copyWith(phase: StudyRunPhase.rating, errorCode: null),
    );
    try {
      await learningRepository.applyStudyRating(
        wordId: candidate.word.id,
        rating: rating,
      );
      if (_closed) {
        return;
      }
      final ratings = {..._state.ratings, candidate.word.id: rating};
      if (_state.isLastCandidate) {
        _replaceState(
          _state.copyWith(
            phase: StudyRunPhase.completed,
            ratings: ratings,
            isFlipped: true,
            errorCode: null,
          ),
        );
      } else {
        _invalidateAudio();
        _replaceState(
          _state.copyWith(
            phase: StudyRunPhase.answering,
            ratings: ratings,
            currentIndex: _state.currentIndex + 1,
            isFlipped: false,
            audioPhase: StudyAudioPhase.idle,
            audioWordId: null,
            audioAccent: null,
            audioSource: null,
            audioErrorCode: null,
            errorCode: null,
          ),
        );
      }
    } on Exception {
      if (_closed) {
        return;
      }
      _replaceState(
        _state.copyWith(
          phase: StudyRunPhase.answering,
          isFlipped: true,
          errorCode: StudyRunErrorCodes.ratingPersistenceFailed,
        ),
      );
    }
  }

  /// 翻开后跳过评级进入下一张；学习事件已经在首次翻开时记录。
  void next() {
    _requirePhase(const {StudyRunPhase.answering}, 'next');
    if (!_state.isFlipped) {
      throw StateError('未翻开的学习卡片不能跳过');
    }
    if (_state.isLastCandidate) {
      _replaceState(_state.copyWith(phase: StudyRunPhase.completed));
      return;
    }
    _invalidateAudio();
    _replaceState(
      _state.copyWith(
        currentIndex: _state.currentIndex + 1,
        isFlipped: false,
        audioPhase: StudyAudioPhase.idle,
        audioWordId: null,
        audioAccent: null,
        audioSource: null,
        audioErrorCode: null,
        errorCode: null,
      ),
    );
  }

  /// 返回上一张；返回后再次翻开不会重复累计学习次数。
  void previous() {
    _requirePhase(const {StudyRunPhase.answering}, 'previous');
    if (_state.currentIndex == 0) {
      return;
    }
    _invalidateAudio();
    _replaceState(
      _state.copyWith(
        currentIndex: _state.currentIndex - 1,
        isFlipped: false,
        audioPhase: StudyAudioPhase.idle,
        audioWordId: null,
        audioAccent: null,
        audioSource: null,
        audioErrorCode: null,
        errorCode: null,
      ),
    );
  }

  /// 幂等切换当前单词收藏；失败只更新收藏子状态。
  Future<void> toggleCurrentWordFavorite() async {
    _requirePhase(const {
      StudyRunPhase.answering,
      StudyRunPhase.completed,
    }, 'toggle_word_favorite');
    final candidate = _requireCurrentCandidate();
    final wordId = candidate.word.id;
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
        throw StateError('单词收藏写入结果与目标状态不一致');
      }
      final favoriteWordIds = {..._state.favoriteWordIds};
      if (target) {
        favoriteWordIds.add(wordId);
      } else {
        favoriteWordIds.remove(wordId);
      }
      final updatingIds = {..._state.updatingFavoriteWordIds}..remove(wordId);
      _replaceState(
        _state.copyWith(
          favoriteWordIds: favoriteWordIds,
          updatingFavoriteWordIds: updatingIds,
          favoriteErrorCode: null,
        ),
      );
    } on Object {
      if (_isCurrentSession(sessionToken)) {
        final updatingIds = {..._state.updatingFavoriteWordIds}..remove(wordId);
        _replaceState(
          _state.copyWith(
            updatingFavoriteWordIds: updatingIds,
            favoriteErrorCode: StudyRunErrorCodes.wordFavoriteFailed,
          ),
        );
      }
    }
  }

  /// 播放当前单词指定口音；词库音频、第三方 TTS 和不可用由服务决定。
  Future<void> playCurrentPronunciation({PronunciationAccent? accent}) async {
    _requirePhase(const {
      StudyRunPhase.answering,
      StudyRunPhase.completed,
    }, 'play_pronunciation');
    final candidate = _requireCurrentCandidate();
    final word = candidate.word;
    final selectedAccent = accent ?? PronunciationAccent.uk;
    final sessionToken = _sessionToken;
    final audioToken = ++_audioToken;
    _replaceState(
      _state.copyWith(
        audioPhase: StudyAudioPhase.playing,
        audioWordId: word.id,
        audioAccent: selectedAccent,
        audioSource: null,
        audioErrorCode: null,
      ),
    );
    try {
      final result = await pronunciationService.play(
        word: word.word,
        accent: selectedAccent,
        audioUkAsset: word.audioUkAsset,
        audioUsAsset: word.audioUsAsset,
      );
      if (!_isCurrentAudio(
        sessionToken: sessionToken,
        audioToken: audioToken,
        wordId: word.id,
      )) {
        return;
      }
      final unavailable =
          result.source == PronunciationPlaybackSource.unavailable;
      _replaceState(
        _state.copyWith(
          audioPhase: unavailable
              ? StudyAudioPhase.unavailable
              : StudyAudioPhase.completed,
          audioSource: result.source,
          audioErrorCode: unavailable
              ? StudyRunErrorCodes.audioUnavailable
              : null,
        ),
      );
    } on Object {
      if (_isCurrentAudio(
        sessionToken: sessionToken,
        audioToken: audioToken,
        wordId: word.id,
      )) {
        _replaceState(
          _state.copyWith(
            audioPhase: StudyAudioPhase.error,
            audioSource: null,
            audioErrorCode: StudyRunErrorCodes.audioFailed,
          ),
        );
      }
    }
  }

  /// 停止当前发音并清除音频子状态，不改变学习进度。
  Future<void> stopPronunciation() async {
    _audioToken++;
    try {
      await pronunciationService.stop();
    } on Object {
      // 停止失败不覆盖学习会话状态。
    }
    if (!_closed && _state.currentCandidate != null) {
      _replaceState(
        _state.copyWith(
          audioPhase: StudyAudioPhase.idle,
          audioWordId: null,
          audioAccent: null,
          audioSource: null,
          audioErrorCode: null,
        ),
      );
    }
  }

  /// 清理未进行中的学习会话。
  void reset() {
    _requirePhase(const {
      StudyRunPhase.idle,
      StudyRunPhase.insufficientCandidates,
      StudyRunPhase.completed,
      StudyRunPhase.error,
    }, 'reset');
    _sessionToken++;
    _invalidateAudio();
    _replaceState(StudyRunState.idle());
  }

  StudyCandidate _requireCurrentCandidate() {
    final candidate = _state.currentCandidate;
    if (candidate == null) {
      throw StateError('当前没有学习卡片');
    }
    return candidate;
  }

  void _requirePhase(Set<StudyRunPhase> allowed, String action) {
    if (!allowed.contains(_state.phase)) {
      throw StudySessionTransitionException(
        phase: _state.phase,
        action: action,
      );
    }
  }

  void _replaceState(StudyRunState nextState) {
    if (_closed) {
      return;
    }
    _state = nextState;
    update([contentUpdateId]);
  }

  bool _isCurrentSession(int token) => !_closed && token == _sessionToken;

  bool _isCurrentAudio({
    required int sessionToken,
    required int audioToken,
    required int wordId,
  }) {
    return _isCurrentSession(sessionToken) &&
        audioToken == _audioToken &&
        _state.currentCandidate?.word.id == wordId;
  }

  void _invalidateAudio() {
    _audioToken++;
    unawaited(pronunciationService.stop().catchError((Object _) {}));
  }

  @override
  void onClose() {
    _closed = true;
    _sessionToken++;
    _invalidateAudio();
    super.onClose();
  }
}
