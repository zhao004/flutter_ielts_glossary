import '../backup/backup_history_record.dart';
import '../backup/backup_manifest.dart';

/// 用户主动导出及系统分享的阶段。
enum BackupExportPhase { idle, exporting, sharing, completed, dismissed, error }

/// 导出页面稳定错误码，不暴露文件路径或平台异常正文。
abstract final class BackupExportErrorCodes {
  static const String exportFailed = 'backup_export_failed';
  static const String shareFailed = 'backup_share_failed';
  static const String shareUnavailable = 'backup_share_unavailable';
}

/// 导出和分享状态；只保存可展示清单，不持有备份正文。
final class BackupExportRunState {
  const BackupExportRunState({
    required this.phase,
    required this.fileName,
    required this.manifest,
    required this.errorCode,
  });

  factory BackupExportRunState.idle() {
    return const BackupExportRunState(
      phase: BackupExportPhase.idle,
      fileName: null,
      manifest: null,
      errorCode: null,
    );
  }

  final BackupExportPhase phase;
  final String? fileName;
  final BackupManifest? manifest;
  final String? errorCode;

  BackupExportRunState copyWith({
    BackupExportPhase? phase,
    Object? fileName = _unset,
    Object? manifest = _unset,
    Object? errorCode = _unset,
  }) {
    return BackupExportRunState(
      phase: phase ?? this.phase,
      fileName: identical(fileName, _unset)
          ? this.fileName
          : fileName as String?,
      manifest: identical(manifest, _unset)
          ? this.manifest
          : manifest as BackupManifest?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

/// 最近备份历史查询阶段。
enum BackupHistoryPhase { idle, loading, loaded, empty, error }

/// 历史列表使用独立错误码，加载失败不覆盖导出或导入结果。
abstract final class BackupHistoryErrorCodes {
  static const String loadFailed = 'backup_history_load_failed';
  static const String deleteFailed = 'backup_history_delete_failed';
}

/// 最近备份操作历史；刷新期间保留上一份列表。
final class BackupHistoryRunState {
  BackupHistoryRunState({
    required this.phase,
    required List<BackupHistoryRecord> records,
    required this.errorCode,
    required this.deletingRecordId,
    required this.errorRecordId,
  }) : records = List<BackupHistoryRecord>.unmodifiable(records);

  factory BackupHistoryRunState.idle() {
    return BackupHistoryRunState(
      phase: BackupHistoryPhase.idle,
      records: const [],
      errorCode: null,
      deletingRecordId: null,
      errorRecordId: null,
    );
  }

  final BackupHistoryPhase phase;
  final List<BackupHistoryRecord> records;
  final String? errorCode;
  final String? deletingRecordId;
  final String? errorRecordId;

  BackupHistoryRunState copyWith({
    BackupHistoryPhase? phase,
    List<BackupHistoryRecord>? records,
    Object? errorCode = _unset,
    Object? deletingRecordId = _unset,
    Object? errorRecordId = _unset,
  }) {
    return BackupHistoryRunState(
      phase: phase ?? this.phase,
      records: records ?? this.records,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      deletingRecordId: identical(deletingRecordId, _unset)
          ? this.deletingRecordId
          : deletingRecordId as String?,
      errorRecordId: identical(errorRecordId, _unset)
          ? this.errorRecordId
          : errorRecordId as String?,
    );
  }
}

const _unset = Object();
