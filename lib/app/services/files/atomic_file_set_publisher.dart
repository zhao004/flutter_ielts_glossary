import 'dart:io';

import 'package:path/path.dart' as p;

/// 原子文件集发布失败；`code` 可用于区分已存在、发布失败和回滚失败。
final class AtomicFilePublishException implements Exception {
  const AtomicFilePublishException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// 文件集发布结果；无法删除的旧备份会保留为可恢复文件。
final class AtomicFilePublishResult {
  const AtomicFilePublishResult({required this.retainedBackups});

  final List<File> retainedBackups;
}

/// 在同一文件系统内发布多个已验证文件，任一重命名失败时恢复全部旧文件。
final class AtomicFileSetPublisher {
  const AtomicFileSetPublisher();

  Future<AtomicFilePublishResult> publish({
    required Map<File, File> stagedToTarget,
    required bool replaceExisting,
  }) async {
    if (stagedToTarget.isEmpty) {
      throw const AtomicFilePublishException(
        code: 'empty_publish_set',
        message: '原子发布文件集不能为空',
      );
    }
    final targetPaths = <String>{};
    final targetParent = p.normalize(
      p.dirname(stagedToTarget.values.first.absolute.path),
    );
    for (final entry in stagedToTarget.entries) {
      final staged = entry.key.absolute;
      final target = entry.value.absolute;
      if (!await staged.exists()) {
        throw const AtomicFilePublishException(
          code: 'missing_staged_file',
          message: '待发布文件不存在',
        );
      }
      if (!p.equals(p.dirname(target.path), targetParent) ||
          !p.isWithin(targetParent, staged.path) ||
          !targetPaths.add(p.normalize(target.path))) {
        throw const AtomicFilePublishException(
          code: 'unsafe_publish_paths',
          message: '待发布文件必须位于同一目标目录的暂存子目录中',
        );
      }
    }

    final existingTargets = <File>[];
    for (final target in stagedToTarget.values) {
      if (await target.exists()) {
        existingTargets.add(target);
      }
    }
    if (existingTargets.isNotEmpty && !replaceExisting) {
      throw const AtomicFilePublishException(
        code: 'output_exists',
        message: '目标文件已存在，必须显式允许替换',
      );
    }

    final suffix = '.previous-$pid-${DateTime.now().microsecondsSinceEpoch}';
    final backups = <File, File>{};
    final publishedTargets = <File>[];
    try {
      for (final target in existingTargets) {
        final backup = File('${target.path}$suffix');
        await target.rename(backup.path);
        backups[target] = backup;
      }
      for (final entry in stagedToTarget.entries) {
        await entry.key.rename(entry.value.path);
        publishedTargets.add(entry.value);
      }
    } on FileSystemException catch (error) {
      final rollbackErrors = <FileSystemException>[];
      for (final target in publishedTargets.reversed) {
        try {
          if (await target.exists()) {
            await target.delete();
          }
        } on FileSystemException catch (rollbackError) {
          rollbackErrors.add(rollbackError);
        }
      }
      for (final entry in backups.entries) {
        try {
          if (await entry.value.exists()) {
            await entry.value.rename(entry.key.path);
          }
        } on FileSystemException catch (rollbackError) {
          rollbackErrors.add(rollbackError);
        }
      }
      if (rollbackErrors.isNotEmpty) {
        throw const AtomicFilePublishException(
          code: 'atomic_rollback_failed',
          message: '文件集发布和旧版本恢复均失败，需要人工检查目标目录',
        );
      }
      throw AtomicFilePublishException(
        code: 'atomic_publish_failed',
        message: '文件集发布失败，旧版本已恢复：${error.osError?.errorCode ?? 'unknown'}',
      );
    }

    final retainedBackups = <File>[];
    for (final backup in backups.values) {
      try {
        await backup.delete();
      } on FileSystemException {
        retainedBackups.add(backup);
      }
    }
    return AtomicFilePublishResult(
      retainedBackups: List.unmodifiable(retainedBackups),
    );
  }
}
