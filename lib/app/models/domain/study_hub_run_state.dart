import 'learning_statistics.dart';

/// 学习中心统计数据的加载阶段。
enum StudyHubRunPhase { idle, loading, loaded, error }

/// 学习中心只暴露稳定错误码，不向页面传递底层异常。
abstract final class StudyHubErrorCodes {
  static const String loadFailed = 'study_hub_load_failed';
}

/// 学习中心不可变状态；刷新失败时保留上一次成功统计。
final class StudyHubRunState {
  const StudyHubRunState({
    required this.phase,
    required this.statistics,
    required this.errorCode,
  });

  factory StudyHubRunState.idle() => const StudyHubRunState(
    phase: StudyHubRunPhase.idle,
    statistics: null,
    errorCode: null,
  );

  final StudyHubRunPhase phase;
  final LearningDashboardStatistics? statistics;
  final String? errorCode;

  StudyHubRunState copyWith({
    StudyHubRunPhase? phase,
    Object? statistics = _unset,
    Object? errorCode = _unset,
  }) {
    return StudyHubRunState(
      phase: phase ?? this.phase,
      statistics: identical(statistics, _unset)
          ? this.statistics
          : statistics as LearningDashboardStatistics?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const _unset = Object();
