import 'dart:io';

import '../../models/content/content_manifest.dart';

enum ContentInstallStatus {
  installed,
  updated,
  repaired,
  alreadyCurrent,
  keptNewerExisting,
}

/// 内容安装器当前执行的阶段。
enum ContentInstallPhase {
  readingManifest,
  checkingExisting,
  copyingDatabase,
  verifying,
  publishing,
}

/// 内容安装过程的可展示进度；字节复制阶段提供确定性百分比。
final class ContentInstallProgress {
  const ContentInstallProgress({
    required this.phase,
    this.completedBytes = 0,
    this.totalBytes,
  });

  final ContentInstallPhase phase;
  final int completedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return (completedBytes / total).clamp(0, 1).toDouble();
  }
}

/// 接收安装阶段更新；回调不应修改安装结果。
typedef ContentInstallProgressCallback =
    void Function(ContentInstallProgress progress);

/// 应用启动编排依赖的内容安装接口。
abstract interface class ContentInstallationService {
  Future<ContentInstallResult> install({
    ContentInstallProgressCallback? onProgress,
  });
}

/// 完全本地内容安装结果。
final class ContentInstallResult {
  const ContentInstallResult({
    required this.status,
    required this.manifest,
    required this.databaseFile,
    required this.manifestFile,
    required this.retainedBackupFiles,
  });

  final ContentInstallStatus status;
  final ContentManifest manifest;
  final File databaseFile;
  final File manifestFile;
  final List<File> retainedBackupFiles;
}

/// 内容安装的文件系统、版本决策或资产读取失败。
final class ContentInstallException implements Exception {
  const ContentInstallException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
