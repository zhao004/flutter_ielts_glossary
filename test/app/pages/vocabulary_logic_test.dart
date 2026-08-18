import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/favorite_record.dart';
import 'package:flutter_ielts_glossary/app/models/domain/frequency_group_summary.dart';
import 'package:flutter_ielts_glossary/app/models/domain/vocabulary_page.dart';
import 'package:flutter_ielts_glossary/app/models/domain/vocabulary_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_summary.dart';
import 'package:flutter_ielts_glossary/app/pages/vocabulary/vocabulary_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/vocabulary_repository.dart';

void main() {
  test('初始化筛选项并按前瞻结果追加下一页', () async {
    final repository = _FakeVocabularyRepository();
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);

    await logic.initialize(filter: WordFilter(pageSize: 2));
    expect(logic.state.phase, VocabularyRunPhase.loaded);
    expect(logic.state.frequencyGroups.map((group) => group.id), [1, 2]);
    expect(logic.state.items.map((item) => item.word.id), [1, 2]);
    expect(logic.state.hasMore, isTrue);

    await logic.loadMore();
    expect(logic.state.items.map((item) => item.word.id), [1, 2, 3]);
    expect(logic.state.loadedPage, 2);
    expect(logic.state.hasMore, isFalse);
  });

  test('快速切换筛选只接收最后一次查询结果', () async {
    final repository = _FakeVocabularyRepository()..blockKeyword('slow');
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);

    final slow = logic.applyFilter(WordFilter(keyword: 'slow'));
    await repository.enteredFor('slow').future;
    await logic.applyFilter(WordFilter(keyword: 'fast'));
    repository.releaseKeyword('slow');
    await slow;

    expect(logic.state.filter.keyword, 'fast');
    expect(logic.state.items.single.word.word, 'fast');
  });

  test('分页失败保留已有内容并可重试同一页', () async {
    final repository = _FakeVocabularyRepository()..failedPages.add(2);
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);
    await logic.initialize(filter: WordFilter(pageSize: 2));

    await logic.loadMore();
    expect(logic.state.phase, VocabularyRunPhase.loaded);
    expect(logic.state.items.map((item) => item.word.id), [1, 2]);
    expect(logic.state.loadedPage, 1);
    expect(logic.state.errorCode, VocabularyRunErrorCodes.loadMoreFailed);

    repository.failedPages.clear();
    await logic.retryLoadMore();
    expect(logic.state.items.map((item) => item.word.id), [1, 2, 3]);
    expect(logic.state.errorCode, null);
  });

  test('首次加载失败进入 error 并按当前筛选恢复', () async {
    final repository = _FakeVocabularyRepository()..failInitial = true;
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);

    await logic.initialize(filter: WordFilter(keyword: 'fast'));
    expect(logic.state.phase, VocabularyRunPhase.error);
    expect(logic.state.errorCode, VocabularyRunErrorCodes.initialLoadFailed);

    repository.failInitial = false;
    await logic.retry();
    expect(logic.state.phase, VocabularyRunPhase.loaded);
    expect(logic.state.items.single.word.word, 'fast');
  });

  test('收藏写入与刷新并行时使用目标状态，失败后恢复原状态', () async {
    final repository = _FakeVocabularyRepository();
    final favorites = _FakeFavoriteRepository()..gate = Completer<void>();
    final logic = _createLogic(repository, favorites: favorites);
    addTearDown(logic.onClose);
    await logic.initialize(filter: WordFilter(pageSize: 2));

    final toggle = logic.toggleFavorite(1);
    await Future<void>.delayed(Duration.zero);
    await logic.toggleFavorite(1);
    expect(favorites.calls, [(1, true)]);
    await logic.reload();
    expect(logic.state.findItem(1)?.isFavorite, isTrue);
    favorites.gate!.complete();
    await toggle;
    expect(logic.state.findItem(1)?.isFavorite, isTrue);

    favorites.fail = true;
    await logic.toggleFavorite(1);
    expect(logic.state.findItem(1)?.isFavorite, isTrue);
    expect(logic.state.errorCode, VocabularyRunErrorCodes.favoriteUpdateFailed);
  });

  test('详情收藏成功后同步当前列表项并在刷新期间保留状态', () async {
    final repository = _FakeVocabularyRepository();
    final logic = _createLogic(repository);
    addTearDown(logic.onClose);
    await logic.initialize(filter: WordFilter(pageSize: 2));

    logic.synchronizeFavorite(wordId: 1, isFavorite: true);
    expect(logic.state.findItem(1)?.isFavorite, isTrue);

    await logic.reload();
    expect(logic.state.findItem(1)?.isFavorite, isTrue);

    logic.synchronizeFavorite(wordId: 1, isFavorite: false);
    expect(logic.state.findItem(1)?.isFavorite, isFalse);
  });

  test('关闭后忽略晚返回分页结果', () async {
    final repository = _FakeVocabularyRepository()..blockKeyword('slow');
    final logic = _createLogic(repository);

    final pending = logic.applyFilter(WordFilter(keyword: 'slow'));
    await repository.enteredFor('slow').future;
    logic.onClose();
    repository.releaseKeyword('slow');
    await pending;

    expect(logic.state.phase, VocabularyRunPhase.loading);
  });
}

