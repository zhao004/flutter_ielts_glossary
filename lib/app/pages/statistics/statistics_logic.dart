import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/statistics_run_state.dart';
import '../../repositories/statistics_report_repository.dart';

/// 协调完整统计报告的加载、刷新和失败重试。
final class StatisticsLogic extends GetxController {
  StatisticsLogic({
    required this.statisticsReportRepository,
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

  static const String updateId = 'statistics_state';

  final StatisticsReportRepository statisticsReportRepository;
  final int calendarDays;
  final int trendDays;
  final bool autoLoad;

  StatisticsRunState _state = StatisticsRunState.idle();
  StatisticsRunState get state => _state;

  bool _closed = false;
  Future<void>? _loadTask;
  int _loadToken = 0;

  @override
  void onInit() {
    super.onInit();
    if (autoLoad) {
      unawaited(load());
    }
  }

  /// 加载完整统计报告；并发调用共享进行中的查询。
  Future<void> load() {
    if (_closed) {
      return Future<void>.value();
    }
    final active = _loadTask;
    if (active != null) {
      return active;
    }
    final task = _performLoad();
    _loadTask = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_loadTask, task)) {
          _loadTask = null;
        }
      }),
    );
    return task;
  }

  Future<void> retry() => load();

  Future<void> _performLoad() async {
    final operationToken = ++_loadToken;
    _replace(
      _state.copyWith(phase: StatisticsRunPhase.loading, errorCode: null),
    );
    try {
      final report = await statisticsReportRepository.loadReport(
        calendarDays: calendarDays,
        trendDays: trendDays,
      );
      if (!_isCurrent(operationToken)) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: StatisticsRunPhase.loaded,
          report: report,
          errorCode: null,
        ),
      );
    } on Object {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: StatisticsRunPhase.error,
            errorCode: StatisticsErrorCodes.loadFailed,
          ),
        );
      }
    }
  }

  bool _isCurrent(int token) => !_closed && token == _loadToken;

  void _replace(StatisticsRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    _loadToken++;
    super.onClose();
  }
}
