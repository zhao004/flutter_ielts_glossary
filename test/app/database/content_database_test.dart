import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_content_repository.dart';

void main() {
  late ContentDatabase database;

  setUp(() async {
    database = ContentDatabase.forExecutor(NativeDatabase.memory());
    await _seedContent(database);
  });

  tearDown(() => database.close());

  test('只返回六个有效词频组并排除预留组', () async {
    final groups = await database.contentDao.findActiveFrequencyGroups();

    expect(groups.map((group) => group.rank), [1, 2]);
  });

  test('Repository 支持组合筛选、排序和分页', () async {
    final repository = LocalContentRepository(database.contentDao);

    final firstPage = await repository.findWords(
      WordFilter(
        frequencyGroupIds: const {1},
        firstLetter: 'a',
        keyword: '学术',
        pageSize: 1,
      ),
    );
    final secondPage = await repository.findWords(
      WordFilter(
        frequencyGroupIds: const {1},
        firstLetter: 'A',
        keyword: '学术',
        page: 2,
        pageSize: 1,
      ),
    );

    expect(firstPage.map((word) => word.word), ['academic']);
    expect(secondPage.map((word) => word.word), ['academy']);
  });

  test('Repository 返回有效词频组和完整单词详情', () async {
    final repository = LocalContentRepository(database.contentDao);

    final groups = await repository.findActiveFrequencyGroups();
    final details = await repository.findWordDetails(1);

    expect(groups.map((group) => group.rank), [1, 2]);
    expect(details?.word, 'academic');
    expect(details?.phoneticUk, '/ˌækəˈdemɪk/');
    expect(details?.definitionEn, 'related to education');
    expect(details?.sentences, hasLength(1));
    expect(details?.sentences.single.id, 101);
    expect(details?.sentences.single.targetForm, 'academic');
    expect(await repository.findWordDetails(999), null);
  });

  test('FTS5 支持英文前缀且不会退化为任意子串匹配', () async {
    final repository = LocalContentRepository(database.contentDao);

    final prefixMatches = await repository.findWords(
      WordFilter(keyword: 'acad'),
    );
    final middleSubstringMatches = await repository.findWords(
      WordFilter(keyword: 'cadem'),
    );

    expect(prefixMatches.map((word) => word.word), ['academic', 'academy']);
    expect(middleSubstringMatches, isEmpty);
  });

  test('单词更新后 FTS5 触发器同步新释义', () async {
    final repository = LocalContentRepository(database.contentDao);
    await (database.update(database.words)..where((row) => row.id.equals(3)))
        .write(const WordsCompanion(translationZh: Value('短暂的')));

    final oldMatches = await repository.findWords(WordFilter(keyword: '简短'));
    final newMatches = await repository.findWords(WordFilter(keyword: '短暂'));

    expect(oldMatches, isEmpty);
    expect(newMatches.map((word) => word.word), ['brief']);
  });

  test('单词主键重复时数据库拒绝写入', () async {
    final duplicate = database
        .into(database.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            word: 'another',
            occurrences: 120,
            frequencyGroupId: 1,
            firstLetter: 'A',
          ),
        );

    await expectLater(duplicate, throwsA(isA<Exception>()));
  });

  test('随机学习查询按词频组计数且不会重复抽取', () async {
    final count = await database.contentDao.countStudyWords({1});
    final words = await database.contentDao.findRandomStudyWords(
      frequencyGroupIds: const {1},
      limit: 2,
      orderSeed: 7,
    );

    expect(count, 2);
    expect(words, hasLength(2));
    expect(words.map((word) => word.id).toSet(), hasLength(2));
  });
}

Future<void> _seedContent(ContentDatabase database) async {
  await database.batch((batch) {
    batch.insertAll(database.frequencyGroups, [
      FrequencyGroupsCompanion.insert(
        id: const Value(1),
        name: '100 次以上',
        rank: 1,
        minOccurrences: 100,
      ),
      FrequencyGroupsCompanion.insert(
        id: const Value(2),
        name: '40-99 次',
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
        word: 'academic',
        phoneticUk: const Value('/ˌækəˈdemɪk/'),
        phoneticUs: const Value('/ˌækəˈdemɪk/'),
        translationZh: const Value('学术的'),
        definitionEn: const Value('related to education'),
        mnemonic: const Value('academy 的形容词'),
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
        audioUkAsset: const Value('assets/audio/uk/academic.mp3'),
      ),
      WordsCompanion.insert(
        id: const Value(2),
        word: 'academy',
        translationZh: const Value('学术机构'),
        definitionEn: const Value('a place of study'),
        occurrences: 130,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
      WordsCompanion.insert(
        id: const Value(3),
        word: 'brief',
        translationZh: const Value('简短的'),
        occurrences: 60,
        frequencyGroupId: 2,
        firstLetter: 'B',
      ),
    ]);
    batch.insert(
      database.sentences,
      SentencesCompanion.insert(
        id: const Value(101),
        wordId: 1,
        targetForm: 'academic',
        sentenceEn: 'The academic year begins in September.',
        translationZh: const Value('学年从九月开始。'),
        source: const Value('Cambridge IELTS'),
        location: const Value('Test 1'),
      ),
    );
  });
}
