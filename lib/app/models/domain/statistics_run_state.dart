import 'statistics_report.dart';

/// 完整统计页的稳定加载阶段。
enum StatisticsRunPhase { idle, loading, loaded, error }

/// 完整统计页稳定错误码。
abstract final class StatisticsErrorCodes {
  static const String loadFailed = 'statistics_load_failed';
}

/// 完整统计页状态；刷新失败时保留上一份报告。
final class StatisticsRunState {
  const StatisticsRunState({
    required this.phase,
    required this.report,
    required this.errorCode,
  });

  factory StatisticsRunState.idle() {
    return const StatisticsRunState(
      phase: StatisticsRunPhase.idle,
      report: null,
      errorCode: null,
    );
  }

  final StatisticsRunPhase phase;
  final StatisticsReport? report;
  final String? errorCode;

  StatisticsRunState copyWith({
    StatisticsRunPhase? phase,
    Object? report = _unset,
    Object? errorCode = _unset,
  }) {
    return StatisticsRunState(
      phase: phase ?? this.phase,
      report: identical(report, _unset)
          ? this.report
          : report as StatisticsReport?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const _unset = Object();
