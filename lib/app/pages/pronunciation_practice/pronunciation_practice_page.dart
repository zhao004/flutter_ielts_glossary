import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/pronunciation_practice_run_state.dart';
import '../../models/domain/pronunciation_score.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';
import '../shell/main_shell_controller.dart';
import 'pronunciation_practice_logic.dart';

/// 发音练习页面，仅在已配置第三方评测服务时采集录音并展示评分。
class PronunciationPracticePage extends StatefulWidget {
  const PronunciationPracticePage({
    required this.expectedWord,
    this.phonetic,
    this.translation,
    super.key,
  });

  final String expectedWord;
  final String? phonetic;
  final String? translation;

  @override
  State<PronunciationPracticePage> createState() =>
      _PronunciationPracticePageState();
}

final class _PronunciationPracticePageState
    extends State<PronunciationPracticePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Get.isRegistered<PronunciationPracticeLogic>()) {
        Get.find<PronunciationPracticeLogic>().prepare(
          expectedWord: widget.expectedWord,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        appBar: AppBar(
          title: const Text('发音练习'),
          leading: IconButton(
            tooltip: '返回',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Get.back<void>();
              } else {
                Get.find<MainShellController>().switchToSettings();
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              tooltip: '返回首页',
              onPressed: () => Get.find<MainShellController>().switchToHome(),
              icon: const Icon(Icons.home_outlined),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: GetBuilder<PronunciationPracticeLogic>(
            id: PronunciationPracticeLogic.updateId,
            builder: (logic) => _PronunciationBody(
              state: logic.state,
              phonetic: widget.phonetic,
              translation: widget.translation,
              onPrepare: logic.prepare,
              onListen: logic.startListening,
              onStop: logic.stop,
              onReset: logic.reset,
              onRetry: logic.retry,
            ),
          ),
        ),
      ),
    );
  }
}

final class _PronunciationBody extends StatelessWidget {
  const _PronunciationBody({
    required this.state,
    required this.phonetic,
    required this.translation,
    required this.onPrepare,
    required this.onListen,
    required this.onStop,
    required this.onReset,
    required this.onRetry,
  });

  final PronunciationPracticeRunState state;
  final String? phonetic;
  final String? translation;
  final Future<void> Function({
    required String expectedWord,
    PronunciationAccent accent,
  })
  onPrepare;
  final Future<void> Function() onListen;
  final Future<void> Function() onStop;
  final VoidCallback onReset;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.phase == PronunciationPracticePhase.idle ||
        state.phase == PronunciationPracticePhase.preparing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.phase == PronunciationPracticePhase.evaluating) {
      return const _PronunciationEvaluating();
    }
    if (state.phase == PronunciationPracticePhase.completed &&
        state.score != null) {
      return _CloudPronunciationResult(state: state, onRetry: onReset);
    }
    if (state.phase == PronunciationPracticePhase.ready ||
        state.phase == PronunciationPracticePhase.listening) {
      return _PronunciationReady(
        state: state,
        phonetic: phonetic,
        translation: translation,
        onPrepare: onPrepare,
        onListen: onListen,
        onStop: onStop,
      );
    }
    return _PronunciationFailure(state: state, onRetry: onRetry);
  }
}

final class _PronunciationReady extends StatelessWidget {
  const _PronunciationReady({
    required this.state,
    required this.phonetic,
    required this.translation,
    required this.onPrepare,
    required this.onListen,
    required this.onStop,
  });

