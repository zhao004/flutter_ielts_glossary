import 'package:drift/drift.dart';

@TableIndex(name: 'frequency_groups_rank', columns: {#rank}, unique: true)
class FrequencyGroups extends Table {
  IntColumn get id => integer()();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  IntColumn get rank =>
      integer().check(const CustomExpression<bool>('rank BETWEEN 1 AND 7'))();

  IntColumn get minOccurrences =>
      integer().check(const CustomExpression<bool>('min_occurrences >= 0'))();

  IntColumn get maxOccurrences => integer().nullable().check(
    const CustomExpression<bool>(
      'max_occurrences IS NULL OR max_occurrences >= 0',
    ),
  )();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
