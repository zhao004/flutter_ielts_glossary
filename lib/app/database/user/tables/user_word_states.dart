import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

@TableIndex(name: 'user_word_states_next_review_at', columns: {#nextReviewAt})
class UserWordStates extends Table {
  IntColumn get wordId => integer()();

  IntColumn get masteryLevel => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('mastery_level BETWEEN 0 AND 5'))();

  IntColumn get studiedCount => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('studied_count >= 0'))();

  IntColumn get correctCount => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('correct_count >= 0'))();

  IntColumn get wrongCount => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('wrong_count >= 0'))();

  IntColumn get correctStreak => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('correct_streak >= 0'))();

  IntColumn get consecutiveForgottenCount => integer()
      .withDefault(const Constant(0))
      .check(
        const CustomExpression<bool>('consecutive_forgotten_count >= 0'),
      )();

  IntColumn get lastStudiedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter()).nullable()();

  IntColumn get lastReviewedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter()).nullable()();

  IntColumn get nextReviewAt =>
      integer().map(const UtcDateTimeMillisecondsConverter()).nullable()();

  IntColumn get updatedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {wordId};
}
