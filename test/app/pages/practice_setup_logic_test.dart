import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/practice_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/practice_setup_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_session.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_session_starter.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_setup_logic.dart';

void main() {
  test('默认配置合法，切换题型会收敛题量并清理题型专属字段', () {
    final logic = PracticeSetupLogic(
      practiceSessionStarter: _FakePracticeSessionStarter(),
    );
    addTearDown(logic.onClose);

    expect(logic.state.config.type, QuestionType.choiceEnglishToChinese);
    expect(logic.state.config.questionCount, 10);

    logic.setQuestionCount(50);
    logic.selectQuestionType(QuestionType.cloze);
    expect(logic.state.config.questionCount, 30);
    expect(logic.state.maximumQuestionCount, 30);

    logic.selectQuestionType(QuestionType.spelling);
    expect(
      logic.state.config.spellingPromptType,
      SpellingPromptType.translation,
    );
    logic.setSpellingPromptType(SpellingPromptType.audio);
    logic.setAllowSpellingPhrases(true);

    logic.selectQuestionType(QuestionType.choiceChineseToEnglish);
    expect(logic.state.config.spellingPromptType, isNull);
    expect(logic.state.config.allowSpellingPhrases, isFalse);
    expect(logic.state.config.questionCount, 30);
  });

  test('显式词频组与难度保持互斥，非法输入不会污染当前配置', () {
    final logic = PracticeSetupLogic(
      practiceSessionStarter: _FakePracticeSessionStarter(),
    );
    addTearDown(logic.onClose);

    logic.selectDifficulty(QuestionDifficulty.hard);
    expect(logic.state.config.frequencyGroupIds, isEmpty);
    expect(logic.state.config.effectiveFrequencyGroupIds, {5, 6});

    logic.selectFrequencyGroups(const {1, 3});
    expect(logic.state.config.frequencyGroupIds, {1, 3});
    expect(logic.state.config.difficulty, isNull);

    final validConfig = logic.state.config;
    expect(() => logic.selectFrequencyGroups(const {7}), throwsArgumentError);
    expect(logic.state.config, same(validConfig));
    expect(() => logic.setQuestionCount(4), throwsArgumentError);
    expect(logic.state.config, same(validConfig));
  });

  test('启动期间拒绝重复操作，成功后映射真实候选统计', () async {
    final gate = Completer<void>();
    final starter = _FakePracticeSessionStarter(
      actions: [
        (config) async {
          await gate.future;
          return _runState(
            config: config,
            phase: PracticeRunPhase.answering,
            availability: _availability(12),
          );
        },
      ],
    );
    final logic = PracticeSetupLogic(practiceSessionStarter: starter);
    addTearDown(logic.onClose);

    final pending = logic.start();
    expect(logic.state.phase, PracticeSetupPhase.starting);
    await expectLater(
      logic.start(),
      throwsA(isA<PracticeSetupTransitionException>()),
    );
    expect(
      () => logic.setTimed(true),
      throwsA(isA<PracticeSetupTransitionException>()),
    );

    gate.complete();
    await pending;

    expect(logic.state.phase, PracticeSetupPhase.started);
    expect(logic.state.availability?.availableCandidateCount, 12);
    expect(starter.receivedConfigs, hasLength(1));
    expect(starter.receivedConfigs.single, same(logic.state.config));
  });

  test('候选不足时可采用达到下限的实际数量并重新启动', () async {
    final starter = _FakePracticeSessionStarter(
      actions: [
        (config) async => _runState(
          config: config,
          phase: PracticeRunPhase.insufficientCandidates,
          availability: _availability(7),
        ),
        (config) async => _runState(
          config: config,
          phase: PracticeRunPhase.answering,
          availability: _availability(7),
        ),
      ],
    );
    final logic = PracticeSetupLogic(practiceSessionStarter: starter);
    addTearDown(logic.onClose);

    await logic.start();
    expect(logic.state.phase, PracticeSetupPhase.insufficientCandidates);
    expect(logic.state.canUseAvailableQuestionCount, isTrue);

    logic.useAvailableQuestionCount();
    expect(logic.state.phase, PracticeSetupPhase.editing);
    expect(logic.state.config.questionCount, 7);

    await logic.start();
    expect(logic.state.phase, PracticeSetupPhase.started);
    expect(starter.receivedConfigs.last.questionCount, 7);
  });

  test('实际候选低于题型下限时必须调整范围而不能采用该数量', () async {
    final starter = _FakePracticeSessionStarter(
      actions: [
        (config) async => _runState(
          config: config,
          phase: PracticeRunPhase.insufficientCandidates,
          availability: _availability(4),
        ),
      ],
    );
    final logic = PracticeSetupLogic(practiceSessionStarter: starter);
    addTearDown(logic.onClose);

    await logic.start();

    expect(logic.state.canUseAvailableQuestionCount, isFalse);
    expect(() => logic.useAvailableQuestionCount(), throwsStateError);
    logic.selectDifficulty(QuestionDifficulty.easy);
    expect(logic.state.phase, PracticeSetupPhase.editing);
    expect(logic.state.availability, isNull);
  });

  test('启动异常或不完整会话状态转为稳定错误并允许编辑重试', () async {
    final starter = _FakePracticeSessionStarter(
      actions: [
        (_) async => throw Exception('test preparation failure'),
        (config) async => PracticeRunState.idle().copyWith(config: config),
        (config) async => _runState(
          config: config,
          phase: PracticeRunPhase.answering,
          availability: _availability(10),
        ),
      ],
    );
    final logic = PracticeSetupLogic(practiceSessionStarter: starter);
    addTearDown(logic.onClose);

    await logic.start();
    expect(logic.state.phase, PracticeSetupPhase.error);
    expect(logic.state.errorCode, PracticeRunErrorCodes.preparationFailed);

    await logic.start();
    expect(logic.state.phase, PracticeSetupPhase.error);
    logic.setTimed(true);
    expect(logic.state.phase, PracticeSetupPhase.editing);
    expect(logic.state.errorCode, isNull);

    await logic.start();
    expect(logic.state.phase, PracticeSetupPhase.started);
  });

  test('关闭后忽略迟到的启动结果', () async {
    final gate = Completer<void>();
    final starter = _FakePracticeSessionStarter(
      actions: [
        (config) async {
          await gate.future;
          return _runState(
            config: config,
            phase: PracticeRunPhase.answering,
            availability: _availability(10),
          );
        },
      ],
    );
    final logic = PracticeSetupLogic(practiceSessionStarter: starter);

    final pending = logic.start();
    logic.onClose();
    gate.complete();
    await pending;

    expect(logic.state.phase, PracticeSetupPhase.starting);
  });
}

typedef _StartAction = Future<PracticeRunState> Function(QuestionConfig config);

final class _FakePracticeSessionStarter implements PracticeSessionStarter {
  _FakePracticeSessionStarter({List<_StartAction> actions = const []})
    : _actions = List<_StartAction>.of(actions);

  final List<_StartAction> _actions;
  final List<QuestionConfig> receivedConfigs = [];
  PracticeRunState _state = PracticeRunState.idle();

  @override
  PracticeRunState get state => _state;

  @override
  Future<void> start(QuestionConfig config) async {
    receivedConfigs.add(config);
    if (_actions.isEmpty) {
      throw StateError('测试未配置启动结果');
    }
    _state = await _actions.removeAt(0)(config);
  }
}

PracticeRunState _runState({
  required QuestionConfig config,
  required PracticeRunPhase phase,
  required QuestionAvailability availability,
}) {
  return PracticeRunState.idle().copyWith(
    phase: phase,
    config: config,
    availability: availability,
  );
}

QuestionAvailability _availability(int availableCount) {
  return QuestionAvailability(
    scopedCandidateCount: availableCount,
    availableCandidateCount: availableCount,
    wrongCandidateCount: 0,
  );
}
