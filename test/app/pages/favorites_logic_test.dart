import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/favorite_page.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorites_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_summary.dart';
import 'package:flutter_ielts_glossary/app/pages/favorites/favorites_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_list_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';

void main() {
  test('初始化收藏列表并追加下一页', () async {
    final repository = _FakeFavoriteListRepository();
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);

    await logic.initialize();
    expect(logic.state.phase, FavoritesRunPhase.loaded);
    expect(logic.state.items.map((item) => item.contentId), [1, 2]);
    expect(logic.state.hasMore, isTrue);

    await logic.loadMore();
    expect(logic.state.items.map((item) => item.contentId), [1, 2, 3]);
    expect(logic.state.filter.page, 2);
    expect(logic.state.hasMore, isFalse);
  });

  test('分页失败保留内容，重试后恢复', () async {
    final repository = _FakeFavoriteListRepository()..failedPages.add(2);
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);
    await logic.initialize();

    await logic.loadMore();
    expect(logic.state.items, hasLength(2));
    expect(logic.state.errorCode, FavoritesErrorCodes.loadMoreFailed);

    repository.failedPages.clear();
    await logic.retry();
    expect(logic.state.items.map((item) => item.contentId), [1, 2, 3]);
    expect(logic.state.errorCode, isNull);
  });

  test('首次加载失败后按当前筛选重试', () async {
    final repository = _FakeFavoriteListRepository()..failInitial = true;
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);

    await logic.initialize();
    expect(logic.state.phase, FavoritesRunPhase.error);
    expect(logic.state.errorCode, FavoritesErrorCodes.initialLoadFailed);

    repository.failInitial = false;
    await logic.retry();
    expect(logic.state.phase, FavoritesRunPhase.loaded);
  });

  test('取消收藏拒绝重复写入，成功后刷新列表', () async {
    final repository = _FakeFavoriteListRepository();
    final favorites = _FakeFavoriteRepository()..gate = Completer<void>();
    final logic = _createLogic(repository, favorites: favorites);
    addTearDown(logic.onClose);
    await logic.initialize();

    final first = logic.removeWord(1);
    await Future<void>.delayed(Duration.zero);
    await logic.removeWord(1);
    expect(favorites.wordCalls, [1]);
    favorites.gate!.complete();
    await first;
    expect(repository.calls, greaterThan(1));
    expect(logic.state.updatingKeys, isEmpty);
  });

  test('关闭后忽略晚返回的第一页', () async {
    final repository = _FakeFavoriteListRepository()..gate = Completer<void>();
    final logic = _createLogic(repository);

    final pending = logic.initialize();
    await repository.entered.future;
    logic.onClose();
    repository.gate!.complete();
    await pending;

    expect(logic.state.phase, FavoritesRunPhase.loading);
  });
}

FavoritesLogic _createLogic(
  _FakeFavoriteListRepository repository, {
  _FakeFavoriteRepository? favorites,
}) {
  return FavoritesLogic(
    favoriteListRepository: repository,
    favoriteRepository: favorites ?? _FakeFavoriteRepository(),
    initialFilter: FavoriteFilter(pageSize: 2),
    autoLoad: false,
  );
}

final class _FakeFavoriteListRepository implements FavoriteListRepository {
  final Set<int> failedPages = {};
  bool failInitial = false;
  int calls = 0;
  Completer<void>? gate;
  final Completer<void> entered = Completer<void>();

  @override
  Future<FavoritePageResult> findPage(FavoriteFilter filter) async {
    calls++;
    if (!entered.isCompleted) {
      entered.complete();
    }
    final currentGate = gate;
    if (currentGate != null && !currentGate.isCompleted) {
      await currentGate.future;
    }
    if (filter.page == 1 && failInitial || failedPages.contains(filter.page)) {
      throw StateError('favorite page failed');
    }
    final items = switch (filter.page) {
      1 => [_item(1), _item(2)],
      2 => [_item(3)],
      _ => <FavoriteListItem>[],
    };
    return FavoritePageResult(
      filter: filter,
      items: items,
      hasMore: filter.page == 1,
      missingContentIds: const [],
    );
  }
}

FavoriteWordItem _item(int id) {
  final now = DateTime.utc(2026, 8, 15);
  return FavoriteWordItem(
    favorite: FavoriteWordRecord(
      id: 'favorite-$id',
      wordId: id,
      createdAt: now,
      updatedAt: now,
    ),
    word: WordSummary(
      id: id,
      word: 'word-$id',
      phoneticUk: null,
      translationZh: '释义',
      occurrences: 100,
      frequencyGroupId: 1,
    ),
    learningState: null,
  );
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  final List<int> wordCalls = [];
  Completer<void>? gate;

  @override
  Future<FavoriteWordRecord?> setWordFavorite({
    required int wordId,
    required bool isFavorite,
  }) async {
    wordCalls.add(wordId);
    final currentGate = gate;
    if (currentGate != null && !currentGate.isCompleted) {
      await currentGate.future;
    }
    return null;
  }

  @override
  Future<List<FavoriteSentenceRecord>> findFavoriteSentences({
    int limit = 100,
    int offset = 0,
  }) async => [];

  @override
  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  }) async => [];

  @override
  Future<Set<int>> findFavoriteSentenceIds(Set<int> sentenceIds) async => {};

  @override
  Future<Set<int>> findFavoriteWordIds(Set<int> wordIds) async => {};

  @override
  Future<bool> isSentenceFavorite(int sentenceId) async => false;

  @override
  Future<bool> isWordFavorite(int wordId) async => false;

  @override
  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  }) async => null;
}
