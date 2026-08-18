import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_platform.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_score.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_page.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator_factory.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_recorder.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('长按录音时图标循环缩放，松手后自动评测', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final recorder = _FakeAudioRecorder();
    final evaluator = _FakeEvaluator();
    Get.put(
      PronunciationPracticeLogic(
        audioRecorder: recorder,
        configRepository: _MemoryAssessmentRepository(),
        evaluatorFactory: _FixedEvaluatorFactory(evaluator),
      ),
    );

    await tester.pumpWidget(
      const GetMaterialApp(
        home: PronunciationPracticePage(
          expectedWord: 'academic',
          phonetic: '/ˌækəˈdemɪk/',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final recordButton = find.byKey(
      const ValueKey('pronunciation-record-button'),
    );
    expect(recordButton, findsOneWidget);
    expect(find.text('选择发音'), findsNothing);
    expect(find.text('英式 UK'), findsNothing);
    expect(find.text('美式 US'), findsNothing);

    await tester.tap(recordButton);
    await tester.pump(const Duration(milliseconds: 600));
    expect(recorder.startCalls, 0);

    final gesture = await tester.startGesture(tester.getCenter(recordButton));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(recorder.startCalls, 1);
    expect(find.text('正在录音…'), findsOneWidget);

    final scaleFinder = find.descendant(
      of: recordButton,
      matching: find.byType(ScaleTransition),
    );
    final initialScale = tester
        .widget<ScaleTransition>(scaleFinder)
        .scale
        .value;
    await tester.pump(const Duration(milliseconds: 180));
    final nextScale = tester.widget<ScaleTransition>(scaleFinder).scale.value;
    expect(nextScale, isNot(closeTo(initialScale, 0.001)));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(recorder.stopCalls, 1);
    expect(evaluator.evaluateCalls, 1);
    expect(find.text('第三方发音评测'), findsOneWidget);
    expect(find.textContaining('88'), findsWidgets);
  });
}

final class _FakeAudioRecorder implements AudioRecorderPort {
  var startCalls = 0;
  var stopCalls = 0;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

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

final class _MemoryAssessmentRepository
    implements PronunciationAssessmentConfigRepository {
  final PronunciationAssessmentConfig value =
      const PronunciationAssessmentConfig(
        platform: PronunciationAssessmentPlatform.xfyun,
        xfyunAppId: 'app-id',
        xfyunApiKey: 'api-key',
        xfyunApiSecret: 'api-secret',
      );

  @override
  Future<PronunciationAssessmentConfig> load() async => value;

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

final class _FakeEvaluator implements PronunciationEvaluatorPort {
  var evaluateCalls = 0;

  @override
  Future<PronunciationScore> evaluate(
    PronunciationEvaluationRequest request,
  ) async {
    evaluateCalls++;
    return const PronunciationScore(
      totalScore: 88,
      accuracyScore: 90,
      fluencyScore: 85,
      integrityScore: 92,
    );
  }
}
