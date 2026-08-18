import 'study_config.dart';

/// 随机学习开始前配置的稳定阶段。
enum StudySetupPhase {
  loadingSettings,
  editing,
  starting,
  insufficientCandidates,
  started,
  error,
}

/// 随机学习配置页使用的稳定错误码。
abstract final class StudySetupErrorCodes {
  static const String settingsLoadFailed = 'study_setup_settings_load_failed';
}

/// 页面配置调用顺序不合法时抛出的编程错误。
final class StudySetupTransitionException implements Exception {
  const StudySetupTransitionException({
    required this.phase,
    required this.action,
  });

  final StudySetupPhase phase;
  final String action;

  @override
  String toString() => 'invalid_study_setup_transition: ${phase.name}/$action';
}

/// 随机学习配置页的不可变状态快照。
final class StudySetupState {
  StudySetupState._({
    required this.phase,
    required this.config,
    required this.availableCount,
    required this.errorCode,
  }) {
    final requiresConfig = switch (phase) {
      StudySetupPhase.loadingSettings => false,
      StudySetupPhase.error => config != null,
      _ => true,
    };
    if (requiresConfig && config == null) {
      throw ArgumentError('当前随机学习配置阶段必须存在配置');
    }
    if (availableCount < 0) {
      throw ArgumentError.value(availableCount, 'availableCount', '候选数量不能为负数');
    }
    final exposesAvailability =
        phase == StudySetupPhase.insufficientCandidates ||
        phase == StudySetupPhase.started;
    if (!exposesAvailability && availableCount != 0) {
      throw ArgumentError('只有候选不足或启动成功状态可以携带候选数量');
    }
    if (phase == StudySetupPhase.insufficientCandidates &&
        availableCount >= config!.wordCount) {
      throw ArgumentError('候选不足状态必须小于请求数量');
    }
    if (phase == StudySetupPhase.started &&
        availableCount < config!.wordCount) {
      throw ArgumentError('启动成功状态必须具备足够候选');
    }
    final normalizedErrorCode = errorCode?.trim();
    if (phase == StudySetupPhase.error) {
      if (normalizedErrorCode == null || normalizedErrorCode.isEmpty) {
        throw ArgumentError('错误状态必须提供稳定错误码');
      }
    } else if (errorCode != null) {
      throw ArgumentError('非错误状态不能携带错误码');
    }
  }

  /// 创建正在读取用户级发音偏好的状态。
  factory StudySetupState.loadingSettings() {
    return StudySetupState._(
      phase: StudySetupPhase.loadingSettings,
      config: null,
      availableCount: 0,
      errorCode: null,
    );
  }

  /// 创建可编辑状态并清除上一次候选或错误反馈。
  factory StudySetupState.editing(StudyConfig config) {
    return StudySetupState._(
      phase: StudySetupPhase.editing,
      config: config,
      availableCount: 0,
      errorCode: null,
    );
  }

  /// 创建正在启动随机学习会话的状态。
  factory StudySetupState.starting(StudyConfig config) {
    return StudySetupState._(
      phase: StudySetupPhase.starting,
      config: config,
      availableCount: 0,
      errorCode: null,
    );
  }

  /// 创建候选不足状态并保留可供用户调整的真实数量。
  factory StudySetupState.insufficientCandidates({
    required StudyConfig config,
    required int availableCount,
  }) {
    return StudySetupState._(
      phase: StudySetupPhase.insufficientCandidates,
      config: config,
      availableCount: availableCount,
      errorCode: null,
    );
  }

  /// 创建成功进入学习会话的状态。
  factory StudySetupState.started({
    required StudyConfig config,
    required int availableCount,
  }) {
    return StudySetupState._(
      phase: StudySetupPhase.started,
      config: config,
      availableCount: availableCount,
      errorCode: null,
    );
  }

  /// 创建设置加载或会话启动失败状态。
  factory StudySetupState.error({
    required StudyConfig? config,
    required String errorCode,
  }) {
    return StudySetupState._(
      phase: StudySetupPhase.error,
      config: config,
      availableCount: 0,
      errorCode: errorCode.trim(),
    );
  }

  final StudySetupPhase phase;
  final StudyConfig? config;
  final int availableCount;
  final String? errorCode;

  /// 候选数量达到领域下限时可直接作为新的学习数量。
  bool get canUseAvailableWordCount {
    return phase == StudySetupPhase.insufficientCandidates &&
        availableCount >= StudyConfig.minimumWordCount &&
        availableCount <= StudyConfig.maximumWordCount;
  }
}
