import 'learning_statistics.dart';
import 'review_memory_rate.dart';

/// 完整统计页使用的快照，组合首页趋势和多时间窗复习记忆率。
final class StatisticsReport {
  StatisticsReport({
    required this.dashboard,
    required this.sevenDayMemoryRate,
    required this.thirtyDayMemoryRate,
    required this.allTimeMemoryRate,
  });

  final LearningDashboardStatistics dashboard;
  final ReviewMemoryRate sevenDayMemoryRate;
  final ReviewMemoryRate thirtyDayMemoryRate;
  final ReviewMemoryRate allTimeMemoryRate;

  int get totalStudiedEvents =>
      dashboard.calendarDays.fold(0, (sum, day) => sum + day.eventCount);

  int get totalAnswered =>
      dashboard.calendarDays.fold(0, (sum, day) => sum + day.answeredCount);

  int get totalCorrect =>
      dashboard.calendarDays.fold(0, (sum, day) => sum + day.correctCount);

  double get overallAccuracy =>
      totalAnswered == 0 ? 0 : totalCorrect / totalAnswered;
}
