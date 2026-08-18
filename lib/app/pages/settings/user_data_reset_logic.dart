import 'package:get/get.dart';

import '../../models/backup/backup_operation.dart';
import '../../models/domain/user_data_reset_state.dart';
import '../../repositories/backup_repository.dart';

/// 协调保护备份与用户数据清除，不让页面直接接触数据库事务。
final class UserDataResetLogic extends GetxController {
  UserDataResetLogic({required this.repository});

  static const String updateId = 'user_data_reset_state';

  final UserDataResetRepository repository;

  UserDataResetState _state = UserDataResetState.idle();
  UserDataResetState get state => _state;

  bool _closed = false;
  bool _busy = false;

  /// 执行一次清除；同一页面内的并发请求会被忽略。
  Future<void> reset() async {
    if (_closed || _busy) {
      return;
    }
    _busy = true;
    _replace(
      _state.copyWith(
        phase: UserDataResetPhase.resetting,
        progress: const BackupProgress(
          stage: BackupProgressStage.protecting,
          fraction: 0,
        ),
        result: null,
        errorCode: null,
      ),
    );
    try {
      final result = await repository.resetUserData(
        onProgress: (progress) {
          if (!_closed) {
            _replace(_state.copyWith(progress: progress));
          }
        },
      );
      if (!_closed) {
        _replace(
          _state.copyWith(
            phase: UserDataResetPhase.success,
            progress: const BackupProgress(
              stage: BackupProgressStage.completed,
              fraction: 1,
            ),
            result: result,
            errorCode: null,
          ),
        );
      }
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(
            phase: UserDataResetPhase.error,
            errorCode: UserDataResetErrorCodes.resetFailed,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  void _replace(UserDataResetState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    super.onClose();
  }
}
