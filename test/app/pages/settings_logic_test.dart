import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/settings_run_state.dart';
import 'package:flutter_ielts_glossary/app/pages/settings/settings_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/settings_repository.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('加载设置并合并领域默认值', () async {
    final repository = _FakeSettingsRepository(
      value: AppSettingsState(
        dailyGoal: 20,
        pronunciationAccent: PronunciationAccent.us,
        autoPlayPronunciation: true,
        themePreference: AppThemePreference.dark,
        accentPreference: FlexScheme.rosewood,
        updatedAt: DateTime.utc(2026, 8, 15),
      ),
    );
    final logic = _createLogic(repository: repository);
    addTearDown(logic.onClose);

    await logic.load();

    expect(logic.state.phase, SettingsRunPhase.loaded);
    expect(logic.state.settings?.dailyGoal, 20);
    expect(logic.state.settings?.pronunciationAccent, PronunciationAccent.us);
    expect(logic.state.settings?.themePreference, AppThemePreference.dark);
    expect(logic.state.settings?.accentPreference, FlexScheme.rosewood);
  });

  test('加载失败后可重试并共享并发查询', () async {
    final repository = _FakeSettingsRepository()..failLoad = true;
    final logic = _createLogic(repository: repository);
    addTearDown(logic.onClose);

    await Future.wait([logic.load(), logic.load()]);
    expect(logic.state.phase, SettingsRunPhase.error);
    expect(logic.state.errorCode, SettingsErrorCodes.loadFailed);
    expect(repository.loadCalls, 1);

    repository.failLoad = false;
    await logic.retry();
    expect(logic.state.phase, SettingsRunPhase.loaded);
    expect(repository.loadCalls, 2);
  });

  test('保存设置期间拒绝重复写入，失败保留原快照', () async {
    final repository = _FakeSettingsRepository()
      ..updateGate = Completer<void>();
    final logic = _createLogic(repository: repository);
    addTearDown(logic.onClose);
    await logic.load();

    final first = logic.updateSettings(dailyGoal: 30);
    await Future<void>.delayed(Duration.zero);
    await logic.updateSettings(dailyGoal: 40);
    expect(repository.updateCalls, 1);
    expect(logic.state.isUpdating, isTrue);
    repository.updateGate!.complete();
    await first;
    expect(logic.state.settings?.dailyGoal, 30);

    repository.failUpdate = true;
    await logic.updateSettings(themePreference: AppThemePreference.dark);
    expect(logic.state.settings?.dailyGoal, 30);
    expect(logic.state.settings?.themePreference, AppThemePreference.system);
    expect(logic.state.errorCode, SettingsErrorCodes.updateFailed);

    await expectLater(
      logic.updateSettings(dailyGoal: AppSettingsState.maximumDailyGoal + 1),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.updateCalls, 2);
  });
}

SettingsLogic _createLogic({_FakeSettingsRepository? repository}) {
  return SettingsLogic(
    settingsRepository: repository ?? _FakeSettingsRepository(),
    contentInstallResult: createTestInstallResult(),
    autoLoad: false,
  );
}

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({AppSettingsState? value})
    : value = value ?? AppSettingsState.defaults();

  AppSettingsState value;
  bool failLoad = false;
  bool failUpdate = false;
  int loadCalls = 0;
  int updateCalls = 0;
  Completer<void>? updateGate;

  @override
  Future<AppSettingsState> load() async {
    loadCalls++;
    if (failLoad) {
      throw Exception('settings load failed');
    }
    return value;
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
    final gate = updateGate;
    if (gate != null && !gate.isCompleted) {
      await gate.future;
    }
    if (failUpdate) {
      throw Exception('settings update failed');
    }
    value = AppSettingsState(
      dailyGoal: dailyGoal ?? value.dailyGoal,
      pronunciationAccent: pronunciationAccent ?? value.pronunciationAccent,
      autoPlayPronunciation:
          autoPlayPronunciation ?? value.autoPlayPronunciation,
      themePreference: themePreference ?? value.themePreference,
      accentPreference: accentPreference ?? value.accentPreference,
      updatedAt: DateTime.utc(2026, 8, 15),
    );
    return value;
  }
}
