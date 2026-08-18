import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_platform.dart';
import 'package:flutter_ielts_glossary/app/pages/speech_services_config/speech_services_config_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/speech_services_config/speech_services_config_page.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/tts_config_repository.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('敏感凭据在各自输入框内独立切换显隐', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put(
      SpeechServicesConfigLogic(
        ttsConfigRepository: _MemoryTtsRepository(
          const TtsConfig(
            platform: TtsPlatform.xfyun,
            xfyunAppId: 'app-id',
            xfyunApiKey: 'api-key',
            xfyunApiSecret: 'api-secret',
          ),
        ),
        assessmentConfigRepository: _MemoryAssessmentRepository(),
      ),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: SpeechServicesConfigPage()),
    );
    await tester.pumpAndSettle();

    expect(_textField(tester, 'AppID').obscureText, isFalse);
    expect(_textField(tester, 'AppID').decoration?.suffixIcon, isNull);
    expect(_textField(tester, 'APIKey').obscureText, isTrue);
    expect(_textField(tester, 'APISecret').obscureText, isTrue);
    expect(find.text('显示'), findsNothing);
    expect(find.text('隐藏'), findsNothing);

    await tester.tap(find.byTooltip('显示APIKey'));
    await tester.pump();

    expect(_textField(tester, 'APIKey').obscureText, isFalse);
    expect(_textField(tester, 'APISecret').obscureText, isTrue);
    expect(find.byTooltip('隐藏APIKey'), findsOneWidget);
  });
}

TextField _textField(WidgetTester tester, String label) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  expect(finder, findsOneWidget);
  return tester.widget<TextField>(finder);
}

final class _MemoryTtsRepository implements TtsConfigRepository {
  _MemoryTtsRepository(this.value);

  TtsConfig value;

  @override
  Future<TtsConfig> load() async => value;

  @override
  Future<TtsConfig> save(TtsConfig config) async => value = config;
}

final class _MemoryAssessmentRepository
    implements PronunciationAssessmentConfigRepository {
  PronunciationAssessmentConfig value =
      PronunciationAssessmentConfig.defaults();

  @override
  Future<PronunciationAssessmentConfig> load() async => value;

  @override
  Future<PronunciationAssessmentConfig> save(
    PronunciationAssessmentConfig config,
  ) async => value = config;
}
