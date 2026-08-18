import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/question_config.dart';
import '../../models/domain/review_queue.dart';
import '../../models/domain/review_rating.dart';
import '../../models/domain/review_run_state.dart';
import '../../services/review/review_scheduler.dart';
import '../../theme/app_theme.dart';
import '../practice/practice_binding.dart';
import '../practice/practice_page.dart';
import 'review_session_logic.dart';

/// 到期复习页面，负责队列加载、翻卡、自评、收藏和发音反馈。
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

final class _ReviewPageState extends State<ReviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Get.isRegistered<ReviewSessionLogic>()) {
        Get.find<ReviewSessionLogic>().start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        body: GetBuilder<ReviewSessionLogic>(
          id: ReviewSessionLogic.contentUpdateId,
          builder: (logic) {
            final state = logic.state;
            if (state.phase == ReviewRunPhase.reviewing) {
              return _ReviewQueuePage(
                state: state,
                onStart: () {
                  Get.to<void>(() => const ReviewSessionPage());
                },
              );
            }
            return _ReviewShell(
              state: state,
              child: _ReviewBody(
                state: state,
                onStart: logic.start,
                onFlip: logic.flip,
                onSubmit: logic.submit,
                onPlayPronunciation: logic.playCurrentPronunciation,
                onStopPronunciation: logic.stopPronunciation,
                onRetryMemoryRate: logic.retryMemoryRate,
                onDismissReinforcement: logic.dismissReinforcement,
                onStartReinforcement: (prompt) =>
                    _startReinforcement(logic, prompt),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 复习会话页面，复用队列页已加载的 Logic 展示翻卡和结果状态。
class ReviewSessionPage extends StatelessWidget {
  const ReviewSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        body: GetBuilder<ReviewSessionLogic>(
          id: ReviewSessionLogic.contentUpdateId,
          builder: (logic) {
            final state = logic.state;
            return _ReviewShell(
              state: state,
              onBack: () => Get.back<void>(),
              child: _ReviewBody(
                state: state,
                onStart: logic.start,
                onFlip: logic.flip,
                onSubmit: logic.submit,
                onPlayPronunciation: logic.playCurrentPronunciation,
                onStopPronunciation: logic.stopPronunciation,
                onRetryMemoryRate: logic.retryMemoryRate,
                onDismissReinforcement: logic.dismissReinforcement,
                onStartReinforcement: (prompt) =>
                    _startReinforcement(logic, prompt),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 从复习会话启动单词定向的单题拼写巩固，并保留当前复习页在返回栈中。
void _startReinforcement(
  ReviewSessionLogic logic,
  ReviewReinforcementPrompt prompt,
) {
  logic.dismissReinforcement();
  Get.to<void>(
    () => const PracticePage(autoStart: true),
    binding: PracticeBinding(
      initialConfig: QuestionConfig.targetedSpelling(wordId: prompt.wordId),
    ),
  );
}

final class _ReviewQueuePage extends StatelessWidget {
  const _ReviewQueuePage({required this.state, required this.onStart});

  final ReviewRunState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final items = state.queue?.items ?? const <ReviewQueueItem>[];
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18, 17 + topInset, 18, 16),
              color: Theme.of(context).appCardSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '复习',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '今日待复习 ${items.length} 个单词',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).appTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 13, 16, 96 + bottomInset),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _ReviewQueueCard(item: items[index]),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16 + bottomInset,
          child: FloatingActionButton.extended(
            key: const ValueKey('review-start-fab'),
            heroTag: 'review-start-fab',
            tooltip: '开始复习',
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('开始复习'),
          ),
        ),
      ],
    );
  }
}

final class _ReviewQueueCard extends StatelessWidget {
  const _ReviewQueueCard({required this.item});

  final ReviewQueueItem item;

  @override
  Widget build(BuildContext context) {
    final learning = item.learningState;
    final rate = learning.studiedCount == 0
        ? 0
        : (learning.correctCount / learning.studiedCount * 100).round();
    final interval = const ReviewScheduler().intervalForLevel(
      learning.masteryLevel,
    );
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.word.word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '第${learning.studiedCount}次',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.word.translationZh ?? '暂无释义',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.appTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '间隔${_intervalText(interval)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.appTextTertiary,
                    ),
                  ),
                  Text(
                    '记忆率 $rate%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: theme.appTextTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 对齐 402px Figma 画板的复习提示态局部尺寸。
abstract final class _ReviewLayout {
  static const double horizontalPadding = 16;
  static const double cardHeight = 260;
  static const double cardMaxWidth = 370;
  static const double cardRadius = 24;
  static const double progressHeight = 6;
  static const Duration flipDuration = Duration(milliseconds: 280);
}

final class _ReviewShell extends StatelessWidget {
  const _ReviewShell({required this.state, required this.child, this.onBack});

  final ReviewRunState state;
  final Widget child;
  final VoidCallback? onBack;

  bool get _showsProgress => switch (state.phase) {
    ReviewRunPhase.reviewing ||
    ReviewRunPhase.submitting ||
    ReviewRunPhase.completing => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final counter = _showsProgress && state.totalCount > 0
        ? '${state.currentIndex + 1}/${state.totalCount}'
        : null;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _ReviewLayout.horizontalPadding,
              16 + topInset,
              _ReviewLayout.horizontalPadding,
              0,
            ),
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: '返回复习列表',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  if (counter != null)
                    Text(
                      counter,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.appTextTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_showsProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _ReviewLayout.horizontalPadding,
                0,
                _ReviewLayout.horizontalPadding,
                16,
              ),
              child: _ReviewProgress(value: state.progress),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

final class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceContainerHighest;
    return Semantics(
      label: '复习进度',
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_ReviewLayout.progressHeight),
        child: LinearProgressIndicator(
          value: value,
          minHeight: _ReviewLayout.progressHeight,
          color: theme.colorScheme.primary,
          backgroundColor: background,
        ),
      ),
    );
  }
}

final class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.state,
    required this.onStart,
    required this.onFlip,
    required this.onSubmit,
    required this.onPlayPronunciation,
    required this.onStopPronunciation,
    required this.onRetryMemoryRate,
    required this.onDismissReinforcement,
    required this.onStartReinforcement,
  });

  final ReviewRunState state;
  final Future<void> Function({int limit}) onStart;
  final VoidCallback onFlip;
  final Future<void> Function(ReviewRating rating) onSubmit;
  final Future<void> Function({PronunciationAccent? accent})
  onPlayPronunciation;
  final Future<void> Function() onStopPronunciation;
  final Future<void> Function() onRetryMemoryRate;
  final VoidCallback onDismissReinforcement;
  final ValueChanged<ReviewReinforcementPrompt> onStartReinforcement;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case ReviewRunPhase.idle:
      case ReviewRunPhase.preparing:
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: '正在加载复习队列'),
        );
      case ReviewRunPhase.empty:
        return _ReviewEmpty(onStart: onStart);
      case ReviewRunPhase.error:
        return _ReviewFailure(onRetry: onStart);
      case ReviewRunPhase.completed:
        return _ReviewCompleted(
          state: state,
          onStart: onStart,
          onRetryMemoryRate: onRetryMemoryRate,
          onDismissReinforcement: onDismissReinforcement,
          onStartReinforcement: onStartReinforcement,
        );
      case ReviewRunPhase.reviewing:
      case ReviewRunPhase.submitting:
      case ReviewRunPhase.completing:
        return _ReviewSessionBody(
          state: state,
          onFlip: onFlip,
          onSubmit: onSubmit,
          onPlayPronunciation: onPlayPronunciation,
          onStopPronunciation: onStopPronunciation,
          onDismissReinforcement: onDismissReinforcement,
          onStartReinforcement: onStartReinforcement,
        );
    }
  }
}

