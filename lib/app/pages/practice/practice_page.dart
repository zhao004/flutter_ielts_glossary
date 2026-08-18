import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/practice_run_state.dart';
import '../../models/domain/practice_setup_state.dart';
import '../../models/domain/question_config.dart';
import '../../models/domain/quiz_question.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import '../shell/main_shell_controller.dart';
import 'practice_session_logic.dart';
import 'practice_setup_logic.dart';

/// 练习页面，串联题型配置、真实题目会话、即时反馈和完成统计。
class PracticePage extends StatefulWidget {
  const PracticePage({super.key, this.autoStart = false});

  /// 例句填空从学习中心直接进入会话，其他题型保留设置页。
  final bool autoStart;

  @override
  State<PracticePage> createState() => _PracticePageState();
}

final class _PracticePageState extends State<PracticePage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startInitialSession());
      });
    }
  }

  Future<void> _startInitialSession() async {
    if (!mounted) {
      return;
    }
    final setup = Get.find<PracticeSetupLogic>();
    if (setup.state.phase != PracticeSetupPhase.editing) {
      return;
    }
    await setup.start();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: GetBuilder<PracticeSetupLogic>(
        id: PracticeSetupLogic.contentUpdateId,
        builder: (setup) {
          final setupState = setup.state;
          return Scaffold(
            appBar: AppBar(
              title: Text(_practiceTitle(setupState.config.type)),
              leading: IconButton(
                tooltip: '返回',
                onPressed: _leaveFlow,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: SafeArea(
              top: false,
              child: GetBuilder<PracticeSessionLogic>(
                id: PracticeSessionLogic.contentUpdateId,
                builder: (session) => _PracticeBody(
                  setup: setupState,
                  session: session.state,
                  onSelectType: setup.selectQuestionType,
                  onSetWrongFirst: setup.setWrongFirst,
                  onSetQuestionCount: setup.setQuestionCount,
                  onSetTimed: setup.setTimed,
                  onSetSpellingPrompt: setup.setSpellingPromptType,
                  onUseAvailableCount: setup.useAvailableQuestionCount,
                  onStart: setup.start,
                  onSubmitChoice: session.submitChoice,
                  onSubmitText: session.submitText,
                  onToggleFavorite: session.toggleCurrentWordFavorite,
                  onPlayPronunciation: session.playCurrentPronunciation,
                  onStopPronunciation: session.stopPronunciation,
                  onNext: session.next,
                  onExit: _leaveFlow,
                  onRestart: () => _restartFlow(setupState.config.type),
                ),
              ),
            ),
          );
        },
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

  void _restartFlow(QuestionType type) {
    final route = switch (type) {
      QuestionType.spelling => AppRouteNames.practiceSpelling,
      QuestionType.cloze => AppRouteNames.practiceCloze,
      _ => AppRouteNames.practiceQuiz,
    };
    Get.offNamed<void>(route);
  }
}

final class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.setup,
    required this.session,
    required this.onSelectType,
    required this.onSetWrongFirst,
    required this.onSetQuestionCount,
    required this.onSetTimed,
    required this.onSetSpellingPrompt,
    required this.onUseAvailableCount,
    required this.onStart,
    required this.onSubmitChoice,
    required this.onSubmitText,
    required this.onToggleFavorite,
    required this.onPlayPronunciation,
    required this.onStopPronunciation,
    required this.onNext,
    required this.onExit,
    required this.onRestart,
  });

  final PracticeSetupState setup;
  final PracticeRunState session;
  final ValueChanged<QuestionType> onSelectType;
  final ValueChanged<bool> onSetWrongFirst;
  final ValueChanged<int> onSetQuestionCount;
  final ValueChanged<bool> onSetTimed;
  final ValueChanged<SpellingPromptType> onSetSpellingPrompt;
  final VoidCallback onUseAvailableCount;
  final Future<void> Function() onStart;
  final Future<void> Function(String optionId) onSubmitChoice;
  final Future<void> Function(String answer) onSubmitText;
  final Future<void> Function() onToggleFavorite;
  final Future<void> Function({PronunciationAccent? accent})
  onPlayPronunciation;
  final Future<void> Function() onStopPronunciation;
  final Future<void> Function() onNext;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    if (setup.phase == PracticeSetupPhase.starting ||
        session.phase == PracticeRunPhase.preparing) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: '正在准备练习'),
      );
    }
    if (setup.phase == PracticeSetupPhase.started ||
        _isActiveSession(session.phase)) {
      return _PracticeSessionBody(
        state: session,
        onSubmitChoice: onSubmitChoice,
        onSubmitText: onSubmitText,
        onToggleFavorite: onToggleFavorite,
        onPlayPronunciation: onPlayPronunciation,
        onStopPronunciation: onStopPronunciation,
        onNext: onNext,
        onExit: onExit,
        onRestart: onRestart,
      );
    }
    return _PracticeSetupBody(
      state: setup,
      onSelectType: onSelectType,
      onSetWrongFirst: onSetWrongFirst,
      onSetQuestionCount: onSetQuestionCount,
      onSetTimed: onSetTimed,
      onSetSpellingPrompt: onSetSpellingPrompt,
      onUseAvailableCount: onUseAvailableCount,
      onStart: onStart,
    );
  }

  bool _isActiveSession(PracticeRunPhase phase) {
    return phase == PracticeRunPhase.answering ||
        phase == PracticeRunPhase.submitting ||
        phase == PracticeRunPhase.feedback ||
        phase == PracticeRunPhase.completing ||
        phase == PracticeRunPhase.completed;
  }
}

