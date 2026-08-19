import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/study_candidate.dart';
import '../../models/domain/study_config.dart';
import '../../models/domain/study_rating.dart';
import '../../models/domain/study_run_state.dart';
import '../../models/domain/study_setup_state.dart';
import '../../models/domain/word_details.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_count_button.dart';
import '../shell/main_shell_controller.dart';
import 'study_session_logic.dart';
import 'study_setup_logic.dart';

/// 随机学习页面，串联配置、翻卡、评级和会话完成状态。
class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

final class _StudyPageState extends State<StudyPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('翻卡学习'),
          leading: IconButton(
            tooltip: '返回',
            onPressed: _leaveFlow,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            GetBuilder<StudySessionLogic>(
              id: StudySessionLogic.contentUpdateId,
              builder: (session) => _StudyFavoriteButton(
                state: session.state,
                onToggleFavorite: session.toggleCurrentWordFavorite,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: GetBuilder<StudySetupLogic>(
            id: StudySetupLogic.contentUpdateId,
            builder: (setup) => GetBuilder<StudySessionLogic>(
              id: StudySessionLogic.contentUpdateId,
              builder: (session) => _StudyBody(
                setup: setup.state,
                session: session.state,
                onRetrySetup: setup.retry,
                onSelectGroups: setup.selectFrequencyGroups,
                onSetWordCount: setup.setWordCount,
                onUseAvailableCount: setup.useAvailableWordCount,
                onStart: setup.start,
                onFlip: session.flip,
                onRate: session.rate,
                onPrevious: session.previous,
                onNext: session.next,
                onPlay: session.playCurrentPronunciation,
                onStop: session.stopPronunciation,
                onPronunciationPractice: (word) async {
                  await session.stopPronunciation();
                  await Get.toNamed<void>(
                    AppRouteNames.pronunciation,
                    arguments: {'word': word},
                  );
                },
                onExit: _leaveFlow,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _leaveFlow() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    Get.find<MainShellController>().switchToStudy();
  }
}

final class _StudyBody extends StatelessWidget {
  const _StudyBody({
    required this.setup,
    required this.session,
    required this.onRetrySetup,
    required this.onSelectGroups,
    required this.onSetWordCount,
    required this.onUseAvailableCount,
    required this.onStart,
    required this.onFlip,
    required this.onRate,
    required this.onPrevious,
    required this.onNext,
    required this.onPlay,
    required this.onStop,
    required this.onPronunciationPractice,
    required this.onExit,
  });

  final StudySetupState setup;
  final StudyRunState session;
  final Future<void> Function() onRetrySetup;
  final ValueChanged<Set<int>> onSelectGroups;
  final ValueChanged<int> onSetWordCount;
  final VoidCallback onUseAvailableCount;
  final Future<void> Function() onStart;
  final Future<void> Function() onFlip;
  final Future<void> Function(StudyRating rating) onRate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;
  final Future<void> Function(String word) onPronunciationPractice;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    if (setup.phase == StudySetupPhase.loadingSettings ||
        setup.phase == StudySetupPhase.starting ||
        session.phase == StudyRunPhase.preparing) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: '正在准备学习'),
      );
    }
    if (setup.phase == StudySetupPhase.error && setup.config == null) {
      return _StudyFailure(onRetry: onRetrySetup);
    }
    if (setup.phase == StudySetupPhase.started ||
        _isActiveSession(session.phase)) {
      return _StudySessionBody(
        state: session,
        onFlip: onFlip,
        onRate: onRate,
        onPrevious: onPrevious,
        onNext: onNext,
        onPlay: onPlay,
        onStop: onStop,
        onPronunciationPractice: onPronunciationPractice,
        onRestart: onStart,
        onExit: onExit,
      );
    }
    final config = setup.config;
    if (config == null) {
      return _StudyFailure(onRetry: onRetrySetup);
    }
    return _StudySetupBody(
      state: setup,
      config: config,
      onSelectGroups: onSelectGroups,
      onSetWordCount: onSetWordCount,
      onUseAvailableCount: onUseAvailableCount,
      onStart: onStart,
      onRetry: onRetrySetup,
    );
  }

  bool _isActiveSession(StudyRunPhase phase) {
    return phase == StudyRunPhase.answering ||
        phase == StudyRunPhase.persisting ||
        phase == StudyRunPhase.rating ||
        phase == StudyRunPhase.completed;
  }
}

