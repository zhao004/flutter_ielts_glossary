import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/review_queue.dart';
import '../../models/domain/review_rating.dart';
import '../../models/domain/review_run_state.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../repositories/review_queue_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/audio/audio_playback_service.dart';

/// 协调到期队列、翻卡、结果写入和会话汇总，不直接访问 Drift DAO。
final class ReviewSessionLogic extends GetxController {
  ReviewSessionLogic({
    required this.reviewQueueRepository,
    required this.learningRepository,
    required this.favoriteRepository,
    required this.settingsRepository,
    required this.pronunciationService,
  });

  static const String contentUpdateId = 'review_content';
  static const int defaultReviewLimit = 100;
  static const int maximumReviewLimit = 500;
  static const int reinforcementThreshold = 2;

  final ReviewQueueRepository reviewQueueRepository;
  final LearningRepository learningRepository;
  final FavoriteRepository favoriteRepository;
  final SettingsRepository settingsRepository;
  final PronunciationService pronunciationService;

  ReviewRunState _state = ReviewRunState.idle();
  ReviewRunState get state => _state;

  bool _closed = false;
  int _operationToken = 0;
  int _sessionToken = 0;
  int _audioToken = 0;

  /// 加载当前到期队列；内容库缺失 ID 会保留在快照中供页面提示。
  Future<void> start({int limit = defaultReviewLimit}) async {
    _requirePhase(const {
      ReviewRunPhase.idle,
      ReviewRunPhase.empty,
      ReviewRunPhase.completed,
      ReviewRunPhase.error,
    }, 'start');
    if (limit <= 0 || limit > maximumReviewLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        '复习数量必须在 1-$maximumReviewLimit 之间',
      );
    }
    final operationToken = ++_operationToken;
    final sessionToken = ++_sessionToken;
    _invalidateAudio();
    _replaceState(
      ReviewRunState.idle().copyWith(phase: ReviewRunPhase.preparing),
    );
    try {
      final results = await Future.wait<Object>([
        reviewQueueRepository.findDueItems(limit: limit),
        settingsRepository.load(),
      ]);
      if (!_isCurrent(operationToken) || !_isCurrentSession(sessionToken)) {
        return;
      }
      final queue = results[0] as ReviewQueueSnapshot;
      final queueWordIds = queue.items.map((item) => item.word.id).toSet();
      final favoriteWordIds = queueWordIds.isEmpty
          ? const <int>{}
          : await favoriteRepository.findFavoriteWordIds(queueWordIds);
      if (!_isCurrent(operationToken) || !_isCurrentSession(sessionToken)) {
        return;
      }
      if (!queueWordIds.containsAll(favoriteWordIds)) {
        throw StateError('收藏 Repository 返回了复习队列外单词');
      }
      _replaceState(
        _state.copyWith(
          phase: queue.items.isEmpty
              ? ReviewRunPhase.empty
              : ReviewRunPhase.reviewing,
          queue: queue,
          currentIndex: 0,
          isFlipped: false,
          responses: const [],
          reinforcementPrompt: null,
          memoryRate: null,
          favoriteWordIds: favoriteWordIds,
          updatingFavoriteWordIds: const {},
          pronunciationAccent: PronunciationAccent.uk,
          audioPhase: ReviewAudioPhase.idle,
          audioWordId: null,
          audioSource: null,
          favoriteErrorCode: null,
          audioErrorCode: null,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_isCurrent(operationToken)) {
        _replaceState(
          _state.copyWith(
            phase: ReviewRunPhase.error,
            errorCode: ReviewRunErrorCodes.preparationFailed,
          ),
        );
      }
    }
  }

  /// 翻开或收起当前复习卡；只有翻开后才能提交记忆结果。
  void flip() {
    _requirePhase(const {ReviewRunPhase.reviewing}, 'flip');
    if (_state.currentItem == null) {
      throw StateError('当前没有可复习单词');
    }
    _replaceState(
      _state.copyWith(isFlipped: !_state.isFlipped, errorCode: null),
    );
  }

