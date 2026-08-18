import '../../models/domain/learning_event_fact.dart';
import '../../models/domain/learning_statistics.dart';
import '../../models/domain/local_date.dart';
import '../clock/local_time_resolver.dart';

/// 纯 Dart 聚合本地日统计，避免把设备时区规则写入 SQL。
final class LearningStatisticsCalculator {
  const LearningStatisticsCalculator();

  /// 生成包含零活动日期的连续日序列，便于日历和趋势直接渲染。
  List<DailyLearningStatistics> buildDailySeries({
    required Iterable<LearningEventFact> events,
    required LocalDate today,
    required int dayCount,
    required LocalTimeResolver localTimeResolver,
  }) {
    if (dayCount <= 0 || dayCount > 3660) {
      throw ArgumentError.value(dayCount, 'dayCount', '统计天数必须在 1-3660 之间');
    }
    final firstDay = today.addDays(-(dayCount - 1));
    final accumulators = <LocalDate, _DailyAccumulator>{};
    for (final event in events) {
      final localDate = LocalDate.fromDateTime(
        localTimeResolver.toLocal(event.occurredAtUtc),
      );
      if (localDate.compareTo(firstDay) < 0 || localDate.compareTo(today) > 0) {
        continue;
      }
      final accumulator = accumulators.putIfAbsent(
        localDate,
        _DailyAccumulator.new,
      );
      accumulator.eventCount++;
      if (event.isCorrect != null) {
        accumulator.answeredCount++;
        if (event.isCorrect!) {
          accumulator.correctCount++;
        }
      }
    }

    return List<DailyLearningStatistics>.generate(dayCount, (index) {
      final date = firstDay.addDays(index);
      final accumulator = accumulators[date];
      return DailyLearningStatistics(
        date: date,
        eventCount: accumulator?.eventCount ?? 0,
        answeredCount: accumulator?.answeredCount ?? 0,
        correctCount: accumulator?.correctCount ?? 0,
      );
    }, growable: false);
  }

  /// 今天尚未学习时允许沿用截至昨天的连续记录，今天结束后再清零。
  int calculateCurrentStreak({
    required Set<LocalDate> activeDates,
    required LocalDate today,
  }) {
    var current = activeDates.contains(today) ? today : today.addDays(-1);
    if (!activeDates.contains(current)) {
      return 0;
    }
    var streak = 0;
    while (activeDates.contains(current)) {
      streak++;
      current = current.addDays(-1);
    }
    return streak;
  }
}

final class _DailyAccumulator {
  int eventCount = 0;
  int answeredCount = 0;
  int correctCount = 0;
}
