import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/services/review/review_scheduler.dart';

void main() {
  const scheduler = ReviewScheduler();
  final now = DateTime.utc(2026, 8, 14, 12);

  test('首次有效学习进入等级 0 并在 4 小时后复习', () {
    final schedule = scheduler.scheduleInitialStudy(
      DateTime.parse('2026-08-14T20:00:00+08:00'),
    );

    expect(schedule.masteryLevel, 0);
    expect(schedule.nextReviewAt, DateTime.utc(2026, 8, 14, 16));
    expect(schedule.nextReviewAt.isUtc, isTrue);
  });

  test('六个等级映射到扩展后的长期记忆间隔', () {
    expect(List.generate(6, scheduler.intervalForLevel), const [
      Duration(hours: 4),
      Duration(hours: 12),
      Duration(days: 1),
      Duration(days: 3),
      Duration(days: 10),
      Duration(days: 30),
    ]);
  });

  for (var currentLevel = 0; currentLevel <= 5; currentLevel++) {
    test('等级 $currentLevel 选择记得时升级且不超过 5', () {
      final schedule = scheduler.scheduleReview(
        currentMasteryLevel: currentLevel,
        rating: ReviewRating.good,
        now: now,
      );
      final expectedLevel = currentLevel < 5 ? currentLevel + 1 : 5;

      expect(schedule.masteryLevel, expectedLevel);
      expect(
        schedule.nextReviewAt,
        now.add(scheduler.intervalForLevel(expectedLevel)),
      );
    });

    test('等级 $currentLevel 选择重学时降级并在 10 分钟后复习', () {
      final schedule = scheduler.scheduleReview(
        currentMasteryLevel: currentLevel,
        rating: ReviewRating.again,
        now: now,
      );
      final expectedLevel = currentLevel > 0 ? currentLevel - 1 : 0;

      expect(schedule.masteryLevel, expectedLevel);
      expect(schedule.nextReviewAt, now.add(const Duration(minutes: 10)));
    });

    test('等级 $currentLevel 选择困难时保持等级并缩短一半间隔', () {
      final schedule = scheduler.scheduleReview(
        currentMasteryLevel: currentLevel,
        rating: ReviewRating.hard,
        now: now,
      );
      final half = Duration(
        milliseconds:
            scheduler.intervalForLevel(currentLevel).inMilliseconds ~/ 2,
      );
      final expected =
          half.inMilliseconds <
              ReviewScheduler.minimumHardInterval.inMilliseconds
          ? ReviewScheduler.minimumHardInterval
          : half;

      expect(schedule.masteryLevel, currentLevel);
      expect(schedule.nextReviewAt, now.add(expected));
    });

    test('等级 $currentLevel 选择轻松时最多跨两级', () {
      final schedule = scheduler.scheduleReview(
        currentMasteryLevel: currentLevel,
        rating: ReviewRating.easy,
        now: now,
      );
      final expectedLevel = currentLevel + 2 > 5 ? 5 : currentLevel + 2;
      final expectedInterval = currentLevel == 5
          ? ReviewScheduler.maximumLevelEasyInterval
          : scheduler.intervalForLevel(expectedLevel);

      expect(schedule.masteryLevel, expectedLevel);
      expect(schedule.nextReviewAt, now.add(expectedInterval));
    });
  }

  test('拒绝范围外的掌握等级', () {
    expect(() => scheduler.intervalForLevel(-1), throwsRangeError);
    expect(
      () => scheduler.scheduleReview(
        currentMasteryLevel: 6,
        rating: ReviewRating.good,
        now: now,
      ),
      throwsRangeError,
    );
  });
}
