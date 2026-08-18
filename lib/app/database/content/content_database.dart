import 'package:drift/drift.dart';

import '../converters/utc_date_time_milliseconds_converter.dart';
import 'daos/content_dao.dart';
import 'tables/content_metadata.dart';
import 'tables/frequency_groups.dart';
import 'tables/sentences.dart';
import 'tables/words.dart';

part 'content_database.g.dart';

/// 只保存随应用发布的词库内容；生产连接通过 SQLite query_only 禁止写入。
@DriftDatabase(
  tables: [FrequencyGroups, Words, Sentences, ContentMetadata],
  daos: [ContentDao],
)
class ContentDatabase extends _$ContentDatabase {
  /// 调用方必须显式提供执行器；Flutter 平台连接由独立工厂负责。
  ContentDatabase.forExecutor(super.executor);

  static const String databaseName = 'ielts_content';

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createWordSearchSchema();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// 由构建工具在批量导入或修复后显式重建全文索引。
  Future<void> rebuildWordSearchIndex() {
    return customStatement(
      "INSERT INTO word_search(word_search) VALUES ('rebuild')",
    );
  }

  Future<void> _createWordSearchSchema() async {
    await customStatement('''
      CREATE VIRTUAL TABLE word_search USING fts5(
        word,
        translation_zh,
        definition_en,
        content='words',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await customStatement('''
      CREATE TRIGGER words_search_insert AFTER INSERT ON words BEGIN
        INSERT INTO word_search(rowid, word, translation_zh, definition_en)
        VALUES (new.id, new.word, new.translation_zh, new.definition_en);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER words_search_delete AFTER DELETE ON words BEGIN
        INSERT INTO word_search(
          word_search,
          rowid,
          word,
          translation_zh,
          definition_en
        ) VALUES (
          'delete',
          old.id,
          old.word,
          old.translation_zh,
          old.definition_en
        );
      END
    ''');
    await customStatement('''
      CREATE TRIGGER words_search_update AFTER UPDATE ON words BEGIN
        INSERT INTO word_search(
          word_search,
          rowid,
          word,
          translation_zh,
          definition_en
        ) VALUES (
          'delete',
          old.id,
          old.word,
          old.translation_zh,
          old.definition_en
        );
        INSERT INTO word_search(rowid, word, translation_zh, definition_en)
        VALUES (new.id, new.word, new.translation_zh, new.definition_en);
      END
    ''');
  }
}