final class _StudySetupBody extends StatelessWidget {
  const _StudySetupBody({
    required this.state,
    required this.config,
    required this.onSelectGroups,
    required this.onSetWordCount,
    required this.onUseAvailableCount,
    required this.onStart,
    required this.onRetry,
  });

  final StudySetupState state;
  final StudyConfig config;
  final ValueChanged<Set<int>> onSelectGroups;
  final ValueChanged<int> onSetWordCount;
  final VoidCallback onUseAvailableCount;
  final Future<void> Function() onStart;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isStarting = state.phase == StudySetupPhase.starting;
    final canEdit =
        state.phase == StudySetupPhase.editing ||
        state.phase == StudySetupPhase.insufficientCandidates;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('翻卡查看释义，按掌握程度评分', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 23),
        const _StudySectionLabel(title: '词汇难度'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StudyOptionButton(
                  width: width,
                  label: '全部',
                  selected: config.frequencyGroupIds.isEmpty,
                  enabled: canEdit,
                  onPressed: () => onSelectGroups(const {}),
                ),
                _StudyOptionButton(
                  width: width,
                  label: '初级',
                  selected: _sameGroups(config.frequencyGroupIds, const {1, 2}),
                  enabled: canEdit,
                  onPressed: () => onSelectGroups(const {1, 2}),
                ),
                _StudyOptionButton(
                  width: width,
                  label: '中级',
                  selected: _sameGroups(config.frequencyGroupIds, const {3, 4}),
                  enabled: canEdit,
                  onPressed: () => onSelectGroups(const {3, 4}),
                ),
                _StudyOptionButton(
                  width: width,
                  label: '高级',
                  selected: _sameGroups(config.frequencyGroupIds, const {5, 6}),
                  enabled: canEdit,
                  onPressed: () => onSelectGroups(const {5, 6}),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const _StudySectionLabel(title: '单词数量'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 27) / 4;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final count in const [10, 20, 30, 50])
                  _StudyOptionButton(
                    width: width,
                    label: '$count',
                    selected: config.wordCount == count,
                    enabled: canEdit,
                    onPressed: () => onSetWordCount(count),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        CustomCountButton(
          key: const ValueKey('study-custom-word-count'),
          value: config.wordCount,
          minimum: StudyConfig.minimumWordCount,
          maximum: StudyConfig.maximumWordCount,
          unit: '个',
          dialogTitle: '自定义单词数量',
          fieldLabel: '本次学习单词数',
          enabled: canEdit,
          onChanged: onSetWordCount,
        ),
        if (state.phase == StudySetupPhase.insufficientCandidates) ...[
          const SizedBox(height: 16),
          _InsufficientCandidates(
            availableCount: state.availableCount,
            canUseAvailableCount: state.canUseAvailableWordCount,
            onUseAvailableCount: onUseAvailableCount,
          ),
        ],
        if (state.phase == StudySetupPhase.error) ...[
          const SizedBox(height: 8),
          _StudyActionError(
            message: _setupErrorMessage(state.errorCode),
            onRetry: onRetry,
          ),
        ],
        const SizedBox(height: 31),
        FilledButton(
          onPressed: isStarting || !canEdit ? null : onStart,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.phase == StudySetupPhase.error ? '重试学习' : '开始学习'),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  bool _sameGroups(Set<int> first, Set<int> second) {
    return first.length == second.length && first.containsAll(second);
  }
}

final class _StudyOptionButton extends StatelessWidget {
  const _StudyOptionButton({
    required this.width,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final double width;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outline = theme.appBorder;
    return SizedBox(
      width: width,
      height: 46,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          backgroundColor: selected ? colorScheme.primary : colorScheme.surface,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.2),
          disabledBackgroundColor: colorScheme.surface.withValues(alpha: 0.45),
          side: BorderSide(color: selected ? colorScheme.primary : outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

final class _StudySectionLabel extends StatelessWidget {
  const _StudySectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).appTextTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

final class _InsufficientCandidates extends StatelessWidget {
  const _InsufficientCandidates({
    required this.availableCount,
    required this.canUseAvailableCount,
    required this.onUseAvailableCount,
  });

  final int availableCount;
  final bool canUseAvailableCount;
  final VoidCallback onUseAvailableCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前范围只有 $availableCount 个可学习单词。',
              style: theme.textTheme.bodyMedium,
            ),
            if (canUseAvailableCount) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onUseAvailableCount,
                icon: const Icon(Icons.tune),
                label: Text('改为学习 $availableCount 个'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _StudySessionBody extends StatelessWidget {
  const _StudySessionBody({
    required this.state,
    required this.onFlip,
    required this.onRate,
    required this.onPrevious,
    required this.onNext,
    required this.onPlay,
    required this.onStop,
    required this.onPronunciationPractice,
    required this.onRestart,
    required this.onExit,
  });

  final StudyRunState state;
  final Future<void> Function() onFlip;
  final Future<void> Function(StudyRating rating) onRate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;
  final Future<void> Function(String word) onPronunciationPractice;
  final Future<void> Function() onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    if (state.phase == StudyRunPhase.insufficientCandidates) {
      return _InsufficientSession(
        availableCount: state.availableCount,
        onRestart: onRestart,
      );
    }
    if (state.phase == StudyRunPhase.error) {
      return _StudyFailure(onRetry: onRestart);
    }
    if (state.phase == StudyRunPhase.completed) {
      return _StudyCompleted(state: state, onBack: onExit);
    }
    final candidate = state.currentCandidate;
    if (candidate == null) {
      return _StudyFailure(onRetry: onRestart);
    }
    return _StudyCardBody(
      state: state,
      candidate: candidate,
      onFlip: onFlip,
      onRate: onRate,
      onPrevious: onPrevious,
      onNext: onNext,
      onPlay: onPlay,
      onStop: onStop,
      onPronunciationPractice: onPronunciationPractice,
    );
  }
}

final class _StudyCardBody extends StatelessWidget {
  const _StudyCardBody({
    required this.state,
    required this.candidate,
    required this.onFlip,
    required this.onRate,
    required this.onPrevious,
    required this.onNext,
    required this.onPlay,
    required this.onStop,
    required this.onPronunciationPractice,
  });

  final StudyRunState state;
  final StudyCandidate candidate;
  final Future<void> Function() onFlip;
  final Future<void> Function(StudyRating rating) onRate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;
  final Future<void> Function(String word) onPronunciationPractice;

  @override
  Widget build(BuildContext context) {
    final details = candidate.word;
    final theme = Theme.of(context);
    final busy =
        state.phase == StudyRunPhase.persisting ||
        state.phase == StudyRunPhase.rating;
    final showAudioMessage = state.audioErrorCode != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                semanticsLabel: '学习进度',
                semanticsValue: '${(state.progress * 100).round()}',
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${state.currentIndex + 1}/${state.candidates.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy ? null : onFlip,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: state.isFlipped
                    ? _StudyCardBack(details: details)
                    : _StudyCardFront(details: details),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          state.isFlipped ? '点击卡片可收起释义' : '点击卡片翻开释义',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _StudyAudioButton(
                accent: PronunciationAccent.uk,
                selectedAccent: state.audioAccent,
                isPlaying: state.audioPhase == StudyAudioPhase.playing,
                onPlay: onPlay,
                onStop: onStop,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _StudyAudioButton(
                accent: PronunciationAccent.us,
                selectedAccent: state.audioAccent,
                isPlaying: state.audioPhase == StudyAudioPhase.playing,
                onPlay: onPlay,
                onStop: onStop,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _StudyActionPill(
                buttonKey: const ValueKey('study-pronunciation-practice'),
                label: '发音练习',
                tooltip: '进入发音练习',
                icon: Icons.mic_outlined,
                emphasized: true,
                onPressed: busy
                    ? null
                    : () => onPronunciationPractice(details.word),
              ),
            ),
          ],
        ),
        if (state.favoriteErrorCode != null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: _StudyActionError(message: '收藏失败，请重试。'),
          ),
        if (showAudioMessage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _audioMessage(state.audioErrorCode!),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (state.errorCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _StudyActionError(
              message: _sessionErrorMessage(state.errorCode!),
            ),
          ),
        if (state.isFlipped) ...[
          const SizedBox(height: 20),
          Text('这次掌握得怎么样？', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: '不认识',
                  icon: Icons.sentiment_dissatisfied_outlined,
                  color: theme.appError,
                  enabled: !busy,
                  onPressed: () => onRate(StudyRating.unknown),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingButton(
                  label: '有印象',
                  icon: Icons.sentiment_neutral_outlined,
                  color: theme.appWarning,
                  enabled: !busy,
                  onPressed: () => onRate(StudyRating.familiar),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingButton(
                  label: '认识',
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  color: theme.appSuccess,
                  enabled: !busy,
                  onPressed: () => onRate(StudyRating.known),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.currentIndex == 0 || busy ? null : onPrevious,
                icon: const Icon(Icons.chevron_left),
                label: const Text('上一张'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !state.isFlipped || busy ? null : onNext,
                icon: const Icon(Icons.chevron_right),
                label: Text(state.isLastCandidate ? '完成' : '下一张'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _StudyCardFront extends StatelessWidget {
  const _StudyCardFront({required this.details});

  final WordDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('study_card_front'),
      children: [
        Text(
          details.word,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '/${details.phoneticUk ?? '暂无 UK 音标'}/',
          style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 28),
        Icon(
          Icons.touch_app_outlined,
          size: 28,
          color: theme.colorScheme.primary,
          semanticLabel: '翻开卡片',
        ),
      ],
    );
  }
}

final class _StudyCardBack extends StatelessWidget {
  const _StudyCardBack({required this.details});

  final WordDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstSentence = details.sentences.isEmpty
        ? null
        : details.sentences.first;
    return Column(
      key: const ValueKey('study_card_back'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          details.word,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          details.translationZh ?? '暂无中文释义',
          style: theme.textTheme.titleMedium,
        ),
        if (details.definitionEn != null) ...[
          const SizedBox(height: 6),
          Text(details.definitionEn!, style: theme.textTheme.bodyMedium),
        ],
        if (firstSentence != null) ...[
          const Divider(height: 26),
          Text(firstSentence.sentenceEn, style: theme.textTheme.bodyMedium),
          if (firstSentence.translationZh != null) ...[
            const SizedBox(height: 6),
            Text(
              firstSentence.translationZh!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
        if (details.mnemonic != null) ...[
          const SizedBox(height: 12),
          Text('记忆法：${details.mnemonic}', style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

final class _StudyAudioButton extends StatelessWidget {
  const _StudyAudioButton({
    required this.accent,
    required this.selectedAccent,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
  });

  final PronunciationAccent accent;
  final PronunciationAccent? selectedAccent;
  final bool isPlaying;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final isCurrent = selectedAccent == accent;
    final label = accent == PronunciationAccent.uk ? 'UK' : 'US';
    final active = isPlaying && isCurrent;
    return _StudyActionPill(
      buttonKey: ValueKey('study-pronunciation-${accent.name}'),
      label: label,
      tooltip: active ? '停止 $label 发音' : '播放 $label 发音',
      icon: active ? Icons.stop : Icons.volume_up,
      active: active,
      onPressed: active ? onStop : () => onPlay(accent: accent),
    );
  }
}

final class _StudyActionPill extends StatelessWidget {
  const _StudyActionPill({
    required this.buttonKey,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.emphasized = false,
  });

  final Key buttonKey;
  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = active || emphasized;
    final foreground = highlighted
        ? theme.colorScheme.primary
        : theme.appTextSecondary;
    final background = highlighted
        ? theme.colorScheme.primaryContainer
        : theme.appSubtleSurface;
    final border = highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : theme.appBorder;
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          foregroundColor: foreground,
          backgroundColor: background,
          side: BorderSide(color: border),
          shape: const StadiumBorder(),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

final class _StudyFavoriteButton extends StatelessWidget {
  const _StudyFavoriteButton({
    required this.state,
    required this.onToggleFavorite,
  });

  final StudyRunState state;
  final Future<void> Function() onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final hasActiveCard =
        state.currentCandidate != null &&
        (state.phase == StudyRunPhase.answering ||
            state.phase == StudyRunPhase.persisting ||
            state.phase == StudyRunPhase.rating);
    if (!hasActiveCard) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: const ValueKey('study-favorite'),
      onPressed: state.isUpdatingCurrentWordFavorite ? null : onToggleFavorite,
      tooltip: state.isCurrentWordFavorite ? '取消收藏' : '收藏单词',
      icon: state.isUpdatingCurrentWordFavorite
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(state.isCurrentWordFavorite ? Icons.star : Icons.star_border),
    );
  }
}

final class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

final class _StudyCompleted extends StatelessWidget {
  const _StudyCompleted({required this.state, required this.onBack});

  final StudyRunState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = state.ratings.values
        .where((rating) => rating == StudyRating.known)
        .length;
    final familiar = state.ratings.values
        .where((rating) => rating == StudyRating.familiar)
        .length;
    final unknown = state.ratings.values
        .where((rating) => rating == StudyRating.unknown)
        .length;
    final total = state.ratings.length;
    final accuracy = total == 0 ? 0 : (known / total * 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
      children: [
        Icon(
          accuracy >= 80 ? Icons.celebration_outlined : Icons.auto_stories,
          size: 64,
          color: theme.colorScheme.primary,
          semanticLabel: '学习完成',
        ),
        const SizedBox(height: 16),
        Text(
          '学习完成',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '本次完成 $total 个单词',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _CompletionMetric(label: '认识', value: known),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompletionMetric(label: '有印象', value: familiar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompletionMetric(label: '不认识', value: unknown),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text('本次掌握率', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 5),
                Text(
                  '$accuracy%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.home_outlined),
          label: const Text('返回首页'),
        ),
      ],
    );
  }
}

final class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

final class _InsufficientSession extends StatelessWidget {
  const _InsufficientSession({
    required this.availableCount,
    required this.onRestart,
  });

  final int availableCount;
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text('当前范围只有 $availableCount 个可学习单词。'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.tune),
              label: const Text('返回调整数量'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StudyFailure extends StatelessWidget {
  const _StudyFailure({required this.onRetry});

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
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
              semanticLabel: '学习准备失败',
            ),
            const SizedBox(height: 12),
            const Text('学习准备失败'),
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

final class _StudyActionError extends StatelessWidget {
  const _StudyActionError({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
              semanticLabel: '学习操作失败',
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

String _setupErrorMessage(String? code) {
  return switch (code) {
    StudySetupErrorCodes.settingsLoadFailed => '学习设置加载失败，请重试。',
    _ => '学习准备失败，请检查词库后重试。',
  };
}

String _sessionErrorMessage(String code) {
  return switch (code) {
    StudyRunErrorCodes.completionPersistenceFailed => '学习记录保存失败，请重新翻卡。',
    StudyRunErrorCodes.ratingPersistenceFailed => '评级保存失败，请重试。',
    _ => '当前学习操作失败，请重试。',
  };
}

String _audioMessage(String code) {
  return switch (code) {
    StudyRunErrorCodes.audioUnavailable => '未找到词库音频，也未配置可用的第三方 TTS。',
    StudyRunErrorCodes.audioFailed => '发音播放失败，请稍后重试。',
    _ => '发音暂时不可用。',
  };
}
