import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/learning_event_types.dart';
import 'package:flutter_ielts_glossary/app/models/domain/practice_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/practice_setup_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/quiz_question.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_session_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_setup_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_practice_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_question_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';
import 'package:flutter_ielts_glossary/app/services/clock/monotonic_clock.dart';
import 'package:flutter_ielts_glossary/app/services/id/id_generator.dart';
import 'package:flutter_ielts_glossary/app/services/question/practice_answer_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_engine.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  test('真实双数据库完成配置、出题、逐题记录和结果持久化闭环', () async {
    final contentDatabase = ContentDatabase.forExecutor(
      NativeDatabase.memory(),
    );
    final userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    final sessionLogic = PracticeSessionLogic(
      questionCandidateRepository: LocalQuestionCandidateRepository(
        contentDatabase.contentDao,
        userDatabase.userDataDao,
        randomSource: DartQuestionRandomSource(seed: 17),
      ),
      questionEngine: QuestionEngine(
        randomSource: DartQuestionRandomSource(seed: 23),
      ),
      practiceRepository: LocalPracticeRepository(
        userDatabase,
        clock: _FixedWallClock(DateTime.utc(2026, 8, 15, 12)),
        idGenerator: _SequenceIdGenerator(),
      ),
      favoriteRepository: LocalFavoriteRepository(
        contentDatabase.contentDao,
        userDatabase.userDataDao,
      ),
      answerEvaluator: const PracticeAnswerEvaluator(),
      monotonicClock: _FakeMonotonicClock(),
    );
    final setupLogic = PracticeSetupLogic(practiceSessionStarter: sessionLogic);
    addTearDown(() async {
      setupLogic.onClose();
      sessionLogic.onClose();
      await userDatabase.close();
      await contentDatabase.close();
    });
    await _seedContent(contentDatabase);

    setupLogic.setQuestionCount(5);
    await setupLogic.start();

    expect(setupLogic.state.phase, PracticeSetupPhase.started);
    expect(sessionLogic.state.phase, PracticeRunPhase.answering);
    final monotonicClock = sessionLogic.monotonicClock as _FakeMonotonicClock;
    for (var index = 0; index < 5; index++) {
      final question = sessionLogic.state.currentQuestion! as ChoiceQuestion;
      monotonicClock.advance(const Duration(seconds: 1));
      await sessionLogic.submitChoice(question.correctOptionId);
      expect(sessionLogic.state.phase, PracticeRunPhase.feedback);
      await sessionLogic.next();
    }

    final sessions = await userDatabase
        .select(userDatabase.practiceSessions)
        .get();
    final answers = await userDatabase
        .select(userDatabase.practiceAnswers)
        .get();
    final events = await userDatabase.select(userDatabase.learningEvents).get();

    expect(sessionLogic.state.phase, PracticeRunPhase.completed);
    expect(sessionLogic.state.correctCount, 5);
    expect(sessions, hasLength(1));
    expect(sessions.single.finishedAt, isNotNull);
    expect(sessions.single.correctCount, 5);
    expect(sessions.single.elapsedMilliseconds, 5000);
    expect(answers, hasLength(5));
    expect(answers.map((answer) => answer.wordId).toSet(), hasLength(5));
    expect(events, hasLength(5));
    expect(
      events.map((event) => event.eventType),
      everyElement(LearningEventTypes.practiceAnswered),
    );
  });
}

Future<void> _seedContent(ContentDatabase database) async {
  const words = ['apple', 'banana', 'cedar', 'delta', 'eagle'];
  await database.batch((batch) {
    batch.insert(
      database.frequencyGroups,
      FrequencyGroupsCompanion.insert(
        id: const Value(1),
        name: '高频',
        rank: 1,
        minOccurrences: 100,
      ),
    );
    batch.insertAll(
      database.words,
      List.generate(words.length, (index) {
        final id = index + 1;
        return WordsCompanion.insert(
          id: Value(id),
          word: words[index],
          translationZh: Value('释义$id'),
          occurrences: 120,
          frequencyGroupId: 1,
          firstLetter: words[index].substring(0, 1).toUpperCase(),
        );
      }, growable: false),
    );
  });
}

final class _FakeMonotonicClock implements MonotonicClock {
  Duration value = Duration.zero;

  @override
  Duration get elapsed => value;

  void advance(Duration duration) => value += duration;
}

final class _FixedWallClock implements AppClock {
  const _FixedWallClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _SequenceIdGenerator implements IdGenerator {
  var _next = 0;

  @override
  String nextId() => 'practice-${_next++}';
}
