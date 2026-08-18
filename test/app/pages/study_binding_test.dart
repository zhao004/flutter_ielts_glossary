import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_session_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_setup_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('按页面生命周期延迟创建随机学习 Logic', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    StudyBinding().dependencies();

    final logic = Get.find<StudySessionLogic>();
    final setupLogic = Get.find<StudySetupLogic>();
    expect(
      logic.studyCandidateRepository,
      same(dependencies.studyCandidateRepository),
    );
    expect(logic.learningRepository, same(dependencies.learningRepository));
    expect(logic.favoriteRepository, same(dependencies.favoriteRepository));
    expect(logic.pronunciationService, same(dependencies.pronunciationService));
    expect(
      setupLogic.settingsRepository,
      same(dependencies.settingsRepository),
    );
    expect(setupLogic.studySessionStarter, same(logic));
    await setupLogic.load();
  });
}
