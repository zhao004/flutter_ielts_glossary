import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';
import 'practice_sessions.dart';

@TableIndex(name: 'practice_answers_session_id', columns: {#sessionId})
class PracticeAnswers extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get sessionId =>
      text().references(PracticeSessions, #id, onDelete: KeyAction.cascade)();

  IntColumn get wordId => integer()();

  IntColumn get sentenceId => integer().nullable()();

  TextColumn get userAnswer => text()();

  BoolColumn get isCorrect => boolean()();

  IntColumn get responseTimeMilliseconds => integer().check(
    const CustomExpression<bool>('response_time_milliseconds >= 0'),
  )();

  IntColumn get answeredAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
