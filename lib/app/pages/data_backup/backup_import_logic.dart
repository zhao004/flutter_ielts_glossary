import 'package:get/get.dart';

import '../../models/backup/backup_operation.dart';
import '../../models/domain/backup_run_state.dart';
import '../../repositories/backup_repository.dart';
import '../../services/backup/backup_transfer_service.dart';

/// 编排文件选择、只读预检、用户确认和事务导入，不持有平台插件细节。
final class BackupImportLogic extends GetxController {
  BackupImportLogic({
    required this.backupRepository,
    required this.transferService,
  });

  static const String stateUpdateId = 'backup_import_state';

  final BackupRepository backupRepository;
  final BackupTransferService transferService;

  BackupRunState _state = BackupRunState.idle();
  BackupRunState get state => _state;

  BackupImportSelection? _selection;
  bool _closed = false;
  bool _busy = false;
  int _operationToken = 0;

  /// 打开文件选择器并生成只读导入预览。
  Future<void> pickAndPreview() async {
    _requireAvailable(const {
      BackupRunPhase.idle,
      BackupRunPhase.completed,
      BackupRunPhase.error,
    }, 'pickAndPreview');
    if (_busy) {
      return;
    }
    _busy = true;
    final operationToken = ++_operationToken;
    await _clearSelection();
    if (!_isCurrent(operationToken)) {
      _busy = false;
      return;
    }
    _replace(
      _state.copyWith(
        phase: BackupRunPhase.picking,
        preview: null,
        report: null,
        errorCode: null,
        progress: null,
      ),
    );
    try {
      final selection = await transferService.pickImport(
        onProgress: (progress) {
          _applyProgress(
            operationToken,
            BackupProgress(
              stage: BackupProgressStage.picking,
              fraction: progress.fraction,
            ),
          );
        },
      );
      if (!_isCurrent(operationToken)) {
        await selection?.cleanup();
        return;
      }
      if (selection == null) {
        _replace(BackupRunState.idle());
        return;
      }
      _selection = selection;
      _replace(
        _state.copyWith(
          phase: BackupRunPhase.previewing,
          selectedFileName: selection.fileName,
          progress: null,
        ),
      );
      final preview = await backupRepository.previewImport(
        selection.bytes,
        onProgress: (progress) => _applyProgress(operationToken, progress),
      );
      if (!_isCurrent(operationToken)) {
        await selection.cleanup();
        return;
      }
      _replace(
        _state.copyWith(
          phase: BackupRunPhase.awaitingConfirmation,
          preview: preview,
          progress: null,
          errorCode: preview.isFutureFormat
              ? BackupRunErrorCodes.futureVersion
              : null,
        ),
      );
    } on Exception {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: BackupRunPhase.error,
            progress: null,
            errorCode: _state.phase == BackupRunPhase.previewing
                ? BackupRunErrorCodes.previewFailed
                : BackupRunErrorCodes.pickFailed,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  /// 用户确认后执行合并或覆盖导入；未来版本预览不可确认。
  Future<void> confirm(BackupImportMode mode) async {
    _requireAvailable(const {BackupRunPhase.awaitingConfirmation}, 'confirm');
    if (_busy) {
      return;
    }
    final preview = _state.preview;
    final selection = _selection;
    if (preview == null || selection == null || !preview.canImport) {
      throw StateError('当前备份预览不可导入');
    }
    _busy = true;
    final operationToken = ++_operationToken;
    _replace(
      _state.copyWith(
        phase: BackupRunPhase.importing,
        progress: null,
        errorCode: null,
      ),
    );
    try {
      final report = await backupRepository.importBackup(
        selection.bytes,
        mode: mode,
        onProgress: (progress) => _applyProgress(operationToken, progress),
      );
      if (!_isCurrent(operationToken)) {
        await selection.cleanup();
        return;
      }
      await _clearSelection();
      _replace(
        _state.copyWith(
          phase: BackupRunPhase.completed,
          report: report,
          progress: null,
          errorCode: null,
        ),
      );
    } on Exception {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: BackupRunPhase.error,
            progress: null,
            errorCode: BackupRunErrorCodes.importFailed,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  /// 预检或导入失败后复用当前选择，避免强迫用户重新定位文件。
  Future<void> retry() async {
    if (_state.phase != BackupRunPhase.error || _selection == null) {
      return pickAndPreview();
    }
    final selection = _selection!;
    _busy = true;
    final operationToken = ++_operationToken;
    _replace(
      _state.copyWith(
        phase: BackupRunPhase.previewing,
        progress: null,
        errorCode: null,
      ),
    );
    try {
      final preview = await backupRepository.previewImport(
        selection.bytes,
        onProgress: (progress) => _applyProgress(operationToken, progress),
      );
      if (!_isCurrent(operationToken)) {
        await selection.cleanup();
        return;
      }
      _replace(
        _state.copyWith(
          phase: BackupRunPhase.awaitingConfirmation,
          preview: preview,
          progress: null,
          errorCode: preview.isFutureFormat
              ? BackupRunErrorCodes.futureVersion
              : null,
        ),
      );
    } on Exception {
      if (_isCurrent(operationToken)) {
        _replace(
          _state.copyWith(
            phase: BackupRunPhase.error,
            progress: null,
            errorCode: BackupRunErrorCodes.previewFailed,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  /// 取消当前预览并清理应用临时文件。
  Future<void> cancel() async {
    _operationToken++;
    await _clearSelection();
    if (!_closed) {
      _replace(BackupRunState.idle());
    }
  }

  @override
  void onClose() {
    _closed = true;
    _operationToken++;
    final selection = _selection;
    _selection = null;
    if (selection != null) {
      // GetX 的 onClose 无法异步等待，清理任务仍会在后台完成。
      selection.cleanup();
    }
    super.onClose();
  }

  Future<void> _clearSelection() async {
    final selection = _selection;
    _selection = null;
    await selection?.cleanup();
  }

  void _replace(BackupRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([stateUpdateId]);
  }

  void _applyProgress(int operationToken, BackupProgress progress) {
    if (!_isCurrent(operationToken)) {
      return;
    }
    _replace(_state.copyWith(progress: progress));
  }

  bool _isCurrent(int operationToken) {
    return !_closed && operationToken == _operationToken;
  }

  void _requireAvailable(Set<BackupRunPhase> phases, String operation) {
    if (_closed) {
      throw StateError('备份 Logic 已关闭');
    }
    if (!phases.contains(_state.phase)) {
      throw StateError('$operation 不允许在 ${_state.phase.name} 阶段执行');
    }
  }
}
