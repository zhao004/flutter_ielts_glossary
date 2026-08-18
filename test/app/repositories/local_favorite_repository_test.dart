import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';
import 'package:flutter_ielts_glossary/app/services/id/id_generator.dart';

void main() {
  late ContentDatabase contentDatabase;
  late UserDatabase userDatabase;
  late _MutableClock clock;
  late _SequenceIdGenerator ids;
  late LocalFavoriteRepository repository;

  setUp(() async {
    contentDatabase = ContentDatabase.forExecutor(NativeDatabase.memory());
    userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    await _seedContent(contentDatabase);
    clock = _MutableClock(DateTime.utc(2026, 8, 15, 8));
    ids = _SequenceIdGenerator();
    repository = LocalFavoriteRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
      clock: clock,
      idGenerator: ids,
    );
  });

  tearDown(() async {
    await userDatabase.close();
    await contentDatabase.close();
  });

  test('单词收藏新增与删除保持幂等且不重复生成记录', () async {
    final first = await repository.setWordFavorite(wordId: 1, isFavorite: true);
    clock.now = clock.now.add(const Duration(hours: 1));
    final repeated = await repository.setWordFavorite(
      wordId: 1,
      isFavorite: true,
    );

    expect(first?.id, 'favorite-0');
    expect(repeated?.id, first?.id);
    expect(repeated?.updatedAt, first?.updatedAt);
    expect(await repository.isWordFavorite(1), isTrue);
    expect(
      await userDatabase.select(userDatabase.favoriteWords).get(),
      hasLength(1),
    );

    await repository.setWordFavorite(wordId: 1, isFavorite: false);
    await repository.setWordFavorite(wordId: 1, isFavorite: false);
    expect(await repository.isWordFavorite(1), isFalse);
  });

  test('并发添加同一单词收藏最终只保留一条关系', () async {
    final results = await Future.wait([
      repository.setWordFavorite(wordId: 1, isFavorite: true),
      repository.setWordFavorite(wordId: 1, isFavorite: true),
    ]);

    expect(results.map((record) => record?.wordId), everyElement(1));
    expect(
      await userDatabase.select(userDatabase.favoriteWords).get(),
      hasLength(1),
    );
  });

  test('例句收藏从内容库解析真实关联单词并支持批量状态', () async {
    final favorite = await repository.setSentenceFavorite(
      sentenceId: 101,
      isFavorite: true,
    );

    expect(favorite?.wordId, 1);
    expect(await repository.findFavoriteSentenceIds({101, 102}), {101});
    expect(await repository.findFavoriteWordIds({1, 2}), isEmpty);

    await repository.setWordFavorite(wordId: 2, isFavorite: true);
    expect(await repository.findFavoriteWordIds({1, 2}), {2});
  });

  test('收藏列表按最近创建时间分页返回', () async {
    await repository.setWordFavorite(wordId: 1, isFavorite: true);
    clock.now = clock.now.add(const Duration(minutes: 1));
    await repository.setWordFavorite(wordId: 2, isFavorite: true);

    final firstPage = await repository.findFavoriteWords(limit: 1);
    final secondPage = await repository.findFavoriteWords(limit: 1, offset: 1);

    expect(firstPage.single.wordId, 2);
    expect(secondPage.single.wordId, 1);
  });

  test('不存在的内容不能创建悬空收藏关系', () async {
    await expectLater(
      repository.setWordFavorite(wordId: 999, isFavorite: true),
      throwsA(isA<FavoriteContentNotFoundException>()),
    );
    await expectLater(
      repository.setSentenceFavorite(sentenceId: 999, isFavorite: true),
      throwsA(isA<FavoriteContentNotFoundException>()),
    );

    expect(
      await userDatabase.select(userDatabase.favoriteWords).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.favoriteSentences).get(),
      isEmpty,
    );
  });
}

Future<void> _seedContent(ContentDatabase database) async {
  await database.batch((batch) {
    batch.insert(
      database.frequencyGroups,
      FrequencyGroupsCompanion.insert(
        id: const Value(1),
        name: '100 次以上',
        rank: 1,
        minOccurrences: 100,
      ),
    );
    batch.insertAll(database.words, [
      WordsCompanion.insert(
        id: const Value(1),
        word: 'academic',
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
      WordsCompanion.insert(
        id: const Value(2),
        word: 'academy',
        occurrences: 130,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
    ]);
    batch.insertAll(database.sentences, [
      SentencesCompanion.insert(
        id: const Value(101),
        wordId: 1,
        targetForm: 'academic',
        sentenceEn: 'The academic year begins in September.',
      ),
      SentencesCompanion.insert(
        id: const Value(102),
        wordId: 2,
        targetForm: 'academy',
        sentenceEn: 'The academy opened last year.',
      ),
    ]);
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}

final class _SequenceIdGenerator implements IdGenerator {
  var _next = 0;

  @override
  String nextId() => 'favorite-${_next++}';
}
