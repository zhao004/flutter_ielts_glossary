import 'app_settings_state.dart';

/// 设置页面主查询和保存阶段。
enum SettingsRunPhase { idle, loading, loaded, error }

/// 设置页面稳定错误码；底层 Repository 和平台异常正文不向 UI 泄露。
abstract final class SettingsErrorCodes {
  static const String loadFailed = 'settings_load_failed';
  static const String updateFailed = 'settings_update_failed';
}

/// 设置页的不可变状态快照。
final class SettingsRunState {
  SettingsRunState({
    required this.phase,
    required this.settings,
    required this.isUpdating,
    required this.errorCode,
  }) {
    if ((phase == SettingsRunPhase.loaded || isUpdating) && settings == null) {
      throw ArgumentError('设置已加载或正在保存时必须存在设置快照');
    }
    if (phase == SettingsRunPhase.idle && isUpdating) {
      throw ArgumentError('设置尚未加载时不能保存');
    }
  }

  factory SettingsRunState.idle() {
    return SettingsRunState(
      phase: SettingsRunPhase.idle,
      settings: null,
      isUpdating: false,
      errorCode: null,
    );
  }

  final SettingsRunPhase phase;
  final AppSettingsState? settings;
  final bool isUpdating;
  final String? errorCode;

  SettingsRunState copyWith({
    SettingsRunPhase? phase,
    Object? settings = _unset,
    bool? isUpdating,
    Object? errorCode = _unset,
  }) {
    return SettingsRunState(
      phase: phase ?? this.phase,
      settings: identical(settings, _unset)
          ? this.settings
          : settings as AppSettingsState?,
      isUpdating: isUpdating ?? this.isUpdating,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}

const _unset = Object();