  final PronunciationPracticeRunState state;
  final String? phonetic;
  final String? translation;
  final Future<void> Function({
    required String expectedWord,
    PronunciationAccent accent,
  })
  onPrepare;
  final Future<void> Function() onListen;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final listening = state.phase == PronunciationPracticePhase.listening;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
      children: [
        Text(
          '目标单词',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).appTextSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          state.expectedWord ?? '',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (phonetic != null && phonetic!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            phonetic!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        if (translation != null && translation!.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            translation!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).appTextSecondary,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择发音',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).appTextSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _AccentButton(
                      label: '英式 UK',
                      selected: state.accent == PronunciationAccent.uk,
                      enabled: !listening,
                      onTap: () => onPrepare(
                        expectedWord: state.expectedWord!,
                        accent: PronunciationAccent.uk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccentButton(
                      label: '美式 US',
                      selected: state.accent == PronunciationAccent.us,
                      enabled: !listening,
                      onTap: () => onPrepare(
                        expectedWord: state.expectedWord!,
                        accent: PronunciationAccent.us,
                      ),
                    ),
                  ),
                  const SizedBox(width: 108),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: _MicrophoneButton(
            listening: listening,
            onStart: onListen,
            onStop: onStop,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          listening ? '正在录音…' : '按住并朗读单词',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          listening ? '松手结束并自动评测' : '长按录音，松手结束',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).appTextSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).appWarningSurface,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Text(
            '录音仅用于本次第三方发音评测，不会保存到本机学习数据。',
            style: TextStyle(color: Theme.of(context).appWarning, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

final class _MicrophoneButton extends StatelessWidget {
  const _MicrophoneButton({
    required this.listening,
    required this.onStart,
    required this.onStop,
  });

  final bool listening;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = listening
        ? theme.colorScheme.onError
        : theme.colorScheme.onPrimary;
    return Listener(
      onPointerDown: (_) => onStart(),
      onPointerUp: (_) => onStop(),
      onPointerCancel: (_) => onStop(),
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              color: listening
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: listening
                  ? Icon(Icons.stop_rounded, color: foreground, size: 36)
                  : AppSvgIcon(
                      AppIconAssets.pronunciationMic,
                      size: 38,
                      color: foreground,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _AccentButton extends StatelessWidget {
  const _AccentButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: selected
          ? FilledButton(onPressed: enabled ? onTap : null, child: Text(label))
          : OutlinedButton(
              onPressed: enabled ? onTap : null,
              child: Text(label),
            ),
    );
  }
}

final class _PronunciationEvaluating extends StatelessWidget {
  const _PronunciationEvaluating();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在获取第三方评测结果…'),
        ],
      ),
    );
  }
}

final class _CloudPronunciationResult extends StatelessWidget {
  const _CloudPronunciationResult({required this.state, required this.onRetry});

  final PronunciationPracticeRunState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final score = state.score!;
    final levelText = _scoreLevelText(score.level);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
      children: [
        Text(
          state.expectedWord ?? '',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          state.accent == PronunciationAccent.uk
              ? '英式发音 · 第三方评测'
              : '美式发音 · 第三方评测',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).appTextSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _SurfaceCard(
          child: SizedBox(
            height: 140,
            child: Row(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text: '${score.totalScore.round()}',
                        children: const [
                          TextSpan(text: '分', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelText,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '总分 ${score.totalScore.round()} · 准确度 ${score.accuracyScore.round()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SurfaceCard(
          child: Column(
            children: [
              _ScoreRow(label: '准确度', value: score.accuracyScore),
              const Divider(height: 22),
              _ScoreRow(label: '流利度', value: score.fluencyScore),
              const Divider(height: 22),
              _ScoreRow(label: '完整度', value: score.integrityScore),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: Get.back<void>,
            child: const Text('继续下一词'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton(onPressed: onRetry, child: const Text('再试一次')),
        ),
      ],
    );
  }
}

final class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          '${value.round()} 分',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

final class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

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
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

final class _PronunciationFailure extends StatelessWidget {
  const _PronunciationFailure({required this.state, required this.onRetry});

  final PronunciationPracticeRunState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final permission =
        state.phase == PronunciationPracticePhase.permissionDenied;
    final unconfigured = state.phase == PronunciationPracticePhase.unavailable;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              permission
                  ? Icons.mic_off_outlined
                  : Icons.settings_voice_outlined,
              size: 50,
              color: Theme.of(context).appTextTertiary,
            ),
            const SizedBox(height: 14),
            Text(
              permission
                  ? '需要麦克风权限'
                  : unconfigured
                  ? '尚未配置第三方评测'
                  : '发音练习不可用',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              permission
                  ? '请在系统设置中允许麦克风权限后重试。'
                  : unconfigured
                  ? '请先在语音服务配置中选择并保存第三方发音评测服务。'
                  : '第三方评测服务初始化失败，请重试。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (unconfigured)
              FilledButton.icon(
                onPressed: () =>
                    Get.toNamed<void>(AppRouteNames.speechServices),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('前往配置'),
              )
            else
              FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

String _scoreLevelText(PronunciationScoreLevel level) => switch (level) {
  PronunciationScoreLevel.excellent => '发音优秀',
  PronunciationScoreLevel.good => '发音良好',
  PronunciationScoreLevel.fair => '还需练习',
  PronunciationScoreLevel.poor => '差距较大',
};
