import 'question_config.dart';
import 'question_session.dart';

/// 练习配置入口的稳定阶段。
enum PracticeSetupPhase {
  editing,
  starting,
  insufficientCandidates,
  started,
  error,
}

/// 页面配置调用顺序不合法时抛出的编程错误。
final class PracticeSetupTransitionException implements Exception {
  const PracticeSetupTransitionException({
    required this.phase,
    required this.action,
  });

  final PracticeSetupPhase phase;
  final String action;

  @override
  String toString() =>
      'invalid_practice_setup_transition: ${phase.name}/$action';
}

/// 练习配置页的不可变状态快照。
final class PracticeSetupState {
  PracticeSetupState._({
    required this.phase,
    required this.config,
    required this.availability,
    required this.candidatePoolTruncated,
    required this.errorCode,
  }) {
    final exposesAvailability =
        phase == PracticeSetupPhase.insufficientCandidates ||
        phase == PracticeSetupPhase.started;
    if (exposesAvailability != (availability != null)) {
      throw ArgumentError('候选统计只允许出现在候选不足或启动成功状态');
    }
    if (availability == null && candidatePoolTruncated) {
      throw ArgumentError('没有候选统计时不能标记候选池截断');
    }
    if (phase == PracticeSetupPhase.insufficientCandidates &&
        availability!.availableCandidateCount >= config.questionCount) {
      throw ArgumentError('候选不足状态必须小于请求题量');
    }
    if (phase == PracticeSetupPhase.started &&
        availability!.availableCandidateCount < config.questionCount) {
      throw ArgumentError('启动成功状态必须具备足够候选');
    }
    final normalizedErrorCode = errorCode?.trim();
    if (phase == PracticeSetupPhase.error) {
      if (normalizedErrorCode == null || normalizedErrorCode.isEmpty) {
        throw ArgumentError('错误状态必须提供稳定错误码');
      }
    } else if (errorCode != null) {
      throw ArgumentError('非错误状态不能携带错误码');
    }
  }

  /// 创建可编辑状态并清除上一次启动反馈。
  factory PracticeSetupState.editing(QuestionConfig config) {
    return PracticeSetupState._(
      phase: PracticeSetupPhase.editing,
      config: config,
      availability: null,
      candidatePoolTruncated: false,
      errorCode: null,
    );
  }

  /// 创建正在启动练习的状态。
  factory PracticeSetupState.starting(QuestionConfig config) {
    return PracticeSetupState._(
      phase: PracticeSetupPhase.starting,
      config: config,
      availability: null,
      candidatePoolTruncated: false,
      errorCode: null,
    );
  }

  /// 创建候选不足状态并保留可供调整的真实数量。
  factory PracticeSetupState.insufficientCandidates({
    required QuestionConfig config,
    required QuestionAvailability availability,
    required bool candidatePoolTruncated,
  }) {
    return PracticeSetupState._(
      phase: PracticeSetupPhase.insufficientCandidates,
      config: config,
      availability: availability,
      candidatePoolTruncated: candidatePoolTruncated,
      errorCode: null,
    );
  }

  /// 创建成功进入答题会话的状态。
  factory PracticeSetupState.started({
    required QuestionConfig config,
    required QuestionAvailability availability,
    required bool candidatePoolTruncated,
  }) {
    return PracticeSetupState._(
      phase: PracticeSetupPhase.started,
      config: config,
      availability: availability,
      candidatePoolTruncated: candidatePoolTruncated,
      errorCode: null,
    );
  }

  /// 创建启动失败状态，只向页面暴露稳定错误码。
  factory PracticeSetupState.error({
    required QuestionConfig config,
    required String errorCode,
  }) {
    return PracticeSetupState._(
      phase: PracticeSetupPhase.error,
      config: config,
      availability: null,
      candidatePoolTruncated: false,
      errorCode: errorCode.trim(),
    );
  }

  final PracticeSetupPhase phase;
  final QuestionConfig config;
  final QuestionAvailability? availability;
  final bool candidatePoolTruncated;
  final String? errorCode;

  /// 当前题型允许的最小题量。
  int get minimumQuestionCount => QuestionCountLimits.minimumFor(config.type);

  /// 当前题型允许的最大题量。
  int get maximumQuestionCount => QuestionCountLimits.maximumFor(config.type);

  /// 候选数量达到题型下限时，配置页可以直接调整为实际数量。
  bool get canUseAvailableQuestionCount {
    final availableCount = availability?.availableCandidateCount;
    return phase == PracticeSetupPhase.insufficientCandidates &&
        availableCount != null &&
        availableCount >= minimumQuestionCount &&
        availableCount <= maximumQuestionCount;
  }
}
