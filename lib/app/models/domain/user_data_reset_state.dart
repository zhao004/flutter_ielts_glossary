import '../backup/backup_operation.dart';

/// 用户数据清除流程的稳定阶段。
enum UserDataResetPhase { idle, resetting, success, error }

/// 用户数据清除页面使用的稳定错误码。
abstract final class UserDataResetErrorCodes {
  static const String resetFailed = 'user_data_reset_failed';
}

/// 清除流程状态；保护备份阶段失败时不会进入成功状态。
final class UserDataResetState {
  const UserDataResetState({
    required this.phase,
    required this.progress,
    required this.result,
    required this.errorCode,
  });

  factory UserDataResetState.idle() {
    return const UserDataResetState(
      phase: UserDataResetPhase.idle,
      progress: null,
      result: null,
      errorCode: null,
    );
  }

  final UserDataResetPhase phase;
  final BackupProgress? progress;
  final UserDataResetResult? result;
  final String? errorCode;

  UserDataResetState copyWith({
    UserDataResetPhase? phase,
    Object? progress = _unset,
    Object? result = _unset,
    Object? errorCode = _unset,
  }) {
    return UserDataResetState(
      phase: phase ?? this.phase,
      progress: identical(progress, _unset)
          ? this.progress
          : progress as BackupProgress?,
      result: identical(result, _unset)
          ? this.result
          : result as UserDataResetResult?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const _unset = Object();
