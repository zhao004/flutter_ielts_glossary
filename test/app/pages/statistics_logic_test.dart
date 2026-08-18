import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/learning_statistics.dart';
import 'package:flutter_ielts_glossary/app/models/domain/local_date.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_memory_rate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/statistics_report.dart';
import 'package:flutter_ielts_glossary/app/models/domain/statistics_run_state.dart';
import 'package:flutter_ielts_glossary/app/pages/statistics/statistics_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/statistics_report_repository.dart';

void main() {
  test('加载完整统计并传递日期窗口', () async {
    final repository = _FakeStatisticsReportRepository();
    final logic = StatisticsLogic(
      statisticsReportRepository: repository,
      calendarDays: 30,
      trendDays: 7,
      autoLoad: false,
    );
    addTearDown(logic.onClose);

    await logic.load();

    expect(logic.state.phase, StatisticsRunPhase.loaded);
    expect(logic.state.report, same(repository.report));
    expect(repository.calendarDays, 30);
    expect(repository.trendDays, 7);
  });

  test('刷新失败保留旧报告，重试成功且并发加载共享任务', () async {
    final repository = _FakeStatisticsReportRepository();
    final logic = StatisticsLogic(
      statisticsReportRepository: repository,
      autoLoad: false,
    );
    addTearDown(logic.onClose);
    await logic.load();

    repository.fail = true;
    final first = logic.load();
    final second = logic.load();
    await Future.wait([first, second]);
    expect(repository.calls, 2);
    expect(logic.state.phase, StatisticsRunPhase.error);
    expect(logic.state.report, same(repository.report));
    expect(logic.state.errorCode, StatisticsErrorCodes.loadFailed);

    repository.fail = false;
    await logic.retry();
    expect(logic.state.phase, StatisticsRunPhase.loaded);
    expect(logic.state.errorCode, isNull);
  });

  test('关闭后忽略晚返回统计报告', () async {
    final repository = _FakeStatisticsReportRepository()
      ..gate = Completer<void>();
    final logic = StatisticsLogic(
      statisticsReportRepository: repository,
      autoLoad: false,
    );

    final pending = logic.load();
    await repository.entered.future;
    logic.onClose();
    repository.gate!.complete();
    await pending;

    expect(logic.state.phase, StatisticsRunPhase.loading);
  });
}

final class _FakeStatisticsReportRepository
    implements StatisticsReportRepository {
  final StatisticsReport report = _report();
  bool fail = false;
  int calls = 0;
  int? calendarDays;
  int? trendDays;
  Completer<void>? gate;
  final Completer<void> entered = Completer<void>();

  @override
  Future<StatisticsReport> loadReport({
    int calendarDays = 365,
    int trendDays = 30,
  }) async {
    calls++;
    this.calendarDays = calendarDays;
    this.trendDays = trendDays;
    if (!entered.isCompleted) {
      entered.complete();
    }
    final currentGate = gate;
    if (currentGate != null && !currentGate.isCompleted) {
      await currentGate.future;
    }
    if (fail) {
      throw StateError('statistics failed');
    }
    return report;
  }
}

StatisticsReport _report() {
  final day = DailyLearningStatistics(
    date: LocalDate(year: 2026, month: 8, day: 15),
    eventCount: 1,
    answeredCount: 1,
    correctCount: 1,
  );
  return StatisticsReport(
    dashboard: LearningDashboardStatistics(
      generatedAtUtc: DateTime.utc(2026, 8, 15),
      today: day,
      dailyGoal: 10,
      currentStreakDays: 1,
      dueReviewCount: 0,
      masteredWordCount: 0,
      learningWordCount: 1,
      favoriteWordCount: 0,
      favoriteSentenceCount: 0,
      calendarDays: [day],
      accuracyTrend: [day],
    ),
    sevenDayMemoryRate: const ReviewMemoryRate(
      correctReviews: 1,
      completedReviews: 1,
    ),
    thirtyDayMemoryRate: const ReviewMemoryRate(
      correctReviews: 1,
      completedReviews: 1,
    ),
    allTimeMemoryRate: const ReviewMemoryRate(
      correctReviews: 1,
      completedReviews: 1,
    ),
  );
}
