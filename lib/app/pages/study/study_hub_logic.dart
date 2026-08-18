import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/study_hub_run_state.dart';
import '../../repositories/statistics_repository.dart';

/// 加载学习中心摘要，不参与具体学习或练习会话。
final class StudyHubLogic extends GetxController {
  StudyHubLogic({required this.statisticsRepository, this.autoLoad = true});

  static const String updateId = 'study_hub_state';

  final StatisticsRepository statisticsRepository;
  final bool autoLoad;

  StudyHubRunState _state = StudyHubRunState.idle();
  StudyHubRunState get state => _state;

  bool _busy = false;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    if (autoLoad) {
      unawaited(load());
    }
  }

  /// 加载近 30 天摘要；重复刷新不会并发查询。
  Future<void> load() async {
    if (_closed || _busy) return;
    _busy = true;
    _replace(_state.copyWith(phase: StudyHubRunPhase.loading, errorCode: null));
    try {
      final statistics = await statisticsRepository.loadDashboard(
        calendarDays: 30,
        trendDays: 30,
      );
      if (_closed) return;
      _replace(
        _state.copyWith(
          phase: StudyHubRunPhase.loaded,
          statistics: statistics,
          errorCode: null,
        ),
      );
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(
            phase: StudyHubRunPhase.error,
            errorCode: StudyHubErrorCodes.loadFailed,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  void _replace(StudyHubRunState next) {
    if (_closed) return;
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    super.onClose();
  }
}
