import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/learning_event_types.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_practice_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';
import 'package:flutter_ielts_glossary/app/services/id/id_generator.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_config_codec.dart';

void main() {
  late UserDatabase database;
  late _MutableClock clock;
  late _SequenceIdGenerator ids;
  late LocalPracticeRepository repository;

  setUp(() {
    database = UserDatabase.forExecutor(NativeDatabase.memory());
    clock = _MutableClock(DateTime.utc(2026, 8, 14, 12));
    ids = _SequenceIdGenerator();
    repository = LocalPracticeRepository(
      database,
      clock: clock,
      idGenerator: ids,
    );
  });

  tearDown(() => database.close());

  test('配置 JSON 往返保留范围、难度、计时和拼写开关', () {
    const codec = QuestionConfigCodec();
    final config = QuestionConfig(
      type: QuestionType.spelling,
      difficulty: QuestionDifficulty.hard,
      wrongFirst: true,
      questionCount: 12,
      timed: true,
      spellingPromptType: SpellingPromptType.definition,
      allowSpellingPhrases: true,
    );

    final decoded = codec.decode(codec.encode(config));

    expect(decoded.type, config.type);
    expect(decoded.frequencyGroupIds, isEmpty);
    expect(decoded.difficulty, config.difficulty);
    expect(decoded.wrongFirst, isTrue);
    expect(decoded.questionCount, 12);
    expect(decoded.timed, isTrue);
    expect(decoded.spellingPromptType, SpellingPromptType.definition);
    expect(decoded.allowSpellingPhrases, isTrue);
  });

  test('拒绝未来版本和损坏配置 JSON', () {
    const codec = QuestionConfigCodec();

    expect(
      () => codec.decode('{"formatVersion":99}'),
      throwsA(
        isA<QuestionConfigFormatException>().having(
          (error) => error.code,
          'code',
          'unsupported_version',
        ),
      ),
    );
    expect(
      () => codec.decode('{not-json'),
      throwsA(
        isA<QuestionConfigFormatException>().having(
          (error) => error.code,
          'code',
          'invalid_json',
        ),
      ),
    );
  });

  test('开始、逐题作答和完成统计在同一用户库闭环', () async {
    final config = QuestionConfig(
      type: QuestionType.choiceEnglishToChinese,
      questionCount: 5,
      timed: true,
    );
    final session = await repository.startSession(config);

    expect(session.id, 'record-0');
    expect(session.isFinished, isFalse);
    expect(session.totalQuestionCount, 5);
    expect(session.answeredQuestionCount, 0);
    expect(
      (await database.select(database.practiceSessions).get()).single.type,
      'choice_english_to_chinese',
    );

    for (var index = 0; index < 5; index++) {
      clock.now = clock.now.add(const Duration(seconds: 1));
      await repository.recordAnswer(
        sessionId: session.id,
        wordId: index + 1,
        userAnswer: index.isEven ? '正确' : '错误',
        isCorrect: index.isEven,
        responseTime: Duration(seconds: index + 1),
      );
    }
    final active = await repository.findSession(session.id);
    expect(active?.answeredQuestionCount, 5);
    expect(active?.correctCount, 3);
    expect(active?.isFinished, isFalse);
    expect(
      (await database.select(database.learningEvents).get()).map(
        (event) => event.eventType,
      ),
      everyElement(LearningEventTypes.practiceAnswered),
    );

    clock.now = clock.now.add(const Duration(minutes: 1));
    final finished = await repository.finishSession(
      sessionId: session.id,
      elapsed: const Duration(seconds: 20),
    );
    expect(finished.isFinished, isTrue);
    expect(finished.correctCount, 3);
    expect(finished.accuracy, closeTo(0.6, 0.0001));
    expect(finished.elapsed, const Duration(seconds: 20));
    expect(
      (await database.select(database.practiceSessions).get())
          .single
          .correctCount,
      3,
    );
  });

  test('重复答案、未完成结束和完成后继续作答都会被拒绝', () async {
    final session = await repository.startSession(
      QuestionConfig(
        type: QuestionType.spelling,
        spellingPromptType: SpellingPromptType.translation,
        questionCount: 5,
      ),
    );
    await repository.recordAnswer(
      sessionId: session.id,
      wordId: 1,
      userAnswer: 'one',
      isCorrect: true,
      responseTime: const Duration(seconds: 1),
    );

    await expectLater(
      repository.recordAnswer(
        sessionId: session.id,
        wordId: 1,
        userAnswer: 'one',
        isCorrect: true,
        responseTime: const Duration(seconds: 1),
      ),
      throwsA(isA<DuplicatePracticeAnswerException>()),
    );
    await expectLater(
      repository.finishSession(
        sessionId: session.id,
        elapsed: const Duration(seconds: 2),
      ),
      throwsA(isA<IncompletePracticeSessionException>()),
    );

    for (var wordId = 2; wordId <= 5; wordId++) {
      await repository.recordAnswer(
        sessionId: session.id,
        wordId: wordId,
        userAnswer: 'answer',
        isCorrect: false,
        responseTime: const Duration(seconds: 1),
      );
    }
    await repository.finishSession(
      sessionId: session.id,
      elapsed: const Duration(seconds: 5),
    );
    await expectLater(
      repository.recordAnswer(
        sessionId: session.id,
        wordId: 6,
        userAnswer: 'late',
        isCorrect: false,
        responseTime: const Duration(seconds: 1),
      ),
      throwsA(isA<PracticeSessionFinishedException>()),
    );
  });

  test('学习事件 ID 冲突时答案和事件一起回滚', () async {
    final now = clock.now;
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-collision',
        eventType: LearningEventTypes.practiceAnswered,
        wordId: 999,
        occurredAt: now,
      ),
    );
    ids.values = ['session-1', 'answer-1', 'event-collision'];
    final session = await repository.startSession(
      QuestionConfig(type: QuestionType.cloze, questionCount: 5),
    );

    await expectLater(
      repository.recordAnswer(
        sessionId: session.id,
        wordId: 1,
        sentenceId: 10,
        userAnswer: 'answer',
        isCorrect: true,
        responseTime: const Duration(seconds: 1),
      ),
      throwsA(anything),
    );

    expect(
      await (database.select(
        database.practiceAnswers,
      )..where((row) => row.sessionId.equals(session.id))).get(),
      isEmpty,
    );
    expect(await database.select(database.learningEvents).get(), hasLength(1));
  });

  test('拒绝不合理的答案和会话耗时', () async {
    final session = await repository.startSession(
      QuestionConfig(
        type: QuestionType.choiceEnglishToChinese,
        questionCount: 5,
      ),
    );

    await expectLater(
      repository.recordAnswer(
        sessionId: session.id,
        wordId: 1,
        userAnswer: 'x' * (LocalPracticeRepository.maximumUserAnswerLength + 1),
        isCorrect: false,
        responseTime: const Duration(seconds: 1),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.recordAnswer(
        sessionId: session.id,
        wordId: 1,
        userAnswer: 'x',
        isCorrect: false,
        responseTime: const Duration(days: 1, seconds: 1),
      ),
      throwsArgumentError,
    );
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}

final class _SequenceIdGenerator implements IdGenerator {
  List<String> values = [];
  var _next = 0;

  @override
  String nextId() {
    if (_next < values.length) {
      return values[_next++];
    }
    return 'record-${_next++}';
  }
}
