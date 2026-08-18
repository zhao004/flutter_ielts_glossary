import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/study_config.dart';
import '../../models/domain/study_run_state.dart';
import '../../models/domain/study_setup_state.dart';
import '../../repositories/settings_repository.dart';
import 'study_session_starter.dart';

/// 初始化随机学习配置，并将启动委托给会话状态机。
class StudySetupLogic extends GetxController {
  StudySetupLogic({
    required this.settingsRepository,
    required this.studySessionStarter,
    this.autoLoad = true,
  });

  static const String contentUpdateId = 'study_setup_content';

  final SettingsRepository settingsRepository;
  final StudySessionStarter studySessionStarter;
  final bool autoLoad;

  StudySetupState _state = StudySetupState.loadingSettings();
  StudySetupState get state => _state;

  bool _closed = false;
  int _loadToken = 0;
  Future<void>? _loadTask;

  @override
  void onInit() {
    super.onInit();
    if (autoLoad) {
      unawaited(load());
    }
  }

  /// 读取用户级口音和自动播放偏好；并发调用共享同一个查询。
  Future<void> load() {
    if (_closed) {
      return Future<void>.value();
    }
    final active = _loadTask;
    if (active != null) {
      return active;
    }
    _requirePhase(const {
      StudySetupPhase.loadingSettings,
      StudySetupPhase.error,
    }, 'load');
    if (_state.phase == StudySetupPhase.error && _state.config != null) {
      throw const StudySetupTransitionException(
        phase: StudySetupPhase.error,
        action: 'load',
      );
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

  /// 设置加载失败时重新读取；会话启动失败时使用当前配置重试。
  Future<void> retry() {
    _requirePhase(const {StudySetupPhase.error}, 'retry');
    return _state.config == null ? load() : start();
  }

  /// 设置本次学习的显式词频组；空集合表示全部有效组。
  void selectFrequencyGroups(Set<int> frequencyGroupIds) {
    final current = _requireEditableConfig('select_frequency_groups');
    final normalized = Set<int>.unmodifiable(frequencyGroupIds);
    if (_sameSet(current.frequencyGroupIds, normalized)) {
      return;
    }
    _edit(current.copyWith(frequencyGroupIds: normalized));
  }

  /// 设置本次随机学习数量，越界值由领域模型统一拒绝。
  void setWordCount(int value) {
    final current = _requireEditableConfig('set_word_count');
    if (current.wordCount == value) {
      return;
    }
    _edit(current.copyWith(wordCount: value));
  }

  /// 候选不足但至少有一个单词时，将学习数量调整为实际可用数量。
  void useAvailableWordCount() {
    _requirePhase(const {
      StudySetupPhase.insufficientCandidates,
    }, 'use_available_word_count');
    if (!_state.canUseAvailableWordCount) {
      throw StateError('当前范围没有可用于随机学习的单词');
    }
    _edit(_state.config!.copyWith(wordCount: _state.availableCount));
  }

  /// 使用当前配置启动随机学习，并映射候选不足或稳定错误状态。
  Future<void> start() async {
    _requirePhase(const {
      StudySetupPhase.editing,
      StudySetupPhase.insufficientCandidates,
      StudySetupPhase.error,
    }, 'start');
    final config = _state.config;
    if (config == null) {
      throw StateError('用户设置尚未成功加载');
    }
    final previousState = _state;
    _replaceState(StudySetupState.starting(config));
    try {
      await studySessionStarter.start(config);
    } on StudySessionTransitionException {
      if (!_closed) {
        _replaceState(previousState);
      }
      rethrow;
    } on Exception {
      if (!_closed) {
        _replacePreparationError(config);
      }
      return;
    }
    if (_closed) {
      return;
    }

    final runState = studySessionStarter.state;
    switch (runState.phase) {
      case StudyRunPhase.answering:
        if (runState.availableCount < config.wordCount) {
          _replacePreparationError(config);
          return;
        }
        _replaceState(
          StudySetupState.started(
            config: config,
            availableCount: runState.availableCount,
          ),
        );
      case StudyRunPhase.insufficientCandidates:
        _replaceState(
          StudySetupState.insufficientCandidates(
            config: config,
            availableCount: runState.availableCount,
          ),
        );
      case StudyRunPhase.error:
        _replaceState(
          StudySetupState.error(
            config: config,
            errorCode:
                runState.errorCode ?? StudyRunErrorCodes.preparationFailed,
          ),
        );
      case _:
        _replacePreparationError(config);
    }
  }

  Future<void> _performLoad() async {
    final operationToken = ++_loadToken;
    _replaceState(StudySetupState.loadingSettings());
    try {
      final settings = await settingsRepository.load();
      if (!_isCurrentLoad(operationToken)) {
        return;
      }
      _replaceState(
        StudySetupState.editing(StudyConfig.fromSettings(settings)),
      );
    } on Object {
      if (_isCurrentLoad(operationToken)) {
        _replaceState(
          StudySetupState.error(
            config: null,
            errorCode: StudySetupErrorCodes.settingsLoadFailed,
          ),
        );
      }
    }
  }

  StudyConfig _requireEditableConfig(String action) {
    _requirePhase(const {
      StudySetupPhase.editing,
      StudySetupPhase.insufficientCandidates,
      StudySetupPhase.error,
    }, action);
    final config = _state.config;
    if (config == null) {
      throw StateError('用户设置尚未成功加载');
    }
    return config;
  }

  void _edit(StudyConfig config) {
    _replaceState(StudySetupState.editing(config));
  }

  void _replacePreparationError(StudyConfig config) {
    _replaceState(
      StudySetupState.error(
        config: config,
        errorCode: StudyRunErrorCodes.preparationFailed,
      ),
    );
  }

  bool _isCurrentLoad(int token) => !_closed && token == _loadToken;

  void _requirePhase(Set<StudySetupPhase> allowed, String action) {
    if (!allowed.contains(_state.phase)) {
      throw StudySetupTransitionException(phase: _state.phase, action: action);
    }
  }

  void _replaceState(StudySetupState nextState) {
    if (_closed) {
      return;
    }
    _state = nextState;
    update([contentUpdateId]);
  }

  bool _sameSet(Set<int> first, Set<int> second) {
    return first.length == second.length && first.containsAll(second);
  }

  @override
  void onClose() {
    _closed = true;
    _loadToken++;
    super.onClose();
  }
}
