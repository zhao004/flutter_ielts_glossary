import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_setup_state.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_session_starter.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_setup_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/settings_repository.dart';

void main() {
  test('并发加载共享设置查询且不继承旧发音偏好', () async {
    final gate = Completer<AppSettingsState>();
    final settingsRepository = _FakeSettingsRepository(
      loadActions: [() => gate.future],
    );
    final logic = _createLogic(settingsRepository: settingsRepository);
    addTearDown(logic.onClose);

    final first = logic.load();
    final second = logic.load();
    expect(identical(first, second), isTrue);
    expect(logic.state.phase, StudySetupPhase.loadingSettings);

    gate.complete(_settings(accent: PronunciationAccent.us, autoPlay: true));
    await Future.wait([first, second]);

    expect(settingsRepository.loadCalls, 1);
    expect(logic.state.phase, StudySetupPhase.editing);
    expect(logic.state.config?.wordCount, StudyConfig.defaultWordCount);
  });

  test('设置加载失败暴露稳定错误码并可重试', () async {
    final settingsRepository = _FakeSettingsRepository(
      loadActions: [
        () async => throw Exception('test settings failure'),
        () async => _settings(),
      ],
    );
    final logic = _createLogic(settingsRepository: settingsRepository);
    addTearDown(logic.onClose);

    await logic.load();
    expect(logic.state.phase, StudySetupPhase.error);
    expect(logic.state.config, isNull);
    expect(logic.state.errorCode, StudySetupErrorCodes.settingsLoadFailed);

    await logic.retry();
    expect(logic.state.phase, StudySetupPhase.editing);
    expect(settingsRepository.loadCalls, 2);
  });

  test('编辑配置统一校验词频范围和数量且不写用户设置', () async {
    final settingsRepository = _FakeSettingsRepository(
      loadActions: [() async => _settings()],
    );
    final logic = _createLogic(settingsRepository: settingsRepository);
    addTearDown(logic.onClose);
    await logic.load();

    logic.selectFrequencyGroups(const {1, 3, 5});
    logic.setWordCount(37);

    expect(logic.state.config?.frequencyGroupIds, {1, 3, 5});
    expect(logic.state.config?.wordCount, 37);
    expect(settingsRepository.updateCalls, 0);

    final validConfig = logic.state.config;
    expect(() => logic.selectFrequencyGroups(const {7}), throwsArgumentError);
    expect(() => logic.setWordCount(0), throwsArgumentError);
    expect(logic.state.config, same(validConfig));
  });

  test('启动期间拒绝重复操作并映射成功候选数量', () async {
    final gate = Completer<void>();
    final starter = _FakeStudySessionStarter(
      actions: [
        (config) async {
          await gate.future;
          return _runState(
            config: config,
            phase: StudyRunPhase.answering,
            availableCount: 20,
          );
        },
      ],
    );
    final logic = _createLogic(starter: starter);
    addTearDown(logic.onClose);
    await logic.load();

    final pending = logic.start();
    expect(logic.state.phase, StudySetupPhase.starting);
    await expectLater(
      logic.start(),
      throwsA(isA<StudySetupTransitionException>()),
    );
    expect(
      () => logic.setWordCount(5),
      throwsA(isA<StudySetupTransitionException>()),
    );

    gate.complete();
    await pending;

    expect(logic.state.phase, StudySetupPhase.started);
    expect(logic.state.availableCount, 20);
    expect(starter.receivedConfigs, hasLength(1));
    expect(starter.receivedConfigs.single, same(logic.state.config));
  });

  test('候选不足时可采用实际数量并重新启动', () async {
    final starter = _FakeStudySessionStarter(
      actions: [
        (config) async => _runState(
          config: config,
          phase: StudyRunPhase.insufficientCandidates,
          availableCount: 3,
        ),
        (config) async => _runState(
          config: config,
          phase: StudyRunPhase.answering,
          availableCount: 3,
        ),
      ],
    );
    final logic = _createLogic(starter: starter);
    addTearDown(logic.onClose);
    await logic.load();

    await logic.start();
    expect(logic.state.phase, StudySetupPhase.insufficientCandidates);
    expect(logic.state.canUseAvailableWordCount, isTrue);

    logic.useAvailableWordCount();
    expect(logic.state.phase, StudySetupPhase.editing);
    expect(logic.state.config?.wordCount, 3);

    await logic.start();
    expect(logic.state.phase, StudySetupPhase.started);
    expect(starter.receivedConfigs.last.wordCount, 3);
  });

  test('零候选必须调整范围，启动失败保留配置并可重试', () async {
    final starter = _FakeStudySessionStarter(
      actions: [
        (config) async => _runState(
          config: config,
          phase: StudyRunPhase.insufficientCandidates,
          availableCount: 0,
        ),
        (_) async => throw Exception('test start failure'),
        (config) async => _runState(
          config: config,
          phase: StudyRunPhase.answering,
          availableCount: 20,
        ),
      ],
    );
    final logic = _createLogic(starter: starter);
    addTearDown(logic.onClose);
    await logic.load();

    await logic.start();
    expect(logic.state.canUseAvailableWordCount, isFalse);
    expect(() => logic.useAvailableWordCount(), throwsStateError);
    logic.selectFrequencyGroups(const {1, 2});

    await logic.start();
    expect(logic.state.phase, StudySetupPhase.error);
    expect(logic.state.config?.frequencyGroupIds, {1, 2});
    expect(logic.state.errorCode, StudyRunErrorCodes.preparationFailed);

    await logic.retry();
    expect(logic.state.phase, StudySetupPhase.started);
  });

  test('关闭后忽略设置和启动的晚返回结果', () async {
    final settingsGate = Completer<AppSettingsState>();
    final settingsLogic = _createLogic(
      settingsRepository: _FakeSettingsRepository(
        loadActions: [() => settingsGate.future],
      ),
    );
    final settingsPending = settingsLogic.load();
    settingsLogic.onClose();
    settingsGate.complete(_settings());
    await settingsPending;
    expect(settingsLogic.state.phase, StudySetupPhase.loadingSettings);

    final startGate = Completer<void>();
    final startLogic = _createLogic(
      starter: _FakeStudySessionStarter(
        actions: [
          (config) async {
            await startGate.future;
            return _runState(
              config: config,
              phase: StudyRunPhase.answering,
              availableCount: 10,
            );
          },
        ],
      ),
    );
    await startLogic.load();
    final startPending = startLogic.start();
    startLogic.onClose();
    startGate.complete();
    await startPending;
    expect(startLogic.state.phase, StudySetupPhase.starting);
  });
}

