import 'local_date.dart';

/// 某个本地日的学习活动和答题统计。
final class DailyLearningStatistics {
  DailyLearningStatistics({
    required this.date,
    required this.eventCount,
    required this.answeredCount,
    required this.correctCount,
  }) {
    if (eventCount < 0 || answeredCount < 0 || correctCount < 0) {
      throw ArgumentError('每日统计数量不能为负数');
    }
    if (correctCount > answeredCount || answeredCount > eventCount) {
      throw ArgumentError('每日统计必须满足正确数 <= 作答数 <= 活动数');
    }
  }

  final LocalDate date;
  final int eventCount;
  final int answeredCount;
  final int correctCount;

  double get accuracy => answeredCount == 0 ? 0 : correctCount / answeredCount;

  int remainingForGoal(int dailyGoal) {
    if (dailyGoal <= 0) {
      throw ArgumentError.value(dailyGoal, 'dailyGoal', '每日目标必须大于 0');
    }
    final remaining = dailyGoal - eventCount;
    return remaining > 0 ? remaining : 0;
  }
}

/// 首页所需的学习摘要，所有日期均按设备本地日计算。
final class LearningDashboardStatistics {
  LearningDashboardStatistics({
    required this.generatedAtUtc,
    required this.today,
    required this.dailyGoal,
    required this.currentStreakDays,
    required this.dueReviewCount,
    required this.masteredWordCount,
    required this.learningWordCount,
    required this.favoriteWordCount,
    required this.favoriteSentenceCount,
    required List<DailyLearningStatistics> calendarDays,
    required List<DailyLearningStatistics> accuracyTrend,
  }) : calendarDays = List<DailyLearningStatistics>.unmodifiable(calendarDays),
       accuracyTrend = List<DailyLearningStatistics>.unmodifiable(
         accuracyTrend,
       ) {
    if (dailyGoal <= 0 ||
        currentStreakDays < 0 ||
        dueReviewCount < 0 ||
        masteredWordCount < 0 ||
        learningWordCount < 0 ||
        favoriteWordCount < 0 ||
        favoriteSentenceCount < 0) {
      throw ArgumentError('首页统计数量无效');
    }
    _validateOrderedDays(this.calendarDays, 'calendarDays');
    _validateOrderedDays(this.accuracyTrend, 'accuracyTrend');
  }

  final DateTime generatedAtUtc;
  final DailyLearningStatistics today;
  final int dailyGoal;
  final int currentStreakDays;
  final int dueReviewCount;
  final int masteredWordCount;
  final int learningWordCount;
  final int favoriteWordCount;
  final int favoriteSentenceCount;
  final List<DailyLearningStatistics> calendarDays;
  final List<DailyLearningStatistics> accuracyTrend;

  int get todayGoalRemaining => today.remainingForGoal(dailyGoal);

  double get todayAccuracy => today.accuracy;
}

void _validateOrderedDays(List<DailyLearningStatistics> days, String name) {
  for (var index = 1; index < days.length; index++) {
    if (days[index - 1].date.compareTo(days[index].date) >= 0) {
      throw ArgumentError.value(days, name, '统计日期必须严格递增且唯一');
    }
  }
}
