import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_platform.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_practice_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_score.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator_factory.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_recorder.dart';

void main() {
  test('未配置第三方评测时不可开始录音', () async {
    final recorder = _FakeAudioRecorder();
    final logic = _createLogic(
      recorder: recorder,
      configRepository: _MemoryConfigRepository(
        PronunciationAssessmentConfig.defaults(),
      ),
      evaluatorFactory: const PronunciationEvaluatorFactory(),
    );
    addTearDown(logic.onClose);

    await logic.prepare(expectedWord: 'alpha');

    expect(logic.state.phase, PronunciationPracticePhase.unavailable);
    expect(
      logic.state.errorCode,
      PronunciationPracticeErrorCodes.assessmentNotConfigured,
    );
    expect(recorder.permissionChecks, 0);
  });

  test('已配置第三方评测时录音并返回评分', () async {
    final recorder = _FakeAudioRecorder();
    final logic = _createLogic(
      recorder: recorder,
      configRepository: _readyConfigRepository(),
      evaluatorFactory: _FixedEvaluatorFactory(
        const _FixedEvaluator(
          PronunciationScore(
            totalScore: 88,
            accuracyScore: 90,
            fluencyScore: 85,
            integrityScore: 92,
          ),
        ),
      ),
    );
    addTearDown(logic.onClose);

    await logic.prepare(expectedWord: ' alpha ');
    expect(logic.state.phase, PronunciationPracticePhase.ready);
    expect(logic.state.expectedWord, 'alpha');

    await logic.startListening();
    expect(logic.state.phase, PronunciationPracticePhase.listening);
    await logic.stop();

    expect(logic.state.phase, PronunciationPracticePhase.completed);
    expect(logic.state.score?.totalScore, 88);
    expect(recorder.startCalls, 1);
    expect(recorder.stopCalls, 1);
  });

  test('麦克风权限或第三方评分失败时保留稳定错误码', () async {
    final deniedLogic = _createLogic(
      recorder: _FakeAudioRecorder(permissionGranted: false),
      configRepository: _readyConfigRepository(),
      evaluatorFactory: _FixedEvaluatorFactory(const _FixedEvaluator(null)),
    );
    addTearDown(deniedLogic.onClose);

    await deniedLogic.prepare(expectedWord: 'alpha');
    expect(
      deniedLogic.state.phase,
      PronunciationPracticePhase.permissionDenied,
    );
    expect(
      deniedLogic.state.errorCode,
      PronunciationPracticeErrorCodes.microphonePermissionDenied,
    );

    final failedLogic = _createLogic(
      recorder: _FakeAudioRecorder(),
      configRepository: _readyConfigRepository(),
      evaluatorFactory: _FixedEvaluatorFactory(const _ThrowingEvaluator()),
    );
    addTearDown(failedLogic.onClose);

    await failedLogic.prepare(expectedWord: 'alpha');
    await failedLogic.startListening();
    await failedLogic.stop();
    expect(failedLogic.state.phase, PronunciationPracticePhase.error);
    expect(
      failedLogic.state.errorCode,
      PronunciationPracticeErrorCodes.evaluationFailed,
    );
  });

  test('取消录音后回到就绪状态并拒绝无效单词', () async {
    final recorder = _FakeAudioRecorder();
    final logic = _createLogic(
      recorder: recorder,
      configRepository: _readyConfigRepository(),
      evaluatorFactory: _FixedEvaluatorFactory(const _FixedEvaluator(null)),
    );
    addTearDown(logic.onClose);

    await logic.prepare(expectedWord: 'alpha');
    await logic.startListening();
    await logic.cancel();
    expect(logic.state.phase, PronunciationPracticePhase.ready);
    expect(recorder.cancelCalls, 1);

    await expectLater(
      logic.prepare(expectedWord: ''),
      throwsA(isA<ArgumentError>()),
    );
  });
}

PronunciationPracticeLogic _createLogic({
  required _FakeAudioRecorder recorder,
  required PronunciationAssessmentConfigRepository configRepository,
  required PronunciationEvaluatorFactory evaluatorFactory,
}) {
  return PronunciationPracticeLogic(
    audioRecorder: recorder,
    configRepository: configRepository,
    evaluatorFactory: evaluatorFactory,
  );
}

_MemoryConfigRepository _readyConfigRepository() {
  return _MemoryConfigRepository(
    const PronunciationAssessmentConfig(
      platform: PronunciationAssessmentPlatform.xfyun,
      xfyunAppId: 'app',
      xfyunApiKey: 'key',
      xfyunApiSecret: 'secret',
    ),
  );
}

final class _FakeAudioRecorder implements AudioRecorderPort {
  _FakeAudioRecorder({this.permissionGranted = true});

  bool permissionGranted;
  int permissionChecks = 0;
  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async {
    permissionChecks++;
    return permissionGranted;
  }

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<RecordedAudio> stop() async {
    stopCalls++;
    return RecordedAudio(pcmBytes: Uint8List(3200));
  }
}

final class _MemoryConfigRepository
    implements PronunciationAssessmentConfigRepository {
  _MemoryConfigRepository(this.config);

  final PronunciationAssessmentConfig config;

  @override
  Future<PronunciationAssessmentConfig> load() async => config;

  @override
  Future<PronunciationAssessmentConfig> save(
    PronunciationAssessmentConfig config,
  ) async => config;
}

final class _FixedEvaluatorFactory extends PronunciationEvaluatorFactory {
  const _FixedEvaluatorFactory(this.evaluator);

  final PronunciationEvaluatorPort evaluator;

  @override
  PronunciationEvaluatorPort? create(PronunciationAssessmentConfig config) {
    return evaluator;
  }
}

final class _FixedEvaluator implements PronunciationEvaluatorPort {
  const _FixedEvaluator(this.score);

  final PronunciationScore? score;

  @override
  Future<PronunciationScore> evaluate(
    PronunciationEvaluationRequest request,
  ) async {
    return score ??
        const PronunciationScore(
          totalScore: 80,
          accuracyScore: 80,
          fluencyScore: 80,
          integrityScore: 80,
        );
  }
}

final class _ThrowingEvaluator implements PronunciationEvaluatorPort {
  const _ThrowingEvaluator();

  @override
  Future<PronunciationScore> evaluate(
    PronunciationEvaluationRequest request,
  ) async {
    throw const PronunciationEvaluationException('test_failure', '测试失败');
  }
}
