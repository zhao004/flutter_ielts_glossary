import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/pronunciation_practice_run_state.dart';
import '../../repositories/pronunciation_assessment_config_repository.dart';
import '../../services/assessment/pronunciation_evaluator.dart';
import '../../services/assessment/pronunciation_evaluator_factory.dart';
import '../../services/audio/audio_recorder.dart';

/// 协调第三方评测配置、录音和评分，不提供设备端语音识别回退。
final class PronunciationPracticeLogic extends GetxController {
  PronunciationPracticeLogic({
    required this.audioRecorder,
    required this.configRepository,
    required this.evaluatorFactory,
  });

  static const String updateId = 'pronunciation_practice_state';

  final AudioRecorderPort audioRecorder;
  final PronunciationAssessmentConfigRepository configRepository;
  final PronunciationEvaluatorFactory evaluatorFactory;

  PronunciationPracticeRunState _state = PronunciationPracticeRunState.idle();
  PronunciationPracticeRunState get state => _state;

  PronunciationEvaluatorPort? _evaluator;
  bool _closed = false;
  int _operationToken = 0;

  /// 加载第三方评测配置并检查录音权限；未配置服务时不请求录音。
  Future<void> prepare({
    required String expectedWord,
    PronunciationAccent accent = PronunciationAccent.uk,
  }) async {
    final normalizedWord = expectedWord.trim();
    _validateWord(normalizedWord);
    if (_closed) {
      throw StateError('发音练习 Logic 已关闭');
    }
    final operationToken = ++_operationToken;
    _replace(
      PronunciationPracticeRunState(
        phase: PronunciationPracticePhase.preparing,
        expectedWord: normalizedWord,
        accent: accent,
        score: null,
        errorCode: null,
      ),
    );
    try {
      final evaluator = await _loadEvaluator();
      if (!_isCurrent(operationToken)) {
        return;
      }
      if (evaluator == null) {
        _evaluator = null;
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.unavailable,
            score: null,
            errorCode: PronunciationPracticeErrorCodes.assessmentNotConfigured,
          ),
        );
        return;
      }
      _evaluator = evaluator;
      final hasPermission = await audioRecorder.hasPermission();
      if (!_isCurrent(operationToken)) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: hasPermission
              ? PronunciationPracticePhase.ready
              : PronunciationPracticePhase.permissionDenied,
          score: null,
          errorCode: hasPermission
              ? null
              : PronunciationPracticeErrorCodes.microphonePermissionDenied,
        ),
      );
    } on Object {
      if (_isCurrent(operationToken)) {
        _evaluator = null;
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.error,
            score: null,
            errorCode: PronunciationPracticeErrorCodes.preparationFailed,
          ),
        );
      }
    }
  }

  /// 重新加载当前单词的服务配置与录音权限。
  Future<void> retry() async {
    final expectedWord = _state.expectedWord;
    if (expectedWord == null ||
        _state.phase == PronunciationPracticePhase.idle) {
      return;
    }
    await prepare(expectedWord: expectedWord, accent: _state.accent);
  }

  /// 开始一次仅供第三方评测使用的录音。
  Future<void> startListening() async {
    if (_closed) {
      throw StateError('发音练习 Logic 已关闭');
    }
    if (_state.phase == PronunciationPracticePhase.listening) {
      return;
    }
    if (_state.phase != PronunciationPracticePhase.ready &&
        _state.phase != PronunciationPracticePhase.completed) {
      throw StateError('当前状态不能开始录音');
    }
    if (_evaluator == null) {
      _replace(
        _state.copyWith(
          phase: PronunciationPracticePhase.unavailable,
          score: null,
          errorCode: PronunciationPracticeErrorCodes.assessmentNotConfigured,
        ),
      );
      return;
    }
    final operationToken = ++_operationToken;
    _replace(
      _state.copyWith(
        phase: PronunciationPracticePhase.listening,
        score: null,
        errorCode: null,
      ),
    );
    try {
      await audioRecorder.start();
    } on Object {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.error,
            score: null,
            errorCode: PronunciationPracticeErrorCodes.recordingFailed,
          ),
        );
      }
    }
  }

  /// 取消当前录音并回到可再次录音的状态。
  Future<void> cancel() async {
    if (_state.phase != PronunciationPracticePhase.listening) {
      return;
    }
    _operationToken++;
    try {
      await audioRecorder.cancel();
      if (!_closed) {
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.ready,
            score: null,
            errorCode: null,
          ),
        );
      }
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.error,
            errorCode: PronunciationPracticeErrorCodes.cancelFailed,
          ),
        );
      }
    }
  }

  /// 结束当前录音并等待第三方服务返回评分。
  Future<void> stop() async {
    if (_state.phase != PronunciationPracticePhase.listening) {
      return;
    }
    await _finishCloudEvaluation();
  }

  /// 回到可录音状态，保留当前目标单词与口音，供再次练习。
  void reset() {
    if (_closed || _state.expectedWord == null) {
      return;
    }
    if (_evaluator == null) {
      _replace(
        _state.copyWith(
          phase: PronunciationPracticePhase.unavailable,
          score: null,
          errorCode: PronunciationPracticeErrorCodes.assessmentNotConfigured,
        ),
      );
      return;
    }
    _replace(
      _state.copyWith(
        phase: PronunciationPracticePhase.ready,
        score: null,
        errorCode: null,
      ),
    );
  }

  Future<void> _finishCloudEvaluation() async {
    final expectedWord = _state.expectedWord;
    final evaluator = _evaluator;
    if (expectedWord == null || evaluator == null) {
      return;
    }
    final operationToken = _operationToken;
    _replace(_state.copyWith(phase: PronunciationPracticePhase.evaluating));
    try {
      final audio = await audioRecorder.stop();
      final score = await evaluator.evaluate(
        PronunciationEvaluationRequest(
          referenceText: expectedWord,
          pcmBytes: audio.pcmBytes,
          accent: _state.accent,
        ),
      );
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.completed,
            score: score,
            errorCode: null,
          ),
        );
      }
    } on Object {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: PronunciationPracticePhase.error,
            score: null,
            errorCode: PronunciationPracticeErrorCodes.evaluationFailed,
          ),
        );
      }
    }
  }

  Future<PronunciationEvaluatorPort?> _loadEvaluator() async {
    final config = await configRepository.load();
    return evaluatorFactory.create(config);
  }

  void _validateWord(String word) {
    if (word.isEmpty || word.length > 200) {
      throw ArgumentError.value(word, 'expectedWord', '目标单词长度必须在 1-200 之间');
    }
  }

  bool _isCurrent(int token) => !_closed && token == _operationToken;

  void _replace(PronunciationPracticeRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    _operationToken++;
    unawaited(audioRecorder.cancel().catchError((Object _) {}));
    super.onClose();
  }
}
