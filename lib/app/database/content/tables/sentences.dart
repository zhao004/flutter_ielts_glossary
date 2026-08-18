import 'package:drift/drift.dart';

import 'words.dart';

@TableIndex(name: 'sentences_word_id', columns: {#wordId})
class Sentences extends Table {
  IntColumn get id => integer()();

  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();

  TextColumn get targetForm => text().withLength(min: 1, max: 200)();

  TextColumn get sentenceEn => text().withLength(min: 1)();

  TextColumn get translationZh => text().nullable()();

  TextColumn get source => text().nullable()();

  TextColumn get location => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
