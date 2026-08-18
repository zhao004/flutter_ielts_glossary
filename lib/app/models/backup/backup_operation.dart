import 'dart:typed_data';

import 'backup_manifest.dart';
import 'backup_record_counts.dart';

/// 备份预检或导入当前执行的阶段。
enum BackupProgressStage {
  picking,
  decoding,
  analyzing,
  protecting,
  writing,
  completed,
}

/// 备份操作的阶段进度；写入阶段按待处理记录数提供百分比。
final class BackupProgress {
  const BackupProgress({required this.stage, this.fraction})
    : assert(fraction == null || (fraction >= 0 && fraction <= 1));

  final BackupProgressStage stage;
  final double? fraction;
}

typedef BackupProgressCallback = void Function(BackupProgress progress);

/// 外部备份复制到应用私有暂存目录的字节进度。
final class BackupTransferProgress {
  const BackupTransferProgress({
    required this.copiedBytes,
    required this.totalBytes,
  });

  final int copiedBytes;
  final int totalBytes;

  double get fraction {
    if (totalBytes <= 0) {
      return 0;
    }
    return (copiedBytes / totalBytes).clamp(0, 1).toDouble();
  }
}

typedef BackupTransferProgressCallback =
    void Function(BackupTransferProgress progress);

/// 导入时的冲突处理策略。
enum BackupImportMode { merge, overwrite }

/// 导出完成后交给文件/分享层的内存结果。
final class BackupExport {
  BackupExport({
    required Uint8List bytes,
    required this.fileName,
    required this.manifest,
  }) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final String fileName;
  final BackupManifest manifest;
}

/// 只读导入预检结果；预检不会修改用户库。
final class BackupImportPreview {
  BackupImportPreview({
    required this.manifest,
    required this.recordCounts,
    required this.existingRecordCount,
    required this.conflictCount,
    required Set<int> missingWordIds,
    required Set<int> missingSentenceIds,
    required this.rejectedRecordCount,
    required this.canImport,
    required this.isFutureFormat,
  }) : missingWordIds = Set.unmodifiable(missingWordIds),
       missingSentenceIds = Set.unmodifiable(missingSentenceIds) {
    if (existingRecordCount < 0 ||
        existingRecordCount > BackupRecordCounts.maximumRecordCount) {
      throw ArgumentError.value(
        existingRecordCount,
        'existingRecordCount',
        '当前用户记录数超出允许范围',
      );
    }
  }

  final BackupManifest manifest;
  final BackupRecordCounts recordCounts;

  /// 当前用户库中可被覆盖模式清空的业务记录数，不包含备份历史。
  final int existingRecordCount;
  final int conflictCount;
  final Set<int> missingWordIds;
  final Set<int> missingSentenceIds;
  final int rejectedRecordCount;
  final bool canImport;
  final bool isFutureFormat;
}

/// 导入事务的业务结果；protectionBackup 是写入前自动生成的恢复包。
final class BackupImportReport {
  BackupImportReport({
    required this.mode,
    required this.importedCounts,
    required this.skippedCounts,
    required this.conflictCount,
    required Set<int> missingWordIds,
    required Set<int> missingSentenceIds,
    required Uint8List protectionBackupBytes,
  }) : missingWordIds = Set.unmodifiable(missingWordIds),
       missingSentenceIds = Set.unmodifiable(missingSentenceIds),
       protectionBackup = Uint8List.fromList(protectionBackupBytes);

  final BackupImportMode mode;
  final BackupRecordCounts importedCounts;
  final BackupRecordCounts skippedCounts;
  final int conflictCount;
  final Set<int> missingWordIds;
  final Set<int> missingSentenceIds;
  final Uint8List protectionBackup;
}

/// 清除用户数据后的审计结果；词库内容不属于此结果并不会被删除。
final class UserDataResetResult {
  const UserDataResetResult({
    required this.fileName,
    required this.clearedCounts,
    required this.resetAtUtc,
  });

  final String fileName;
  final BackupRecordCounts clearedCounts;
  final DateTime resetAtUtc;
}
