import '../backup/backup_operation.dart';

/// 备份导入页面可观察的阶段。
enum BackupRunPhase {
  idle,
  picking,
  previewing,
  awaitingConfirmation,
  importing,
  completed,
  error,
}

/// 备份流程稳定错误码，页面不依赖平台异常正文。
abstract final class BackupRunErrorCodes {
  static const String pickFailed = 'pick_failed';
  static const String previewFailed = 'preview_failed';
  static const String importFailed = 'import_failed';
  static const String futureVersion = 'future_version';
}

/// 备份导入流程的不可变页面状态；不在状态中复制完整备份字节。
final class BackupRunState {
  const BackupRunState({
    required this.phase,
    required this.selectedFileName,
    required this.preview,
    required this.report,
    required this.errorCode,
    required this.progress,
  });

  factory BackupRunState.idle() {
    return const BackupRunState(
      phase: BackupRunPhase.idle,
      selectedFileName: null,
      preview: null,
      report: null,
      errorCode: null,
      progress: null,
    );
  }

  final BackupRunPhase phase;
  final String? selectedFileName;
  final BackupImportPreview? preview;
  final BackupImportReport? report;
  final String? errorCode;
  final BackupProgress? progress;

  BackupRunState copyWith({
    BackupRunPhase? phase,
    Object? selectedFileName = _unset,
    Object? preview = _unset,
    Object? report = _unset,
    Object? errorCode = _unset,
    Object? progress = _unset,
  }) {
    return BackupRunState(
      phase: phase ?? this.phase,
      selectedFileName: identical(selectedFileName, _unset)
          ? this.selectedFileName
          : selectedFileName as String?,
      preview: identical(preview, _unset)
          ? this.preview
          : preview as BackupImportPreview?,
      report: identical(report, _unset)
          ? this.report
          : report as BackupImportReport?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      progress: identical(progress, _unset)
          ? this.progress
          : progress as BackupProgress?,
    );
  }
}

const _unset = Object();
