import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/home_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/learning_statistics.dart';
import 'package:flutter_ielts_glossary/app/models/domain/local_date.dart';
import 'package:flutter_ielts_glossary/app/pages/home/home_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/statistics_repository.dart';

void main() {
  test('成功加载首页统计并向 Repository 传递窗口参数', () async {
    final repository = _FakeStatisticsRepository();
    final logic = HomeLogic(
      statisticsRepository: repository,
      calendarDays: 7,
      trendDays: 3,
      autoLoad: false,
    );

    await logic.load();

    expect(logic.state.phase, HomeRunPhase.loaded);
    expect(logic.state.statistics, same(repository.statistics));
    expect(repository.calendarDays, 7);
    expect(repository.trendDays, 3);
    logic.onClose();
  });

  test('加载失败暴露稳定错误码，重试成功且重复调用不并发', () async {
    final repository = _FakeStatisticsRepository()..fail = true;
    final logic = HomeLogic(statisticsRepository: repository, autoLoad: false);

    final first = logic.load();
    final second = logic.load();
    await Future.wait([first, second]);
    expect(logic.state.phase, HomeRunPhase.error);
    expect(logic.state.errorCode, HomeRunErrorCodes.loadFailed);
    expect(repository.callCount, 1);

    repository.fail = false;
    await logic.retry();
    expect(logic.state.phase, HomeRunPhase.loaded);
    expect(logic.state.errorCode, isNull);
    expect(repository.callCount, 2);
    logic.onClose();
  });

  test('关闭后异步结果不会重新写入状态', () async {
    final repository = _FakeStatisticsRepository()..waitForRelease = true;
    final logic = HomeLogic(statisticsRepository: repository, autoLoad: false);

    final pending = logic.load();
    logic.onClose();
    repository.release();
    await pending;

    expect(logic.state.phase, HomeRunPhase.loading);
  });
}

final class _FakeStatisticsRepository implements StatisticsRepository {
  final LearningDashboardStatistics statistics = LearningDashboardStatistics(
    generatedAtUtc: DateTime.utc(2026, 8, 15),
    today: DailyLearningStatistics(
      date: LocalDate(year: 2026, month: 8, day: 15),
      eventCount: 1,
      answeredCount: 1,
      correctCount: 1,
    ),
    dailyGoal: 10,
    currentStreakDays: 1,
    dueReviewCount: 0,
    masteredWordCount: 0,
    learningWordCount: 1,
    favoriteWordCount: 0,
    favoriteSentenceCount: 0,
    calendarDays: [
      DailyLearningStatistics(
        date: LocalDate(year: 2026, month: 8, day: 15),
        eventCount: 1,
        answeredCount: 1,
        correctCount: 1,
      ),
    ],
    accuracyTrend: [
      DailyLearningStatistics(
        date: LocalDate(year: 2026, month: 8, day: 15),
        eventCount: 1,
        answeredCount: 1,
        correctCount: 1,
      ),
    ],
  );

  bool fail = false;
  bool waitForRelease = false;
  int callCount = 0;
  int? calendarDays;
  int? trendDays;
  Completer<void>? _releaseCompleter;

  @override
  Future<LearningDashboardStatistics> loadDashboard({
    int calendarDays = 365,
    int trendDays = 30,
  }) async {
    callCount++;
    this.calendarDays = calendarDays;
    this.trendDays = trendDays;
    if (waitForRelease) {
      _releaseCompleter = Completer<void>();
      await _releaseCompleter!.future;
    }
    if (fail) {
      throw Exception('statistics failed');
    }
    return statistics;
  }

  void release() {
    final completer = _releaseCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
