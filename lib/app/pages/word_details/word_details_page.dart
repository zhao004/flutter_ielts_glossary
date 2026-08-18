import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/word_details.dart';
import '../../models/domain/word_details_run_state.dart';
import '../../routes/app_route_names.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';
import 'word_details_logic.dart';

/// 单词详情底部弹层：加载详情并在底部展示，供路由页和模态弹层复用。
class WordDetailsSheet extends StatefulWidget {
  const WordDetailsSheet({
    required this.wordId,
    this.onWordFavoriteChanged,
    super.key,
  });

  final int wordId;

  /// 单词收藏成功后通知宿主页面，避免宿主列表继续显示旧状态。
  final ValueChanged<bool>? onWordFavoriteChanged;

  @override
  State<WordDetailsSheet> createState() => _WordDetailsSheetState();
}

final class _WordDetailsSheetState extends State<WordDetailsSheet> {
  late final WordDetailsLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = Get.find<WordDetailsLogic>();
    if (widget.wordId > 0) {
      unawaited(_logic.load(widget.wordId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WordDetailsLogic>(
      id: WordDetailsLogic.contentUpdateId,
      builder: (logic) => _DetailsSheet(
        state: logic.state,
        onRetry: logic.retry,
        onToggleWordFavorite: _toggleWordFavorite,
        onToggleSentenceFavorite: logic.toggleSentenceFavorite,
        onPlay: logic.playPronunciation,
        onStop: logic.stopPronunciation,
      ),
    );
  }

  Future<void> _toggleWordFavorite() async {
    final previous = _logic.state.isWordFavorite;
    await _logic.toggleWordFavorite();
    if (!mounted) {
      return;
    }
    final state = _logic.state;
    if (state.phase != WordDetailsRunPhase.loaded ||
        state.details == null ||
        state.updatingWordFavorite ||
        state.isWordFavorite == previous) {
      return;
    }
    widget.onWordFavoriteChanged?.call(state.isWordFavorite);
  }
}

/// 单词详情路由页：透明背景 + 底部弹层，供收藏页跳转使用。
class WordDetailsPage extends StatelessWidget {
  const WordDetailsPage({required this.wordId, super.key});

  final int wordId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: Get.back<void>,
                child: ColoredBox(
                  color: theme.appPageBackground.withValues(alpha: 0.96),
                ),
              ),
            ),
            WordDetailsSheet(wordId: wordId),
          ],
        ),
      ),
    );
  }
}

final class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({
    required this.state,
    required this.onRetry,
    required this.onToggleWordFavorite,
    required this.onToggleSentenceFavorite,
    required this.onPlay,
    required this.onStop,
  });

  final WordDetailsRunState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onToggleWordFavorite;
  final Future<void> Function(int sentenceId) onToggleSentenceFavorite;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final desiredHeight = switch (state.phase) {
          WordDetailsRunPhase.loaded => 629.0,
          _ => 280.0,
        };
        final sheetHeight = desiredHeight.clamp(220.0, maxHeight - 48);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: sheetHeight,
            width: double.infinity,
            child: Material(
              color: Theme.of(context).appCardSurface,
              elevation: 8,
              shadowColor: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.sheet),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const _SheetHandle(),
                  Expanded(child: _buildContent(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (state.phase) {
      WordDetailsRunPhase.idle || WordDetailsRunPhase.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      WordDetailsRunPhase.notFound => const _SheetMessage(
        icon: Icons.search_off_rounded,
        title: '找不到这个单词',
        message: '词库版本更新后，该词条可能已被移除。',
      ),
      WordDetailsRunPhase.error => _SheetMessage(
        icon: Icons.error_outline,
        title: '单词详情加载失败',
        message: '请检查本地词库后重试。',
        onRetry: onRetry,
      ),
      WordDetailsRunPhase.loaded => _LoadedDetails(
        state: state,
        onToggleWordFavorite: onToggleWordFavorite,
        onToggleSentenceFavorite: onToggleSentenceFavorite,
        onPlay: onPlay,
        onStop: onStop,
      ),
    };
  }
}

final class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).appBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

final class _LoadedDetails extends StatelessWidget {
  const _LoadedDetails({
    required this.state,
    required this.onToggleWordFavorite,
    required this.onToggleSentenceFavorite,
    required this.onPlay,
    required this.onStop,
  });

