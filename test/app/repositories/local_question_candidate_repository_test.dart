import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_candidate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_question_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  late ContentDatabase contentDatabase;
  late UserDatabase userDatabase;

  setUp(() async {
    contentDatabase = ContentDatabase.forExecutor(NativeDatabase.memory());
    userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    await _seedContent(contentDatabase);
  });

  tearDown(() async {
    await userDatabase.close();
    await contentDatabase.close();
  });

  test('大范围查询只返回受限候选池且固定种子顺序可复现', () async {
    final config = QuestionConfig(
      type: QuestionType.choiceEnglishToChinese,
      frequencyGroupIds: const {1},
      questionCount: 10,
    );
    final firstRepository = _repository(
      contentDatabase,
      userDatabase,
      seed: 77,
    );
    final secondRepository = _repository(
      contentDatabase,
      userDatabase,
      seed: 77,
    );

    final first = await firstRepository.loadCandidateBatch(config);
    final second = await secondRepository.loadCandidateBatch(config);

    expect(first.databaseQualifiedWordCount, 110);
    expect(first.poolLimit, 100);
    expect(first.candidates, hasLength(100));
    expect(first.isTruncated, isTrue);
    expect(
      first.candidates.map((candidate) => candidate.wordId),
      second.candidates.map((candidate) => candidate.wordId),
    );
    expect(
      first.candidates,
      everyElement(
        isA<QuestionCandidate>().having(
          (candidate) => candidate.frequencyGroupId,
          'frequencyGroupId',
          1,
        ),
      ),
    );
  });

  test('定向拼写只返回指定单词且允许单题会话', () async {
    final repository = _repository(contentDatabase, userDatabase, seed: 7);

    final batch = await repository.loadCandidateBatch(
      QuestionConfig.targetedSpelling(wordId: 1),
    );

    expect(batch.databaseQualifiedWordCount, 1);
    expect(batch.candidates.map((candidate) => candidate.wordId), [1]);
    expect(batch.isTruncated, isFalse);
  });

  test('题型字段资格在数据库层过滤并一次装配关联例句', () async {
    final repository = _repository(contentDatabase, userDatabase, seed: 9);

    final phonetic = await repository.loadCandidateBatch(
      QuestionConfig(
        type: QuestionType.spelling,
        spellingPromptType: SpellingPromptType.phonetic,
        questionCount: 5,
      ),
    );
    final audio = await repository.loadCandidateBatch(
      QuestionConfig(
        type: QuestionType.spelling,
        spellingPromptType: SpellingPromptType.audio,
        questionCount: 5,
      ),
    );
    final definition = await repository.loadCandidateBatch(
      QuestionConfig(
        type: QuestionType.spelling,
        spellingPromptType: SpellingPromptType.definition,
        questionCount: 5,
      ),
    );
    final cloze = await repository.loadCandidateBatch(
      QuestionConfig(type: QuestionType.cloze, questionCount: 5),
    );

    expect(phonetic.databaseQualifiedWordCount, 60);
    expect(
      phonetic.candidates,
      everyElement(
        isA<QuestionCandidate>().having(
          (candidate) => candidate.phoneticUk,
          'phoneticUk',
          isNotNull,
        ),
      ),
    );
    expect(audio.databaseQualifiedWordCount, 12);
    expect(
      audio.candidates,
      everyElement(
        isA<QuestionCandidate>().having(
          (candidate) => candidate.audioUkAsset,
          'audioUkAsset',
          isNotNull,
        ),
      ),
    );
    expect(definition.databaseQualifiedWordCount, 120);
    expect(
      definition.candidates,
      everyElement(
        isA<QuestionCandidate>().having(
          (candidate) => candidate.definitionEn,
          'definitionEn',
          isNotNull,
        ),
      ),
    );
    expect(cloze.databaseQualifiedWordCount, 20);
    expect(cloze.candidates, hasLength(20));
    expect(
      cloze.candidates,
      everyElement(
        isA<QuestionCandidate>().having(
          (candidate) => candidate.sentences.length,
          'sentenceCount',
          1,
        ),
      ),
    );
  });

  test('错题优先补入当前范围内历史错题并排除范围外记录', () async {
    final now = DateTime.utc(2026, 8, 14, 12);
    await userDatabase
        .into(userDatabase.practiceSessions)
        .insert(
          PracticeSessionsCompanion.insert(
            id: 'session-1',
            type: 'choice_english_to_chinese',
            configJson: '{}',
            startedAt: now,
          ),
        );
    await userDatabase.batch((batch) {
      batch.insertAll(userDatabase.practiceAnswers, [
        PracticeAnswersCompanion.insert(
          id: 'answer-in-range',
          sessionId: 'session-1',
          wordId: 120,
          userAnswer: '错误',
          isCorrect: false,
          responseTimeMilliseconds: 500,
          answeredAt: now,
        ),
        PracticeAnswersCompanion.insert(
          id: 'answer-out-of-range',
          sessionId: 'session-1',
          wordId: 1,
          userAnswer: '错误',
          isCorrect: false,
          responseTimeMilliseconds: 600,
          answeredAt: now.subtract(const Duration(minutes: 1)),
        ),
        PracticeAnswersCompanion.insert(
          id: 'answer-correct',
          sessionId: 'session-1',
          wordId: 119,
          userAnswer: '正确',
          isCorrect: true,
          responseTimeMilliseconds: 700,
          answeredAt: now,
        ),
      ]);
    });
    final repository = _repository(contentDatabase, userDatabase, seed: 2);

    final batch = await repository.loadCandidateBatch(
      QuestionConfig(
        type: QuestionType.choiceEnglishToChinese,
        frequencyGroupIds: const {2},
        wrongFirst: true,
        questionCount: 5,
      ),
    );

    expect(batch.candidates, hasLength(10));
    expect(
      batch.candidates
          .singleWhere((candidate) => candidate.wordId == 120)
          .isWrong,
      isTrue,
    );
    expect(
      batch.candidates
          .singleWhere((candidate) => candidate.wordId == 119)
          .isWrong,
      isFalse,
    );
    expect(
      batch.candidates.map((candidate) => candidate.wordId),
      isNot(contains(1)),
    );
  });
}

