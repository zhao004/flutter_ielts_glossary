import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';

void main() {
  late UserDatabase database;

  setUp(() {
    database = UserDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('到期队列只返回已学习且到期的单词', () async {
    final now = DateTime.utc(2026, 8, 14, 12);
    await database.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(1),
        nextReviewAt: Value(now.subtract(const Duration(minutes: 5))),
        updatedAt: now,
      ),
    );
    await database.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(2),
        studiedCount: const Value(1),
        nextReviewAt: Value(now.add(const Duration(hours: 1))),
        updatedAt: now,
      ),
    );
    await database.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(3),
        nextReviewAt: Value(now.subtract(const Duration(hours: 1))),
        updatedAt: now,
      ),
    );

    final dueStates = await database.userDataDao.findDueWordStates(now: now);

    expect(dueStates.map((state) => state.wordId), [1]);
  });

  test('日期按 UTC Unix 毫秒写入并按 UTC 读回', () async {
    final source = DateTime.parse('2026-08-14T20:30:00+08:00');
    await database.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(1),
        nextReviewAt: Value(source),
        updatedAt: source,
      ),
    );

    final state = await (database.select(
      database.userWordStates,
    )..where((row) => row.wordId.equals(1))).getSingle();
    final rawRow = await database
        .customSelect(
          'SELECT next_review_at FROM user_word_states WHERE word_id = ?',
          variables: [const Variable<int>(1)],
        )
        .getSingle();

    expect(state.nextReviewAt, source.toUtc());
    expect(
      rawRow.read<int>('next_review_at'),
      source.toUtc().millisecondsSinceEpoch,
    );
  });

  test('单词收藏保持唯一', () async {
    final now = DateTime.utc(2026, 8, 14);
    await database.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'favorite-1',
        wordId: 10,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final duplicate = database.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'favorite-2',
        wordId: 10,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await expectLater(duplicate, throwsA(isA<Exception>()));
  });

  test('删除练习会话会级联删除答案', () async {
    final now = DateTime.utc(2026, 8, 14);
    await database
        .into(database.practiceSessions)
        .insert(
          PracticeSessionsCompanion.insert(
            id: 'session-1',
            type: 'choice',
            configJson: '{}',
            startedAt: now,
          ),
        );
    await database
        .into(database.practiceAnswers)
        .insert(
          PracticeAnswersCompanion.insert(
            id: 'answer-1',
            sessionId: 'session-1',
            wordId: 10,
            userAnswer: '答案',
            isCorrect: true,
            responseTimeMilliseconds: 800,
            answeredAt: now,
          ),
        );

    await (database.delete(
      database.practiceSessions,
    )..where((row) => row.id.equals('session-1'))).go();

    expect(await database.select(database.practiceAnswers).get(), isEmpty);
  });
}
