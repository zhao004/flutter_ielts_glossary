import 'package:drift/drift.dart';

import 'frequency_groups.dart';

@TableIndex(name: 'words_frequency_group_id', columns: {#frequencyGroupId})
@TableIndex(name: 'words_first_letter', columns: {#firstLetter})
@TableIndex(name: 'words_occurrences', columns: {#occurrences})
class Words extends Table {
  IntColumn get id => integer()();

  TextColumn get word => text().withLength(min: 1, max: 200).unique()();

  TextColumn get phoneticUk => text().nullable()();

  TextColumn get phoneticUs => text().nullable()();

  TextColumn get translationZh => text().nullable()();

  TextColumn get definitionEn => text().nullable()();

  TextColumn get mnemonic => text().nullable()();

  IntColumn get occurrences =>
      integer().check(const CustomExpression<bool>('occurrences >= 0'))();

  IntColumn get frequencyGroupId =>
      integer().references(FrequencyGroups, #id)();

  TextColumn get firstLetter => text().withLength(min: 1, max: 1)();

  TextColumn get audioUkAsset => text().nullable()();

  TextColumn get audioUsAsset => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
