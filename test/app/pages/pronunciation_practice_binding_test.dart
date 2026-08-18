import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('发音练习 Binding 复用应用级录音器和第三方评测配置', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    PronunciationPracticeBinding().dependencies();

    final logic = Get.find<PronunciationPracticeLogic>();
    expect(logic.audioRecorder, same(dependencies.audioRecorder));
    expect(
      logic.configRepository,
      same(dependencies.pronunciationAssessmentConfigRepository),
    );
  });
}