VocabularyLogic _createLogic(
  _FakeVocabularyRepository repository, {
  _FakeFavoriteRepository? favorites,
}) {
  return VocabularyLogic(
    vocabularyRepository: repository,
    favoriteRepository: favorites ?? _FakeFavoriteRepository(),
  );
}

final class _FakeVocabularyRepository implements VocabularyRepository {
  final Set<int> failedPages = {};
  final Map<String, Completer<void>> _gates = {};
  final Map<String, Completer<void>> _entered = {};
  bool failInitial = false;

  @override
  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups() async {
    if (failInitial) {
      throw Exception('groups failed');
    }
    return [
      FrequencyGroupSummary(
        id: 1,
        name: '高频',
        rank: 1,
        minOccurrences: 100,
        maxOccurrences: null,
      ),
      FrequencyGroupSummary(
        id: 2,
        name: '次高频',
        rank: 2,
        minOccurrences: 40,
        maxOccurrences: 99,
      ),
    ];
  }

  @override
  Future<VocabularyPageResult> findPage(WordFilter filter) async {
    final keyword = filter.keyword;
    if (keyword != null) {
      final entered = _entered[keyword];
      if (entered != null && !entered.isCompleted) {
        entered.complete();
      }
      final gate = _gates[keyword];
      if (gate != null && !gate.isCompleted) {
        await gate.future;
      }
    }
    if (failedPages.contains(filter.page) || failInitial) {
      throw Exception('page failed');
    }
    if (keyword != null) {
      return VocabularyPageResult(
        filter: filter,
        items: [_item(keyword == 'fast' ? 10 : 11, keyword)],
        hasMore: false,
      );
    }
    final items = switch (filter.page) {
      1 => [_item(1, 'alpha'), _item(2, 'beta')],
      2 => [_item(3, 'gamma')],
      _ => <VocabularyWordItem>[],
    };
    return VocabularyPageResult(
      filter: filter,
      items: items.take(filter.pageSize).toList(growable: false),
      hasMore: filter.page == 1,
    );
  }

  void blockKeyword(String keyword) {
    _gates[keyword] = Completer<void>();
    _entered[keyword] = Completer<void>();
  }

  Completer<void> enteredFor(String keyword) => _entered[keyword]!;

  void releaseKeyword(String keyword) {
    final gate = _gates[keyword];
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
  }
}

final class _FakeFavoriteRepository implements FavoriteRepository {
  final List<(int, bool)> calls = [];
  Completer<void>? gate;
  bool fail = false;

  @override
  Future<FavoriteWordRecord?> setWordFavorite({
    required int wordId,
    required bool isFavorite,
  }) async {
    calls.add((wordId, isFavorite));
    final currentGate = gate;
    if (currentGate != null && !currentGate.isCompleted) {
      await currentGate.future;
    }
    if (fail) {
      throw Exception('favorite failed');
    }
    if (!isFavorite) {
      return null;
    }
    final now = DateTime.utc(2026, 8, 15);
    return FavoriteWordRecord(
      id: 'favorite-$wordId',
      wordId: wordId,
      createdAt: now,
      updatedAt: now,
    );
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
  }) {
    throw UnimplementedError();
  }
}

VocabularyWordItem _item(int id, String word) {
  return VocabularyWordItem(
    word: WordSummary(
      id: id,
      word: word,
      phoneticUk: null,
      translationZh: '释义 $word',
      occurrences: 100,
      frequencyGroupId: 1,
    ),
    isFavorite: false,
    learningState: null,
  );
}