  /// 持久化四档回忆评分，成功后自动进入下一张或完成会话。
  Future<void> submit(ReviewRating rating) async {
    _requirePhase(const {ReviewRunPhase.reviewing}, 'submit');
    final item = _state.currentItem;
    if (item == null) {
      throw StateError('当前没有可提交的复习卡片');
    }
    if (!_state.isFlipped) {
      throw StateError('提交复习结果前必须先翻开卡片');
    }
    final operationToken = ++_operationToken;
    _replaceState(
      _state.copyWith(phase: ReviewRunPhase.submitting, errorCode: null),
    );

    late final ReviewCardResponse response;
    late final ReviewReinforcementPrompt? reinforcementPrompt;
    try {
      final learningState = await learningRepository.recordReview(
        wordId: item.word.id,
        rating: rating,
      );
      if (!_isCurrent(operationToken)) {
        return;
      }
      if (learningState.wordId != item.word.id ||
          learningState.lastReviewedAt == null) {
        throw StateError('复习写入结果与当前单词不一致');
      }
      response = ReviewCardResponse(
        wordId: item.word.id,
        rating: rating,
        previousMasteryLevel: item.learningState.masteryLevel,
        learningState: learningState,
      );
      reinforcementPrompt =
          rating == ReviewRating.again &&
              learningState.consecutiveForgottenCount >=
                  reinforcementThreshold &&
              item.word.translationZh?.trim().isNotEmpty == true
          ? ReviewReinforcementPrompt(
              wordId: item.word.id,
              word: item.word.word,
            )
          : _state.reinforcementPrompt;
    } on Exception {
      if (_isCurrent(operationToken)) {
        _replaceState(
          _state.copyWith(
            phase: ReviewRunPhase.reviewing,
            isFlipped: true,
            errorCode: ReviewRunErrorCodes.persistenceFailed,
          ),
        );
      }
      return;
    }

    final responses = [..._state.responses, response];
    if (!_state.isLastItem) {
      _invalidateAudio();
      _replaceState(
        _state.copyWith(
          phase: ReviewRunPhase.reviewing,
          currentIndex: _state.currentIndex + 1,
          isFlipped: false,
          responses: responses,
          reinforcementPrompt: reinforcementPrompt,
          audioPhase: ReviewAudioPhase.idle,
          audioWordId: null,
          audioSource: null,
          audioErrorCode: null,
          errorCode: null,
        ),
      );
      return;
    }

    _replaceState(
      _state.copyWith(
        phase: ReviewRunPhase.completing,
        isFlipped: true,
        responses: responses,
        reinforcementPrompt: reinforcementPrompt,
        errorCode: null,
      ),
    );
    await _loadMemoryRate(operationToken);
  }

  /// 清除当前非强制专项巩固提示，不影响已经保存的复习结果。
  void dismissReinforcement() {
    _requirePhase(const {
      ReviewRunPhase.reviewing,
      ReviewRunPhase.completing,
      ReviewRunPhase.completed,
    }, 'dismiss_reinforcement');
    if (_state.reinforcementPrompt == null) {
      return;
    }
    _replaceState(_state.copyWith(reinforcementPrompt: null));
  }

  /// 会话结果已经保存但记忆率查询失败时，仅重试统计查询。
  Future<void> retryMemoryRate() async {
    _requirePhase(const {ReviewRunPhase.completed}, 'retryMemoryRate');
    if (_state.errorCode != ReviewRunErrorCodes.memoryRateFailed) {
      return;
    }
    final operationToken = ++_operationToken;
    _replaceState(
      _state.copyWith(phase: ReviewRunPhase.completing, errorCode: null),
    );
    await _loadMemoryRate(operationToken);
  }