StudySetupLogic _createLogic({
  _FakeSettingsRepository? settingsRepository,
  _FakeStudySessionStarter? starter,
}) {
  return StudySetupLogic(
    settingsRepository:
        settingsRepository ??
        _FakeSettingsRepository(loadActions: [() async => _settings()]),
    studySessionStarter: starter ?? _FakeStudySessionStarter(),
    autoLoad: false,
  );
}

typedef _SettingsLoadAction = Future<AppSettingsState> Function();

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({required List<_SettingsLoadAction> loadActions})
    : _loadActions = List<_SettingsLoadAction>.of(loadActions);

  final List<_SettingsLoadAction> _loadActions;
  var loadCalls = 0;
  var updateCalls = 0;

  @override
  Future<AppSettingsState> load() {
    loadCalls++;
    if (_loadActions.isEmpty) {
      throw StateError('测试未配置设置加载结果');
    }
    return _loadActions.removeAt(0)();
  }

  @override
  Future<AppSettingsState> update({
    int? dailyGoal,
    PronunciationAccent? pronunciationAccent,
    bool? autoPlayPronunciation,
    AppThemePreference? themePreference,
    FlexScheme? accentPreference,
  }) async {
    updateCalls++;
    return _settings(
      accent: pronunciationAccent ?? PronunciationAccent.uk,
      autoPlay: autoPlayPronunciation ?? false,
    );
  }
}

typedef _StartAction = Future<StudyRunState> Function(StudyConfig config);

final class _FakeStudySessionStarter implements StudySessionStarter {
  _FakeStudySessionStarter({List<_StartAction> actions = const []})
    : _actions = List<_StartAction>.of(actions);

  final List<_StartAction> _actions;
  final List<StudyConfig> receivedConfigs = [];
  StudyRunState _state = StudyRunState.idle();

  @override
  StudyRunState get state => _state;

  @override
  Future<void> start(StudyConfig config) async {
    receivedConfigs.add(config);
    if (_actions.isEmpty) {
      throw StateError('测试未配置学习启动结果');
    }
    _state = await _actions.removeAt(0)(config);
  }
}

StudyRunState _runState({
  required StudyConfig config,
  required StudyRunPhase phase,
  required int availableCount,
}) {
  return StudyRunState.idle().copyWith(
    phase: phase,
    config: config,
    availableCount: availableCount,
  );
}

AppSettingsState _settings({
  PronunciationAccent accent = PronunciationAccent.uk,
  bool autoPlay = false,
}) {
  return AppSettingsState(
    dailyGoal: AppSettingsState.defaultDailyGoal,
    pronunciationAccent: accent,
    autoPlayPronunciation: autoPlay,
    themePreference: AppThemePreference.system,
    updatedAt: null,
  );
}
