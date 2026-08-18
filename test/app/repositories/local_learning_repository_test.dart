import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/learning_event_types.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_learning_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';
import 'package:flutter_ielts_glossary/app/services/id/id_generator.dart';

void main() {
  late UserDatabase database;
  late _MutableClock clock;
  late _SequenceIdGenerator ids;
  late LocalLearningRepository repository;

  setUp(() {
    database = UserDatabase.forExecutor(NativeDatabase.memory());
    clock = _MutableClock(DateTime.utc(2026, 8, 14, 12));
    ids = _SequenceIdGenerator();
    repository = LocalLearningRepository(
      database,
      clock: clock,
      idGenerator: ids,
    );
  });

  tearDown(() => database.close());

  test('首次完成学习原子写入等级 0 状态和学习事件', () async {
    final state = await repository.recordStudyCompletion(
      wordId: 10,
      sessionId: ' session-1 ',
    );
    final events = await database.select(database.learningEvents).get();

    expect(state.masteryLevel, 0);
    expect(state.studiedCount, 1);
    expect(state.consecutiveForgottenCount, 0);
    expect(state.nextReviewAt, clock.now.add(const Duration(hours: 4)));
    expect(state.lastStudiedAt, clock.now);
    expect(events, hasLength(1));
    expect(events.single.eventType, LearningEventTypes.studyCompleted);
    expect(events.single.sessionId, 'session-1');
    expect(events.single.isCorrect, isNull);
    expect(events.single.reviewRating, isNull);
  });

  test('可读取已学习状态，未学习单词返回空值', () async {
    final created = await repository.recordStudyCompletion(wordId: 10);

    expect(await repository.findWordState(10), isNotNull);
    expect(
      (await repository.findWordState(10))?.masteryLevel,
      created.masteryLevel,
    );
    expect(await repository.findWordState(999), isNull);
    await expectLater(
      repository.findWordState(0),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('重复完成学习增加次数但不重置既有复习计划', () async {
    final first = await repository.recordStudyCompletion(wordId: 10);
    clock.now = clock.now.add(const Duration(hours: 1));

    final second = await repository.recordStudyCompletion(wordId: 10);

    expect(second.studiedCount, 2);
    expect(second.masteryLevel, first.masteryLevel);
    expect(second.nextReviewAt, first.nextReviewAt);
  });

  test('记得后升级并写入成功评分事件', () async {
    await repository.recordStudyCompletion(wordId: 10);
    clock.now = clock.now.add(const Duration(hours: 4));

    final state = await repository.recordReview(
      wordId: 10,
      rating: ReviewRating.good,
    );
    final event = (await database.select(database.learningEvents).get()).last;

    expect(state.masteryLevel, 1);
    expect(state.nextReviewAt, clock.now.add(const Duration(hours: 12)));
    expect(state.studiedCount, 2);
    expect(state.correctCount, 1);
    expect(state.wrongCount, 0);
    expect(state.correctStreak, 1);
    expect(state.consecutiveForgottenCount, 0);
    expect(state.lastReviewedAt, clock.now);
    expect(event.isCorrect, isTrue);
    expect(event.reviewRating, ReviewRating.good.name);
  });

  test('重学会降级、缩短到 10 分钟并累计连续遗忘次数', () async {
    await repository.recordStudyCompletion(wordId: 10);

    final first = await repository.recordReview(
      wordId: 10,
      rating: ReviewRating.again,
    );
    clock.now = clock.now.add(const Duration(minutes: 10));
    final second = await repository.recordReview(
      wordId: 10,
      rating: ReviewRating.again,
    );

    expect(first.masteryLevel, 0);
    expect(first.nextReviewAt, DateTime.utc(2026, 8, 14, 12, 10));
    expect(first.correctCount, 0);
    expect(first.wrongCount, 1);
    expect(first.correctStreak, 0);
    expect(first.consecutiveForgottenCount, 1);
    expect(second.consecutiveForgottenCount, 2);
    expect(second.nextReviewAt, DateTime.utc(2026, 8, 14, 12, 20));
  });

  test('困难仍计为成功回忆且会重置连续遗忘次数', () async {
    await repository.recordStudyCompletion(wordId: 10);
    await repository.recordReview(wordId: 10, rating: ReviewRating.again);
    clock.now = clock.now.add(const Duration(minutes: 10));

    final state = await repository.recordReview(
      wordId: 10,
      rating: ReviewRating.hard,
    );

    expect(state.masteryLevel, 0);
    expect(state.nextReviewAt, clock.now.add(const Duration(hours: 2)));
    expect(state.correctCount, 1);
    expect(state.wrongCount, 1);
    expect(state.correctStreak, 1);
    expect(state.consecutiveForgottenCount, 0);
  });

  test('学习自评按 1/3/5 策略更新掌握等级但不重复累计学习次数', () async {
    final initial = await repository.recordStudyCompletion(wordId: 10);
    clock.now = clock.now.add(const Duration(minutes: 1));

    final state = await repository.applyStudyRating(
      wordId: 10,
      rating: StudyRating.known,
    );

    expect(initial.studiedCount, 1);
    expect(state.studiedCount, 1);
    expect(state.masteryLevel, 5);
    expect(state.nextReviewAt, clock.now.add(const Duration(days: 30)));
    expect(await database.select(database.learningEvents).get(), hasLength(1));
  });

  test('未翻开的单词不能直接提交学习自评', () async {
    await expectLater(
      repository.applyStudyRating(wordId: 99, rating: StudyRating.familiar),
      throwsA(isA<StudyStateNotFoundException>()),
    );
  });

  test('到期队列按最早 nextReviewAt 返回且排除未到期项', () async {
    await repository.recordStudyCompletion(wordId: 10);
    clock.now = clock.now.add(const Duration(hours: 1));
    await repository.recordStudyCompletion(wordId: 20);
    clock.now = clock.now.add(const Duration(hours: 4));

    final due = await repository.findDueReviews();

    expect(due.map((state) => state.wordId), [10, 20]);
  });

  test('记忆率只统计复习事件并将困难视为一次成功回忆', () async {
    clock.now = DateTime.utc(2026, 8, 1, 12);
    await repository.recordStudyCompletion(wordId: 10);
    await repository.recordReview(wordId: 10, rating: ReviewRating.hard);
    clock.now = DateTime.utc(2026, 8, 10, 12);
    await repository.recordReview(wordId: 10, rating: ReviewRating.again);
    clock.now = DateTime.utc(2026, 8, 14, 12);

    final allTime = await repository.getReviewMemoryRate();
    final lastSevenDays = await repository.getReviewMemoryRate(
      window: const Duration(days: 7),
    );

    expect(allTime.correctReviews, 1);
    expect(allTime.completedReviews, 2);
    expect(allTime.value, 0.5);
    expect(lastSevenDays.correctReviews, 0);
    expect(lastSevenDays.completedReviews, 1);
    expect(lastSevenDays.value, 0);
  });

  test('重复事件 ID 使状态变更和事件写入一起回滚', () async {
    ids.values = ['duplicate-id', 'duplicate-id'];
    final initial = await repository.recordStudyCompletion(wordId: 10);

    await expectLater(
      repository.recordReview(wordId: 10, rating: ReviewRating.good),
      throwsA(anything),
    );
    final afterFailure = await database.userDataDao.findWordState(10);
    final events = await database.select(database.learningEvents).get();

    expect(afterFailure?.masteryLevel, initial.masteryLevel);
    expect(afterFailure?.studiedCount, initial.studiedCount);
    expect(afterFailure?.correctCount, initial.correctCount);
    expect(
      afterFailure?.consecutiveForgottenCount,
      initial.consecutiveForgottenCount,
    );
    expect(events, hasLength(1));
  });

  test('未学习单词不能直接提交复习结果', () async {
    await expectLater(
      repository.recordReview(wordId: 99, rating: ReviewRating.good),
      throwsA(isA<ReviewStateNotFoundException>()),
    );
    expect(await database.select(database.learningEvents).get(), isEmpty);
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
    if (values.isNotEmpty) {
      return values[_next++];
    }
    return 'event-${_next++}';
  }
}
