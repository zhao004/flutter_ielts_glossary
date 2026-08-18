import 'frequency_group_summary.dart';
import 'vocabulary_page.dart';
import 'word_filter.dart';

/// 词库总览的稳定加载阶段。
enum VocabularyRunPhase { idle, loading, loaded, empty, loadingMore, error }

/// 页面只消费稳定错误码，不展示 SQL、FTS 或文件异常正文。
abstract final class VocabularyRunErrorCodes {
  static const String initialLoadFailed = 'vocabulary_initial_load_failed';
  static const String loadMoreFailed = 'vocabulary_load_more_failed';
  static const String favoriteUpdateFailed =
      'vocabulary_favorite_update_failed';
}

/// 词库列表的不可变页面状态快照。
final class VocabularyRunState {
  VocabularyRunState({
    required this.phase,
    required List<FrequencyGroupSummary> frequencyGroups,
    required this.filter,
    required List<VocabularyWordItem> items,
    required this.loadedPage,
    required this.hasMore,
    this.totalCount = 0,
    required Set<int> updatingFavoriteWordIds,
    required this.errorCode,
  }) : frequencyGroups = List<FrequencyGroupSummary>.unmodifiable(
         frequencyGroups,
       ),
       items = List<VocabularyWordItem>.unmodifiable(items),
       updatingFavoriteWordIds = Set<int>.unmodifiable(
         updatingFavoriteWordIds,
       ) {
    if (filter.page != WordFilter.firstPage) {
      throw ArgumentError('页面状态中的筛选条件必须固定为第一页');
    }
    if (loadedPage < 0 || (loadedPage == 0 && this.items.isNotEmpty)) {
      throw ArgumentError('已加载页码与词条数量不一致');
    }
    if (this.items.isEmpty && hasMore) {
      throw ArgumentError('空列表不能声明存在下一页');
    }
    final wordIds = this.items.map((item) => item.word.id).toSet();
    if (wordIds.length != this.items.length) {
      throw ArgumentError('词库状态不能包含重复词条');
    }
    final groupIds = this.frequencyGroups.map((group) => group.id).toSet();
    final groupRanks = this.frequencyGroups.map((group) => group.rank).toSet();
    if (groupIds.length != this.frequencyGroups.length ||
        groupRanks.length != this.frequencyGroups.length) {
      throw ArgumentError('有效词频组 ID 和 rank 必须唯一');
    }
  }

  factory VocabularyRunState.idle() {
    return VocabularyRunState(
      phase: VocabularyRunPhase.idle,
      frequencyGroups: const [],
      filter: WordFilter(),
      items: const [],
      loadedPage: 0,
      hasMore: false,
      updatingFavoriteWordIds: const {},
      errorCode: null,
    );
  }

  final VocabularyRunPhase phase;
  final List<FrequencyGroupSummary> frequencyGroups;
  final WordFilter filter;
  final List<VocabularyWordItem> items;
  final int loadedPage;
  final bool hasMore;
  final int totalCount;
  final Set<int> updatingFavoriteWordIds;
  final String? errorCode;

  VocabularyWordItem? findItem(int wordId) {
    for (final item in items) {
      if (item.word.id == wordId) {
        return item;
      }
    }
    return null;
  }

  VocabularyRunState copyWith({
    VocabularyRunPhase? phase,
    List<FrequencyGroupSummary>? frequencyGroups,
    WordFilter? filter,
    List<VocabularyWordItem>? items,
    int? loadedPage,
    bool? hasMore,
    int? totalCount,
    Set<int>? updatingFavoriteWordIds,
    Object? errorCode = _unset,
  }) {
    return VocabularyRunState(
      phase: phase ?? this.phase,
      frequencyGroups: frequencyGroups ?? this.frequencyGroups,
      filter: filter ?? this.filter,
      items: items ?? this.items,
      loadedPage: loadedPage ?? this.loadedPage,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      updatingFavoriteWordIds:
          updatingFavoriteWordIds ?? this.updatingFavoriteWordIds,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const _unset = Object();
