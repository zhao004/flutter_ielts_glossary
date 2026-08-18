import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/review/review_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/review/review_session_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('复习 Binding 延迟创建会话 Logic 并复用应用级 Repository', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    ReviewBinding().dependencies();

    final logic = Get.find<ReviewSessionLogic>();
    expect(
      logic.reviewQueueRepository,
      same(dependencies.reviewQueueRepository),
    );
    expect(logic.learningRepository, same(dependencies.learningRepository));
    expect(logic.favoriteRepository, same(dependencies.favoriteRepository));
    expect(logic.settingsRepository, same(dependencies.settingsRepository));
    expect(logic.pronunciationService, same(dependencies.pronunciationService));
  });
}