  /// 幂等切换当前复习单词收藏；失败不改变翻卡和复习结果。
  Future<void> toggleCurrentWordFavorite() async {
    _requirePhase(const {
      ReviewRunPhase.reviewing,
      ReviewRunPhase.completed,
    }, 'toggle_word_favorite');
    final item = _requireCurrentItem();
    final wordId = item.word.id;
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
        throw StateError('复习单词收藏写入结果与目标状态不一致');
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
            favoriteErrorCode: ReviewRunErrorCodes.wordFavoriteFailed,
          ),
        );
      }
    }
  }

  /// 播放当前复习单词指定口音，并隔离不可用和平台错误状态。
  Future<void> playCurrentPronunciation({PronunciationAccent? accent}) async {
    _requirePhase(const {
      ReviewRunPhase.reviewing,
      ReviewRunPhase.completed,
    }, 'play_pronunciation');
    final item = _requireCurrentItem();
    final word = item.word;
    final selectedAccent = accent ?? _state.pronunciationAccent;
    final sessionToken = _sessionToken;
    final audioToken = ++_audioToken;
    _replaceState(
      _state.copyWith(
        pronunciationAccent: selectedAccent,
        audioPhase: ReviewAudioPhase.playing,
        audioWordId: word.id,
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
              ? ReviewAudioPhase.unavailable
              : ReviewAudioPhase.completed,
          audioSource: result.source,
          audioErrorCode: unavailable
              ? ReviewRunErrorCodes.audioUnavailable
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
            audioPhase: ReviewAudioPhase.error,
            audioSource: null,
            audioErrorCode: ReviewRunErrorCodes.audioFailed,
          ),
        );
      }
    }
  }

  /// 停止当前参考发音并清除音频子状态。
  Future<void> stopPronunciation() async {
    _audioToken++;
    try {
      await pronunciationService.stop();
    } on Object {
      // 停止失败不覆盖复习队列和结果。
    }
    if (!_closed && _state.currentItem != null) {
      _replaceState(
        _state.copyWith(
          audioPhase: ReviewAudioPhase.idle,
          audioWordId: null,
          audioSource: null,
          audioErrorCode: null,
        ),
      );
    }
  }

  /// 清理尚未开始或已经结束的会话。
  void reset() {
    _requirePhase(const {
      ReviewRunPhase.idle,
      ReviewRunPhase.empty,
      ReviewRunPhase.completed,
      ReviewRunPhase.error,
    }, 'reset');
    _operationToken++;
    _sessionToken++;
    _invalidateAudio();
    _replaceState(ReviewRunState.idle());
  }

  ReviewQueueItem _requireCurrentItem() {
    final item = _state.currentItem;
    if (item == null) {
      throw StateError('当前没有复习单词');
    }
    return item;
  }

  Future<void> _loadMemoryRate(int operationToken) async {
    try {
      final memoryRate = await learningRepository.getReviewMemoryRate();
      if (!_isCurrent(operationToken)) {
        return;
      }
      _replaceState(
        _state.copyWith(
          phase: ReviewRunPhase.completed,
          memoryRate: memoryRate,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_isCurrent(operationToken)) {
        _replaceState(
          _state.copyWith(
            phase: ReviewRunPhase.completed,
            memoryRate: null,
            errorCode: ReviewRunErrorCodes.memoryRateFailed,
          ),
        );
      }
    }
  }

  void _requirePhase(Set<ReviewRunPhase> allowed, String action) {
    if (_closed || !allowed.contains(_state.phase)) {
      throw ReviewSessionTransitionException(
        phase: _state.phase,
        action: action,
      );
    }
  }

  void _replaceState(ReviewRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([contentUpdateId]);
  }

  bool _isCurrent(int operationToken) {
    return !_closed && operationToken == _operationToken;
  }

  bool _isCurrentSession(int token) => !_closed && token == _sessionToken;

  bool _isCurrentAudio({
    required int sessionToken,
    required int audioToken,
    required int wordId,
  }) {
    return _isCurrentSession(sessionToken) &&
        audioToken == _audioToken &&
        _state.currentItem?.word.id == wordId;
  }

  void _invalidateAudio() {
    _audioToken++;
    unawaited(pronunciationService.stop().catchError((Object _) {}));
  }

  @override
  void onClose() {
    _closed = true;
    _operationToken++;
    _sessionToken++;
    _invalidateAudio();
    super.onClose();
  }
}