final class _PracticeSetupBody extends StatelessWidget {
  const _PracticeSetupBody({
    required this.state,
    required this.onSelectType,
    required this.onSetWrongFirst,
    required this.onSetQuestionCount,
    required this.onSetTimed,
    required this.onSetSpellingPrompt,
    required this.onUseAvailableCount,
    required this.onStart,
  });

  final PracticeSetupState state;
  final ValueChanged<QuestionType> onSelectType;
  final ValueChanged<bool> onSetWrongFirst;
  final ValueChanged<int> onSetQuestionCount;
  final ValueChanged<bool> onSetTimed;
  final ValueChanged<SpellingPromptType> onSetSpellingPrompt;
  final VoidCallback onUseAvailableCount;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final config = state.config;
    if (config.isTargeted) {
      return _TargetedPracticeSetupBody(state: state, onStart: onStart);
    }
    final theme = Theme.of(context);
    final isSpelling = config.type == QuestionType.spelling;
    final canEdit =
        state.phase == PracticeSetupPhase.editing ||
        state.phase == PracticeSetupPhase.insufficientCandidates ||
        state.phase == PracticeSetupPhase.error;
    final accent = _practiceAccent(theme, config.type);
    final accentForeground = _practiceAccentForeground(theme, config.type);
    final actionColor = accent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          isSpelling ? '根据提示，输入正确的英文单词' : '四选一，测试词汇掌握度',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 23),
        _PracticeSectionLabel(title: isSpelling ? '提示类型' : '题型'),
        const SizedBox(height: 10),
        if (isSpelling)
          _SpellingPromptOptions(
            selected: config.spellingPromptType!,
            enabled: canEdit,
            onChanged: onSetSpellingPrompt,
          )
        else
          _QuizTypeOptions(
            selected: config.type,
            enabled: canEdit,
            onChanged: onSelectType,
          ),
        const SizedBox(height: 20),
        _PracticeSectionLabel(title: isSpelling ? '单词数量' : '题目数量'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 27) / 4;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final count in const [10, 20, 30, 40])
                  _PracticeCountButton(
                    width: itemWidth,
                    count: count,
                    selected: config.questionCount == count,
                    enabled: canEdit,
                    accent: accent,
                    foreground: accentForeground,
                    onPressed: () => onSetQuestionCount(count),
                  ),
              ],
            );
          },
        ),
        if (!isSpelling) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PracticeToggleButton(
                  icon: Icons.timer_outlined,
                  label: '计时模式',
                  selected: config.timed,
                  enabled: canEdit,
                  onPressed: () => onSetTimed(!config.timed),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PracticeToggleButton(
                  icon: Icons.inventory_2_outlined,
                  label: '错题优先',
                  selected: config.wrongFirst,
                  enabled: canEdit,
                  onPressed: () => onSetWrongFirst(!config.wrongFirst),
                ),
              ),
            ],
          ),
        ],
        if (state.phase == PracticeSetupPhase.insufficientCandidates)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _CandidateWarning(
              availableCount: state.availability?.availableCandidateCount ?? 0,
              canUseAvailableCount: state.canUseAvailableQuestionCount,
              onUseAvailableCount: onUseAvailableCount,
            ),
          ),
        if (state.phase == PracticeSetupPhase.error)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _PracticeErrorCard(
              message: _setupErrorMessage(state.errorCode),
            ),
          ),
        SizedBox(height: isSpelling ? 31 : 33),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(
                color: actionColor.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: canEdit ? onStart : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: actionColor,
              foregroundColor: accentForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.phase == PracticeSetupPhase.error
                      ? '重试练习'
                      : isSpelling
                      ? '开始拼写'
                      : '开始答题',
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _TargetedPracticeSetupBody extends StatelessWidget {
  const _TargetedPracticeSetupBody({
    required this.state,
    required this.onStart,
  });

  final PracticeSetupState state;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canStart =
        state.phase == PracticeSetupPhase.editing ||
        state.phase == PracticeSetupPhase.insufficientCandidates ||
        state.phase == PracticeSetupPhase.error;
    final unavailable =
        state.phase == PracticeSetupPhase.insufficientCandidates;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        Icon(
          Icons.spellcheck_outlined,
          size: 56,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 16),
        Text(
          '单词拼写巩固',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          unavailable ? '该单词暂时无法生成拼写题，请返回复习页稍后再试。' : '请根据中文释义输入正确的英文单词。',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.appTextTertiary,
          ),
        ),
        if (state.phase == PracticeSetupPhase.error) ...[
          const SizedBox(height: 20),
          _PracticeErrorCard(message: _setupErrorMessage(state.errorCode)),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: canStart ? onStart : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            unavailable || state.phase == PracticeSetupPhase.error
                ? '重试准备'
                : '开始拼写巩固',
          ),
        ),
      ],
    );
  }
}

