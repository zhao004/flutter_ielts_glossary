import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/home_run_state.dart';
import '../../models/domain/learning_statistics.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import 'home_logic.dart';

/// 首页：展示今日目标、学习趋势、热力图和四个快速入口。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroColors = AppTheme.heroColorsOf(theme);
    final isHeroDark =
        ThemeData.estimateBrightnessForColor(heroColors.start) ==
        Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isHeroDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isHeroDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        body: GetBuilder<HomeLogic>(
          id: HomeLogic.stateUpdateId,
          builder: (logic) => _HomeBody(logic: logic),
        ),
      ),
    );
  }
}

final class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.logic});

  final HomeLogic logic;

  @override
  Widget build(BuildContext context) {
    final state = logic.state;
    final statistics = state.statistics;
    if (state.phase == HomeRunPhase.loading && statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.phase == HomeRunPhase.error && statistics == null) {
      return _HomeFailure(onRetry: logic.retry);
    }
    return RefreshIndicator(
      onRefresh: logic.load,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HomeHero(statistics: statistics),
          _TodayGoal(statistics: statistics),
          _WeeklyProgress(statistics: statistics),
          _QuickStarts(),
          _LearningHeatmap(statistics: statistics),
          if (state.phase == HomeRunPhase.error)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _InlineFailure(onRetry: logic.retry),
            ),
        ],
      ),
    );
  }
}

