import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../models/backup/backup_operation.dart';
import 'backup_file_store.dart';
import 'backup_package_codec.dart';

/// 系统文件选择器返回的最小信息；页面不接触外部绝对路径。
final class PickedBackupSource {
  PickedBackupSource({
    required this.name,
    required this.size,
    Uint8List? bytes,
    this.path,
  }) : bytes = bytes == null ? null : Uint8List.fromList(bytes) {
    if (name.isEmpty || size < 0 || bytes == null && path == null) {
      throw ArgumentError('选择的备份来源字段无效');
    }
  }

  final String name;
  final int size;
  final Uint8List? bytes;
  final String? path;
}

/// 已复制到应用临时目录、可以交给备份预检的输入。
final class BackupImportSelection {
  BackupImportSelection({
    required this.fileName,
    required Uint8List bytes,
    required this.stagedFile,
  }) : bytes = Uint8List.fromList(bytes);

  final String fileName;
  final Uint8List bytes;
  final File stagedFile;

  /// 预览或导入结束后清理私有暂存文件；重复调用保持幂等。
  Future<void> cleanup() async {
    try {
      if (await stagedFile.exists()) {
        await stagedFile.delete();
      }
    } on FileSystemException {
      // 临时目录由系统后续回收，清理失败不覆盖业务结果。
    }
  }
}

enum BackupShareStatus { success, dismissed, unavailable }

/// 备份文件选择或分享平台调用失败。
final class BackupTransferException implements Exception {
  const BackupTransferException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'backup_transfer_error: $code';
}

abstract interface class BackupPickerClient {
  Future<PickedBackupSource?> pickBackup();
}

abstract interface class BackupShareClient {
  Future<BackupShareStatus> shareBackup(File file);
}

/// 系统文件选择和分享的业务边界。
abstract interface class BackupTransferService {
  Future<BackupImportSelection?> pickImport({
    BackupTransferProgressCallback? onProgress,
  });

  Future<BackupShareStatus> shareExport(BackupExport backup);
}

/// 先把外部文件流式复制到私有临时目录，再提供受大小限制的字节。
final class PlatformBackupTransferService implements BackupTransferService {
  PlatformBackupTransferService({
    required this.pickerClient,
    required this.shareClient,
    required this.fileStore,
    required this.temporaryDirectoryProvider,
    this.maxBackupBytes = BackupPackageCodec.defaultMaxBackupBytes,
  }) {
    if (maxBackupBytes <= 0) {
      throw ArgumentError.value(maxBackupBytes, 'maxBackupBytes', '大小上限必须为正数');
    }
  }

  static const String importDirectoryName = 'backup-imports';

  final BackupPickerClient pickerClient;
  final BackupShareClient shareClient;
  final BackupFileStore fileStore;
  final BackupDirectoryProvider temporaryDirectoryProvider;
  final int maxBackupBytes;

  @override
  Future<BackupImportSelection?> pickImport({
    BackupTransferProgressCallback? onProgress,
  }) async {
    final source = await pickerClient.pickBackup();
    if (source == null) {
      return null;
    }
    _validateSource(source);
    final temporaryRoot = await temporaryDirectoryProvider();
    final importDirectory = Directory(
      p.join(temporaryRoot.absolute.path, importDirectoryName),
    );
    await importDirectory.create(recursive: true);
    final stagedFile = File(
      p.join(
        importDirectory.path,
        '.incoming-${DateTime.now().microsecondsSinceEpoch}.ieltsbackup',
      ),
    );
    IOSink? sink;
    try {
      sink = stagedFile.openWrite(mode: FileMode.writeOnly);
      var copiedBytes = 0;
      _notifyProgress(
        onProgress,
        BackupTransferProgress(
          copiedBytes: copiedBytes,
          totalBytes: source.size,
        ),
      );
      final stream = source.bytes == null
          ? File(source.path!).openRead()
          : Stream<List<int>>.value(source.bytes!);
      await for (final chunk in stream) {
        copiedBytes += chunk.length;
        if (copiedBytes > maxBackupBytes) {
          throw const BackupTransferException(
            'backup_too_large',
            '选择的备份超过大小上限',
          );
        }
        sink.add(chunk);
        _notifyProgress(
          onProgress,
          BackupTransferProgress(
            copiedBytes: copiedBytes,
            totalBytes: source.size,
          ),
        );
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (copiedBytes != source.size || copiedBytes == 0) {
        throw const BackupTransferException(
          'source_size_changed',
          '选择的文件大小在复制期间发生变化',
        );
      }
      final bytes = await stagedFile.readAsBytes();
      return BackupImportSelection(
        fileName: source.name,
        bytes: bytes,
        stagedFile: stagedFile,
      );
    } on BackupTransferException {
      await sink?.close();
      await _deleteStaged(stagedFile);
      rethrow;
    } on FileSystemException {
      await sink?.close();
      await _deleteStaged(stagedFile);
      throw const BackupTransferException('copy_failed', '无法把外部备份复制到应用临时目录');
    }
  }

  @override
  Future<BackupShareStatus> shareExport(BackupExport backup) async {
    final file = await fileStore.saveExport(backup);
    try {
      return await shareClient.shareBackup(file);
    } on Object {
      throw const BackupTransferException('share_failed', '系统分享面板调用失败');
    }
  }

  void _validateSource(PickedBackupSource source) {
    final normalizedName = source.name.trim();
    if (normalizedName != source.name ||
        p.basename(normalizedName) != normalizedName ||
        normalizedName.contains('..') ||
        !normalizedName.toLowerCase().endsWith('.ieltsbackup')) {
      throw const BackupTransferException(
        'invalid_extension',
        '只能选择 .ieltsbackup 文件',
      );
    }
    if (source.size <= 0 || source.size > maxBackupBytes) {
      throw const BackupTransferException('backup_too_large', '选择的备份为空或超过大小上限');
    }
    if (source.bytes != null && source.bytes!.length != source.size) {
      throw const BackupTransferException(
        'source_size_mismatch',
        '文件选择器返回的大小与字节不一致',
      );
    }
  }

  Future<void> _deleteStaged(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // 暂存文件由系统临时目录回收。
    }
  }

  void _notifyProgress(
    BackupTransferProgressCallback? onProgress,
    BackupTransferProgress progress,
  ) {
    try {
      onProgress?.call(progress);
    } on Object {
      // 进度观察器不是文件复制结果的一部分，观察器异常不应破坏暂存操作。
    }
  }
}
