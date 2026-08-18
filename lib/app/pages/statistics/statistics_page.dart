import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/domain/learning_statistics.dart';
import '../../models/domain/review_memory_rate.dart';
import '../../models/domain/statistics_report.dart';
import '../../models/domain/statistics_run_state.dart';
import 'statistics_logic.dart';

/// 完整统计页面，展示累计活动、正确率、复习记忆率、趋势和学习日历。
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习统计')),
      body: GetBuilder<StatisticsLogic>(
        id: StatisticsLogic.updateId,
        builder: (logic) =>
            _StatisticsBody(state: logic.state, onRetry: logic.retry),
      ),
    );
  }
}

final class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.state, required this.onRetry});

  final StatisticsRunState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final report = state.report;
    if (report == null && state.phase == StatisticsRunPhase.loading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: '正在加载统计'),
      );
    }
    if (report == null) {
      return _StatisticsFailure(onRetry: onRetry);
    }
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _OverviewCard(report: report),
          const SizedBox(height: 16),
          _MemoryRateSection(report: report),
          const SizedBox(height: 16),
          _AccuracyTrendCard(days: report.dashboard.accuracyTrend),
          const SizedBox(height: 16),
          _CalendarCard(days: report.dashboard.calendarDays),
          if (state.errorCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _StatisticsRefreshError(onRetry: onRetry),
            ),
        ],
      ),
    );
  }
}

final class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.report});

  final StatisticsReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboard = report.dashboard;
    final accuracy = (report.overallAccuracy * 100).round();
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('学习总览', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    label: '学习活动',
                    value: '${report.totalStudiedEvents}',
                    icon: Icons.menu_book_outlined,
                  ),
                ),
                Expanded(
                  child: _OverviewMetric(
                    label: '累计答题',
                    value: '${report.totalAnswered}',
                    icon: Icons.quiz_outlined,
                  ),
                ),
                Expanded(
                  child: _OverviewMetric(
                    label: '正确率',
                    value: '$accuracy%',
                    icon: Icons.track_changes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '连续学习 ${dashboard.currentStreakDays} 天 · 待复习 ${dashboard.dueReviewCount} 个',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

final class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

final class _MemoryRateSection extends StatelessWidget {
  const _MemoryRateSection({required this.report});

  final StatisticsReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('复习记忆率', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MemoryRateCard(
                label: '近 7 天',
                rate: report.sevenDayMemoryRate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MemoryRateCard(
                label: '近 30 天',
                rate: report.thirtyDayMemoryRate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MemoryRateCard(
                label: '全部',
                rate: report.allTimeMemoryRate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _MemoryRateCard extends StatelessWidget {
  const _MemoryRateCard({required this.label, required this.rate});

  final String label;
  final ReviewMemoryRate rate;

  @override
  Widget build(BuildContext context) {
    final percentage = (rate.value * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Text('$percentage%', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              '${rate.completedReviews} 次',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _AccuracyTrendCard extends StatelessWidget {
  const _AccuracyTrendCard({required this.days});

  final List<DailyLearningStatistics> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = days.length > 14 ? days.sublist(days.length - 14) : days;
    final maxValue = visible.fold<double>(1, (max, day) {
      final value = day.answeredCount == 0 ? 0.0 : day.accuracy;
      return value > max ? value : max;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('正确率趋势', style: theme.textTheme.titleMedium),
            const SizedBox(height: 14),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < visible.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                        child: _TrendBar(
                          day: visible[index],
                          maxValue: maxValue,
                        ),
                      ),
                    ),
                  if (visible.isEmpty)
                    const Expanded(child: Center(child: Text('暂无答题趋势'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.day, required this.maxValue});

  final DailyLearningStatistics day;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final accuracy = day.answeredCount == 0 ? 0.0 : day.accuracy;
    final height = accuracy == 0 ? 4.0 : 12 + accuracy / maxValue * 78;
    return Tooltip(
      message: '${day.date}: ${(accuracy * 100).round()}%',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: height,
                constraints: const BoxConstraints(minWidth: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${day.date.day}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

final class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.days});

  final List<DailyLearningStatistics> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = days.length > 84 ? days.sublist(days.length - 84) : days;
    final maxCount = visible.fold<int>(
      1,
      (max, day) => day.eventCount > max ? day.eventCount : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('学习日历', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('最近 ${visible.length} 天', style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final day in visible)
                  Tooltip(
                    message: '${day.date}: ${day.eventCount} 项',
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: day.eventCount == 0
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primary.withValues(
                                alpha: 0.25 + day.eventCount / maxCount * 0.75,
                              ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatisticsFailure extends StatelessWidget {
  const _StatisticsFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('统计加载失败'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

final class _StatisticsRefreshError extends StatelessWidget {
  const _StatisticsRefreshError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            const Expanded(child: Text('刷新失败，当前仍显示上一次统计。')),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
