import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../database/content/content_database.dart';
import '../../models/content/content_asset_names.dart';
import '../../models/content/content_manifest.dart';
import 'content_validation.dart';

/// 安装或发布前校验数据库字节、元数据、记录数与 FTS5 索引。
final class ContentDatabaseVerifier {
  const ContentDatabaseVerifier();

  static const int maxManifestBytes = 1024 * 1024;

  /// 解析受大小限制的清单字节，并把协议错误转换为统一完整性问题。
  ContentManifest parseManifestBytes(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxManifestBytes) {
      throw ContentValidationException([
        const ContentValidationIssue(
          code: 'invalid_manifest_size',
          message: '内容清单大小必须在 1-1048576 字节之间',
        ),
      ]);
    }
    try {
      return ContentManifest.fromBytes(bytes);
    } on ContentManifestException catch (error) {
      throw ContentValidationException([
        ContentValidationIssue(code: error.code, message: error.message),
      ]);
    }
  }

  /// 验证固定命名的数据库与清单文件，成功时返回已解析清单。
  Future<ContentManifest> verify({
    required File databaseFile,
    required File manifestFile,
  }) async {
    final issues = <ContentValidationIssue>[];
    if (!await databaseFile.exists()) {
      issues.add(
        const ContentValidationIssue(
          code: 'missing_database',
          message: '内容数据库文件不存在',
        ),
      );
    }
    if (!await manifestFile.exists()) {
      issues.add(
        const ContentValidationIssue(
          code: 'missing_manifest',
          message: '内容清单文件不存在',
        ),
      );
    }
    if (issues.isNotEmpty) {
      throw ContentValidationException(issues);
    }

    final manifestLength = await manifestFile.length();
    if (manifestLength <= 0 || manifestLength > maxManifestBytes) {
      throw ContentValidationException([
        ContentValidationIssue(
          code: 'invalid_manifest_size',
          message: '内容清单大小必须在 1-$maxManifestBytes 字节之间',
        ),
      ]);
    }
    final manifest = parseManifestBytes(await manifestFile.readAsBytes());
    if (manifest.formatVersion != ContentManifest.currentFormatVersion) {
      issues.add(
        ContentValidationIssue(
          code: 'unsupported_content_format',
          message: '不支持内容格式版本 ${manifest.formatVersion}',
        ),
      );
    }
    if (p.basename(databaseFile.path) != manifest.databaseFile ||
        manifest.databaseFile != ContentAssetNames.databaseFile) {
      issues.add(
        const ContentValidationIssue(
          code: 'database_name_mismatch',
          message: '内容清单中的数据库文件名不正确',
        ),
      );
    }

    final databaseBytes = await databaseFile.length();
    if (databaseBytes != manifest.databaseBytes) {
      issues.add(
        ContentValidationIssue(
          code: 'database_size_mismatch',
          message: '数据库大小 $databaseBytes 与清单不一致',
        ),
      );
    }
    final databaseSha256 = await _sha256File(databaseFile);
    if (databaseSha256 != manifest.databaseSha256) {
      issues.add(
        const ContentValidationIssue(
          code: 'database_checksum_mismatch',
          message: '数据库 SHA-256 与内容清单不一致',
        ),
      );
    }
    if (issues.isNotEmpty) {
      throw ContentValidationException(issues);
    }

    final database = ContentDatabase.forExecutor(
      NativeDatabase(
        databaseFile,
        enableMigrations: false,
        setup: (sqlite) {
          sqlite.execute('PRAGMA query_only = ON');
        },
      ),
    );
    try {
      final wordCount = await _count(database, 'words');
      final sentenceCount = await _count(database, 'sentences');
      final activeGroupCount = await _scalar(
        database,
        'SELECT COUNT(*) AS value FROM frequency_groups WHERE rank BETWEEN 1 AND 6',
      );
      final groupRows = await database.customSelect('''
        SELECT frequency_groups.rank AS group_rank, COUNT(words.id) AS word_count
        FROM frequency_groups
        LEFT JOIN words ON words.frequency_group_id = frequency_groups.id
        WHERE frequency_groups.rank BETWEEN 1 AND 6
        GROUP BY frequency_groups.rank
        ORDER BY frequency_groups.rank
      ''').get();
      final groupWordCounts = {
        for (final row in groupRows)
          row.read<int>('group_rank'): row.read<int>('word_count'),
      };
      final searchCount = await _count(database, 'word_search');
      final schemaVersion = await _scalar(
        database,
        'PRAGMA user_version',
        columnName: 'user_version',
      );
      final metadata = await database.contentDao.findMetadata();

      if (schemaVersion != database.schemaVersion) {
        issues.add(
          ContentValidationIssue(
            code: 'schema_version_mismatch',
            message:
                '数据库 schemaVersion 为 $schemaVersion，预期 ${database.schemaVersion}',
          ),
        );
      }
      if (wordCount != manifest.wordCount ||
          sentenceCount != manifest.sentenceCount ||
          activeGroupCount != manifest.activeGroupCount ||
          !_sameIntMap(groupWordCounts, manifest.groupWordCounts)) {
        issues.add(
          const ContentValidationIssue(
            code: 'record_count_mismatch',
            message: '数据库记录数与内容清单不一致',
          ),
        );
      }
      if (searchCount != wordCount) {
        issues.add(
          ContentValidationIssue(
            code: 'search_index_mismatch',
            message: 'FTS5 索引包含 $searchCount 条记录，单词表包含 $wordCount 条',
          ),
        );
      }
      if (metadata == null ||
          metadata.contentVersion != manifest.contentVersion ||
          metadata.formatVersion != manifest.formatVersion ||
          metadata.sourceRepository != manifest.sourceRepository ||
          metadata.sourceRevision != manifest.sourceRevision ||
          metadata.generatedAt.millisecondsSinceEpoch !=
              manifest.generatedAt.millisecondsSinceEpoch ||
          metadata.wordCount != manifest.wordCount ||
          metadata.sentenceCount != manifest.sentenceCount ||
          metadata.sha256 != manifest.sourceDataSha256 ||
          metadata.licenseNotice != manifest.licenseNotice) {
        issues.add(
          const ContentValidationIssue(
            code: 'metadata_mismatch',
            message: '数据库 ContentMetadata 与内容清单不一致',
          ),
        );
      }
    } on ContentValidationException {
      rethrow;
    } on Exception {
      issues.add(
        const ContentValidationIssue(
          code: 'database_open_failed',
          message: '数据库无法按当前 Drift schema 只读打开',
        ),
      );
    } finally {
      await database.close();
    }

    if (issues.isNotEmpty) {
      throw ContentValidationException(issues);
    }
    return manifest;
  }

  Future<int> _count(ContentDatabase database, String tableName) {
    return _scalar(database, 'SELECT COUNT(*) AS value FROM $tableName');
  }

  Future<int> _scalar(
    ContentDatabase database,
    String sql, {
    String columnName = 'value',
  }) async {
    final row = await database.customSelect(sql).getSingle();
    return row.read<int>(columnName);
  }

  Future<String> _sha256File(File file) async {
    return (await sha256.bind(file.openRead()).first).toString();
  }

  bool _sameIntMap(Map<int, int> left, Map<int, int> right) {
    if (left.length != right.length) {
      return false;
    }
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }
}