final class _ReviewEmpty extends StatelessWidget {
  const _ReviewEmpty({required this.onStart});

  final Future<void> Function({int limit}) onStart;

  @override
  Widget build(BuildContext context) {
    return _ReviewStateMessage(
      icon: Icons.event_available_outlined,
      title: '暂时没有到期单词',
      message: '完成学习后，单词会按照复习计划再次出现在这里。',
      action: FilledButton.icon(
        onPressed: () => onStart(),
        icon: const Icon(Icons.refresh),
        label: const Text('重新检查'),
      ),
    );
  }
}

final class _ReviewFailure extends StatelessWidget {
  const _ReviewFailure({required this.onRetry});

  final Future<void> Function({int limit}) onRetry;

  @override
  Widget build(BuildContext context) {
    return _ReviewStateMessage(
      icon: Icons.error_outline,
      title: '复习队列加载失败',
      message: '本次没有修改学习记录，可以安全重试。',
      action: FilledButton.icon(
        onPressed: () => onRetry(),
        icon: const Icon(Icons.refresh),
        label: const Text('重试'),
      ),
    );
  }
}

final class _ReviewStateMessage extends StatelessWidget {
  const _ReviewStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _ReviewLayout.cardMaxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

final class _ReviewSessionBody extends StatelessWidget {
  const _ReviewSessionBody({
    required this.state,
    required this.onFlip,
    required this.onSubmit,
    required this.onPlayPronunciation,
    required this.onStopPronunciation,
    required this.onDismissReinforcement,
    required this.onStartReinforcement,
  });

