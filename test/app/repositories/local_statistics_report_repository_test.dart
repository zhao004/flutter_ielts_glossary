import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/learning_statistics.dart';
import 'package:flutter_ielts_glossary/app/models/domain/local_date.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_memory_rate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_learning_state.dart';
import 'package:flutter_ielts_glossary/app/repositories/learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_statistics_report_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/statistics_repository.dart';

void main() {
  test('并行组合首页统计与三个时间窗记忆率', () async {
    final statistics = _FakeStatisticsRepository();
    final learning = _FakeLearningRepository();
    final repository = LocalStatisticsReportRepository(statistics, learning);

    final report = await repository.loadReport(calendarDays: 2, trendDays: 1);

    expect(statistics.calendarDays, 2);
    expect(statistics.trendDays, 1);
    expect(learning.windows, [
      const Duration(days: 7),
      const Duration(days: 30),
      null,
    ]);
    expect(report.sevenDayMemoryRate.value, 0.5);
    expect(report.thirtyDayMemoryRate.value, 0.75);
    expect(report.allTimeMemoryRate.value, 0.8);
    expect(report.totalStudiedEvents, 5);
    expect(report.totalAnswered, 4);
    expect(report.totalCorrect, 3);
    expect(report.overallAccuracy, 0.75);
  });

  test('统计窗口边界在查询前拒绝', () async {
    final statistics = _FakeStatisticsRepository();
    final repository = LocalStatisticsReportRepository(
      statistics,
      _FakeLearningRepository(),
    );

    await expectLater(
      repository.loadReport(calendarDays: 0),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.loadReport(calendarDays: 7, trendDays: 8),
      throwsA(isA<ArgumentError>()),
    );
    expect(statistics.calls, 0);
  });
}

final class _FakeStatisticsRepository implements StatisticsRepository {
  int calls = 0;
  int? calendarDays;
  int? trendDays;

  @override
  Future<LearningDashboardStatistics> loadDashboard({
    int calendarDays = 365,
    int trendDays = 30,
  }) async {
    calls++;
    this.calendarDays = calendarDays;
    this.trendDays = trendDays;
    final first = DailyLearningStatistics(
      date: LocalDate(year: 2026, month: 8, day: 14),
      eventCount: 2,
      answeredCount: 2,
      correctCount: 1,
    );
    final second = DailyLearningStatistics(
      date: LocalDate(year: 2026, month: 8, day: 15),
      eventCount: 3,
      answeredCount: 2,
      correctCount: 2,
    );
    return LearningDashboardStatistics(
      generatedAtUtc: DateTime.utc(2026, 8, 15),
      today: second,
      dailyGoal: 10,
      currentStreakDays: 2,
      dueReviewCount: 1,
      masteredWordCount: 1,
      learningWordCount: 2,
      favoriteWordCount: 1,
      favoriteSentenceCount: 1,
      calendarDays: [first, second],
      accuracyTrend: [second],
    );
  }
}

final class _FakeLearningRepository implements LearningRepository {
  final List<Duration?> windows = [];

  @override
  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window}) async {
    windows.add(window);
    return switch (window?.inDays) {
      7 => const ReviewMemoryRate(correctReviews: 1, completedReviews: 2),
      30 => const ReviewMemoryRate(correctReviews: 3, completedReviews: 4),
      _ => const ReviewMemoryRate(correctReviews: 4, completedReviews: 5),
    };
  }

  @override
  Future<WordLearningState?> findWordState(int wordId) async => null;

  @override
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds) async =>
      [];

  @override
  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  }) => throw UnimplementedError();

  @override
  Future<List<WordLearningState>> findDueReviews({int limit = 100}) =>
      throw UnimplementedError();

  @override
  Future<WordLearningState> recordReview({
    required int wordId,
    required ReviewRating rating,
    String? sessionId,
  }) => throw UnimplementedError();

  @override
  Future<WordLearningState> recordStudyCompletion({
    required int wordId,
    String? sessionId,
  }) => throw UnimplementedError();
}
