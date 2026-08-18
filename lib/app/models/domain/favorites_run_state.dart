import 'favorite_page.dart';

/// 收藏列表的分页阶段。
enum FavoritesRunPhase { idle, loading, loaded, empty, error }

/// 收藏列表稳定错误码；页面不展示底层数据库异常正文。
abstract final class FavoritesErrorCodes {
  static const String initialLoadFailed = 'favorites_initial_load_failed';
  static const String loadMoreFailed = 'favorites_load_more_failed';
  static const String favoriteUpdateFailed = 'favorites_update_failed';
}

/// 收藏页不可变状态，保留缺失内容报告和分页游标。
final class FavoritesRunState {
  FavoritesRunState({
    required this.phase,
    required this.filter,
    required List<FavoriteListItem> items,
    required this.hasMore,
    required List<int> missingContentIds,
    required this.isLoadingMore,
    required Set<String> updatingKeys,
    required this.errorCode,
    this.isSelectionMode = false,
    Set<int> selectedContentIds = const {},
    this.isBatchUpdating = false,
    this.totalCount = 0,
  }) : items = List<FavoriteListItem>.unmodifiable(items),
       missingContentIds = List<int>.unmodifiable(missingContentIds),
       updatingKeys = Set<String>.unmodifiable(updatingKeys),
       selectedContentIds = Set<int>.unmodifiable(selectedContentIds) {
    final expectedType = filter.type;
    if (this.items.any(
      (item) => expectedType == FavoriteCollectionType.words
          ? item is! FavoriteWordItem
          : item is! FavoriteSentenceItem,
    )) {
      throw ArgumentError('收藏结果项类型与筛选类型不一致');
    }
    if (this.items.length > filter.page * filter.pageSize) {
      throw ArgumentError('收藏状态项超过当前页允许的范围');
    }
    if (missingContentIds.any((id) => id <= 0)) {
      throw ArgumentError('缺失收藏内容 ID 必须为正整数');
    }
    if (selectedContentIds.any((id) => id <= 0)) {
      throw ArgumentError('选中的收藏内容 ID 必须为正整数');
    }
  }

  factory FavoritesRunState.idle({FavoriteFilter? filter}) {
    return FavoritesRunState(
      phase: FavoritesRunPhase.idle,
      filter: filter ?? FavoriteFilter(),
      items: const [],
      hasMore: false,
      missingContentIds: const [],
      isLoadingMore: false,
      updatingKeys: const {},
      errorCode: null,
      isSelectionMode: false,
      selectedContentIds: const {},
      isBatchUpdating: false,
      totalCount: 0,
    );
  }

  final FavoritesRunPhase phase;
  final FavoriteFilter filter;
  final List<FavoriteListItem> items;
  final bool hasMore;
  final List<int> missingContentIds;
  final bool isLoadingMore;
  final Set<String> updatingKeys;
  final String? errorCode;
  final bool isSelectionMode;
  final Set<int> selectedContentIds;
  final bool isBatchUpdating;
  final int totalCount;

  bool isUpdating(String key) => updatingKeys.contains(key);

  FavoritesRunState copyWith({
    FavoritesRunPhase? phase,
    FavoriteFilter? filter,
    List<FavoriteListItem>? items,
    bool? hasMore,
    List<int>? missingContentIds,
    bool? isLoadingMore,
    Set<String>? updatingKeys,
    Object? errorCode = _unset,
    bool? isSelectionMode,
    Set<int>? selectedContentIds,
    bool? isBatchUpdating,
    int? totalCount,
  }) {
    return FavoritesRunState(
      phase: phase ?? this.phase,
      filter: filter ?? this.filter,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      missingContentIds: missingContentIds ?? this.missingContentIds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      updatingKeys: updatingKeys ?? this.updatingKeys,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedContentIds: selectedContentIds ?? this.selectedContentIds,
      isBatchUpdating: isBatchUpdating ?? this.isBatchUpdating,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

const _unset = Object();
