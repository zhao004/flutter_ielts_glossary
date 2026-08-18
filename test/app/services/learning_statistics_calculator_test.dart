import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/learning_event_fact.dart';
import 'package:flutter_ielts_glossary/app/models/domain/local_date.dart';
import 'package:flutter_ielts_glossary/app/services/clock/local_time_resolver.dart';
import 'package:flutter_ielts_glossary/app/services/statistics/learning_statistics_calculator.dart';

void main() {
  const resolver = FixedOffsetLocalTimeResolver(Duration(hours: 8));
  const calculator = LearningStatisticsCalculator();

  test('按固定时区把 UTC 事件归入正确本地日并生成零值日期', () {
    final today = LocalDate(year: 2026, month: 8, day: 15);
    final series = calculator.buildDailySeries(
      today: today,
      dayCount: 3,
      localTimeResolver: resolver,
      events: [
        LearningEventFact(
          occurredAt: DateTime.utc(2026, 8, 12, 15, 59),
          isCorrect: null,
        ),
        LearningEventFact(
          occurredAt: DateTime.utc(2026, 8, 12, 16),
          isCorrect: true,
        ),
        LearningEventFact(
          occurredAt: DateTime.utc(2026, 8, 14, 16),
          isCorrect: false,
        ),
      ],
    );

    expect(series.map((day) => day.date.toString()), [
      '2026-08-13',
      '2026-08-14',
      '2026-08-15',
    ]);
    expect(series[0].eventCount, 1);
    expect(series[0].answeredCount, 1);
    expect(series[0].correctCount, 1);
    expect(series[1].eventCount, 0);
    expect(series[2].eventCount, 1);
    expect(series[2].accuracy, 0);
  });

  test('今天未活动时沿用昨天连续学习天数，跨月跨年仍连续', () {
    final today = LocalDate(year: 2026, month: 1, day: 1);
    final activeDates = <LocalDate>{
      LocalDate(year: 2025, month: 12, day: 31),
      LocalDate(year: 2025, month: 12, day: 30),
      LocalDate(year: 2025, month: 12, day: 29),
    };

    expect(
      calculator.calculateCurrentStreak(activeDates: activeDates, today: today),
      3,
    );
  });

  test('今天和昨天都没有活动时连续天数为零', () {
    expect(
      calculator.calculateCurrentStreak(
        activeDates: {LocalDate(year: 2026, month: 8, day: 10)},
        today: LocalDate(year: 2026, month: 8, day: 15),
      ),
      0,
    );
  });
}
