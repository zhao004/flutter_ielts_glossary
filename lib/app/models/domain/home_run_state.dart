import 'learning_statistics.dart';

/// 首页统计查询的生命周期阶段。
enum HomeRunPhase { idle, loading, loaded, error }

/// 首页只消费稳定错误码，不展示数据库或平台异常正文。
abstract final class HomeRunErrorCodes {
  static const String loadFailed = 'home_load_failed';
}

/// 首页统计状态快照；刷新失败时保留上一次成功数据供页面继续展示。
final class HomeRunState {
  const HomeRunState({
    required this.phase,
    required this.statistics,
    required this.errorCode,
  });

  factory HomeRunState.idle() {
    return const HomeRunState(
      phase: HomeRunPhase.idle,
      statistics: null,
      errorCode: null,
    );
  }

  final HomeRunPhase phase;
  final LearningDashboardStatistics? statistics;
  final String? errorCode;

  HomeRunState copyWith({
    HomeRunPhase? phase,
    Object? statistics = _unset,
    Object? errorCode = _unset,
  }) {
    return HomeRunState(
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
