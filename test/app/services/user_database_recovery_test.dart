import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_ielts_glossary/app/services/user/user_database_recovery.dart';

void main() {
  final root = Directory('.cache/user-database-recovery-test');
  final now = DateTime.utc(2026, 8, 15, 12, 30, 45, 123, 456);

  setUp(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    await root.create(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('移动用户库及 SQLite 旁车文件到私有恢复目录并保留原始字节', () async {
    final expected = <String, List<int>>{
      for (final artifact in LocalUserDatabaseRecovery.databaseArtifacts)
        artifact: artifact.codeUnits,
    };
    for (final entry in expected.entries) {
      await File(p.join(root.path, entry.key)).writeAsBytes(entry.value);
    }

    final recovery = LocalUserDatabaseRecovery(
      applicationSupportDirectory: root,
      clock: () => now,
    );
    final result = await recovery.backupAndReset();

    expect(result.backupFiles, hasLength(expected.length));
    for (final entry in expected.entries) {
      expect(await File(p.join(root.path, entry.key)).exists(), isFalse);
      final backups = result.backupFiles
          .where((file) => p.basename(file.path).startsWith('${entry.key}.'))
          .toList();
      expect(backups, hasLength(1));
      expect(await backups.single.readAsBytes(), entry.value);
      expect(backups.single.path, contains('20260815_123045_123456.bak'));
    }
  });

  test('没有旧用户库时只创建恢复目录，不伪造备份文件', () async {
    final recovery = LocalUserDatabaseRecovery(
      applicationSupportDirectory: root,
      clock: () => now,
    );

    final result = await recovery.backupAndReset();

    expect(result.backupFiles, isEmpty);
    expect(
      await Directory(
        p.join(root.path, LocalUserDatabaseRecovery.recoveryDirectoryName),
      ).exists(),
      isTrue,
    );
  });

  test('恢复目录创建失败时返回稳定错误并保留原始文件', () async {
    final databaseFile = File(
      p.join(root.path, LocalUserDatabaseRecovery.databaseArtifacts.first),
    );
    await databaseFile.writeAsString('keep-me');
    await File(
      p.join(root.path, LocalUserDatabaseRecovery.recoveryDirectoryName),
    ).writeAsString('not-a-directory');

    final recovery = LocalUserDatabaseRecovery(
      applicationSupportDirectory: root,
      clock: () => now,
    );

    await expectLater(
      recovery.backupAndReset(),
      throwsA(
        isA<UserDatabaseRecoveryException>().having(
          (error) => error.code,
          'code',
          'backup_failed',
        ),
      ),
    );
    expect(await databaseFile.readAsString(), 'keep-me');
  });
}