  final WordDetailsRunState state;
  final Future<void> Function() onToggleWordFavorite;
  final Future<void> Function(int sentenceId) onToggleSentenceFavorite;
  final Future<void> Function({PronunciationAccent? accent}) onPlay;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final details = state.details!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                details.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.control),
              child: IconButton(
                key: const ValueKey('word-details-favorite'),
                onPressed: state.updatingWordFavorite
                    ? null
                    : onToggleWordFavorite,
                tooltip: state.isWordFavorite ? '取消收藏' : '收藏单词',
                icon: state.updatingWordFavorite
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppSvgIcon(
                        state.isWordFavorite
                            ? AppIconAssets.starFilled
                            : AppIconAssets.starOutline,
                        size: 21,
                        color: state.isWordFavorite
                            ? Theme.of(context).appFavorite
                            : Theme.of(context).appTextTertiary,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _AudioAction(
                label: 'UK',
                phonetic: details.phoneticUk,
                playing:
                    state.audioPhase == WordDetailsAudioPhase.playing &&
                    state.pronunciationAccent == PronunciationAccent.uk,
                onTap: () => _toggleAudio(PronunciationAccent.uk),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AudioAction(
                label: 'US',
                phonetic: details.phoneticUs,
                playing:
                    state.audioPhase == WordDetailsAudioPhase.playing &&
                    state.pronunciationAccent == PronunciationAccent.us,
                onTap: () => _toggleAudio(PronunciationAccent.us),
              ),
            ),
            IconButton(
              onPressed: () => Get.toNamed(
                AppRouteNames.pronunciation,
                arguments: {
                  'word': details.word,
                  'phonetic':
                      state.pronunciationAccent == PronunciationAccent.uk
                      ? details.phoneticUk
                      : details.phoneticUs,
                  'translation': details.translationZh,
                },
              ),
              tooltip: '发音练习',
              icon: const Icon(Icons.mic_none_rounded, size: 21),
            ),
          ],
        ),
        if (state.audioErrorCode != null)
          Text(
            _audioMessage(state.audioErrorCode!),
            style: TextStyle(color: Theme.of(context).appError, fontSize: 11),
          ),
        const SizedBox(height: 18),
        _DefinitionPanel(details: details),
        if (state.errorCode == WordDetailsErrorCodes.wordFavoriteFailed)
          const _ActionError(message: '单词收藏失败，请重试。'),
        if (details.sentences.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('例句'),
          const SizedBox(height: 10),
          for (final sentence in details.sentences) ...[
            _SentencePanel(
              sentence: sentence,
              favorite: state.isSentenceFavorite(sentence.id),
              updating: state.updatingSentenceIds.contains(sentence.id),
              onToggleFavorite: () => onToggleSentenceFavorite(sentence.id),
            ),
            const SizedBox(height: 9),
          ],
        ],
        if (state.errorCode == WordDetailsErrorCodes.sentenceFavoriteFailed)
          const _ActionError(message: '例句收藏失败，请重试。'),
        if (details.mnemonic != null && details.mnemonic!.trim().isNotEmpty)
          _MnemonicPanel(text: details.mnemonic!),
      ],
    );
  }

  Future<void> _toggleAudio(PronunciationAccent accent) {
    final playing =
        state.audioPhase == WordDetailsAudioPhase.playing &&
        state.pronunciationAccent == accent;
    return playing ? onStop() : onPlay(accent: accent);
  }
}

final class _AudioAction extends StatelessWidget {
  const _AudioAction({
    required this.label,
    required this.phonetic,
    required this.playing,
    required this.onTap,
  });

  final String label;
  final String? phonetic;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AppSvgIcon(
              AppIconAssets.volume,
              size: 18,
              color: playing
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                phonetic == null ? '暂无音标' : '/$phonetic/',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DefinitionPanel extends StatelessWidget {
  const _DefinitionPanel({required this.details});

  final WordDetails details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).appSubtleSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '释义',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).appTextTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Text(
              '词义',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            details.translationZh ?? '暂无中文释义',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (details.definitionEn != null &&
              details.definitionEn!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details.definitionEn!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).appTextSecondary,
              ),
            ),
          ],
        ],
      ),
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
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).appTextTertiary,
      ),
    );
  }
}

final class _SentencePanel extends StatelessWidget {
  const _SentencePanel({
    required this.sentence,
    required this.favorite,
    required this.updating,
    required this.onToggleFavorite,
  });

  final SentenceDetails sentence;
  final bool favorite;
  final bool updating;
  final Future<void> Function() onToggleFavorite;

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HighlightedSentence(
                    text: sentence.sentenceEn,
                    target: sentence.targetForm,
                  ),
                ),
                IconButton(
                  onPressed: updating ? null : onToggleFavorite,
                  tooltip: favorite ? '取消收藏例句' : '收藏例句',
                  icon: updating
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : AppSvgIcon(
                          favorite
                              ? AppIconAssets.starFilled
                              : AppIconAssets.starOutline,
                          size: 20,
                          color: favorite
                              ? theme.appFavorite
                              : theme.appTextTertiary,
                        ),
                ),
              ],
            ),
            if (sentence.translationZh != null &&
                sentence.translationZh!.trim().isNotEmpty)
              Text(
                sentence.translationZh!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: theme.appTextTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

final class _HighlightedSentence extends StatelessWidget {
  const _HighlightedSentence({required this.text, required this.target});

  final String text;
  final String target;

  @override
  Widget build(BuildContext context) {
    final matches = RegExp(
      RegExp.escape(target),
      caseSensitive: false,
    ).allMatches(text).toList(growable: false);
    if (matches.isEmpty) {
      return Text(text, style: Theme.of(context).textTheme.bodyMedium);
    }
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(style: Theme.of(context).textTheme.bodyMedium, children: spans),
    );
  }
}

final class _MnemonicPanel extends StatelessWidget {
  const _MnemonicPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appWarningSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: theme.appWarning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '记忆法',
            style: TextStyle(
              color: theme.appWarning,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: theme.appWarningStrong)),
        ],
      ),
    );
  }
}

final class _ActionError extends StatelessWidget {
  const _ActionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: TextStyle(color: Theme.of(context).appError)),
    );
  }
}

final class _SheetMessage extends StatelessWidget {
  const _SheetMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Theme.of(context).appTextTertiary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ],
        ),
      ),
    );
  }
}

String _audioMessage(String code) => switch (code) {
  WordDetailsErrorCodes.audioUnavailable => '未找到词库音频，也未配置可用的第三方 TTS。',
  WordDetailsErrorCodes.audioFailed => '发音播放失败，请稍后重试。',
  _ => '发音暂时不可用。',
};