final class _QuizTypeOptions extends StatelessWidget {
  const _QuizTypeOptions({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final QuestionType selected;
  final bool enabled;
  final ValueChanged<QuestionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      (QuestionType.choiceEnglishToChinese, '英 → 中', '看英文选中文释义'),
      (QuestionType.choiceChineseToEnglish, '中 → 英', '看中文选英文单词'),
      (QuestionType.choiceWordToSentence, '词 → 例句', '根据例句选正确单词'),
    ];
    return Column(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _PracticeLongOption(
            title: options[index].$2,
            subtitle: options[index].$3,
            selected: selected == options[index].$1,
            enabled: enabled,
            accent: theme.colorScheme.primary,
            selectedSurface: theme.colorScheme.primaryContainer,
            onPressed: () => onChanged(options[index].$1),
          ),
          if (index < options.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

final class _SpellingPromptOptions extends StatelessWidget {
  const _SpellingPromptOptions({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final SpellingPromptType selected;
  final bool enabled;
  final ValueChanged<SpellingPromptType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      (SpellingPromptType.translation, '🇨🇳', '中文提示'),
      (SpellingPromptType.phonetic, '🔤', '音标提示'),
      (SpellingPromptType.definition, '📖', '英文释义'),
    ];
    return Column(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _PracticeLongOption(
            emoji: options[index].$2,
            title: options[index].$3,
            selected: selected == options[index].$1,
            enabled: enabled,
            accent: _practiceAccent(theme, QuestionType.spelling),
            selectedSurface: _practiceAccentContainer(
              theme,
              QuestionType.spelling,
            ),
            strongSelectedBorder: true,
            height: 57,
            onPressed: () => onChanged(options[index].$1),
          ),
          if (index < options.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

final class _PracticeLongOption extends StatelessWidget {
  const _PracticeLongOption({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.selectedSurface,
    required this.onPressed,
    this.subtitle,
    this.emoji,
    this.height = 54,
    this.strongSelectedBorder = false,
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final bool selected;
  final bool enabled;
  final Color accent;
  final Color selectedSurface;
  final double height;
  final bool strongSelectedBorder;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.appBorder;
    final background = selected ? selectedSurface : theme.colorScheme.surface;
    final borderColor = selected && strongSelectedBorder
        ? accent
        : selected
        ? background
        : outline;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: background,
          foregroundColor: selected ? accent : theme.colorScheme.onSurface,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected ? accent : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? accent.withValues(alpha: 0.72)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PracticeCountButton extends StatelessWidget {
  const _PracticeCountButton({
    required this.width,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.foreground,
    required this.onPressed,
  });

  final double width;
  final int count;
  final bool selected;
  final bool enabled;
  final Color accent;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.appBorder;
    return SizedBox(
      width: width,
      height: 46,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected
              ? foreground
              : theme.colorScheme.onSurfaceVariant,
          backgroundColor: selected ? accent : theme.colorScheme.surface,
          side: BorderSide(color: selected ? accent : outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
        child: Text('$count'),
      ),
    );
  }
}

final class _PracticeToggleButton extends StatelessWidget {
  const _PracticeToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          backgroundColor: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          side: BorderSide(color: theme.appBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
        icon: Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }
}

final class _PracticeSessionBody extends StatelessWidget {
  const _PracticeSessionBody({
    required this.state,
    required this.onSubmitChoice,
    required this.onSubmitText,
    required this.onToggleFavorite,
    required this.onPlayPronunciation,
    required this.onStopPronunciation,
    required this.onNext,
    required this.onExit,
    required this.onRestart,
  });

  final PracticeRunState state;
  final Future<void> Function(String optionId) onSubmitChoice;
  final Future<void> Function(String answer) onSubmitText;
  final Future<void> Function() onToggleFavorite;
  final Future<void> Function({PronunciationAccent? accent})
  onPlayPronunciation;
  final Future<void> Function() onStopPronunciation;
  final Future<void> Function() onNext;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    if (state.phase == PracticeRunPhase.insufficientCandidates) {
      return _PracticeErrorState(
        title: '可用题目不足',
        message:
            '当前范围只有 ${state.availability?.availableCandidateCount ?? 0} 道符合条件的题目。',
        actionLabel: '重新配置',
        onAction: onRestart,
      );
    }
    if (state.phase == PracticeRunPhase.error) {
      return _PracticeErrorState(
        title: '练习暂时不可用',
        message: _sessionErrorMessage(state.errorCode),
        actionLabel: '重新配置',
        onAction: onRestart,
      );
    }
    if (state.phase == PracticeRunPhase.completed) {
      return _PracticeCompleted(
        state: state,
        onExit: onExit,
        onRestart: onRestart,
      );
    }
    final question = state.currentQuestion;
    if (question == null) {
      return _PracticeErrorState(
        title: '题目加载失败',
        message: '没有找到当前题目，请重新配置练习。',
        actionLabel: '重新配置',
        onAction: onRestart,
      );
    }
    return _PracticeQuestionBody(
      key: ValueKey(question.id),
      state: state,
      question: question,
      onSubmitChoice: onSubmitChoice,
      onSubmitText: onSubmitText,
      onToggleFavorite: onToggleFavorite,
      onPlayPronunciation: onPlayPronunciation,
      onStopPronunciation: onStopPronunciation,
      onNext: onNext,
    );
  }
}

final class _PracticeQuestionBody extends StatefulWidget {
  const _PracticeQuestionBody({
    super.key,
    required this.state,
    required this.question,
    required this.onSubmitChoice,
    required this.onSubmitText,
    required this.onToggleFavorite,
    required this.onPlayPronunciation,
    required this.onStopPronunciation,
    required this.onNext,
  });

  final PracticeRunState state;
  final QuizQuestion question;
  final Future<void> Function(String optionId) onSubmitChoice;
  final Future<void> Function(String answer) onSubmitText;
  final Future<void> Function() onToggleFavorite;
  final Future<void> Function({PronunciationAccent? accent})
  onPlayPronunciation;
  final Future<void> Function() onStopPronunciation;
  final Future<void> Function() onNext;

  @override
  State<_PracticeQuestionBody> createState() => _PracticeQuestionBodyState();
}

final class _PracticeQuestionBodyState extends State<_PracticeQuestionBody> {
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final question = widget.question;
    final theme = Theme.of(context);
    final isAnswering = state.phase == PracticeRunPhase.answering;
    final isSubmitting = state.phase == PracticeRunPhase.submitting;
    final isFeedback = state.phase == PracticeRunPhase.feedback;
    final response = state.currentResponse;
    final isCloze = question is ClozeQuestion;
    final modeType = isCloze
        ? QuestionType.cloze
        : question is SpellingQuestion
        ? QuestionType.spelling
        : QuestionType.choiceEnglishToChinese;
    final modeAccent = _practiceAccent(theme, modeType);
    final modeForeground = _practiceAccentForeground(theme, modeType);
    final modeContainer = _practiceAccentContainer(theme, modeType);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          '${state.currentQuestionIndex + 1}/${state.questionSession?.questions.length ?? 0}',
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: state.progress,
          minHeight: 5,
          borderRadius: BorderRadius.circular(5),
          color: modeAccent,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          semanticsLabel: '练习进度',
          semanticsValue: '${(state.progress * 100).round()}',
        ),
        if (state.config?.timed ?? false) ...[
          const SizedBox(height: 8),
          Text(
            '本题 ${_formatDuration(state.currentQuestionElapsed)} · 总计 ${_formatDuration(state.elapsed)}',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Container(
          constraints: isCloze
              ? const BoxConstraints(minHeight: 159, maxHeight: 159)
              : const BoxConstraints(),
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.fromLTRB(24, isCloze ? 22 : 20, 24, 20),
          decoration: BoxDecoration(
            color: isCloze ? modeContainer : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(
              isCloze ? AppRadii.sheet : AppRadii.card,
            ),
            border: Border.all(
              color: isCloze
                  ? modeAccent.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: _QuestionPrompt(question: question),
        ),
        SizedBox(height: isCloze ? 23 : 16),
        if (question is ChoiceQuestion)
          _ChoiceAnswerList(
            question: question,
            response: response,
            enabled: isAnswering,
            onSubmit: widget.onSubmitChoice,
          )
        else if (question is SpellingQuestion || question is ClozeQuestion)
          _TextAnswerPanel(
            question: question,
            response: response,
            controller: _answerController,
            enabled: isAnswering,
            submitting: isSubmitting,
            audioPhase: state.audioPhase,
            onPlayPronunciation: widget.onPlayPronunciation,
            onStopPronunciation: widget.onStopPronunciation,
            onSubmit: widget.onSubmitText,
            accent: modeAccent,
            foreground: modeForeground,
          ),
        if (state.errorCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _PracticeErrorCard(
              message: _sessionErrorMessage(state.errorCode),
            ),
          ),
        if (isFeedback && response != null) ...[
          const SizedBox(height: 16),
          _FeedbackCard(question: question, response: response),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: state.isUpdatingCurrentWordFavorite
                ? null
                : widget.onToggleFavorite,
            icon: state.isUpdatingCurrentWordFavorite
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    state.isCurrentWordFavorite
                        ? Icons.star
                        : Icons.star_border,
                  ),
            label: Text(state.isCurrentWordFavorite ? '已收藏当前单词' : '收藏当前单词'),
          ),
          if (state.favoriteErrorCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '收藏失败，请重试。',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.isUpdatingCurrentWordFavorite
                ? null
                : () => widget.onNext(),
            style: FilledButton.styleFrom(
              backgroundColor: modeAccent,
              foregroundColor: modeForeground,
            ),
            icon: Icon(
              state.isLastQuestion ? Icons.check : Icons.arrow_forward,
            ),
            label: Text(state.isLastQuestion ? '完成练习' : '下一题'),
          ),
        ],
      ],
    );
  }
}

final class _QuestionPrompt extends StatelessWidget {
  const _QuestionPrompt({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCloze = question is ClozeQuestion;
    final (title, prompt) = switch (question) {
      ChoiceQuestion(:final type, :final prompt) => (
        _questionTypeLabel(type),
        prompt,
      ),
      SpellingQuestion(:final promptType, :final promptText) => (
        _spellingPromptLabel(promptType),
        promptText ?? '请根据发音输入英文单词',
      ),
      ClozeQuestion(:final maskedSentence) => ('根据语境填入正确词形', maskedSentence),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: _practiceAccent(
              theme,
              isCloze
                  ? QuestionType.cloze
                  : QuestionType.choiceEnglishToChinese,
            ),
            fontSize: isCloze ? 12 : null,
          ),
        ),
        SizedBox(height: isCloze ? 14 : 12),
        Text(
          prompt,
          maxLines: isCloze ? 2 : null,
          overflow: isCloze ? TextOverflow.ellipsis : null,
          style: isCloze
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                )
              : theme.textTheme.headlineSmall,
        ),
        if (question case ClozeQuestion(:final translationZh)) ...[
          if (translationZh != null) ...[
            const SizedBox(height: 10),
            Text(
              translationZh,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appTextTertiary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

final class _ChoiceAnswerList extends StatelessWidget {
  const _ChoiceAnswerList({
    required this.question,
    required this.response,
    required this.enabled,
    required this.onSubmit,
  });

  final ChoiceQuestion question;
  final PracticeQuestionResponse? response;
  final bool enabled;
  final Future<void> Function(String optionId) onSubmit;

  @override
  Widget build(BuildContext context) {
    final isFeedback = response != null;
    return Column(
      children: [
        for (var index = 0; index < question.options.length; index++) ...[
          _ChoiceAnswerButton(
            index: index,
            option: question.options[index],
            selected: response?.userAnswer == question.options[index].id,
            correct: question.correctOptionId == question.options[index].id,
            showFeedback: isFeedback,
            enabled: enabled,
            onPressed: () => onSubmit(question.options[index].id),
          ),
          if (index < question.options.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

final class _ChoiceAnswerButton extends StatelessWidget {
  const _ChoiceAnswerButton({
    required this.index,
    required this.option,
    required this.selected,
    required this.correct,
    required this.showFeedback,
    required this.enabled,
    required this.onPressed,
  });

  final int index;
  final ChoiceOption option;
  final bool selected;
  final bool correct;
  final bool showFeedback;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color? backgroundColor;
    final Color? foregroundColor;
    if (showFeedback && correct) {
      backgroundColor = colorScheme.primaryContainer;
      foregroundColor = colorScheme.onPrimaryContainer;
    } else if (showFeedback && selected) {
      backgroundColor = colorScheme.errorContainer;
      foregroundColor = colorScheme.onErrorContainer;
    } else {
      backgroundColor = null;
      foregroundColor = null;
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${String.fromCharCode(65 + index)}. '),
            Expanded(child: Text(option.text)),
            if (showFeedback && correct)
              const Icon(Icons.check_circle_outline, size: 20),
            if (showFeedback && selected && !correct)
              const Icon(Icons.cancel_outlined, size: 20),
          ],
        ),
      ),
    );
  }
}

final class _TextAnswerPanel extends StatefulWidget {
  const _TextAnswerPanel({
    required this.question,
    required this.response,
    required this.controller,
    required this.enabled,
    required this.submitting,
    required this.audioPhase,
    required this.onPlayPronunciation,
    required this.onStopPronunciation,
    required this.onSubmit,
    required this.accent,
    required this.foreground,
  });

  final QuizQuestion question;
  final PracticeQuestionResponse? response;
  final TextEditingController controller;
  final bool enabled;
  final bool submitting;
  final PracticeAudioPhase audioPhase;
  final Future<void> Function({PronunciationAccent? accent})
  onPlayPronunciation;
  final Future<void> Function() onStopPronunciation;
  final Future<void> Function(String answer) onSubmit;
  final Color accent;
  final Color foreground;

  @override
  State<_TextAnswerPanel> createState() => _TextAnswerPanelState();
}

final class _TextAnswerPanelState extends State<_TextAnswerPanel> {
  int _revealedLetters = 0;

  @override
  void didUpdateWidget(covariant _TextAnswerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _revealedLetters = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFeedback = widget.response != null;
    final clozeQuestion = widget.question is ClozeQuestion
        ? widget.question as ClozeQuestion
        : null;
    final isCloze = clozeQuestion != null;
    final expected = switch (widget.question) {
      SpellingQuestion(:final expectedAnswer) => expectedAnswer,
      ClozeQuestion(:final expectedAnswer) => expectedAnswer,
      _ => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clozeQuestion != null) ...[
          Semantics(
            button: true,
            label: '显示填空提示',
            child: InkWell(
              onTap:
                  widget.enabled &&
                      _revealedLetters < clozeQuestion.answerLength
                  ? () => setState(() => _revealedLetters++)
                  : null,
              borderRadius: BorderRadius.circular(AppRadii.medium),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _revealedLetters == 0
                      ? '💡 提示：首字母 ${clozeQuestion.firstLetterHint} · 共 ${clozeQuestion.answerLength} 个字母'
                      : '💡 提示：${clozeQuestion.hintForRevealedLetters(_revealedLetters)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isCloze ? 56 : 22),
        ],
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          autofocus: false,
          textInputAction: TextInputAction.done,
          onSubmitted: widget.enabled ? widget.onSubmit : null,
          textAlign: isCloze ? TextAlign.center : TextAlign.start,
          style: isCloze
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )
              : null,
          decoration: InputDecoration(
            hintText: isCloze
                ? '填入正确词形（共${clozeQuestion.answerLength}个字母）'
                : '输入答案',
            hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCloze ? 14 : 12),
              borderSide: BorderSide(
                color: isCloze
                    ? widget.accent.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCloze ? 14 : 12),
              borderSide: BorderSide(
                color: isCloze
                    ? widget.accent.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCloze ? 14 : 12),
              borderSide: BorderSide(color: widget.accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!isFeedback)
          FilledButton(
            onPressed: widget.enabled && !widget.submitting
                ? () => widget.onSubmit(widget.controller.text)
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: widget.accent,
              foregroundColor: widget.foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
            ),
            child: widget.submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.foreground,
                    ),
                  )
                : Text(isCloze ? '确认答案' : '提交答案'),
          ),
        if (isFeedback)
          Text('正确答案：$expected', style: Theme.of(context).textTheme.bodyLarge),
        if (widget.question case SpellingQuestion(
          promptType: SpellingPromptType.audio,
        )) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: (widget.enabled || isFeedback)
                ? widget.audioPhase == PracticeAudioPhase.playing
                      ? widget.onStopPronunciation
                      : () => widget.onPlayPronunciation()
                : null,
            icon: Icon(
              widget.audioPhase == PracticeAudioPhase.playing
                  ? Icons.stop
                  : Icons.volume_up_outlined,
            ),
            label: Text(
              widget.audioPhase == PracticeAudioPhase.playing ? '停止发音' : '播放发音',
            ),
          ),
          if (widget.audioPhase == PracticeAudioPhase.unavailable ||
              widget.audioPhase == PracticeAudioPhase.error)
            Text(
              widget.audioPhase == PracticeAudioPhase.unavailable
                  ? '未找到词库音频，也未配置可用的第三方 TTS。'
                  : '发音播放失败，请重试。',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ],
    );
  }
}

final class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.question, required this.response});

  final QuizQuestion question;
  final PracticeQuestionResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = response.isCorrect;
    final expected = switch (question) {
      ChoiceQuestion(:final correctOption) => correctOption.text,
      SpellingQuestion(:final expectedAnswer) => expectedAnswer,
      ClozeQuestion(:final expectedAnswer) => expectedAnswer,
    };
    return Card(
      color: correct
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.info_outline,
              color: correct
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                correct ? '回答正确' : '再复习一下：正确答案是 $expected',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PracticeCompleted extends StatelessWidget {
  const _PracticeCompleted({
    required this.state,
    required this.onExit,
    required this.onRestart,
  });

  final PracticeRunState state;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy =
        (state.correctCount /
                (state.questionSession?.questions.length ?? 1) *
                100)
            .round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
      children: [
        Icon(Icons.task_alt, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          '练习完成',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '本次正确率 $accuracy%',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultMetric(
                  label: '题目',
                  value: '${state.answeredQuestionCount}',
                ),
                _ResultMetric(label: '答对', value: '${state.correctCount}'),
                _ResultMetric(
                  label: '用时',
                  value: _formatDuration(state.elapsed),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.refresh),
          label: const Text('再练一组'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onExit,
          icon: const Icon(Icons.home_outlined),
          label: const Text('返回首页'),
        ),
      ],
    );
  }
}

final class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

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

final class _CandidateWarning extends StatelessWidget {
  const _CandidateWarning({
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
            Text('当前范围只有 $availableCount 道可用题目。'),
            if (canUseAvailableCount) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onUseAvailableCount,
                icon: const Icon(Icons.tune),
                label: Text('改为练习 $availableCount 题'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PracticeErrorState extends StatelessWidget {
  const _PracticeErrorState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.settings_outlined),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PracticeErrorCard extends StatelessWidget {
  const _PracticeErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}

final class _PracticeSectionLabel extends StatelessWidget {
  const _PracticeSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.appTextTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

Color _practiceAccent(ThemeData theme, QuestionType type) => switch (type) {
  QuestionType.spelling => theme.colorScheme.tertiary,
  QuestionType.cloze => theme.colorScheme.secondary,
  _ => theme.colorScheme.primary,
};

Color _practiceAccentForeground(ThemeData theme, QuestionType type) =>
    switch (type) {
      QuestionType.spelling => theme.colorScheme.onTertiary,
      QuestionType.cloze => theme.colorScheme.onSecondary,
      _ => theme.colorScheme.onPrimary,
    };

Color _practiceAccentContainer(ThemeData theme, QuestionType type) =>
    switch (type) {
      QuestionType.spelling => theme.colorScheme.tertiaryContainer,
      QuestionType.cloze => theme.colorScheme.secondaryContainer,
      _ => theme.colorScheme.primaryContainer,
    };

String _practiceTitle(QuestionType type) => switch (type) {
  QuestionType.spelling => '拼写练习',
  QuestionType.cloze => '例句填空',
  _ => '选择题',
};

String _questionTypeLabel(QuestionType type) => switch (type) {
  QuestionType.choiceEnglishToChinese => '英译中',
  QuestionType.choiceChineseToEnglish => '中译英',
  QuestionType.choiceWordToSentence => '例句选择',
  QuestionType.spelling => '拼写',
  QuestionType.cloze => '例句填空',
};

String _spellingPromptLabel(SpellingPromptType type) => switch (type) {
  SpellingPromptType.translation => '中文释义拼写',
  SpellingPromptType.phonetic => '音标拼写',
  SpellingPromptType.definition => '英文释义拼写',
  SpellingPromptType.audio => '听音拼写',
};

String _setupErrorMessage(String? code) => switch (code) {
  PracticeRunErrorCodes.preparationFailed => '题目准备失败，请检查词库后重试。',
  _ => '练习准备失败，请重试。',
};

String _sessionErrorMessage(String? code) => switch (code) {
  PracticeRunErrorCodes.answerPersistenceFailed => '答案保存失败，请重新提交。',
  PracticeRunErrorCodes.completionFailed => '完成统计保存失败，请再次点击完成练习。',
  PracticeRunErrorCodes.preparationFailed => '题目准备失败，请重新配置。',
  _ => '练习暂时不可用，请重试。',
};

String _formatDuration(Duration value) {
  final seconds = value.inSeconds;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return minutes == 0
      ? '${remainder}s'
      : '$minutes:${remainder.toString().padLeft(2, '0')}';
}
