import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

@TableIndex(name: 'learning_events_occurred_at', columns: {#occurredAt})
class LearningEvents extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get eventType => text().withLength(min: 1, max: 64)();

  IntColumn get wordId => integer()();

  TextColumn get sessionId => text().withLength(min: 1, max: 64).nullable()();

  BoolColumn get isCorrect => boolean().nullable()();

  TextColumn get reviewRating =>
      text().withLength(min: 1, max: 16).nullable()();

  IntColumn get occurredAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
