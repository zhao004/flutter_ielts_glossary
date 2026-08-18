import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_config.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_study_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  late ContentDatabase database;
  late LocalStudyCandidateRepository repository;

  setUp(() async {
    database = ContentDatabase.forExecutor(NativeDatabase.memory());
    await _seedContent(database);
    repository = LocalStudyCandidateRepository(
      database.contentDao,
      randomSource: DartQuestionRandomSource(seed: 42),
    );
  });

  tearDown(() => database.close());

  test('候选 Repository 返回完整详情和真实例句', () async {
    final batch = await repository.loadCandidates(
      StudyConfig(frequencyGroupIds: const {1}, wordCount: 2),
    );

    expect(batch.availableCount, 2);
    expect(batch.hasEnoughCandidates, isTrue);
    expect(batch.candidates, hasLength(2));
    expect(
      batch.candidates.map((candidate) => candidate.word.id).toSet(),
      hasLength(2),
    );
    final academic = batch.candidates
        .map((candidate) => candidate.word)
        .firstWhere((word) => word.word == 'academic');
    expect(academic.sentences.single.id, 101);
  });

  test('候选不足时返回实际数量而不是生成空卡片', () async {
    final batch = await repository.loadCandidates(
      StudyConfig(frequencyGroupIds: const {1}, wordCount: 3),
    );

    expect(batch.availableCount, 2);
    expect(batch.candidates, hasLength(2));
    expect(batch.hasEnoughCandidates, isFalse);
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
        phoneticUk: const Value('/ˌækəˈdemɪk/'),
        translationZh: const Value('学术的'),
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
      WordsCompanion.insert(
        id: const Value(2),
        word: 'academy',
        translationZh: const Value('学术机构'),
        occurrences: 130,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
    ]);
    batch.insert(
      database.sentences,
      SentencesCompanion.insert(
        id: const Value(101),
        wordId: 1,
        targetForm: 'academic',
        sentenceEn: 'The academic year begins in September.',
      ),
    );
  });
}
