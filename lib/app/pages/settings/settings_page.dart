import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/settings_about_info.dart';
import '../../models/domain/settings_run_state.dart';
import '../../models/domain/statistics_report.dart';
import '../../models/domain/statistics_run_state.dart';
import '../../models/domain/user_data_reset_state.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_controller.dart';
import '../shell/main_shell_controller.dart';
import '../statistics/statistics_logic.dart';
import 'settings_logic.dart';
import 'user_data_reset_logic.dart';

/// “我的”主页面，组合学习概览、个性化设置与受保护的数据管理入口。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroColors = AppTheme.heroColorsOf(theme);
    final isPrimaryDark =
        ThemeData.estimateBrightnessForColor(heroColors.start) ==
        Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isPrimaryDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isPrimaryDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        body: GetBuilder<SettingsLogic>(
          id: SettingsLogic.updateId,
          builder: (settingsLogic) {
            final statisticsAvailable = Get.isRegistered<StatisticsLogic>();
            if (!statisticsAvailable) {
              return _buildBody(settingsLogic, null, null);
            }
            return GetBuilder<StatisticsLogic>(
              id: StatisticsLogic.updateId,
              builder: (statisticsLogic) => _buildBody(
                settingsLogic,
                statisticsLogic.state,
                statisticsLogic.load,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    SettingsLogic logic,
    StatisticsRunState? statisticsState,
    Future<void> Function()? reloadStatistics,
  ) {
    final state = logic.state;
    if (state.phase == SettingsRunPhase.error && state.settings == null) {
      return _ProfileFailure(onRetry: logic.retry);
    }
    if (state.settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _ProfileContent(
      state: state,
      statistics: statisticsState?.report,
      aboutInfo: logic.aboutInfo,
      onRefresh: () async {
        await Future.wait([
          logic.load(),
          if (reloadStatistics != null) reloadStatistics(),
        ]);
      },
      onUpdate: ({int? dailyGoal, AppThemePreference? themePreference}) async {
        await logic.updateSettings(
          dailyGoal: dailyGoal,
          themePreference: themePreference,
        );
        final saved = logic.state.settings;
        if (saved != null && Get.isRegistered<AppThemeController>()) {
          Get.find<AppThemeController>().apply(
            themePreference: saved.themePreference,
            accentPreference: saved.accentPreference,
          );
        }
      },
      onReset: _confirmAndReset,
    );
  }

  Future<void> _confirmAndReset() async {
    final theme = Theme.of(context);
    if (!Get.isRegistered<UserDataResetLogic>()) {
      _showMessage('当前环境未配置保护备份，无法清除数据');
      return;
    }
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除学习数据？'),
        content: const Text('将清除学习记录、收藏、练习记录和个性化设置。内置词库不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (firstConfirmed != true || !mounted) {
      return;
    }
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('最后确认'),
        content: const Text('清除前会自动保存一份保护备份。操作完成后，当前学习进度将从零开始。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('返回'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
    if (finalConfirmed != true || !mounted) {
      return;
    }
    final resetLogic = Get.find<UserDataResetLogic>();
    await resetLogic.reset();
    if (!mounted) {
      return;
    }
    if (resetLogic.state.phase != UserDataResetPhase.success) {
      _showMessage('保护备份或数据清除失败，原有数据未被主动忽略');
      return;
    }
    final defaults = AppSettingsState.defaults();
    if (Get.isRegistered<AppThemeController>()) {
      Get.find<AppThemeController>().apply(
        themePreference: defaults.themePreference,
        accentPreference: defaults.accentPreference,
      );
    }
    // 数据已清空，回到外壳首页并重建各一级页，使统计、收藏等恢复到空态。
    Get.find<MainShellController>().select(MainShellController.homeIndex);
    Get.offAllNamed(AppRouteNames.home);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.state,
    required this.statistics,
    required this.aboutInfo,
    required this.onRefresh,
    required this.onUpdate,
    required this.onReset,
  });

  final SettingsRunState state;
  final StatisticsReport? statistics;
  final SettingsAboutInfo aboutInfo;
  final Future<void> Function() onRefresh;
  final Future<void> Function({
    int? dailyGoal,
    AppThemePreference? themePreference,
  })
  onUpdate;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final settings = state.settings!;
    final dashboard = statistics?.dashboard;
    final totalEvents = statistics?.totalStudiedEvents ?? 0;
    final favorites =
        (dashboard?.favoriteWordCount ?? 0) +
        (dashboard?.favoriteSentenceCount ?? 0);
    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: MediaQuery.paddingOf(context).top + 24,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              streak: dashboard?.currentStreakDays ?? 0,
              totalEvents: totalEvents,
              todayEvents: dashboard?.today.eventCount ?? 0,
              accuracy: statistics?.overallAccuracy ?? 0,
              favorites: favorites,
              isUpdating: state.isUpdating,
              themePreference: settings.themePreference,
              onThemePressed: () => _cycleTheme(settings.themePreference),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _ProfileShortcutCard(
                  favoriteWords: dashboard?.favoriteWordCount ?? 0,
                  favoriteSentences: dashboard?.favoriteSentenceCount ?? 0,
                  totalEvents: totalEvents,
                  totalAnswered: statistics?.totalAnswered ?? 0,
                ),
                const SizedBox(height: 12),
                _AppearanceCard(
                  settings: settings,
                  enabled: !state.isUpdating,
                  onUpdate: onUpdate,
                ),
                const SizedBox(height: 12),
                _LearningSettingsCard(
                  settings: settings,
                  enabled: !state.isUpdating,
                  onUpdate: onUpdate,
                ),
                const SizedBox(height: 12),
                _DataManagementCard(onReset: onReset),
                const SizedBox(height: 12),
                _AboutCard(info: aboutInfo),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _cycleTheme(AppThemePreference current) {
    final next = switch (current) {
      AppThemePreference.system => AppThemePreference.light,
      AppThemePreference.light => AppThemePreference.dark,
      AppThemePreference.dark => AppThemePreference.system,
    };
    onUpdate(themePreference: next);
  }
}

final class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.streak,
    required this.totalEvents,
    required this.todayEvents,
    required this.accuracy,
    required this.favorites,
    required this.isUpdating,
    required this.themePreference,
    required this.onThemePressed,
  });

  final int streak;
  final int totalEvents;
  final int todayEvents;
  final double accuracy;
  final int favorites;
  final bool isUpdating;
  final AppThemePreference themePreference;
  final VoidCallback onThemePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroColors = AppTheme.heroColorsOf(theme);
    final onPrimary = heroColors.foreground;
    return Container(
      key: const ValueKey('settings-profile-hero'),
      height: 238 + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        32,
      ),
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
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: const Center(
                  child: Text('🦉', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习者',
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '坚持 $streak 天 · $totalEvents 词',
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.72),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: isUpdating ? null : onThemePressed,
                tooltip: '切换显示模式',
                style: IconButton.styleFrom(
                  backgroundColor: onPrimary.withValues(alpha: 0.14),
                  foregroundColor: onPrimary,
                  fixedSize: const Size(40, 40),
                ),
                icon: Icon(switch (themePreference) {
                  AppThemePreference.system => Icons.brightness_auto_outlined,
                  AppThemePreference.light => Icons.light_mode_outlined,
                  AppThemePreference.dark => Icons.dark_mode_outlined,
                }, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroMetric(value: '$streak', label: '连击', foreground: onPrimary),
              const SizedBox(width: 8),
              _HeroMetric(
                value: '$todayEvents',
                label: '今天学',
                foreground: onPrimary,
              ),
              const SizedBox(width: 8),
              _HeroMetric(
                value: '${(accuracy * 100).round()}%',
                label: '正确率',
                foreground: onPrimary,
              ),
              const SizedBox(width: 8),
              _HeroMetric(
                value: '$favorites',
                label: '收藏',
                foreground: onPrimary,
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
    required this.value,
    required this.label,
    required this.foreground,
  });

  final String value;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProfileShortcutCard extends StatelessWidget {
  const _ProfileShortcutCard({
    required this.favoriteWords,
    required this.favoriteSentences,
    required this.totalEvents,
    required this.totalAnswered,
  });

  final int favoriteWords;
  final int favoriteSentences;
  final int totalEvents;
  final int totalAnswered;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ShortcutRow(
            icon: '⭐',
            title: '我的收藏',
            subtitle: '$favoriteWords 词 · $favoriteSentences 句',
            onTap: () => Get.toNamed<void>(AppRouteNames.favorites),
          ),
          const Divider(height: 1),
          _ShortcutRow(
            icon: '📊',
            title: '学习统计',
            subtitle: '累计 $totalEvents 词 · $totalAnswered 题',
            onTap: () => Get.toNamed<void>(AppRouteNames.statistics),
          ),
        ],
      ),
    );
  }
}

