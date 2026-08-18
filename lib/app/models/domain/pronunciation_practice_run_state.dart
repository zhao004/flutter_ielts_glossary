import 'pronunciation_score.dart';

/// 发音练习会话的稳定阶段。
enum PronunciationPracticePhase {
  idle,
  preparing,
  ready,
  listening,
  evaluating,
  completed,
  permissionDenied,
  unavailable,
  error,
}

/// 发音练习只向页面暴露稳定错误码。
abstract final class PronunciationPracticeErrorCodes {
  static const String preparationFailed =
      'pronunciation_practice_preparation_failed';
  static const String assessmentNotConfigured =
      'pronunciation_practice_assessment_not_configured';
  static const String microphonePermissionDenied =
      'pronunciation_practice_microphone_permission_denied';
  static const String recordingFailed =
      'pronunciation_practice_recording_failed';
  static const String evaluationFailed =
      'pronunciation_practice_evaluation_failed';
  static const String cancelFailed = 'pronunciation_practice_cancel_failed';
}

/// 发音练习的不可变快照，只保留第三方评测需要的评分结果。
final class PronunciationPracticeRunState {
  PronunciationPracticeRunState({
    required this.phase,
    required this.expectedWord,
    required this.score,
    required this.errorCode,
  }) {
    if (expectedWord != null &&
        (expectedWord!.trim().isEmpty || expectedWord!.length > 200)) {
      throw ArgumentError.value(expectedWord, 'expectedWord', '目标单词长度无效');
    }
    if (phase != PronunciationPracticePhase.idle && expectedWord == null) {
      throw ArgumentError('非空闲发音练习必须存在目标单词');
    }
    if (phase == PronunciationPracticePhase.completed && score == null) {
      throw ArgumentError('完成评测时必须存在评分结果');
    }
    if ((phase == PronunciationPracticePhase.error ||
            phase == PronunciationPracticePhase.unavailable ||
            phase == PronunciationPracticePhase.permissionDenied) &&
        errorCode == null) {
      throw ArgumentError('失败或不可用阶段必须存在稳定错误码');
    }
  }

  factory PronunciationPracticeRunState.idle() {
    return PronunciationPracticeRunState(
      phase: PronunciationPracticePhase.idle,
      expectedWord: null,
      score: null,
      errorCode: null,
    );
  }

  final PronunciationPracticePhase phase;
  final String? expectedWord;
  final PronunciationScore? score;
  final String? errorCode;

  PronunciationPracticeRunState copyWith({
    PronunciationPracticePhase? phase,
    Object? expectedWord = _unset,
    Object? score = _unset,
    Object? errorCode = _unset,
  }) {
    return PronunciationPracticeRunState(
      phase: phase ?? this.phase,
      expectedWord: identical(expectedWord, _unset)
          ? this.expectedWord
          : expectedWord as String?,
      score: identical(score, _unset)
          ? this.score
          : score as PronunciationScore?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const _unset = Object();
