import '../models/domain/statistics_report.dart';

/// 完整统计页的跨 Repository 聚合边界。
abstract interface class StatisticsReportRepository {
  Future<StatisticsReport> loadReport({
    int calendarDays = 365,
    int trendDays = 30,
  });
}
