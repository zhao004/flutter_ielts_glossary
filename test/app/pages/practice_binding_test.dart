import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_session_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_setup_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('按页面生命周期延迟创建练习 Logic 并复用应用级依赖', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    PracticeBinding().dependencies();

    expect(Get.isRegistered<PracticeSessionLogic>(), isTrue);
    expect(Get.isRegistered<PracticeSetupLogic>(), isTrue);
    final logic = Get.find<PracticeSessionLogic>();
    final setupLogic = Get.find<PracticeSetupLogic>();
    expect(
      logic.questionCandidateRepository,
      same(dependencies.questionCandidateRepository),
    );
    expect(logic.questionEngine, same(dependencies.questionEngine));
    expect(logic.practiceRepository, same(dependencies.practiceRepository));
    expect(logic.favoriteRepository, same(dependencies.favoriteRepository));
    expect(logic.answerEvaluator, same(dependencies.practiceAnswerEvaluator));
    expect(logic.monotonicClock, same(dependencies.monotonicClock));
    expect(setupLogic.practiceSessionStarter, same(logic));
  });
}
