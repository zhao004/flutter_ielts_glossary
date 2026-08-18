import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

@DataClassName('ContentMetadataEntry')
class ContentMetadata extends Table {
  IntColumn get id => integer()
      .withDefault(const Constant(1))
      .check(const CustomExpression<bool>('id = 1'))();

  TextColumn get contentVersion => text().withLength(min: 1, max: 100)();

  IntColumn get formatVersion =>
      integer().check(const CustomExpression<bool>('format_version > 0'))();

  TextColumn get sourceRepository => text().withLength(min: 1, max: 500)();

  TextColumn get sourceRevision => text().withLength(min: 1, max: 200)();

  IntColumn get generatedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  IntColumn get wordCount =>
      integer().check(const CustomExpression<bool>('word_count >= 0'))();

  IntColumn get sentenceCount =>
      integer().check(const CustomExpression<bool>('sentence_count >= 0'))();

  TextColumn get licenseNotice => text()();

  TextColumn get sha256 => text().withLength(min: 64, max: 64)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