final class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).appTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).appTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.settings,
    required this.enabled,
    required this.onUpdate,
  });

  final AppSettingsState settings;
  final bool enabled;
  final Future<void> Function({
    int? dailyGoal,
    AppThemePreference? themePreference,
  })
  onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('外观'),
          const SizedBox(height: 16),
          InkWell(
            onTap: enabled
                ? () => Get.toNamed(AppRouteNames.colorSchemes)
                : null,
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.swatchFor(settings.accentPreference),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '主题配色',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.accentPreference.displayLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.appTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.appTextTertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Text('显示模式', style: theme.textTheme.bodySmall),
              const Spacer(),
              _CompactSegment<AppThemePreference>(
                values: AppThemePreference.values,
                selected: settings.themePreference,
                label: (value) => switch (value) {
                  AppThemePreference.system => '系统',
                  AppThemePreference.light => '浅色',
                  AppThemePreference.dark => '深色',
                },
                enabled: enabled,
                onSelected: (value) => onUpdate(themePreference: value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _LearningSettingsCard extends StatelessWidget {
  const _LearningSettingsCard({
    required this.settings,
    required this.enabled,
    required this.onUpdate,
  });

  final AppSettingsState settings;
  final bool enabled;
  final Future<void> Function({
    int? dailyGoal,
    AppThemePreference? themePreference,
  })
  onUpdate;

  @override
  Widget build(BuildContext context) {
    const goals = [5, 10, 20, 50];
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('学习设置'),
          const SizedBox(height: 19),
          InkWell(
            onTap: enabled
                ? () => Get.toNamed(AppRouteNames.speechServices)
                : null,
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Text('🎙️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '语音服务配置',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '配置第三方 TTS 和发音评测',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).appTextTertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).appTextTertiary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text('每日目标：', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${settings.dailyGoal} 词',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final goal in goals) ...[
                Expanded(
                  child: _GoalButton(
                    goal: goal,
                    selected: settings.dailyGoal == goal,
                    enabled: enabled,
                    onPressed: () => onUpdate(dailyGoal: goal),
                  ),
                ),
                if (goal != goals.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: enabled
                  ? () => _showCustomGoal(context, settings.dailyGoal)
                  : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('自定义目标'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomGoal(BuildContext context, int current) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _CustomGoalDialog(initialGoal: current),
    );
    if (result != null) {
      await onUpdate(dailyGoal: result);
    }
  }
}

final class _CustomGoalDialog extends StatefulWidget {
  const _CustomGoalDialog({required this.initialGoal});

  final int initialGoal;

  @override
  State<_CustomGoalDialog> createState() => _CustomGoalDialogState();
}

final class _CustomGoalDialogState extends State<_CustomGoalDialog> {
  // 控制器随对话框卸载，覆盖路由的退出动画阶段。
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialGoal}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自定义每日目标'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 3,
        decoration: const InputDecoration(
          labelText: '每天学习的单词数',
          helperText: '范围 1-500',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value == null ||
                value < AppSettingsState.minimumDailyGoal ||
                value > AppSettingsState.maximumDailyGoal) {
              return;
            }
            Navigator.pop(context, value);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

final class _GoalButton extends StatelessWidget {
  const _GoalButton({
    required this.goal,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final int goal;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: selected
          ? FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: Text('$goal词'),
            )
          : OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: Text('$goal词'),
            ),
    );
  }
}

final class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({required this.onReset});

  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SectionLabel('数据管理'),
            ),
          ),
          _ManagementRow(
            icon: '📦',
            title: '数据备份',
            subtitle: '导出、导入与查看保护备份',
            onTap: () => Get.toNamed(AppRouteNames.dataBackup),
          ),
          const Divider(height: 1, indent: 52),
          _ManagementRow(
            icon: '🗑️',
            title: '清除学习数据',
            subtitle: '先保存保护备份，再清除个人记录',
            destructive: true,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

final class _ManagementRow extends StatelessWidget {
  const _ManagementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: destructive ? Theme.of(context).appError : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).appTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).appTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

final class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.info});

  final SettingsAboutInfo info;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showDialog(context),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Text('📚', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('关于词库', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '应用 ${info.appVersion} · 词库 ${info.contentVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).appTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).appTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('关于词库'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(
            child: Text(
              '应用 ${info.appVersion}\n'
              '词库 ${info.contentVersion}\n\n'
              '${info.wordCount} 个单词 · ${info.sentenceCount} 条例句\n'
              '${info.sourceRepository}@${info.sourceRevision}\n\n'
              '${info.licenseNotice}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

final class _CompactSegment<T> extends StatelessWidget {
  const _CompactSegment({
    required this.values,
    required this.selected,
    required this.label,
    required this.enabled,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final bool enabled;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.appSubtleSurface,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            InkWell(
              onTap: enabled ? () => onSelected(value) : null,
              borderRadius: BorderRadius.circular(AppRadii.medium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: value == selected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
                child: Center(
                  child: Text(
                    label(value),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: value == selected
                          ? theme.colorScheme.onPrimary
                          : theme.appTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.appCardSurface,
      elevation: isDark ? 0 : 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: theme.appBorder),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).appTextTertiary,
      ),
    );
  }
}

final class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            const Text('设置加载失败'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
