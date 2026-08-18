import 'package:get/get.dart';

import '../../models/domain/frequency_group_summary.dart';
import '../../models/domain/vocabulary_page.dart';
import '../../models/domain/vocabulary_run_state.dart';
import '../../models/domain/word_filter.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/vocabulary_repository.dart';

/// 协调词库筛选、分页和收藏状态，不直接访问内容库或用户库 DAO。
final class VocabularyLogic extends GetxController {
  VocabularyLogic({
    required this.vocabularyRepository,
    required this.favoriteRepository,
  });

  static const String contentUpdateId = 'vocabulary_content';

  final VocabularyRepository vocabularyRepository;
  final FavoriteRepository favoriteRepository;

  VocabularyRunState _state = VocabularyRunState.idle();
  VocabularyRunState get state => _state;

  bool _closed = false;
  int _loadToken = 0;
  final Map<int, bool> _favoriteOverrides = {};
  final Map<int, bool> _favoritePreviousStates = {};

  /// 首次加载有效词频组和第一页词条。
  Future<void> initialize({WordFilter? filter}) {
    return _loadFirstPage(
      _firstPage(filter ?? _state.filter),
      loadFrequencyGroups: true,
    );
  }

  /// 应用新的组合筛选；进行中的旧查询会被标记过期。
  Future<void> applyFilter(WordFilter filter) {
    return _loadFirstPage(
      _firstPage(filter),
      loadFrequencyGroups: _state.frequencyGroups.isEmpty,
    );
  }

  /// 保留当前筛选并重新读取第一页。
  Future<void> reload() {
    return _loadFirstPage(
      _state.filter,
      loadFrequencyGroups: _state.frequencyGroups.isEmpty,
    );
  }

  /// 初始查询失败后重试当前筛选。
  Future<void> retry() {
    if (_state.phase != VocabularyRunPhase.error) {
      return Future<void>.value();
    }
    return reload();
  }

