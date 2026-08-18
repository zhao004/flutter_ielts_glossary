import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

class BackupHistory extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get type => text().withLength(min: 1, max: 64)();

  TextColumn get fileName => text().withLength(min: 1, max: 255)();

  TextColumn get summaryJson => text().withLength(min: 2)();

  TextColumn get result => text().withLength(min: 1, max: 64)();

  IntColumn get occurredAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
