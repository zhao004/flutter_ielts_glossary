import '../database/user/daos/user_data_dao.dart';
import '../models/domain/learning_event_fact.dart';
import '../models/domain/learning_statistics.dart';
import '../models/domain/local_date.dart';
import '../services/clock/app_clock.dart';
import '../services/clock/local_time_resolver.dart';
import '../services/statistics/learning_statistics_calculator.dart';
import 'statistics_repository.dart';

/// 将用户库事件、复习状态和设备本地日期聚合为首页统计快照。
final class LocalStatisticsRepository implements StatisticsRepository {
  LocalStatisticsRepository(
    this._userDataDao, {
    this.clock = const SystemAppClock(),
    this.localTimeResolver = const SystemLocalTimeResolver(),
    this.calculator = const LearningStatisticsCalculator(),
  });

  static const int defaultCalendarDays = 365;
  static const int defaultTrendDays = 30;
  static const int defaultDailyGoal = 10;
  static const int pageSize = 500;

  final UserDataDao _userDataDao;
  final AppClock clock;
  final LocalTimeResolver localTimeResolver;
  final LearningStatisticsCalculator calculator;

  @override
  Future<LearningDashboardStatistics> loadDashboard({
    int calendarDays = defaultCalendarDays,
    int trendDays = defaultTrendDays,
  }) async {
    _validateWindow(calendarDays, 'calendarDays');
    if (trendDays <= 0 || trendDays > calendarDays) {
      throw ArgumentError.value(
        trendDays,
        'trendDays',
        '趋势天数必须在 1-$calendarDays 之间',
      );
    }
    final nowUtc = clock.nowUtc().toUtc();
    final today = LocalDate.fromDateTime(localTimeResolver.toLocal(nowUtc));
    final firstDate = today.addDays(-(calendarDays - 1));
    final fromUtc = localTimeResolver.startOfDayUtc(firstDate);
    final untilUtc = localTimeResolver.startOfDayUtc(today.addDays(1));
    final facts = await _loadFacts(fromUtc: fromUtc, untilUtc: untilUtc);
    final dailySeries = calculator.buildDailySeries(
      events: facts,
      today: today,
      dayCount: calendarDays,
      localTimeResolver: localTimeResolver,
    );
    final activeDates = facts
        .map(
          (event) => LocalDate.fromDateTime(
            localTimeResolver.toLocal(event.occurredAtUtc),
          ),
        )
        .toSet();
    var currentStreakDays = calculator.calculateCurrentStreak(
      activeDates: activeDates,
      today: today,
    );
    final streakAnchor = activeDates.contains(today)
        ? today
        : today.addDays(-1);
    final nextExpectedStreakDate = streakAnchor.addDays(-currentStreakDays);
    if (nextExpectedStreakDate.compareTo(firstDate) < 0) {
      currentStreakDays = await _extendStreak(
        activeDates: activeDates,
        today: today,
        currentStreakDays: currentStreakDays,
        beforeUtc: fromUtc,
      );
    }
    final counts = await _userDataDao.countUserStatistics(now: nowUtc);
    final setting = await _userDataDao.findAppSetting();
    final dailyGoal = setting?.dailyGoal ?? defaultDailyGoal;
    final trendStart = dailySeries.length - trendDays;
    return LearningDashboardStatistics(
      generatedAtUtc: nowUtc,
      today: dailySeries.last,
      dailyGoal: dailyGoal,
      currentStreakDays: currentStreakDays,
      dueReviewCount: counts.dueReviewCount,
      masteredWordCount: counts.masteredWordCount,
      learningWordCount: counts.learningWordCount,
      favoriteWordCount: counts.favoriteWordCount,
      favoriteSentenceCount: counts.favoriteSentenceCount,
      calendarDays: dailySeries,
      accuracyTrend: dailySeries.sublist(trendStart),
    );
  }

  Future<List<LearningEventFact>> _loadFacts({
    required DateTime fromUtc,
    required DateTime untilUtc,
  }) async {
    final facts = <LearningEventFact>[];
    var offset = 0;
    while (true) {
      final page = await _userDataDao.findLearningEventFacts(
        fromUtc: fromUtc,
        toUtc: untilUtc,
        limit: pageSize,
        offset: offset,
      );
      facts.addAll(page);
      if (page.length < pageSize) {
        return facts;
      }
      offset += page.length;
    }
  }

  Future<int> _extendStreak({
    required Set<LocalDate> activeDates,
    required LocalDate today,
    required int currentStreakDays,
    required DateTime beforeUtc,
  }) async {
    var streak = currentStreakDays;
    var offset = 0;
    while (true) {
      final page = await _userDataDao.findLearningEventFacts(
        toUtc: beforeUtc,
        limit: pageSize,
        offset: offset,
        descending: true,
      );
      if (page.isEmpty) {
        return streak;
      }
      final pageDates = <LocalDate>[];
      for (final event in page) {
        final date = LocalDate.fromDateTime(
          localTimeResolver.toLocal(event.occurredAtUtc),
        );
        activeDates.add(date);
        pageDates.add(date);
      }
      final nextStreak = calculator.calculateCurrentStreak(
        activeDates: activeDates,
        today: today,
      );
      if (nextStreak > streak) {
        streak = nextStreak;
      }
      final expectedMissingDate = today.addDays(
        -(streak + (activeDates.contains(today) ? 0 : 1)),
      );
      final earliestPageDate = pageDates.reduce(
        (first, candidate) =>
            candidate.compareTo(first) < 0 ? candidate : first,
      );
      if (!activeDates.contains(expectedMissingDate) &&
          earliestPageDate.compareTo(expectedMissingDate) < 0) {
        return streak;
      }
      if (page.length < pageSize) {
        return streak;
      }
      offset += page.length;
    }
  }

  void _validateWindow(int days, String name) {
    if (days <= 0 || days > 3660) {
      throw ArgumentError.value(days, name, '统计天数必须在 1-3660 之间');
    }
  }
}