  /// 读取下一页并追加；失败时保留已经展示的词条。
  Future<void> loadMore() async {
    if (_closed ||
        _state.phase == VocabularyRunPhase.loadingMore ||
        _state.phase == VocabularyRunPhase.loading ||
        !_state.hasMore) {
      return;
    }
    if (_state.phase != VocabularyRunPhase.loaded) {
      return;
    }
    final nextPage = _state.loadedPage + 1;
    final pageFilter = _withPage(_state.filter, nextPage);
    final operationToken = ++_loadToken;
    _replaceState(
      _state.copyWith(phase: VocabularyRunPhase.loadingMore, errorCode: null),
    );
    try {
      final page = await vocabularyRepository.findPage(pageFilter);
      if (!_isCurrentLoad(operationToken)) {
        return;
      }
      _validatePage(page, pageFilter);
      final pageItems = _applyFavoriteOverrides(page.items);
      final existingIds = _state.items.map((item) => item.word.id).toSet();
      final additions = pageItems
          .where((item) => existingIds.add(item.word.id))
          .toList(growable: false);
      _replaceState(
        _state.copyWith(
          phase: VocabularyRunPhase.loaded,
          items: [..._state.items, ...additions],
          loadedPage: nextPage,
          hasMore: pageItems.isNotEmpty && page.hasMore,
          totalCount: page.totalCount,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_isCurrentLoad(operationToken)) {
        _replaceState(
          _state.copyWith(
            phase: VocabularyRunPhase.loaded,
            errorCode: VocabularyRunErrorCodes.loadMoreFailed,
          ),
        );
      }
    }
  }

  /// 分页失败后重试同一页，不重复追加已存在词条。
  Future<void> retryLoadMore() {
    if (_state.errorCode != VocabularyRunErrorCodes.loadMoreFailed) {
      return Future<void>.value();
    }
    return loadMore();
  }

  /// 幂等更新当前词条收藏；同一单词的快速重复操作只执行一次写入。
  Future<void> toggleFavorite(int wordId) async {
    if (_closed) {
      return;
    }
    final item = _state.findItem(wordId);
    if (item == null) {
      throw ArgumentError.value(wordId, 'wordId', '当前列表不存在该单词');
    }
    if (_state.updatingFavoriteWordIds.contains(wordId)) {
      return;
    }
    final target = !item.isFavorite;
    _favoriteOverrides[wordId] = target;
    _favoritePreviousStates[wordId] = item.isFavorite;
    _replaceState(
      _state.copyWith(
        updatingFavoriteWordIds: {..._state.updatingFavoriteWordIds, wordId},
        errorCode: null,
      ),
    );
    try {
      final record = await favoriteRepository.setWordFavorite(
        wordId: wordId,
        isFavorite: target,
      );
      if (_closed) {
        return;
      }
      if ((target && (record == null || record.wordId != wordId)) ||
          (!target && record != null)) {
        throw StateError('收藏写入结果与目标状态不一致');
      }
      _finishFavoriteUpdate(wordId, succeeded: true, errorCode: null);
    } on Exception {
      if (!_closed) {
        _finishFavoriteUpdate(
          wordId,
          succeeded: false,
          errorCode: VocabularyRunErrorCodes.favoriteUpdateFailed,
        );
      }
    }
  }

  /// 同步详情弹层已经成功写入的收藏状态，不重复访问收藏 Repository。
  void synchronizeFavorite({required int wordId, required bool isFavorite}) {
    if (_closed) {
      return;
    }
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    final item = _state.findItem(wordId);
    if (item == null || _state.updatingFavoriteWordIds.contains(wordId)) {
      return;
    }
    _favoriteOverrides[wordId] = isFavorite;
    _favoritePreviousStates.remove(wordId);
    if (item.isFavorite == isFavorite) {
      return;
    }
    final items = _state.items
        .map(
          (current) => current.word.id == wordId
              ? current.copyWith(isFavorite: isFavorite)
              : current,
        )
        .toList(growable: false);
    final errorCode =
        _state.errorCode == VocabularyRunErrorCodes.favoriteUpdateFailed
        ? null
        : _state.errorCode;
    _replaceState(_state.copyWith(items: items, errorCode: errorCode));
  }

  Future<void> _loadFirstPage(
    WordFilter filter, {
    required bool loadFrequencyGroups,
  }) async {
    if (_closed) {
      return;
    }
    final operationToken = ++_loadToken;
    _replaceState(
      _state.copyWith(
        phase: VocabularyRunPhase.loading,
        filter: filter,
        items: const [],
        loadedPage: 0,
        hasMore: false,
        totalCount: 0,
        errorCode: null,
      ),
    );
    try {
      final groupsFuture = loadFrequencyGroups
          ? vocabularyRepository.findActiveFrequencyGroups()
          : Future.value(_state.frequencyGroups);
      final pageFuture = vocabularyRepository.findPage(filter);
      final results = await Future.wait<Object>([groupsFuture, pageFuture]);
      if (!_isCurrentLoad(operationToken)) {
        return;
      }
      final groups = results[0] as List<FrequencyGroupSummary>;
      final page = results[1] as VocabularyPageResult;
      _validatePage(page, filter);
      final pageItems = _applyFavoriteOverrides(page.items);
      _replaceState(
        _state.copyWith(
          phase: pageItems.isEmpty
              ? VocabularyRunPhase.empty
              : VocabularyRunPhase.loaded,
          frequencyGroups: groups,
          items: pageItems,
          loadedPage: WordFilter.firstPage,
          hasMore: pageItems.isNotEmpty && page.hasMore,
          totalCount: page.totalCount,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_isCurrentLoad(operationToken)) {
        _replaceState(
          _state.copyWith(
            phase: VocabularyRunPhase.error,
            errorCode: VocabularyRunErrorCodes.initialLoadFailed,
          ),
        );
      }
    }
  }

  void _finishFavoriteUpdate(
    int wordId, {
    required bool succeeded,
    required String? errorCode,
  }) {
    final target = _favoriteOverrides[wordId];
    final previous = _favoritePreviousStates.remove(wordId);
    if (!succeeded) {
      _favoriteOverrides.remove(wordId);
    }
    final isFavorite = succeeded ? target : previous;
    final updatingIds = {..._state.updatingFavoriteWordIds}..remove(wordId);
    final items = isFavorite == null
        ? _state.items
        : _state.items
              .map(
                (item) => item.word.id == wordId
                    ? item.copyWith(isFavorite: isFavorite)
                    : item,
              )
              .toList(growable: false);
    _replaceState(
      _state.copyWith(
        items: items,
        updatingFavoriteWordIds: updatingIds,
        errorCode: errorCode,
      ),
    );
  }

  List<VocabularyWordItem> _applyFavoriteOverrides(
    List<VocabularyWordItem> items,
  ) {
    return items
        .map((item) {
          final wordId = item.word.id;
          final target = _favoriteOverrides[wordId];
          if (target == null) {
            return item;
          }
          if (item.isFavorite == target &&
              !_favoritePreviousStates.containsKey(wordId)) {
            _favoriteOverrides.remove(wordId);
            return item;
          }
          return item.copyWith(isFavorite: target);
        })
        .toList(growable: false);
  }

  void _validatePage(VocabularyPageResult page, WordFilter expected) {
    final actual = page.filter;
    if (actual.page != expected.page ||
        actual.pageSize != expected.pageSize ||
        actual.firstLetter != expected.firstLetter ||
        actual.keyword != expected.keyword ||
        actual.sortOrder != expected.sortOrder ||
        actual.frequencyGroupIds.length != expected.frequencyGroupIds.length ||
        !actual.frequencyGroupIds.containsAll(expected.frequencyGroupIds)) {
      throw StateError('词库 Repository 返回了其他筛选条件的分页结果');
    }
  }

  WordFilter _firstPage(WordFilter filter) {
    return _withPage(filter, WordFilter.firstPage);
  }

  WordFilter _withPage(WordFilter filter, int page) {
    return WordFilter(
      frequencyGroupIds: filter.frequencyGroupIds,
      firstLetter: filter.firstLetter,
      keyword: filter.keyword,
      sortOrder: filter.sortOrder,
      page: page,
      pageSize: filter.pageSize,
    );
  }

  void _replaceState(VocabularyRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([contentUpdateId]);
  }

  bool _isCurrentLoad(int operationToken) {
    return !_closed && operationToken == _loadToken;
  }

  @override
  void onClose() {
    _closed = true;
    _loadToken++;
    super.onClose();
  }
}
