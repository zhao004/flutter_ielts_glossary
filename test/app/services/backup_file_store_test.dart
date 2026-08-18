import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_snapshot.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_file_store.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_package_codec.dart';

void main() {
  final root = Directory('.cache/backup-file-store-test');

  setUp(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  BackupExport export() {
    final bytes = BackupPackageCodec().encode(
      appVersion: 'test-app',
      userSchemaVersion: 1,
      contentVersion: 'test-content',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: BackupSnapshot(
        userWordStates: const [],
        favoriteWords: const [],
        favoriteSentences: const [],
        practiceSessions: const [],
        practiceAnswers: const [],
        learningEvents: const [],
        appSettings: null,
      ),
    );
    return BackupExport(
      bytes: bytes,
      fileName: 'ielts_vocab_20260815_000000.ieltsbackup',
      manifest: BackupPackageCodec().decode(bytes).manifest,
    );
  }

  test('导出和保护备份写入固定私有子目录并保留完整字节', () async {
    final store = LocalBackupFileStore(directoryProvider: () async => root);
    final exported = await store.saveExport(export());
    final protected = await store.saveProtection(export());

    expect(exported.path, contains('backups'));
    expect(protected.path, contains('protection_'));
    expect(await exported.readAsBytes(), isNotEmpty);
    expect(await protected.readAsBytes(), isNotEmpty);
    expect(await File('${exported.path}.tmp').exists(), isFalse);
  });

  test('拒绝路径穿越和非协议文件名', () async {
    final store = LocalBackupFileStore(directoryProvider: () async => root);
    final source = export();
    final unsafe = BackupExport(
      bytes: source.bytes,
      fileName: '../outside.ieltsbackup',
      manifest: source.manifest,
    );

    expect(() => store.saveExport(unsafe), throwsA(isA<BackupFileException>()));
  });
}