final class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.statistics});

  final LearningDashboardStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroColors = AppTheme.heroColorsOf(theme);
    final topInset = MediaQuery.paddingOf(context).top;
    final data = statistics;
    final today = data?.today.eventCount ?? 0;
    final accuracy = data == null ? 0 : (data.todayAccuracy * 100).round();
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8 + topInset, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroColors.start, heroColors.end],
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(DateTime.now()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: heroColors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_greeting(DateTime.now().hour)} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: heroColors.foreground,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: heroColors.foreground.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🦉', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: '🔥',
                  value: '${data?.currentStreakDays ?? 0}天',
                  label: '连续学习',
                  foreground: heroColors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  icon: '📚',
                  value: '$today词',
                  label: '今日学习',
                  foreground: heroColors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  icon: '🎯',
                  value: '$accuracy%',
                  label: '正确率',
                  foreground: heroColors.foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.foreground,
  });

  final String icon;
  final String value;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      height: 93 + ((textScale - 1).clamp(0, 1) * 70),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20, height: 1.4)),
          const Spacer(),
          Text(
            value,
            style: style.titleMedium?.copyWith(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: style.labelSmall?.copyWith(
              color: foreground.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

final class _TodayGoal extends StatelessWidget {
  const _TodayGoal({required this.statistics});

  final LearningDashboardStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = statistics;
    final goal = data?.dailyGoal ?? 20;
    final completed = data?.today.eventCount ?? 0;
    final progress = goal == 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);
    final remaining = math.max(goal - completed, 0);
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.appCardSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('今日目标', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$completed/$goal 词',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: theme.appSubtleSurface,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  remaining == 0 ? '目标已完成' : '还差 $remaining 词完成目标',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appTextTertiary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appTextTertiary,
                    fontSize: 11,
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

final class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.statistics});

  final LearningDashboardStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _lastSevenDays(statistics?.calendarDays ?? const []);
    final maxCount = days.fold<int>(
      1,
      (maxValue, day) => math.max(maxValue, day.eventCount),
    );
    final total = days.fold<int>(0, (sum, day) => sum + day.eventCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '本周进度',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.appTextSecondary,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  '$total 词',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 68,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < days.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                        child: _DayBar(
                          day: days[index],
                          maxCount: maxCount,
                          isToday: index == days.length - 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.maxCount,
    required this.isToday,
  });

  final DailyLearningStatistics day;
  final int maxCount;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = day.eventCount == 0 ? 0.04 : day.eventCount / maxCount;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: ratio.clamp(0.04, 1.0),
              widthFactor: 0.82,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.72),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _weekdayLabel(
            DateTime(day.date.year, day.date.month, day.date.day).weekday,
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.appTextTertiary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

final class _QuickStarts extends StatelessWidget {
  const _QuickStarts();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速开始',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.appTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickStartTile(
                  emoji: '🃏',
                  label: '翻卡学习',
                  color: theme.colorScheme.primaryContainer,
                  foreground: theme.colorScheme.onPrimaryContainer,
                  onTap: () => Get.toNamed(AppRouteNames.studyFlashcards),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStartTile(
                  emoji: '✅',
                  label: '选择题',
                  color: theme.colorScheme.secondaryContainer,
                  foreground: theme.colorScheme.onSecondaryContainer,
                  onTap: () => Get.toNamed(AppRouteNames.practiceQuiz),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickStartTile(
                  emoji: '✏️',
                  label: '拼写练习',
                  color: theme.colorScheme.tertiaryContainer,
                  foreground: theme.colorScheme.onTertiaryContainer,
                  onTap: () => Get.toNamed(AppRouteNames.practiceSpelling),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStartTile(
                  emoji: '📝',
                  label: '例句填空',
                  color: theme.colorScheme.surfaceContainerHighest,
                  foreground: theme.colorScheme.onSurface,
                  onTap: () => Get.toNamed(AppRouteNames.practiceCloze),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _QuickStartTile extends StatelessWidget {
  const _QuickStartTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.foreground,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LearningHeatmap extends StatelessWidget {
  const _LearningHeatmap({required this.statistics});

  final LearningDashboardStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _lastThirtyFiveDays(statistics?.calendarDays ?? const []);
    final maxCount = days.fold<int>(
      1,
      (maxValue, day) => math.max(maxValue, day.eventCount),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '学习热力图',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.appTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '少',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.appTextTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                for (final opacity in const [0.08, 0.28, 0.52, 0.82])
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: opacity,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  '多',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.appTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HeatmapGrid(days: days, maxCount: maxCount),
          ],
        ),
      ),
    );
  }
}

final class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days, required this.maxCount});

  final List<DailyLearningStatistics> days;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final values = List<DailyLearningStatistics?>.filled(35, null);
    final start = math.max(0, 35 - days.length);
    for (
      var index = 0;
      index < days.length && start + index < values.length;
      index++
    ) {
      values[start + index] = days[index];
    }
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 26),
            for (final label in const ['6月', '', '7月', '', '8月'])
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).appTextTertiary,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < 5; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: row.isEven
                      ? Text(
                          row == 0 ? '周一' : '周三',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).appTextTertiary,
                                fontSize: 9,
                              ),
                        )
                      : const SizedBox.shrink(),
                ),
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: _HeatCell(
                        day: values[row * 7 + column],
                        maxCount: maxCount,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.day, required this.maxCount});

  final DailyLearningStatistics? day;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final count = day?.eventCount ?? 0;
    final opacity = count == 0
        ? 0.04
        : (0.18 + 0.82 * count / maxCount).clamp(0.18, 1.0);
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

final class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).appCardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Theme.of(context).appBorder),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

final class _HomeFailure extends StatelessWidget {
  const _HomeFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text('首页数据加载失败'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('刷新失败，仍显示上一次数据。')),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}

List<DailyLearningStatistics> _lastSevenDays(
  List<DailyLearningStatistics> days,
) {
  if (days.length <= 7) {
    return days;
  }
  return days.sublist(days.length - 7);
}

List<DailyLearningStatistics> _lastThirtyFiveDays(
  List<DailyLearningStatistics> days,
) {
  if (days.length <= 35) {
    return days;
  }
  return days.sublist(days.length - 35);
}

String _weekdayLabel(int weekday) =>
    '周${const ['一', '二', '三', '四', '五', '六', '日'][weekday - 1]}';

String _formatDate(DateTime date) {
  final weekday = _weekdayLabel(date.weekday);
  return '${date.year}年${date.month}月${date.day}日$weekday';
}

String _greeting(int hour) {
  if (hour < 6) return '夜深了';
  if (hour < 12) return '早上好，继续加油';
  if (hour < 18) return '你好，继续加油';
  return '晚上好，继续加油';
}
