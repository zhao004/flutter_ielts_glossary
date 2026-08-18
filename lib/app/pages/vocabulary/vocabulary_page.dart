import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/vocabulary_page.dart';
import '../../models/domain/vocabulary_run_state.dart';
import '../../models/domain/word_filter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_svg_icon.dart';
import '../word_details/word_details_binding.dart';
import '../word_details/word_details_logic.dart';
import '../word_details/word_details_page.dart';
import 'vocabulary_logic.dart';

/// 词库总览：按关键词和三档难度筛选，并支持分页与收藏。
class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

final class _VocabularyPageState extends State<VocabularyPage> {
  late final VocabularyLogic _logic;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _logic = Get.find<VocabularyLogic>();
    _searchController = TextEditingController(
      text: _logic.state.filter.keyword ?? '',
    );
    _scrollController = ScrollController()..addListener(_loadMoreNearBottom);
    unawaited(_logic.initialize());
  }

  void _loadMoreNearBottom() {
    if (_scrollController.position.extentAfter < 260) {
      unawaited(_logic.loadMore());
    }
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _applyFilter(keyword: value);
    });
  }

  void _applyFilter({Set<int>? groups, Object? keyword = _unset}) {
    final current = _logic.state.filter;
    final next = WordFilter(
      frequencyGroupIds: groups ?? current.frequencyGroupIds,
      keyword: identical(keyword, _unset)
          ? current.keyword
          : keyword as String?,
      sortOrder: current.sortOrder,
      pageSize: current.pageSize,
    );
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    unawaited(_logic.applyFilter(next));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_loadMoreNearBottom)
      ..dispose();
    _searchController.dispose();
    super.dispose();
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
      child: Scaffold(
        backgroundColor: Theme.of(context).appPageBackground,
        body: GetBuilder<VocabularyLogic>(
          id: VocabularyLogic.contentUpdateId,
          builder: (logic) => _VocabularyBody(
            logic: logic,
            searchController: _searchController,
            scrollController: _scrollController,
            onSearch: _scheduleSearch,
            onGroupsChanged: (groups) => _applyFilter(groups: groups),
          ),
        ),
      ),
    );
  }
}

const _unset = Object();

final class _VocabularyBody extends StatelessWidget {
  const _VocabularyBody({
    required this.logic,
    required this.searchController,
    required this.scrollController,
    required this.onSearch,
    required this.onGroupsChanged,
  });

  final VocabularyLogic logic;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onSearch;
  final ValueChanged<Set<int>> onGroupsChanged;

  Future<void> _showWordDetails(BuildContext context, int wordId) async {
    if (!Get.isRegistered<WordDetailsLogic>()) {
      WordDetailsBinding().dependencies();
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => WordDetailsSheet(
        wordId: wordId,
        onWordFavoriteChanged: (isFavorite) =>
            logic.synchronizeFavorite(wordId: wordId, isFavorite: isFavorite),
      ),
    );
    if (Get.isRegistered<WordDetailsLogic>()) {
      Get.delete<WordDetailsLogic>(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = logic.state;
    final initialLoading =
        state.phase == VocabularyRunPhase.loading && state.items.isEmpty;
    return RefreshIndicator(
      onRefresh: logic.reload,
      child: CustomScrollView(
        key: const PageStorageKey<String>('vocabulary-list'),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _VocabularyHeader(
              filter: state.filter,
              searchController: searchController,
              onSearch: onSearch,
              onGroupsChanged: onGroupsChanged,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '共 ${state.totalCount} 个单词',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).appTextTertiary,
                ),
              ),
            ),
          ),
          if (initialLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.phase == VocabularyRunPhase.error &&
              state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _VocabularyFailure(onRetry: logic.retry),
            )
          else if (state.phase == VocabularyRunPhase.empty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _VocabularyEmpty(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _VocabularyWordCard(
                    item: item,
                    updating: state.updatingFavoriteWordIds.contains(
                      item.word.id,
                    ),
                    onFavorite: () => logic.toggleFavorite(item.word.id),
                    onOpen: () => _showWordDetails(context, item.word.id),
                  );
                },
              ),
            ),
          if (state.phase == VocabularyRunPhase.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          if (state.errorCode == VocabularyRunErrorCodes.loadMoreFailed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: logic.retryLoadMore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('加载失败，点击重试'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _VocabularyHeader extends StatelessWidget {
  const _VocabularyHeader({
    required this.filter,
    required this.searchController,
    required this.onSearch,
    required this.onGroupsChanged,
  });

  final WordFilter filter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<Set<int>> onGroupsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: theme.appCardSurface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16 + topInset, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('词库', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '搜索单词或中文释义...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.appTextTertiary,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(11),
                    child: AppSvgIcon(AppIconAssets.search, size: 20),
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        tooltip: '清除',
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          searchController.clear();
                          FocusScope.of(context).unfocus();
                          onSearch('');
                        },
                      );
                    },
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _FilterChip(
                  label: '全部',
                  selected: filter.frequencyGroupIds.isEmpty,
                  onTap: () => onGroupsChanged(const {}),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '初级',
                  selected: _sameGroups(filter.frequencyGroupIds, const {1, 2}),
                  onTap: () => onGroupsChanged(const {1, 2}),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '中级',
                  selected: _sameGroups(filter.frequencyGroupIds, const {3, 4}),
                  onTap: () => onGroupsChanged(const {3, 4}),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '高级',
                  selected: _sameGroups(filter.frequencyGroupIds, const {5, 6}),
                  onTap: () => onGroupsChanged(const {5, 6}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.appSubtleSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.appTextSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

final class _VocabularyWordCard extends StatelessWidget {
  const _VocabularyWordCard({
    required this.item,
    required this.updating,
    required this.onFavorite,
    required this.onOpen,
  });

  final VocabularyWordItem item;
  final bool updating;
  final Future<void> Function() onFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = item.word;
    return Material(
      color: theme.appCardSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            word.word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _DifficultyBadge(groupId: word.frequencyGroupId),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "/${word.phoneticUk ?? '暂无音标'}/",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.appTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      word.translationZh ?? '暂无中文释义',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('vocabulary-favorite-${word.id}'),
                onPressed: updating ? null : onFavorite,
                tooltip: item.isFavorite ? '取消收藏' : '收藏单词',
                visualDensity: VisualDensity.compact,
                icon: updating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppSvgIcon(
                        item.isFavorite
                            ? AppIconAssets.starFilled
                            : AppIconAssets.starOutline,
                        size: 20,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final common = groupId <= 2;
    final color = common ? theme.appSuccess : theme.appTextSecondary;
    final background = common
        ? theme.appSuccess.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12,
          )
        : theme.appSubtleSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        common ? '常用' : '进阶',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final class _VocabularyEmpty extends StatelessWidget {
  const _VocabularyEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          const Text('没有匹配的单词'),
        ],
      ),
    );
  }
}

final class _VocabularyFailure extends StatelessWidget {
  const _VocabularyFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('词库加载失败，点击重试'),
      ),
    );
  }
}

bool _sameGroups(Set<int> left, Set<int> right) =>
    left.length == right.length && left.containsAll(right);
