import 'package:drift/drift.dart';

import '../../converters/utc_date_time_milliseconds_converter.dart';

@DataClassName('AppSetting')
class AppSettings extends Table {
  IntColumn get id => integer()
      .withDefault(const Constant(1))
      .check(const CustomExpression<bool>('id = 1'))();

  IntColumn get dailyGoal =>
      integer().check(const CustomExpression<bool>('daily_goal > 0'))();

  TextColumn get pronunciationAccent => text().withLength(min: 2, max: 2)();

  BoolColumn get autoPlayPronunciation => boolean()();

  TextColumn get themeMode => text().withLength(min: 4, max: 6)();

  TextColumn get accentColor =>
      text().withLength(min: 3, max: 32).withDefault(const Constant('indigo'))();

  IntColumn get updatedAt =>
      integer().map(const UtcDateTimeMillisecondsConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