  final ReviewRunState state;
  final VoidCallback onFlip;
  final Future<void> Function(ReviewRating rating) onSubmit;
  final Future<void> Function({PronunciationAccent? accent})
  onPlayPronunciation;
  final Future<void> Function() onStopPronunciation;
  final VoidCallback onDismissReinforcement;
  final ValueChanged<ReviewReinforcementPrompt> onStartReinforcement;

  @override
  Widget build(BuildContext context) {
    final item = state.currentItem;
    if (item == null) {
      return const Center(child: Text('当前没有可复习的单词。'));
    }
    final theme = Theme.of(context);
    final busy = state.phase != ReviewRunPhase.reviewing;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _ReviewLayout.horizontalPadding,
        0,
        _ReviewLayout.horizontalPadding,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.missingWordIds.isNotEmpty) ...[
            Material(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '部分历史记录对应的词条已不在当前词库中，已跳过这些词条。',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.reinforcementPrompt case final prompt?) ...[
            _ReviewReinforcementNotice(
              prompt: prompt,
              onDismiss: onDismissReinforcement,
              onStart: () => onStartReinforcement(prompt),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _ReviewLayout.cardMaxWidth,
              ),
              child: SizedBox(
                height: _ReviewLayout.cardHeight,
                child: _ReviewFlipCard(
                  isFlipped: state.isFlipped,
                  enabled: !busy,
                  onTap: onFlip,
                  front: _ReviewCardFront(
                    item: item,
                    state: state,
                    enabled: !busy,
                    onPlay: onPlayPronunciation,
                    onStop: onStopPronunciation,
                  ),
                  back: _ReviewCardBack(item: item),
                ),
              ),
            ),
          ),
          if (!state.isFlipped) ...[
            const SizedBox(height: 16),
            Text(
              '点击卡片查看释义后作答',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appTextTertiary,
              ),
            ),
          ],
          if (state.isFlipped) ...[
            const SizedBox(height: 16),
            if (state.errorCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _reviewErrorMessage(state.errorCode!),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            _ReviewRatingButtons(enabled: !busy, onSubmit: onSubmit),
          ],
        ],
      ),
    );
  }
}

final class _ReviewRatingButtons extends StatelessWidget {
  const _ReviewRatingButtons({required this.enabled, required this.onSubmit});

