import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_snapshot.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_file_store.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_package_codec.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_transfer_service.dart';

void main() {
  final root = Directory('.cache/backup-transfer-service-test');

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

  test('选择器返回字节时先暂存到私有目录并可清理', () async {
    final picker = _FakePicker(
      PickedBackupSource(
        name: 'sample.ieltsbackup',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    final service = PlatformBackupTransferService(
      pickerClient: picker,
      shareClient: _FakeShareClient(),
      fileStore: _FakeFileStore(root),
      temporaryDirectoryProvider: () async => root,
      maxBackupBytes: 100,
    );

    final progress = <BackupTransferProgress>[];
    final selection = await service.pickImport(onProgress: progress.add);
    expect(selection, isNotNull);
    expect(selection!.fileName, 'sample.ieltsbackup');
    expect(selection.bytes, [1, 2, 3]);
    expect(progress.first.fraction, 0);
    expect(progress.last.fraction, 1);
    expect(await selection.stagedFile.exists(), isTrue);
    await selection.cleanup();
    expect(await selection.stagedFile.exists(), isFalse);
  });

  test('外部路径按流复制并拒绝扩展名和大小越界', () async {
    final sourceFile = File('${root.path}/source.ieltsbackup');
    await sourceFile.writeAsBytes([4, 5, 6, 7]);
    final service = PlatformBackupTransferService(
      pickerClient: _FakePicker(
        PickedBackupSource(
          name: 'source.ieltsbackup',
          size: 4,
          path: sourceFile.path,
        ),
      ),
      shareClient: _FakeShareClient(),
      fileStore: _FakeFileStore(root),
      temporaryDirectoryProvider: () async => root,
      maxBackupBytes: 100,
    );
    final selection = await service.pickImport();
    expect(await selection!.stagedFile.readAsBytes(), [4, 5, 6, 7]);
    await selection.cleanup();

    final invalid = PlatformBackupTransferService(
      pickerClient: _FakePicker(
        PickedBackupSource(
          name: 'malware.zip',
          size: 1,
          bytes: Uint8List.fromList([1]),
        ),
      ),
      shareClient: _FakeShareClient(),
      fileStore: _FakeFileStore(root),
      temporaryDirectoryProvider: () async => root,
      maxBackupBytes: 100,
    );
    expect(() => invalid.pickImport(), throwsA(isA<BackupTransferException>()));

    final oversized = PlatformBackupTransferService(
      pickerClient: _FakePicker(
        PickedBackupSource(
          name: 'large.ieltsbackup',
          size: 101,
          bytes: Uint8List.fromList([1]),
        ),
      ),
      shareClient: _FakeShareClient(),
      fileStore: _FakeFileStore(root),
      temporaryDirectoryProvider: () async => root,
      maxBackupBytes: 100,
    );
    expect(
      () => oversized.pickImport(),
      throwsA(isA<BackupTransferException>()),
    );
  });

  test('取消选择返回 null，分享结果透传平台状态', () async {
    final shareClient = _FakeShareClient(status: BackupShareStatus.success);
    final fileStore = _FakeFileStore(root);
    final service = PlatformBackupTransferService(
      pickerClient: _FakePicker(null),
      shareClient: shareClient,
      fileStore: fileStore,
      temporaryDirectoryProvider: () async => root,
    );
    expect(await service.pickImport(), isNull);
    final backup = _createExport();
    expect(await service.shareExport(backup), BackupShareStatus.success);
    expect(shareClient.sharedFile, isNotNull);
  });
}

BackupExport _createExport() {
  final bytes = BackupPackageCodec().encode(
    appVersion: 'test',
    userSchemaVersion: 1,
    contentVersion: 'test',
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
    fileName: 'sample.ieltsbackup',
    manifest: BackupPackageCodec().decode(bytes).manifest,
  );
}

final class _FakePicker implements BackupPickerClient {
  const _FakePicker(this.value);

  final PickedBackupSource? value;

  @override
  Future<PickedBackupSource?> pickBackup() async => value;
}

final class _FakeShareClient implements BackupShareClient {
  _FakeShareClient({this.status = BackupShareStatus.dismissed});

  final BackupShareStatus status;
  File? sharedFile;

  @override
  Future<BackupShareStatus> shareBackup(File file) async {
    sharedFile = file;
    return status;
  }
}

final class _FakeFileStore implements BackupFileStore {
  _FakeFileStore(this.root);

  final Directory root;

  @override
  Future<File> saveExport(BackupExport backup) async {
    final file = File('${root.path}/${backup.fileName}');
    await file.writeAsBytes(backup.bytes);
    return file;
  }

  @override
  Future<File> saveProtection(BackupExport backup) => saveExport(backup);
}
