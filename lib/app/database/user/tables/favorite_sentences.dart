import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

@TableIndex(
  name: 'favorite_sentences_sentence_id',
  columns: {#sentenceId},
  unique: true,
)
class FavoriteSentences extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();

  IntColumn get sentenceId => integer()();

  IntColumn get wordId => integer()();

  IntColumn get createdAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  IntColumn get updatedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
