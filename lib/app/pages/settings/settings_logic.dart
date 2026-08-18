import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:get/get.dart';

import '../../models/app/app_build_info.dart';
import '../../services/content/content_installation.dart';
import '../../models/domain/app_settings_state.dart';
import '../../models/domain/settings_about_info.dart';
import '../../models/domain/settings_run_state.dart';
import '../../repositories/settings_repository.dart';

/// 协调用户设置，不直接操作用户库。
final class SettingsLogic extends GetxController {
  SettingsLogic({
    required this.settingsRepository,
    required ContentInstallResult contentInstallResult,
    String appVersion = AppBuildInfo.version,
    this.autoLoad = true,
  }) : aboutInfo = SettingsAboutInfo.fromManifest(
         appVersion: appVersion,
         manifest: contentInstallResult.manifest,
       );

  static const String updateId = 'settings_state';

  final SettingsRepository settingsRepository;
  final SettingsAboutInfo aboutInfo;
  final bool autoLoad;

  SettingsRunState _state = SettingsRunState.idle();
  SettingsRunState get state => _state;

  bool _closed = false;
  bool _updateBusy = false;
  int _loadToken = 0;
  Future<void>? _loadTask;

  @override
  void onInit() {
    super.onInit();
    if (autoLoad) {
      unawaited(load());
    }
  }

  /// 加载当前设置；并发调用共享同一个查询。
  Future<void> load() {
    if (_closed || _updateBusy) {
      return Future<void>.value();
    }
    final active = _loadTask;
    if (active != null) {
      return active;
    }
    final task = _performLoad();
    _loadTask = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_loadTask, task)) {
          _loadTask = null;
        }
      }),
    );
    return task;
  }

  /// 设置加载失败时按当前页面状态重试。
  Future<void> retry() async {
    if (_state.phase != SettingsRunPhase.error) {
      return;
    }
    await load();
  }

  /// 事务化保存一组设置；失败时保留已加载快照。
  Future<void> updateSettings({
    int? dailyGoal,
    PronunciationAccent? pronunciationAccent,
    bool? autoPlayPronunciation,
    AppThemePreference? themePreference,
    FlexScheme? accentPreference,
  }) async {
    _requireLoaded();
    if (dailyGoal != null &&
        (dailyGoal < AppSettingsState.minimumDailyGoal ||
            dailyGoal > AppSettingsState.maximumDailyGoal)) {
      throw ArgumentError.value(
        dailyGoal,
        'dailyGoal',
        '每日目标必须在 ${AppSettingsState.minimumDailyGoal}-'
            '${AppSettingsState.maximumDailyGoal} 之间',
      );
    }
    if (_updateBusy) {
      return;
    }
    _updateBusy = true;
    final operationToken = ++_loadToken;
    _replace(_state.copyWith(isUpdating: true, errorCode: null));
    try {
      final saved = await settingsRepository.update(
        dailyGoal: dailyGoal,
        pronunciationAccent: pronunciationAccent,
        autoPlayPronunciation: autoPlayPronunciation,
        themePreference: themePreference,
        accentPreference: accentPreference,
      );
      if (!_isCurrentLoad(operationToken)) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: SettingsRunPhase.loaded,
          settings: saved,
          isUpdating: false,
          errorCode: null,
        ),
      );
    } on Object {
      if (_isCurrentLoad(operationToken)) {
        _replace(
          _state.copyWith(
            isUpdating: false,
            errorCode: SettingsErrorCodes.updateFailed,
          ),
        );
      }
    } finally {
      _updateBusy = false;
    }
  }

  AppSettingsState _requireLoaded() {
    if (_closed || _state.phase != SettingsRunPhase.loaded) {
      throw StateError('当前设置尚未加载');
    }
    final settings = _state.settings;
    if (settings == null) {
      throw StateError('当前设置为空');
    }
    return settings;
  }

  Future<void> _performLoad() async {
    final operationToken = ++_loadToken;
    _replace(
      _state.copyWith(
        phase: SettingsRunPhase.loading,
        isUpdating: false,
        errorCode: null,
      ),
    );
    try {
      final settings = await settingsRepository.load();
      if (!_isCurrentLoad(operationToken)) {
        return;
      }
      _replace(
        _state.copyWith(
          phase: SettingsRunPhase.loaded,
          settings: settings,
          isUpdating: false,
          errorCode: null,
        ),
      );
    } on Object {
      if (_isCurrentLoad(operationToken)) {
        _replace(
          _state.copyWith(
            phase: SettingsRunPhase.error,
            isUpdating: false,
            errorCode: SettingsErrorCodes.loadFailed,
          ),
        );
      }
    }
  }

  bool _isCurrentLoad(int token) => !_closed && token == _loadToken;

  void _replace(SettingsRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    _loadToken++;
    super.onClose();
  }
}
