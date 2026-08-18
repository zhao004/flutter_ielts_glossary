import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/favorite_page.dart';
import '../../models/domain/favorites_run_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';
import '../word_details/word_details_binding.dart';
import '../word_details/word_details_logic.dart';
import '../word_details/word_details_page.dart';
import 'favorites_logic.dart';

/// 收藏主页面，按设计稿承载搜索、排序、分类与批量取消收藏流程。
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        body: const SafeArea(child: _FavoritesBody()),
      ),
    );
  }
}

final class _FavoritesBody extends StatefulWidget {
  const _FavoritesBody();

  @override
  State<_FavoritesBody> createState() => _FavoritesBodyState();
}

final class _FavoritesBodyState extends State<_FavoritesBody> {
  final _searchController = TextEditingController();
  final _counts = <FavoriteCollectionType, int>{
    FavoriteCollectionType.words: 0,
    FavoriteCollectionType.sentences: 0,
  };
  Timer? _searchDebounce;
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FavoritesLogic>(
      id: FavoritesLogic.updateId,
      builder: (logic) {
        final state = logic.state;
        _counts[state.filter.type] = state.totalCount;
        return Column(
          children: [
            AppBar(
              primary: false,
              title: _searchVisible
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      maxLength: 100,
                      onChanged: (value) => _search(logic, value),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '搜索收藏',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    )
                  : Text(
                      '收藏',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              actions: [
                _HeaderIconButton(
                  tooltip: _searchVisible ? '关闭搜索' : '搜索收藏',
                  onPressed: () => _toggleSearch(logic),
                  child: _searchVisible
                      ? const Icon(Icons.close, size: 21)
                      : AppSvgIcon(
                          AppIconAssets.search,
                          size: 20,
                          color: Theme.of(context).appTextTertiary,
                        ),
                ),
                const SizedBox(width: 8),
                _HeaderPill(
                  label:
                      state.filter.sortOrder ==
                          FavoriteSortOrder.alphabetAscending
                      ? 'A→Z'
                      : 'Z→A',
                  tooltip: '切换字母排序',
                  onPressed: () => logic.applyFilter(
                    state.filter.copyWith(
                      sortOrder:
                          state.filter.sortOrder ==
                              FavoriteSortOrder.alphabetAscending
                          ? FavoriteSortOrder.alphabetDescending
                          : FavoriteSortOrder.alphabetAscending,
                      page: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderPill(
                  label: state.isSelectionMode ? '完成' : '多选',
                  tooltip: state.isSelectionMode ? '退出多选' : '批量管理',
                  onPressed: state.isSelectionMode
                      ? logic.cancelSelection
                      : logic.startSelection,
                ),
              ],
            ),
            _FavoritesTabs(
              selected: state.filter.type,
              counts: _counts,
              onSelected: (type) {
                _searchDebounce?.cancel();
                logic.applyFilter(
                  FavoriteFilter(
                    type: type,
                    keyword: state.filter.keyword,
                    sortOrder: state.filter.sortOrder,
                    pageSize: state.filter.pageSize,
                  ),
                );
              },
            ),
            Expanded(
              child: _FavoritesContent(
                state: state,
                onRefresh: logic.reload,
                onLoadMore: logic.loadMore,
                onRetry: logic.retry,
                onToggleSelection: logic.toggleSelection,
                onRemoveWord: logic.removeWord,
                onRemoveSentence: logic.removeSentence,
              ),
            ),
            if (state.isSelectionMode)
              _SelectionActionBar(
                selectedCount: state.selectedContentIds.length,
                busy: state.isBatchUpdating,
                onRemove: logic.removeSelected,
              ),
          ],
        );
      },
    );
  }

  void _toggleSearch(FavoritesLogic logic) {
    _searchDebounce?.cancel();
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchController.clear();
      }
    });
    if (!_searchVisible && logic.state.filter.keyword != null) {
      unawaited(
        logic.applyFilter(logic.state.filter.copyWith(keyword: null, page: 1)),
      );
    }
  }

  void _search(FavoritesLogic logic, String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      unawaited(
        logic.applyFilter(logic.state.filter.copyWith(keyword: value, page: 1)),
      );
    });
  }
}

final class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: SizedBox(width: 30, height: 30, child: Center(child: child)),
      ),
    );
  }
}

final class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.appSubtleSurface,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.appTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _FavoritesTabs extends StatelessWidget {
  const _FavoritesTabs({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final FavoriteCollectionType selected;
  final Map<FavoriteCollectionType, int> counts;
  final ValueChanged<FavoriteCollectionType> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.appCardSurface,
      child: Row(
        children: [
          for (final type in FavoriteCollectionType.values)
            Expanded(
              child: _FavoriteTab(
                label: type == FavoriteCollectionType.words ? '单词' : '例句',
                count: counts[type] ?? 0,
                selected: type == selected,
                onTap: () => onSelected(type),
              ),
            ),
        ],
      ),
    );
  }
}

final class _FavoriteTab extends StatelessWidget {
  const _FavoriteTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? primary : theme.appTextTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.1)
                        : theme.appSubtleSurface,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: Text(
                        '$count',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected ? primary : theme.appTextTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 2, color: primary),
              ),
          ],
        ),
      ),
    );
  }
}