  final bool enabled;
  final Future<void> Function(ReviewRating rating) onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReviewRatingButton(
                label: '重学',
                icon: Icons.replay_outlined,
                enabled: enabled,
                foregroundColor: theme.colorScheme.onErrorContainer,
                backgroundColor: theme.colorScheme.errorContainer,
                borderColor: theme.colorScheme.error.withValues(alpha: 0.35),
                onPressed: () => onSubmit(ReviewRating.again),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReviewRatingButton(
                label: '困难',
                icon: Icons.sentiment_dissatisfied_outlined,
                enabled: enabled,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                backgroundColor: theme.colorScheme.secondaryContainer,
                borderColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.35,
                ),
                onPressed: () => onSubmit(ReviewRating.hard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ReviewRatingButton(
                label: '记得',
                icon: Icons.check_circle_outline,
                enabled: enabled,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                borderColor: theme.colorScheme.tertiary.withValues(alpha: 0.35),
                onPressed: () => onSubmit(ReviewRating.good),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReviewRatingButton(
                label: '轻松',
                icon: Icons.rocket_launch_outlined,
                enabled: enabled,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                backgroundColor: theme.colorScheme.primaryContainer,
                borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
                onPressed: () => onSubmit(ReviewRating.easy),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _ReviewRatingButton extends StatelessWidget {
  const _ReviewRatingButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
        side: BorderSide(color: borderColor),
      ),
    );
  }
}

final class _ReviewReinforcementNotice extends StatelessWidget {
  const _ReviewReinforcementNotice({
    required this.prompt,
    required this.onDismiss,
    required this.onStart,
  });

  final ReviewReinforcementPrompt prompt;
  final VoidCallback onDismiss;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“${prompt.word}”已连续两次未想起',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '建议先完成一次拼写巩固，再继续当前复习。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: const Text('稍后')),
                FilledButton(onPressed: onStart, child: const Text('开始拼写巩固')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReviewFlipCard extends StatefulWidget {
  const _ReviewFlipCard({
    required this.isFlipped,
    required this.enabled,
    required this.onTap,
    required this.front,
    required this.back,
  });

  final bool isFlipped;
  final bool enabled;
  final VoidCallback onTap;
  final Widget front;
  final Widget back;

  @override
  State<_ReviewFlipCard> createState() => _ReviewFlipCardState();
}

final class _ReviewFlipCardState extends State<_ReviewFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _disableAnimations =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.isFlipped ? 1 : 0,
      duration: _ReviewLayout.flipDuration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant _ReviewFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped == widget.isFlipped) {
      return;
    }
    final target = widget.isFlipped ? 1.0 : 0.0;
    if (_disableAnimations) {
      _controller.value = target;
      return;
    }
    _controller.animateTo(target, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.isFlipped ? '收起释义' : '查看释义',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('review-flip-card'),
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(_ReviewLayout.cardRadius),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final isBackVisible = _controller.value >= 0.5;
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_controller.value * math.pi);
                return Transform(
                  alignment: Alignment.center,
                  transform: transform,
                  child: isBackVisible
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: widget.back,
                        )
                      : widget.front,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _ReviewCardSurface extends StatelessWidget {
  const _ReviewCardSurface({required this.child, required this.decoration});

  final Widget child;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(decoration: decoration, child: child),
  );
}

final class _ReviewCardFront extends StatelessWidget {
  const _ReviewCardFront({
    required this.item,
    required this.state,
    required this.enabled,
    required this.onPlay,
    required this.onStop,
  });

  final ReviewQueueItem item;
  final ReviewRunState state;
  final bool enabled;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = item.word;
    final heroColors = AppTheme.heroColorsOf(theme);
    final secondary = heroColors.foreground.withValues(alpha: 0.72);
    return _ReviewCardSurface(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroColors.start, heroColors.end],
        ),
        borderRadius: BorderRadius.circular(_ReviewLayout.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: heroColors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReviewPronunciationAction(
                    accent: PronunciationAccent.uk,
                    phonetic: word.phoneticUk,
                    enabled: enabled,
                    playing: _isPlaying(PronunciationAccent.uk),
                    foreground: heroColors.foreground,
                    secondary: secondary,
                    onTap: () => _toggleAudio(PronunciationAccent.uk),
                  ),
                  const SizedBox(height: 8),
                  _ReviewPronunciationAction(
                    accent: PronunciationAccent.us,
                    phonetic: word.phoneticUs,
                    enabled: enabled,
                    playing: _isPlaying(PronunciationAccent.us),
                    foreground: heroColors.foreground,
                    secondary: secondary,
                    onTap: () => _toggleAudio(PronunciationAccent.us),
                  ),
                  if (state.audioErrorCode case final errorCode?) ...[
                    const SizedBox(height: 8),
                    Text(
                      _reviewAudioMessage(errorCode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: heroColors.foreground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isPlaying(PronunciationAccent accent) =>
      state.audioPhase == ReviewAudioPhase.playing &&
      state.audioWordId == item.word.id &&
      state.pronunciationAccent == accent;

  Future<void> _toggleAudio(PronunciationAccent accent) {
    return _isPlaying(accent) ? onStop() : onPlay(accent: accent);
  }
}

final class _ReviewPronunciationAction extends StatelessWidget {
  const _ReviewPronunciationAction({
    required this.accent,
    required this.phonetic,
    required this.enabled,
    required this.playing,
    required this.foreground,
    required this.secondary,
    required this.onTap,
  });

  final PronunciationAccent accent;
  final String? phonetic;
  final bool enabled;
  final bool playing;
  final Color foreground;
  final Color secondary;
  final VoidCallback onTap;

  String get _label => accent == PronunciationAccent.uk ? 'UK' : 'US';

  String get _tooltip => playing ? '停止$_label发音' : '播放$_label发音';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            _label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            phonetic ?? '暂无音标',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: secondary,
              fontFamily: 'monospace',
            ),
          ),
        ),
        IconButton(
          key: ValueKey('review-pronunciation-${accent.name}'),
          tooltip: _tooltip,
          onPressed: enabled ? onTap : null,
          color: foreground,
          disabledColor: secondary,
          icon: Icon(
            playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          ),
        ),
      ],
    );
  }
}

