import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_statistics_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';
import 'package:flutter_ielts_glossary/app/services/clock/local_time_resolver.dart';

void main() {
  late UserDatabase database;
  late _MutableClock clock;
  late LocalStatisticsRepository repository;

  setUp(() {
    database = UserDatabase.forExecutor(NativeDatabase.memory());
    clock = _MutableClock(DateTime.utc(2026, 8, 15, 4));
    repository = LocalStatisticsRepository(
      database.userDataDao,
      clock: clock,
      localTimeResolver: const FixedOffsetLocalTimeResolver(Duration(hours: 8)),
    );
  });

  tearDown(() => database.close());

  test('首页统计聚合本地日、连续天数、复习状态、收藏和每日目标', () async {
    final now = clock.now;
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-0',
        eventType: 'study_completed',
        wordId: 3,
        occurredAt: DateTime.utc(2026, 8, 11, 16),
      ),
    );
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-1',
        eventType: 'study_completed',
        wordId: 1,
        occurredAt: DateTime.utc(2026, 8, 12, 16),
      ),
    );
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-2',
        eventType: 'practice_answered',
        wordId: 1,
        isCorrect: const Value(true),
        occurredAt: DateTime.utc(2026, 8, 13, 16),
      ),
    );
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-3',
        eventType: 'review',
        wordId: 1,
        isCorrect: const Value(false),
        occurredAt: DateTime.utc(2026, 8, 14, 16),
      ),
    );
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-4',
        eventType: 'study_completed',
        wordId: 2,
        occurredAt: DateTime.utc(2026, 8, 14, 15, 59),
      ),
    );
    await database.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        masteryLevel: const Value(5),
        studiedCount: const Value(2),
        nextReviewAt: Value(now.subtract(const Duration(minutes: 1))),
        updatedAt: now,
      ),
    );
    await database.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(2),
        masteryLevel: const Value(2),
        studiedCount: const Value(1),
        nextReviewAt: Value(now.add(const Duration(days: 1))),
        updatedAt: now,
      ),
    );
    await database.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'favorite-word-1',
        wordId: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.userDataDao.insertFavoriteSentence(
      FavoriteSentencesCompanion.insert(
        id: 'favorite-sentence-1',
        sentenceId: 101,
        wordId: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database
        .into(database.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            dailyGoal: 3,
            pronunciationAccent: 'UK',
            autoPlayPronunciation: false,
            themeMode: 'system',
            updatedAt: now,
          ),
        );

    final summary = await repository.loadDashboard(
      calendarDays: 5,
      trendDays: 3,
    );

    expect(summary.today.date.toString(), '2026-08-15');
    expect(summary.today.eventCount, 1);
    expect(summary.today.answeredCount, 1);
    expect(summary.today.correctCount, 0);
    expect(summary.dailyGoal, 3);
    expect(summary.currentStreakDays, 4);
    expect(summary.dueReviewCount, 1);
    expect(summary.masteredWordCount, 1);
    expect(summary.learningWordCount, 1);
    expect(summary.favoriteWordCount, 1);
    expect(summary.favoriteSentenceCount, 1);
    expect(summary.calendarDays, hasLength(5));
    expect(summary.accuracyTrend, hasLength(3));
  });

  test('没有设置和活动时使用默认目标且返回空统计', () async {
    final summary = await repository.loadDashboard(
      calendarDays: 2,
      trendDays: 1,
    );

    expect(summary.dailyGoal, LocalStatisticsRepository.defaultDailyGoal);
    expect(summary.today.eventCount, 0);
    expect(summary.currentStreakDays, 0);
    expect(summary.todayGoalRemaining, 10);
    expect(summary.dueReviewCount, 0);
  });

  test('今天未学习时连续天数可以从昨天跨越日历查询窗口', () async {
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'yesterday',
        eventType: 'study_completed',
        wordId: 1,
        occurredAt: DateTime.utc(2026, 8, 13, 16),
      ),
    );
    await database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'two-days-ago',
        eventType: 'study_completed',
        wordId: 2,
        occurredAt: DateTime.utc(2026, 8, 12, 16),
      ),
    );

    final summary = await repository.loadDashboard(
      calendarDays: 2,
      trendDays: 1,
    );

    expect(summary.today.eventCount, 0);
    expect(summary.currentStreakDays, 2);
  });

  test('超过单页上限的同日事件仍完整计入统计', () async {
    await database.batch((batch) {
      batch.insertAll(
        database.learningEvents,
        List.generate(
          501,
          (index) => LearningEventsCompanion.insert(
            id: 'paged-event-$index',
            eventType: 'study_completed',
            wordId: index + 1,
            occurredAt: DateTime.utc(2026, 8, 14, 16, 1),
          ),
        ),
      );
    });

    final summary = await repository.loadDashboard(
      calendarDays: 1,
      trendDays: 1,
    );

    expect(summary.today.eventCount, 501);
    expect(summary.currentStreakDays, 1);
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}
