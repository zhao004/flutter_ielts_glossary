import 'dart:io';

import 'package:path/path.dart' as p;

import '../../database/user/user_database.dart';

/// 用户库恢复动作的结果；文件仍留在应用私有目录，不返回原始数据内容。
final class UserDatabaseRecoveryResult {
  UserDatabaseRecoveryResult({required Iterable<File> backupFiles})
    : backupFiles = List.unmodifiable(backupFiles);

  final List<File> backupFiles;
}

/// 用户库恢复文件操作失败；调用方应保留原始错误态并允许重试。
final class UserDatabaseRecoveryException implements Exception {
  const UserDatabaseRecoveryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'user_database_recovery_error: $code';
}

/// 备份损坏用户库的文件边界，调用成功后由启动流程创建新的空用户库。
abstract interface class UserDatabaseRecovery {
  Future<UserDatabaseRecoveryResult> backupAndReset();
}

/// 将 Drift Native 用户库及其 WAL/临时日志文件移动到私有恢复目录。
final class LocalUserDatabaseRecovery implements UserDatabaseRecovery {
  LocalUserDatabaseRecovery({
    required Directory applicationSupportDirectory,
    DateTime Function()? clock,
  }) : applicationSupportDirectory = Directory(
         p.normalize(applicationSupportDirectory.absolute.path),
       ),
       _clock = clock ?? DateTime.now {
    if (_isFileSystemRoot(this.applicationSupportDirectory.path)) {
      throw ArgumentError('应用支持目录不能是文件系统根目录');
    }
  }

  static const String recoveryDirectoryName = 'database-recovery';

  /// `drift_flutter` 的 native SQLite 文件及可能存在的旁车文件。
  static List<String> get databaseArtifacts => [
    '${UserDatabase.databaseName}.sqlite',
    '${UserDatabase.databaseName}.sqlite-wal',
    '${UserDatabase.databaseName}.sqlite-shm',
    '${UserDatabase.databaseName}.sqlite-journal',
  ];

  final Directory applicationSupportDirectory;
  final DateTime Function() _clock;

  @override
  Future<UserDatabaseRecoveryResult> backupAndReset() async {
    final recoveryDirectory = Directory(
      p.join(applicationSupportDirectory.path, recoveryDirectoryName),
    );
    final suffix = _suffix(_clock().toUtc());
    final backupFiles = <File>[];
    final movedFiles = <({String sourcePath, String targetPath})>[];
    try {
      await recoveryDirectory.create(recursive: true);
      for (final artifact in databaseArtifacts) {
        final source = File(p.join(applicationSupportDirectory.path, artifact));
        if (!await source.exists()) {
          continue;
        }
        final target = await _nextTarget(
          recoveryDirectory: recoveryDirectory,
          artifact: artifact,
          suffix: suffix,
        );
        await source.rename(target.path);
        movedFiles.add((sourcePath: source.path, targetPath: target.path));
        backupFiles.add(target);
      }
    } on Object catch (error) {
      await _rollbackMoves(movedFiles);
      final errorCode = error is FileSystemException
          ? error.osError?.errorCode ?? 'unknown'
          : 'unknown';
      throw UserDatabaseRecoveryException(
        'backup_failed',
        '用户库备份失败：$errorCode',
      );
    }
    return UserDatabaseRecoveryResult(backupFiles: backupFiles);
  }

  Future<void> _rollbackMoves(
    List<({String sourcePath, String targetPath})> movedFiles,
  ) async {
    for (final move in movedFiles.reversed) {
      try {
        await File(move.targetPath).rename(move.sourcePath);
      } on Object {
        // 回滚失败时保留原始错误码；恢复目录中的文件仍可供人工取证。
      }
    }
  }

  Future<File> _nextTarget({
    required Directory recoveryDirectory,
    required String artifact,
    required String suffix,
  }) async {
    var attempt = 0;
    while (true) {
      final attemptSuffix = attempt == 0 ? suffix : '$suffix-$attempt';
      final target = File(
        p.join(recoveryDirectory.path, '$artifact.$attemptSuffix.bak'),
      );
      if (!await target.exists()) {
        return target;
      }
      attempt++;
    }
  }

  String _suffix(DateTime value) {
    final utc = value.toUtc();
    final subsecond =
        (utc.millisecond * Duration.microsecondsPerMillisecond +
                utc.microsecond)
            .toString()
            .padLeft(6, '0');
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}_'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}_'
        '$subsecond';
  }
}

bool _isFileSystemRoot(String path) {
  final normalized = p.normalize(path);
  return p.dirname(normalized) == normalized;
}
