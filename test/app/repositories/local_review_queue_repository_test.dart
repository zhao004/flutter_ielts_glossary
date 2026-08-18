import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_review_queue_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';

void main() {
  late ContentDatabase contentDatabase;
  late UserDatabase userDatabase;
  late _FixedClock clock;
  late LocalReviewQueueRepository repository;

  setUp(() async {
    contentDatabase = ContentDatabase.forExecutor(NativeDatabase.memory());
    userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    await _seedContent(contentDatabase);
    clock = _FixedClock(DateTime.utc(2026, 8, 15, 12));
    repository = LocalReviewQueueRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
      clock: clock,
    );
  });

  tearDown(() async {
    await userDatabase.close();
    await contentDatabase.close();
  });

  test('跨库合并到期状态并保留到期顺序，缺失内容显式返回', () async {
    final now = clock.now;
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(2),
        studiedCount: const Value(1),
        nextReviewAt: Value(now.subtract(const Duration(minutes: 1))),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(1),
        nextReviewAt: Value(now.subtract(const Duration(hours: 1))),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(999),
        studiedCount: const Value(1),
        nextReviewAt: Value(now.subtract(const Duration(hours: 2))),
        updatedAt: now,
      ),
    );

    final snapshot = await repository.findDueItems();

    expect(snapshot.items.map((item) => item.word.id), [1, 2]);
    expect(snapshot.items.first.learningState.wordId, 1);
    expect(snapshot.items.first.word.phoneticUs, '/academic-us/');
    expect(
      snapshot.items.first.word.audioUsAsset,
      'assets/audio/us/academic.mp3',
    );
    expect(snapshot.missingWordIds, [999]);
  });

  test('复习队列数量边界受统一上限约束', () async {
    await expectLater(
      repository.findDueItems(limit: 0),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.findDueItems(
        limit: LocalReviewQueueRepository.maximumQueueLimit + 1,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}

final class _FixedClock implements AppClock {
  const _FixedClock(this.now);

  final DateTime now;

  @override
  DateTime nowUtc() => now;
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
        phoneticUs: const Value('/academic-us/'),
        translationZh: const Value('学术的'),
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
        audioUsAsset: const Value('assets/audio/us/academic.mp3'),
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
  });
}
