import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_ielts_glossary/app/services/files/atomic_file_set_publisher.dart';

void main() {
  final workspace = Directory.current.absolute;
  final cacheRoot = Directory(
    p.join(workspace.path, '.cache', 'atomic_publisher_tests'),
  );
  final cleanupDirectories = <Directory>[];

  tearDown(() async {
    for (final directory in cleanupDirectories.reversed) {
      if (p.isWithin(cacheRoot.path, directory.path) &&
          await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    cleanupDirectories.clear();
  });

  test('第二个文件发布失败时撤回新文件并恢复旧文件', () async {
    final targetDirectory = Directory(
      p.join(
        cacheRoot.path,
        'rollback-${DateTime.now().microsecondsSinceEpoch}-$pid',
      ),
    );
    cleanupDirectories.add(targetDirectory);
    final stagingDirectory = Directory(
      p.join(targetDirectory.path, '.staging'),
    );
    await stagingDirectory.create(recursive: true);
    final stagedDatabase = File(p.join(stagingDirectory.path, 'database'));
    final stagedManifest = File(p.join(stagingDirectory.path, 'manifest'));
    final targetDatabase = File(p.join(targetDirectory.path, 'database'));
    final targetManifest = File(p.join(targetDirectory.path, 'manifest'));
    await stagedDatabase.writeAsString('new-database');
    await stagedManifest.writeAsString('new-manifest');
    await targetDatabase.writeAsString('old-database');

    // 同名目录会让第二次 File.rename 失败，触发发布器的回滚分支。
    await Directory(targetManifest.path).create();

    final operation = const AtomicFileSetPublisher().publish(
      stagedToTarget: {
        stagedDatabase: targetDatabase,
        stagedManifest: targetManifest,
      },
      replaceExisting: true,
    );

    await expectLater(
      operation,
      throwsA(
        isA<AtomicFilePublishException>().having(
          (error) => error.code,
          'code',
          'atomic_publish_failed',
        ),
      ),
    );
    expect(await targetDatabase.readAsString(), 'old-database');
    expect(await stagedManifest.exists(), isTrue);
    expect(await Directory(targetManifest.path).exists(), isTrue);
  });
}
