import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/favorite_page.dart';
import '../../models/domain/favorites_run_state.dart';
import '../../repositories/favorite_list_repository.dart';
import '../../repositories/favorite_repository.dart';

/// 协调收藏筛选、分页和取消收藏，不直接访问任一数据库。
final class FavoritesLogic extends GetxController {
  FavoritesLogic({
    required this.favoriteListRepository,
    required this.favoriteRepository,
    FavoriteFilter? initialFilter,
    this.autoLoad = true,
  }) : initialFilter = initialFilter ?? FavoriteFilter() {
    _state = FavoritesRunState.idle(filter: this.initialFilter);
  }

  static const String updateId = 'favorites_state';

  final FavoriteListRepository favoriteListRepository;
  final FavoriteRepository favoriteRepository;
  final FavoriteFilter initialFilter;
  final bool autoLoad;

  late FavoritesRunState _state;
  FavoritesRunState get state => _state;

  bool _closed = false;
  bool _loadingMoreBusy = false;
  int _loadToken = 0;
  Future<void>? _initialLoadTask;

  @override
  void onInit() {
    super.onInit();
    if (autoLoad) {
      unawaited(initialize());
    }
  }

  /// 使用初始筛选加载第一页；重复调用共享进行中的查询。
  Future<void> initialize() {
    if (_closed) {
      return Future<void>.value();
    }
    final active = _initialLoadTask;
    if (active != null) {
      return active;
    }
    final task = _loadFirstPage(initialFilter);
    _initialLoadTask = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_initialLoadTask, task)) {
          _initialLoadTask = null;
        }
      }),
    );
    return task;
  }

  /// 切换筛选条件并丢弃旧列表；旧查询晚返回时不会覆盖新结果。
  Future<void> applyFilter(FavoriteFilter filter) async {
    await _loadFirstPage(filter);
  }

  /// 按当前筛选重新从第一页加载。
  Future<void> reload() async {
    await _loadFirstPage(_state.filter.copyWith(page: 1));
  }

  /// 追加下一页；分页失败时保留当前已有内容并可重试。
  Future<void> loadMore() async {
    if (_closed ||
        _loadingMoreBusy ||
        !_state.hasMore ||
        _state.phase == FavoritesRunPhase.loading) {
      return;
    }
    _loadingMoreBusy = true;
    final operationToken = ++_loadToken;
    final nextFilter = _state.filter.copyWith(page: _state.filter.page + 1);
    _replace(_state.copyWith(isLoadingMore: true, errorCode: null));
    try {
      final result = await favoriteListRepository.findPage(nextFilter);
      if (!_isCurrent(operationToken)) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: result.items.isEmpty && _state.items.isEmpty
              ? FavoritesRunPhase.empty
              : FavoritesRunPhase.loaded,
          filter: nextFilter,
          items: [..._state.items, ...result.items],
          hasMore: result.hasMore,
          missingContentIds: {
            ..._state.missingContentIds,
            ...result.missingContentIds,
          }.toList(growable: false)..sort(),
          isLoadingMore: false,
          errorCode: null,
          totalCount: result.totalCount,
        ),
      );
    } on Object {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            isLoadingMore: false,
            errorCode: FavoritesErrorCodes.loadMoreFailed,
          ),
        );
      }
    } finally {
      _loadingMoreBusy = false;
    }
  }

  /// 重试失败的首次加载或分页。
  Future<void> retry() async {
    if (_state.isLoadingMore ||
        _state.errorCode == FavoritesErrorCodes.loadMoreFailed) {
      await loadMore();
      return;
    }
    if (_state.phase == FavoritesRunPhase.error) {
      await reload();
    }
  }

  /// 取消收藏单词并刷新当前筛选结果。
  Future<void> removeWord(int wordId) async {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    await _remove(
      key: 'word:$wordId',
      action: () =>
          favoriteRepository.setWordFavorite(wordId: wordId, isFavorite: false),
    );
  }

  /// 取消收藏例句并刷新当前筛选结果。
  Future<void> removeSentence(int sentenceId) async {
    if (sentenceId <= 0) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '例句 ID 必须为正整数');
    }
    await _remove(
      key: 'sentence:$sentenceId',
      action: () => favoriteRepository.setSentenceFavorite(
        sentenceId: sentenceId,
        isFavorite: false,
      ),
    );
  }

  /// 进入批量管理模式；选择只保留在当前筛选结果中。
  void startSelection() {
    if (_closed || _state.isSelectionMode) {
      return;
    }
    _replace(
      _state.copyWith(
        isSelectionMode: true,
        selectedContentIds: const {},
        errorCode: null,
      ),
    );
  }

  /// 退出批量管理并清空临时选择。
  void cancelSelection() {
    if (_closed) {
      return;
    }
    _replace(
      _state.copyWith(isSelectionMode: false, selectedContentIds: const {}),
    );
  }

  /// 切换当前可见收藏项的选择状态。
  void toggleSelection(int contentId) {
    if (_closed || !_state.isSelectionMode || _state.isBatchUpdating) {
      return;
    }
    if (!_state.items.any((item) => item.contentId == contentId)) {
      throw ArgumentError.value(contentId, 'contentId', '只能选择当前已加载的收藏内容');
    }
    final selected = {..._state.selectedContentIds};
    selected.contains(contentId)
        ? selected.remove(contentId)
        : selected.add(contentId);
    _replace(_state.copyWith(selectedContentIds: selected));
  }

  /// 批量取消当前类型中已选择的收藏；本地实现会使用单条原子删除语句。
  Future<void> removeSelected() async {
    if (_closed ||
        _state.isBatchUpdating ||
        _state.selectedContentIds.isEmpty) {
      return;
    }
    final selected = Set<int>.of(_state.selectedContentIds);
    final type = _state.filter.type;
    _replace(_state.copyWith(isBatchUpdating: true, errorCode: null));
    try {
      final repository = favoriteRepository;
      if (repository is FavoriteBatchRepository) {
        final batchRepository = repository as FavoriteBatchRepository;
        if (type == FavoriteCollectionType.words) {
          await batchRepository.removeWordFavorites(selected);
        } else {
          await batchRepository.removeSentenceFavorites(selected);
        }
      } else if (type == FavoriteCollectionType.words) {
        await Future.wait(
          selected.map(
            (wordId) =>
                repository.setWordFavorite(wordId: wordId, isFavorite: false),
          ),
        );
      } else {
        await Future.wait(
          selected.map(
            (sentenceId) => repository.setSentenceFavorite(
              sentenceId: sentenceId,
              isFavorite: false,
            ),
          ),
        );
      }
      if (!_closed) {
        await reload();
      }
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(
            isBatchUpdating: false,
            errorCode: FavoritesErrorCodes.favoriteUpdateFailed,
          ),
        );
      }
    }
  }

  Future<void> _remove({
    required String key,
    required Future<Object?> Function() action,
  }) async {
    if (_closed || _state.isUpdating(key)) {
      return;
    }
    _replace(_state.copyWith(updatingKeys: {..._state.updatingKeys, key}));
    try {
      await action();
      if (_closed) {
        return;
      }
      await reload();
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(errorCode: FavoritesErrorCodes.favoriteUpdateFailed),
        );
      }
    } finally {
      if (!_closed) {
        final updatingKeys = {..._state.updatingKeys}..remove(key);
        _replace(_state.copyWith(updatingKeys: updatingKeys));
      }
    }
  }

  Future<void> _loadFirstPage(FavoriteFilter filter) async {
    if (_closed) {
      return;
    }
    final operationToken = ++_loadToken;
    _replace(
      _state.copyWith(
        phase: FavoritesRunPhase.loading,
        filter: filter.copyWith(page: 1),
        items: const [],
        hasMore: false,
        missingContentIds: const [],
        isLoadingMore: false,
        errorCode: null,
        isSelectionMode: false,
        selectedContentIds: const {},
        isBatchUpdating: false,
        totalCount: 0,
      ),
    );
    try {
      final result = await favoriteListRepository.findPage(
        filter.copyWith(page: 1),
      );
      if (!_isCurrent(operationToken)) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: result.items.isEmpty
              ? FavoritesRunPhase.empty
              : FavoritesRunPhase.loaded,
          filter: result.filter,
          items: result.items,
          hasMore: result.hasMore,
          missingContentIds: result.missingContentIds,
          isLoadingMore: false,
          errorCode: null,
          totalCount: result.totalCount,
        ),
      );
    } on Object {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: FavoritesRunPhase.error,
            items: const [],
            hasMore: false,
            isLoadingMore: false,
            errorCode: FavoritesErrorCodes.initialLoadFailed,
            totalCount: 0,
          ),
        );
      }
    }
  }

  bool _isCurrent(int token) => !_closed && token == _loadToken;

  void _replace(FavoritesRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    _loadToken++;
    super.onClose();
  }
}
