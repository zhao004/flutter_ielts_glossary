import '../models/domain/statistics_report.dart';
import '../models/domain/learning_statistics.dart';
import '../models/domain/review_memory_rate.dart';
import 'learning_repository.dart';
import 'statistics_report_repository.dart';
import 'statistics_repository.dart';

/// 并行组合学习趋势和 7 天、30 天、全部时间的真实复习记忆率。
final class LocalStatisticsReportRepository
    implements StatisticsReportRepository {
  const LocalStatisticsReportRepository(
    this._statisticsRepository,
    this._learningRepository,
  );

  final StatisticsRepository _statisticsRepository;
  final LearningRepository _learningRepository;

  @override
  Future<StatisticsReport> loadReport({
    int calendarDays = 365,
    int trendDays = 30,
  }) async {
    if (calendarDays <= 0 || calendarDays > 3660) {
      throw ArgumentError.value(
        calendarDays,
        'calendarDays',
        '统计天数必须在 1-3660 之间',
      );
    }
    if (trendDays <= 0 || trendDays > calendarDays) {
      throw ArgumentError.value(
        trendDays,
        'trendDays',
        '趋势天数必须在 1-$calendarDays 之间',
      );
    }
    final results = await Future.wait<Object>([
      _statisticsRepository.loadDashboard(
        calendarDays: calendarDays,
        trendDays: trendDays,
      ),
      _learningRepository.getReviewMemoryRate(window: const Duration(days: 7)),
      _learningRepository.getReviewMemoryRate(window: const Duration(days: 30)),
      _learningRepository.getReviewMemoryRate(),
    ]);
    return StatisticsReport(
      dashboard: results[0] as LearningDashboardStatistics,
      sevenDayMemoryRate: results[1] as ReviewMemoryRate,
      thirtyDayMemoryRate: results[2] as ReviewMemoryRate,
      allTimeMemoryRate: results[3] as ReviewMemoryRate,
    );
  }
}
