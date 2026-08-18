import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_vocabulary_repository.dart';

void main() {
  late ContentDatabase contentDatabase;
  late UserDatabase userDatabase;
  late LocalVocabularyRepository repository;

  setUp(() async {
    contentDatabase = ContentDatabase.forExecutor(NativeDatabase.memory());
    userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    await _seedContent(contentDatabase);
    final now = DateTime.utc(2026, 8, 15, 12);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        masteryLevel: const Value(4),
        studiedCount: const Value(3),
        correctCount: const Value(2),
        wrongCount: const Value(1),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'favorite-2',
        wordId: 2,
        createdAt: now,
        updatedAt: now,
      ),
    );
    repository = LocalVocabularyRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
    );
  });

  tearDown(() async {
    await userDatabase.close();
    await contentDatabase.close();
  });

  test('分页前瞻并批量组合收藏和掌握状态', () async {
    final first = await repository.findPage(
      WordFilter(sortOrder: WordSortOrder.alphabetAscending, pageSize: 2),
    );
    final second = await repository.findPage(
      WordFilter(
        sortOrder: WordSortOrder.alphabetAscending,
        page: 2,
        pageSize: 2,
      ),
    );

    expect(first.items.map((item) => item.word.word), ['alpha', 'beta']);
    expect(first.hasMore, isTrue);
    expect(first.items.first.masteryLevel, 4);
    expect(first.items.first.isNew, isFalse);
    expect(first.items.first.isFavorite, isFalse);
    expect(first.items.last.learningState, null);
    expect(first.items.last.isNew, isTrue);
    expect(first.items.last.isFavorite, isTrue);
    expect(second.items.map((item) => item.word.word), ['gamma']);
    expect(second.hasMore, isFalse);
  });

  test('组合搜索只查询当前页用户状态且预留组不进入筛选项', () async {
    final page = await repository.findPage(
      WordFilter(keyword: 'beta', pageSize: 10),
    );
    final groups = await repository.findActiveFrequencyGroups();

    expect(page.items.map((item) => item.word.id), [2]);
    expect(page.items.single.isFavorite, isTrue);
    expect(groups.map((group) => group.id), [1, 2]);
  });
}

Future<void> _seedContent(ContentDatabase database) async {
  await database.batch((batch) {
    batch.insertAll(database.frequencyGroups, [
      FrequencyGroupsCompanion.insert(
        id: const Value(1),
        name: '高频',
        rank: 1,
        minOccurrences: 100,
      ),
      FrequencyGroupsCompanion.insert(
        id: const Value(2),
        name: '次高频',
        rank: 2,
        minOccurrences: 40,
        maxOccurrences: const Value(99),
      ),
      FrequencyGroupsCompanion.insert(
        id: const Value(7),
        name: '预留',
        rank: 7,
        minOccurrences: 1,
        maxOccurrences: const Value(2),
      ),
    ]);
    batch.insertAll(database.words, [
      WordsCompanion.insert(
        id: const Value(1),
        word: 'alpha',
        translationZh: const Value('阿尔法'),
        occurrences: 120,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
      WordsCompanion.insert(
        id: const Value(2),
        word: 'beta',
        translationZh: const Value('贝塔'),
        occurrences: 80,
        frequencyGroupId: 2,
        firstLetter: 'B',
      ),
      WordsCompanion.insert(
        id: const Value(3),
        word: 'gamma',
        translationZh: const Value('伽马'),
        occurrences: 70,
        frequencyGroupId: 2,
        firstLetter: 'G',
      ),
    ]);
  });
}