final class _FavoritesContent extends StatelessWidget {
  const _FavoritesContent({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetry,
    required this.onToggleSelection,
    required this.onRemoveWord,
    required this.onRemoveSentence,
  });

  final FavoritesRunState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRetry;
  final ValueChanged<int> onToggleSelection;
  final Future<void> Function(int) onRemoveWord;
  final Future<void> Function(int) onRemoveSentence;

  Future<void> _showWordDetails(BuildContext context, int wordId) async {
    if (!Get.isRegistered<WordDetailsLogic>()) {
      WordDetailsBinding().dependencies();
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => WordDetailsSheet(wordId: wordId),
    );
    if (Get.isRegistered<WordDetailsLogic>()) {
      Get.delete<WordDetailsLogic>(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.phase == FavoritesRunPhase.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.phase == FavoritesRunPhase.error && state.items.isEmpty) {
      return _FavoritesMessage(
        icon: Icons.error_outline,
        title: '收藏加载失败',
        actionLabel: '重试',
        onAction: onRetry,
      );
    }
    if (state.items.isEmpty) {
      return _FavoritesMessage(
        icon: state.filter.type == FavoriteCollectionType.words
            ? Icons.star_border_rounded
            : Icons.format_quote_rounded,
        title: state.filter.keyword == null
            ? state.filter.type == FavoriteCollectionType.words
                  ? '还没有收藏单词'
                  : '还没有收藏例句'
            : '没有匹配的收藏',
        actionLabel: '刷新',
        onAction: onRefresh,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 180 &&
            state.hasMore &&
            !state.isLoadingMore) {
          unawaited(onLoadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final item = state.items[index];
            final selected = state.selectedContentIds.contains(item.contentId);
            return switch (item) {
              FavoriteWordItem word => _FavoriteWordCard(
                item: word,
                selected: selected,
                selectionMode: state.isSelectionMode,
                updating: state.isUpdating('word:${word.word.id}'),
                onTap: state.isSelectionMode
                    ? () => onToggleSelection(word.contentId)
                    : () => unawaited(_showWordDetails(context, word.word.id)),
                onRemove: () => onRemoveWord(word.word.id),
              ),
              FavoriteSentenceItem sentence => _FavoriteSentenceCard(
                item: sentence,
                selected: selected,
                selectionMode: state.isSelectionMode,
                updating: state.isUpdating('sentence:${sentence.sentence.id}'),
                onTap: state.isSelectionMode
                    ? () => onToggleSelection(sentence.contentId)
                    : () => unawaited(
                        _showWordDetails(context, sentence.word.id),
                      ),
                onRemove: () => onRemoveSentence(sentence.sentence.id),
              ),
            };
          },
        ),
      ),
    );
  }
}

final class _FavoriteWordCard extends StatelessWidget {
  const _FavoriteWordCard({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.updating,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteWordItem item;
  final bool selected;
  final bool selectionMode;
  final bool updating;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          if (selectionMode) ...[
            _SelectionIndicator(selected: selected),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.word.word,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.word.phoneticUk ?? item.word.phoneticUs ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).appTextTertiary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.word.translationZh ?? '暂无释义',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!selectionMode)
            _FavoriteButton(updating: updating, onPressed: onRemove),
        ],
      ),
    );
  }
}

final class _FavoriteSentenceCard extends StatelessWidget {
  const _FavoriteSentenceCard({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.updating,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteSentenceItem item;
  final bool selected;
  final bool selectionMode;
  final bool updating;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      selected: selected,
      minHeight: 126,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectionMode) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _SelectionIndicator(selected: selected),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.word.word,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.sentence.sentenceEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 5),
                Text(
                  item.sentence.translationZh ?? '暂无翻译',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).appTextTertiary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!selectionMode)
            _FavoriteButton(updating: updating, onPressed: onRemove),
        ],
      ),
    );
  }
}

final class _FavoriteCardShell extends StatelessWidget {
  const _FavoriteCardShell({
    required this.selected,
    required this.onTap,
    required this.child,
    this.minHeight = 88,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.appCardSurface,
      elevation: isDark ? 0 : 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.appBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

final class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.updating, required this.onPressed});

  final bool updating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: updating ? null : onPressed,
      tooltip: '取消收藏',
      icon: updating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : AppSvgIcon(
              AppIconAssets.starFilled,
              size: 22,
              color: Theme.of(context).appFavorite,
            ),
    );
  }
}

final class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? primary : theme.appBorder,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: theme.colorScheme.onPrimary)
          : null,
    );
  }
}

final class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedCount,
    required this.busy,
    required this.onRemove,
  });

  final int selectedCount;
  final bool busy;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).appCardSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton.icon(
            onPressed: selectedCount == 0 || busy ? null : onRemove,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.star_border_rounded, size: 20),
            label: Text(selectedCount == 0 ? '请选择收藏' : '取消收藏 ($selectedCount)'),
          ),
        ),
      ),
    );
  }
}

final class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 150),
        Icon(icon, size: 48, color: Theme.of(context).appTextTertiary),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    );
  }
}
