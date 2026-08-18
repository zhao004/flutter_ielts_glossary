import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/learning_statistics.dart';
import '../../models/domain/study_hub_run_state.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import 'study_hub_logic.dart';

/// 学习中心：聚合翻卡、选择、拼写和例句填空四种入口。
class StudyHubPage extends StatelessWidget {
  const StudyHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageBackground = theme.appPageBackground;
    final isPageDark =
        ThemeData.estimateBrightnessForColor(pageBackground) == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: pageBackground,
        statusBarIconBrightness: isPageDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isPageDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: pageBackground,
        body: SafeArea(
          bottom: false,
          child: GetBuilder<StudyHubLogic>(
            id: StudyHubLogic.updateId,
            builder: (logic) => _StudyHubBody(logic: logic),
          ),
        ),
      ),
    );
  }
}

final class _StudyHubBody extends StatelessWidget {
  const _StudyHubBody({required this.logic});

  final StudyHubLogic logic;

  @override
  Widget build(BuildContext context) {
    final state = logic.state;
    if (state.phase == StudyHubRunPhase.loading && state.statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.phase == StudyHubRunPhase.error && state.statistics == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: logic.load,
          icon: const Icon(Icons.refresh),
          label: const Text('重新加载学习模式'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: logic.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _Header(statistics: state.statistics),
          const SizedBox(height: 20),
          _ModeCard(
            emoji: '🃏',
            title: '翻卡学习',
            subtitle: '设置词频范围，逐词翻卡评级',
            tone: _ModeCardTone.primary,
            onTap: () => Get.toNamed(AppRouteNames.studyFlashcards),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            emoji: '✅',
            title: '选择题',
            subtitle: '英译中 / 中译英 / 词配例句',
            tone: _ModeCardTone.secondary,
            onTap: () => Get.toNamed(AppRouteNames.practiceQuiz),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            emoji: '✏️',
            title: '拼写练习',
            subtitle: '听提示，拼写正确的单词',
            tone: _ModeCardTone.tertiary,
            onTap: () => Get.toNamed(AppRouteNames.practiceSpelling),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            emoji: '📝',
            title: '例句填空',
            subtitle: '随机例句，补全挖空词形',
            tone: _ModeCardTone.primaryContainer,
            onTap: () => Get.toNamed(AppRouteNames.practiceCloze),
          ),
          const SizedBox(height: 20),
          _StudyStatistics(statistics: state.statistics),
          if (state.phase == StudyHubRunPhase.error) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: logic.load,
              icon: const Icon(Icons.refresh),
              label: const Text('统计刷新失败，点击重试'),
            ),
          ],
        ],
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.statistics});

  final LearningDashboardStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('学习模式', style: Theme.of(context).textTheme.headlineSmall),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '今日已学 '),
                    TextSpan(
                      text: '${statistics?.today.eventCount ?? 0}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' 词'),
                  ],
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ModeCardTone { primary, secondary, tertiary, primaryContainer }

final class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final _ModeCardTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final heroColors = AppTheme.heroColorsOf(theme);
    final start = switch (tone) {
      _ModeCardTone.primary => heroColors.start,
      _ModeCardTone.secondary => scheme.secondaryContainer,
      _ModeCardTone.tertiary => scheme.tertiaryContainer,
      _ModeCardTone.primaryContainer => scheme.primaryContainer,
    };
    final foreground = switch (tone) {
      _ModeCardTone.primary => heroColors.foreground,
      _ModeCardTone.secondary => scheme.onSecondaryContainer,
      _ModeCardTone.tertiary => scheme.onTertiaryContainer,
      _ModeCardTone.primaryContainer => scheme.onPrimaryContainer,
    };
    final end = tone == _ModeCardTone.primary
        ? heroColors.end
        : Color.lerp(start, scheme.surface, 0.14)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          height: 85,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [start, end]),
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: foreground.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StudyStatistics extends StatelessWidget {
  const _StudyStatistics({required this.statistics});

  final LearningDashboardStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = statistics;
    final learned =
        (data?.learningWordCount ?? 0) + (data?.masteredWordCount ?? 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.appCardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: theme.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '学习统计',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.appTextTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(value: learned, label: '词汇总量'),
              ),
              Expanded(
                child: _Stat(value: data?.favoriteWordCount ?? 0, label: '已收藏'),
              ),
              Expanded(
                child: _Stat(value: data?.dueReviewCount ?? 0, label: '待复习'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).appTextTertiary,
          ),
        ),
      ],
    );
  }
}
