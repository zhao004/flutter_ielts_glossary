import '../models/domain/learning_statistics.dart';

/// 首页学习数据和统计趋势的领域接口。
abstract interface class StatisticsRepository {
  Future<LearningDashboardStatistics> loadDashboard({
    int calendarDays = 365,
    int trendDays = 30,
  });
}
