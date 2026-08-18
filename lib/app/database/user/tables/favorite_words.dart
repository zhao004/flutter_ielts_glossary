import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

@TableIndex(name: 'favorite_words_word_id', columns: {#wordId}, unique: true)
class FavoriteWords extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();

  IntColumn get wordId => integer()();

  IntColumn get createdAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  IntColumn get updatedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