final class _ReviewCardBack extends StatelessWidget {
  const _ReviewCardBack({required this.item});

  final ReviewQueueItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = item.word;
    final learning = item.learningState;
    final heroColors = AppTheme.heroColorsOf(theme);
    final secondary = heroColors.foreground.withValues(alpha: 0.72);
    return _ReviewCardSurface(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroColors.start, heroColors.end],
        ),
        borderRadius: BorderRadius.circular(_ReviewLayout.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: heroColors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.phoneticUk ?? '暂无音标',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    word.translationZh ?? '暂无中文释义',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: heroColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: heroColors.foreground.withValues(alpha: 0.32),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '掌握等级 ${learning.masteryLevel}/5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                  if (learning.nextReviewAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '下次复习：${_dateText(learning.nextReviewAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ReviewCompleted extends StatelessWidget {
  const _ReviewCompleted({
    required this.state,
    required this.onStart,
    required this.onRetryMemoryRate,
    required this.onDismissReinforcement,
    required this.onStartReinforcement,
  });

  final ReviewRunState state;
  final Future<void> Function({int limit}) onStart;
  final Future<void> Function() onRetryMemoryRate;
  final VoidCallback onDismissReinforcement;
  final ValueChanged<ReviewReinforcementPrompt> onStartReinforcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = (state.sessionAccuracy * 100).round();
    final memoryRate = state.memoryRate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Icon(Icons.task_alt, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          '复习完成',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '本次记忆率 $accuracy%',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        if (state.reinforcementPrompt case final prompt?) ...[
          _ReviewReinforcementNotice(
            prompt: prompt,
            onDismiss: onDismissReinforcement,
            onStart: () => onStartReinforcement(prompt),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ReviewMetric(label: '重学', value: '${state.againCount}'),
                _ReviewMetric(label: '困难', value: '${state.hardCount}'),
                _ReviewMetric(label: '记得', value: '${state.goodCount}'),
                _ReviewMetric(label: '轻松', value: '${state.easyCount}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (memoryRate != null)
          Text(
            '累计记忆率 ${(memoryRate.value * 100).round()}%（${memoryRate.completedReviews} 次复习）',
            textAlign: TextAlign.center,
          )
        else if (state.errorCode == ReviewRunErrorCodes.memoryRateFailed)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('累计记忆率暂时不可用'),
              TextButton(onPressed: onRetryMemoryRate, child: const Text('重试')),
            ],
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => onStart(),
          icon: const Icon(Icons.refresh),
          label: const Text('再次检查'),
        ),
      ],
    );
  }
}

final class _ReviewMetric extends StatelessWidget {
  const _ReviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _reviewErrorMessage(String code) => switch (code) {
  ReviewRunErrorCodes.persistenceFailed => '复习结果保存失败，请重新提交。',
  ReviewRunErrorCodes.memoryRateFailed => '累计记忆率读取失败。',
  _ => '复习暂时不可用，请重试。',
};

String _reviewAudioMessage(String code) => switch (code) {
  ReviewRunErrorCodes.audioUnavailable => '当前口音暂无可用参考发音。',
  ReviewRunErrorCodes.audioFailed => '参考发音播放失败，请重试。',
  _ => '参考发音暂时不可用。',
};

String _intervalText(Duration interval) {
  if (interval.inDays > 0) {
    return '${interval.inDays}天';
  }
  if (interval.inHours > 0) {
    return '${interval.inHours}小时';
  }
  return '${interval.inMinutes}分钟';
}

String _dateText(DateTime value) {
  final local = value.toLocal();
  return '${local.year}/${local.month}/${local.day}';
}
