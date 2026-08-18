import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

class PracticeSessions extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get type => text().withLength(min: 1, max: 64)();

  TextColumn get configJson => text().withLength(min: 2)();

  IntColumn get startedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  IntColumn get finishedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter()).nullable()();

  IntColumn get totalQuestionCount => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('total_question_count >= 0'))();

  IntColumn get correctCount => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('correct_count >= 0'))();

  IntColumn get elapsedMilliseconds => integer()
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('elapsed_milliseconds >= 0'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
