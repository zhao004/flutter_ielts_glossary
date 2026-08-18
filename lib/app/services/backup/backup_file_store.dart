import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/backup/backup_operation.dart';

typedef BackupDirectoryProvider = Future<Directory> Function();

/// 备份文件路径或原子写入失败。
final class BackupFileException implements Exception {
  const BackupFileException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'backup_file_error: $code';
}

/// 只允许把备份写入应用私有支持目录中的固定子目录。
abstract interface class BackupFileStore {
  Future<File> saveExport(BackupExport backup);

  Future<File> saveProtection(BackupExport backup);
}

/// 使用临时文件和同目录重命名保存备份，避免留下半个 ZIP 文件。
final class LocalBackupFileStore implements BackupFileStore {
  LocalBackupFileStore({BackupDirectoryProvider? directoryProvider})
    : directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const String backupDirectoryName = 'backups';
  static final RegExp _fileNamePattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,254}\.ieltsbackup$',
  );

  final BackupDirectoryProvider directoryProvider;

  @override
  Future<File> saveExport(BackupExport backup) {
    return _save(backup, prefix: '');
  }

  @override
  Future<File> saveProtection(BackupExport backup) {
    return _save(backup, prefix: 'protection_');
  }

  Future<File> _save(BackupExport backup, {required String prefix}) async {
    final fileName = _safeFileName('$prefix${backup.fileName}');
    final supportDirectory = await directoryProvider();
    final backupDirectory = Directory(
      p.join(supportDirectory.absolute.path, backupDirectoryName),
    );
    await backupDirectory.create(recursive: true);
    final target = File(p.join(backupDirectory.path, fileName));
    final temporary = File(
      p.join(
        backupDirectory.path,
        '.$fileName.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await temporary.writeAsBytes(backup.bytes, flush: true);
      await temporary.rename(target.path);
      return target;
    } on FileSystemException catch (error) {
      try {
        if (await temporary.exists()) {
          await temporary.delete();
        }
      } on FileSystemException {
        // 保留原始写入错误，临时文件由后续清理任务处理。
      }
      throw BackupFileException(
        'write_failed',
        '备份文件写入失败：${error.osError?.errorCode ?? 'unknown'}',
      );
    }
  }

  String _safeFileName(String value) {
    if (!_fileNamePattern.hasMatch(value) ||
        p.basename(value) != value ||
        value.contains('..')) {
      throw const BackupFileException('unsafe_file_name', '备份文件名包含不安全路径片段');
    }
    return value;
  }
}
