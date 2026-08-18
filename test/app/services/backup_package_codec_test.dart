import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/backup/backup_exceptions.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_snapshot.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_package_codec.dart';

void main() {
  final codec = BackupPackageCodec();
  final snapshot = BackupSnapshot(
    userWordStates: const [],
    favoriteWords: const [],
    favoriteSentences: const [],
    practiceSessions: const [],
    practiceAnswers: const [],
    learningEvents: const [],
    appSettings: null,
  );

  test('ZIP 包往返并校验 manifest 计数和 data 哈希', () {
    final bytes = codec.encode(
      appVersion: '1.0.0+1',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: snapshot,
    );
    final decoded = codec.decode(bytes);

    expect(decoded.manifest.appVersion, '1.0.0+1');
    expect(decoded.manifest.contentVersion, 'content-v1');
    expect(decoded.manifest.recordCounts.appSettings, 0);
    expect(decoded.snapshot!.userWordStates, isEmpty);
  });

  test('后台 Isolate 解析结果与同步协议一致', () async {
    final bytes = codec.encode(
      appVersion: '1.0.0+1',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: snapshot,
    );

    final decoded = await codec.decodeInBackground(bytes);

    expect(decoded.manifest.appVersion, '1.0.0+1');
    expect(decoded.manifest.recordCounts.appSettings, 0);
    expect(decoded.snapshot?.userWordStates, isEmpty);
  });

  test('篡改 data.json 后在业务解析前失败', () {
    final source = codec.encode(
      appVersion: '1.0.0',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: snapshot,
    );
    final archive = ZipDecoder().decodeBytes(source);
    final tamperedArchive = Archive();
    for (final file in archive) {
      final content = file.name == 'data.json'
          ? utf8.encode('{"formatVersion":1}')
          : file.content;
      tamperedArchive.addFile(ArchiveFile(file.name, content.length, content));
    }
    final tampered = ZipEncoder().encode(tamperedArchive);

    expect(
      () => codec.decode(tampered),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.code,
          'code',
          'data_checksum_mismatch',
        ),
      ),
    );
  });

  test('后台 Isolate 保留稳定的校验错误码', () async {
    final source = codec.encode(
      appVersion: '1.0.0',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: snapshot,
    );
    final archive = ZipDecoder().decodeBytes(source);
    final tamperedArchive = Archive();
    for (final file in archive) {
      final content = file.name == 'data.json'
          ? utf8.encode('{"formatVersion":1}')
          : file.content;
      tamperedArchive.addFile(ArchiveFile(file.name, content.length, content));
    }
    final tampered = ZipEncoder().encode(tamperedArchive);

    await expectLater(
      codec.decodeInBackground(tampered),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.code,
          'code',
          'data_checksum_mismatch',
        ),
      ),
    );
  });

  test('拒绝额外 ZIP 条目和超过上限的压缩包', () {
    final archive = Archive()
      ..addFile(ArchiveFile('manifest.json', 2, utf8.encode('{}')))
      ..addFile(ArchiveFile('data.json', 2, utf8.encode('{}')))
      ..addFile(ArchiveFile('extra.txt', 1, [1]));
    final bytes = ZipEncoder().encode(archive);
    expect(() => codec.decode(bytes), throwsA(isA<BackupFormatException>()));

    final limited = BackupPackageCodec(maxBackupBytes: 10);
    expect(
      () => limited.encode(
        appVersion: '1.0.0',
        userSchemaVersion: 1,
        contentVersion: 'v1',
        exportedAt: DateTime.utc(2026, 8, 15),
        snapshot: snapshot,
      ),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('按 ZIP 声明长度在解压内容前拒绝超限条目', () {
    final source = codec.encode(
      appVersion: '1.0.0',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: snapshot,
    );
    const limited = BackupPackageCodec(maxDecompressedBytes: 32);

    expect(
      () => limited.decode(source),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.code,
          'code',
          'decompressed_too_large',
        ),
      ),
    );
  });

  test('高于当前协议的包可只读预览但默认拒绝导入', () {
    final source = codec.encode(
      appVersion: '1.0.0',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15),
      snapshot: snapshot,
    );
    final sourceArchive = ZipDecoder().decodeBytes(source);
    final futureArchive = Archive();
    for (final file in sourceArchive) {
      final content = file.name == 'manifest.json'
          ? (() {
              final manifest = jsonDecode(utf8.decode(file.content)) as Map;
              manifest['formatVersion'] = 99;
              return utf8.encode(jsonEncode(manifest));
            })()
          : file.content;
      futureArchive.addFile(ArchiveFile(file.name, content.length, content));
    }
    final futureBytes = ZipEncoder().encode(futureArchive);

    final preview = codec.decode(futureBytes, allowFutureFormat: true);
    expect(preview.isFutureFormat, isTrue);
    expect(preview.snapshot, isNull);
    expect(
      () => codec.decode(futureBytes),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.code,
          'code',
          'future_format_version',
        ),
      ),
    );
  });
}
