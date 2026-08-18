import '../../models/domain/review_rating.dart';

/// 一次学习或复习后的掌握等级与下次复习时间。
final class ReviewSchedule {
  const ReviewSchedule({
    required this.masteryLevel,
    required this.nextReviewAt,
  });

  final int masteryLevel;
  final DateTime nextReviewAt;
}

/// 集中实现六级间隔与四档复习反馈对应的排程规则。
final class ReviewScheduler {
  const ReviewScheduler();

  static const int minMasteryLevel = 0;
  static const int maxMasteryLevel = 5;
  static const Duration relearnInterval = Duration(minutes: 10);
  static const Duration minimumHardInterval = Duration(minutes: 30);
  static const Duration maximumLevelEasyInterval = Duration(days: 60);
  static const List<Duration> intervals = [
    Duration(hours: 4),
    Duration(hours: 12),
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 10),
    Duration(days: 30),
  ];

  /// 首次有效学习固定进入等级 0，并在 4 小时后复习。
  ReviewSchedule scheduleInitialStudy(DateTime now) {
    final nowUtc = now.toUtc();
    return ReviewSchedule(
      masteryLevel: minMasteryLevel,
      nextReviewAt: nowUtc.add(intervals[minMasteryLevel]),
    );
  }

  /// 按自评难度调整等级和下次复习间隔。
  ReviewSchedule scheduleReview({
    required int currentMasteryLevel,
    required ReviewRating rating,
    required DateTime now,
  }) {
    _validateMasteryLevel(currentMasteryLevel);
    final nowUtc = now.toUtc();
    return switch (rating) {
      ReviewRating.again => _again(currentMasteryLevel, nowUtc),
      ReviewRating.hard => _hard(currentMasteryLevel, nowUtc),
      ReviewRating.good => _good(currentMasteryLevel, nowUtc),
      ReviewRating.easy => _easy(currentMasteryLevel, nowUtc),
    };
  }

  Duration intervalForLevel(int masteryLevel) {
    _validateMasteryLevel(masteryLevel);
    return intervals[masteryLevel];
  }

  ReviewSchedule _again(int currentMasteryLevel, DateTime nowUtc) {
    final newLevel = currentMasteryLevel > minMasteryLevel
        ? currentMasteryLevel - 1
        : minMasteryLevel;
    return ReviewSchedule(
      masteryLevel: newLevel,
      nextReviewAt: nowUtc.add(relearnInterval),
    );
  }

  ReviewSchedule _hard(int currentMasteryLevel, DateTime nowUtc) {
    final halfIntervalMilliseconds =
        intervals[currentMasteryLevel].inMilliseconds ~/ 2;
    final intervalMilliseconds =
        halfIntervalMilliseconds < minimumHardInterval.inMilliseconds
        ? minimumHardInterval.inMilliseconds
        : halfIntervalMilliseconds;
    return ReviewSchedule(
      masteryLevel: currentMasteryLevel,
      nextReviewAt: nowUtc.add(Duration(milliseconds: intervalMilliseconds)),
    );
  }

  ReviewSchedule _good(int currentMasteryLevel, DateTime nowUtc) {
    final newLevel = currentMasteryLevel < maxMasteryLevel
        ? currentMasteryLevel + 1
        : maxMasteryLevel;
    return ReviewSchedule(
      masteryLevel: newLevel,
      nextReviewAt: nowUtc.add(intervals[newLevel]),
    );
  }

  ReviewSchedule _easy(int currentMasteryLevel, DateTime nowUtc) {
    final newLevel = currentMasteryLevel + 2 > maxMasteryLevel
        ? maxMasteryLevel
        : currentMasteryLevel + 2;
    final interval = currentMasteryLevel == maxMasteryLevel
        ? maximumLevelEasyInterval
        : intervals[newLevel];
    return ReviewSchedule(
      masteryLevel: newLevel,
      nextReviewAt: nowUtc.add(interval),
    );
  }

  void _validateMasteryLevel(int masteryLevel) {
    if (masteryLevel < minMasteryLevel || masteryLevel > maxMasteryLevel) {
      throw RangeError.range(
        masteryLevel,
        minMasteryLevel,
        maxMasteryLevel,
        'masteryLevel',
      );
    }
  }
}