LocalQuestionCandidateRepository _repository(
  ContentDatabase contentDatabase,
  UserDatabase userDatabase, {
  required int seed,
}) {
  return LocalQuestionCandidateRepository(
    contentDatabase.contentDao,
    userDatabase.userDataDao,
    randomSource: DartQuestionRandomSource(seed: seed),
  );
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
    ]);
    batch.insertAll(
      database.words,
      List.generate(120, (index) {
        final id = index + 1;
        final word = _word(id);
        return WordsCompanion.insert(
          id: Value(id),
          word: word,
          translationZh: Value('释义$id'),
          definitionEn: Value('definition$id'),
          phoneticUk: id.isEven ? Value('/$word/') : const Value.absent(),
          occurrences: id <= 110 ? 120 : 60,
          frequencyGroupId: id <= 110 ? 1 : 2,
          firstLetter: word.substring(0, 1).toUpperCase(),
          audioUkAsset: id % 10 == 0
              ? Value('assets/audio/$word.mp3')
              : const Value.absent(),
        );
      }, growable: false),
    );
    batch.insertAll(
      database.sentences,
      List.generate(20, (index) {
        final id = index + 1;
        final word = _word(id);
        return SentencesCompanion.insert(
          id: Value(id * 10),
          wordId: id,
          targetForm: word,
          sentenceEn: 'The term $word appears here.',
          translationZh: Value('例句$id'),
        );
      }, growable: false),
    );
  });
}

String _word(int id) {
  var value = id;
  final suffix = StringBuffer();
  while (value > 0) {
    value--;
    suffix.writeCharCode(97 + (value % 26));
    value ~/= 26;
  }
  return 'term${suffix.toString()}';
}
