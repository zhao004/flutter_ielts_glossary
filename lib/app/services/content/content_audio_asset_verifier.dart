import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../database/content/content_database.dart';
import '../audio/audio_asset_path_policy.dart';
import 'content_validation.dart';

/// 只读检查内容库中的本地音频路径是否存在于最终资源目录。
final class ContentAudioAssetVerifier {
  const ContentAudioAssetVerifier();

  static const int maxReportedIssues = 200;

  /// 校验数据库音频字段、资源路径白名单和打包目录中的普通文件。
  Future<void> verify({
    required File databaseFile,
    required Directory audioDirectory,
  }) async {
    final issues = <ContentValidationIssue>[];
    final issueCounts = <String, int>{};
    void addIssue(
      String code,
      String message, {
      Map<String, Object> details = const <String, Object>{},
    }) {
      issueCounts.update(code, (count) => count + 1, ifAbsent: () => 1);
      if (issues.length < maxReportedIssues) {
        issues.add(
          ContentValidationIssue(
            code: code,
            message: message,
            details: details,
          ),
        );
      }
    }

    final databaseType = await FileSystemEntity.type(
      databaseFile.path,
      followLinks: false,
    );
    if (databaseType != FileSystemEntityType.file) {
      addIssue('missing_audio_database', '用于音频校验的内容数据库不是普通文件');
    }
    final audioType = await FileSystemEntity.type(
      audioDirectory.path,
      followLinks: false,
    );
    if (audioType != FileSystemEntityType.directory) {
      addIssue('missing_audio_directory', '音频资源目录不是普通目录');
    }
    if (issues.isNotEmpty) {
      throw ContentValidationException(issues, issueCounts: issueCounts);
    }

    final database = ContentDatabase.forExecutor(
      NativeDatabase(
        databaseFile,
        enableMigrations: false,
        setup: (sqlite) => sqlite.execute('PRAGMA query_only = ON'),
      ),
    );
    try {
      final rows = await database.customSelect('''
        SELECT id, audio_uk_asset, audio_us_asset
        FROM words
        WHERE audio_uk_asset IS NOT NULL OR audio_us_asset IS NOT NULL
        ORDER BY id
      ''').get();
      for (final row in rows) {
        final wordId = row.read<int>('id');
        _verifyPath(
          row.readNullable<String>('audio_uk_asset'),
          accent: 'uk',
          wordId: wordId,
          audioDirectory: audioDirectory,
          addIssue: addIssue,
        );
        _verifyPath(
          row.readNullable<String>('audio_us_asset'),
          accent: 'us',
          wordId: wordId,
          audioDirectory: audioDirectory,
          addIssue: addIssue,
        );
      }
    } on ContentValidationException {
      rethrow;
    } on Object {
      addIssue('audio_database_read_failed', '无法读取内容库中的音频字段');
    } finally {
      await database.close();
    }

    if (issues.isNotEmpty) {
      throw ContentValidationException(issues, issueCounts: issueCounts);
    }
  }

  void _verifyPath(
    String? assetPath, {
    required String accent,
    required int wordId,
    required Directory audioDirectory,
    required void Function(
      String code,
      String message, {
      Map<String, Object> details,
    })
    addIssue,
  }) {
    if (assetPath == null) {
      return;
    }
    final details = <String, Object>{
      'wordId': wordId,
      'accent': accent,
      'assetPath': assetPath,
    };
    const policy = AudioAssetPathPolicy();
    if (!policy.isAllowed(assetPath, accent: accent)) {
      addIssue(
        'invalid_audio_asset_path',
        '单词 ID $wordId 的 $accent 音频路径不符合资源白名单',
        details: details,
      );
      return;
    }

    final relativePath = assetPath
        .substring(AudioAssetPathPolicy.assetRoot.length)
        .split('/');
    var currentPath = audioDirectory.path;
    for (var index = 0; index < relativePath.length; index++) {
      currentPath = p.join(currentPath, relativePath[index]);
      final fileType = FileSystemEntity.typeSync(
        currentPath,
        followLinks: false,
      );
      if (fileType == FileSystemEntityType.link) {
        addIssue(
          'invalid_audio_asset_path',
          '单词 ID $wordId 的 $accent 音频路径经过符号链接',
          details: details,
        );
        return;
      }
      final isLast = index == relativePath.length - 1;
      if ((!isLast && fileType != FileSystemEntityType.directory) ||
          (isLast && fileType != FileSystemEntityType.file)) {
        addIssue(
          'missing_audio_file',
          '单词 ID $wordId 的 $accent 音频文件不存在或不是普通文件',
          details: details,
        );
        return;
      }
    }
  }
}
