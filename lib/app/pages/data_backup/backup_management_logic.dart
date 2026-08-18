import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/backup_management_state.dart';
import '../../repositories/backup_repository.dart';
import '../../services/backup/backup_transfer_service.dart';

/// 协调用户导出、系统分享和最近备份历史，不接触文件系统或平台插件细节。
final class BackupManagementLogic extends GetxController {
  BackupManagementLogic({
    required this.backupRepository,
    required this.transferService,
    this.historyLimit = 20,
    this.autoLoadHistory = true,
  }) {
    if (historyLimit <= 0 || historyLimit > 100) {
      throw ArgumentError.value(
        historyLimit,
        'historyLimit',
        '历史条数必须在 1-100 之间',
      );
    }
  }

  static const String exportUpdateId = 'backup_export_state';
  static const String historyUpdateId = 'backup_history_state';

  final BackupRepository backupRepository;
  final BackupTransferService transferService;
  final int historyLimit;
  final bool autoLoadHistory;

  BackupExportRunState _exportState = BackupExportRunState.idle();
  BackupHistoryRunState _historyState = BackupHistoryRunState.idle();

  BackupExportRunState get exportState => _exportState;
  BackupHistoryRunState get historyState => _historyState;

  bool _closed = false;
  bool _exportBusy = false;
  int _exportToken = 0;
  int _historyToken = 0;
  Future<void>? _historyTask;

  @override
  void onInit() {
    super.onInit();
    if (autoLoadHistory) {
      unawaited(loadHistory());
    }
  }

  /// 查询最近备份历史；并发调用共享同一个进行中的查询。
  Future<void> loadHistory() {
    if (_closed) {
      return Future<void>.value();
    }
    final active = _historyTask;
    if (active != null) {
      return active;
    }
    final task = _performHistoryLoad();
    _historyTask = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_historyTask, task)) {
          _historyTask = null;
        }
      }),
    );
    return task;
  }

  /// 创建版本化备份并打开系统分享；用户关闭分享面板属于正常结果。
  Future<void> exportAndShare() async {
    if (_closed) {
      throw StateError('备份管理 Logic 已关闭');
    }
    if (_exportBusy) {
      return;
    }
    _exportBusy = true;
    final operationToken = ++_exportToken;
    _replaceExport(
      _exportState.copyWith(
        phase: BackupExportPhase.exporting,
        fileName: null,
        manifest: null,
        errorCode: null,
      ),
    );
    try {
      final backup = await backupRepository.exportBackup();
      if (!_isCurrentExport(operationToken)) {
        return;
      }
      _replaceExport(
        _exportState.copyWith(
          phase: BackupExportPhase.sharing,
          fileName: backup.fileName,
          manifest: backup.manifest,
          errorCode: null,
        ),
      );
      final shareStatus = await transferService.shareExport(backup);
      if (!_isCurrentExport(operationToken)) {
        return;
      }
      final (phase, errorCode) = switch (shareStatus) {
        BackupShareStatus.success => (BackupExportPhase.completed, null),
        BackupShareStatus.dismissed => (BackupExportPhase.dismissed, null),
        BackupShareStatus.unavailable => (
          BackupExportPhase.error,
          BackupExportErrorCodes.shareUnavailable,
        ),
      };
      _replaceExport(_exportState.copyWith(phase: phase, errorCode: errorCode));
      await _refreshHistoryAfterCurrent();
    } on Exception {
      if (_isCurrentExport(operationToken)) {
        final errorCode = _exportState.phase == BackupExportPhase.sharing
            ? BackupExportErrorCodes.shareFailed
            : BackupExportErrorCodes.exportFailed;
        _replaceExport(
          _exportState.copyWith(
            phase: BackupExportPhase.error,
            errorCode: errorCode,
          ),
        );
      }
    } finally {
      _exportBusy = false;
    }
  }

  /// 清除上一次导出结果；进行中的导出不能被静默重置。
  void resetExport() {
    if (_closed) {
      throw StateError('备份管理 Logic 已关闭');
    }
    if (_exportBusy) {
      return;
    }
    _replaceExport(BackupExportRunState.idle());
  }

  Future<void> _performHistoryLoad() async {
    final operationToken = ++_historyToken;
    _replaceHistory(
      _historyState.copyWith(
        phase: BackupHistoryPhase.loading,
        errorCode: null,
      ),
    );
    try {
      final records = await backupRepository.findHistory(limit: historyLimit);
      if (!_isCurrentHistory(operationToken)) {
        return;
      }
      _replaceHistory(
        _historyState.copyWith(
          phase: records.isEmpty
              ? BackupHistoryPhase.empty
              : BackupHistoryPhase.loaded,
          records: records,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_isCurrentHistory(operationToken)) {
        _replaceHistory(
          _historyState.copyWith(
            phase: BackupHistoryPhase.error,
            errorCode: BackupHistoryErrorCodes.loadFailed,
          ),
        );
      }
    }
  }

  Future<void> _refreshHistoryAfterCurrent() async {
    final active = _historyTask;
    if (active != null) {
      await active;
    }
    if (!_closed) {
      await loadHistory();
    }
  }

  void _replaceExport(BackupExportRunState next) {
    if (_closed) {
      return;
    }
    _exportState = next;
    update([exportUpdateId]);
  }

  void _replaceHistory(BackupHistoryRunState next) {
    if (_closed) {
      return;
    }
    _historyState = next;
    update([historyUpdateId]);
  }

  bool _isCurrentExport(int operationToken) {
    return !_closed && operationToken == _exportToken;
  }

  bool _isCurrentHistory(int operationToken) {
    return !_closed && operationToken == _historyToken;
  }

  @override
  void onClose() {
    _closed = true;
    _exportToken++;
    _historyToken++;
    super.onClose();
  }
}
