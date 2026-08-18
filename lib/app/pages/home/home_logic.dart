import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/home_run_state.dart';
import '../../repositories/statistics_repository.dart';

/// 协调首页统计快照加载、刷新和失败重试，不直接接触数据库。
final class HomeLogic extends GetxController {
  HomeLogic({
    required this.statisticsRepository,
    this.calendarDays = 365,
    this.trendDays = 30,
    this.autoLoad = true,
  }) {
    if (calendarDays <= 0 || calendarDays > 3660) {
      throw ArgumentError.value(
        calendarDays,
        'calendarDays',
        '统计天数必须在 1-3660 之间',
      );
    }
    if (trendDays <= 0 || trendDays > calendarDays) {
      throw ArgumentError.value(
        trendDays,
        'trendDays',
        '趋势天数必须在 1-$calendarDays 之间',
      );
    }
  }

  static const String stateUpdateId = 'home_state';

  final StatisticsRepository statisticsRepository;
  final int calendarDays;
  final int trendDays;
  final bool autoLoad;

  HomeRunState _state = HomeRunState.idle();
  HomeRunState get state => _state;

  bool _busy = false;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    if (autoLoad) {
      unawaited(load());
    }
  }

  /// 加载或刷新首页统计；重复调用不会并发查询同一快照。
  Future<void> load() async {
    if (_closed || _busy) {
      return;
    }
    _busy = true;
    _replace(_state.copyWith(phase: HomeRunPhase.loading, errorCode: null));
    try {
      final statistics = await statisticsRepository.loadDashboard(
        calendarDays: calendarDays,
        trendDays: trendDays,
      );
      if (_closed) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: HomeRunPhase.loaded,
          statistics: statistics,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_closed) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: HomeRunPhase.error,
          errorCode: HomeRunErrorCodes.loadFailed,
        ),
      );
    } finally {
      _busy = false;
    }
  }

  /// 失败状态下重新查询；已有成功数据会在刷新期间保留。
  Future<void> retry() => load();

  @override
  void onClose() {
    _closed = true;
    super.onClose();
  }

  void _replace(HomeRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([stateUpdateId]);
  }
}
