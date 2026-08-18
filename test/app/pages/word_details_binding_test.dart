import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('详情 Binding 延迟创建 Logic 并复用应用级内容、收藏和发音服务', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    WordDetailsBinding().dependencies();

    final logic = Get.find<WordDetailsLogic>();
    expect(logic.contentRepository, same(dependencies.contentRepository));
    expect(logic.favoriteRepository, same(dependencies.favoriteRepository));
    expect(logic.learningRepository, same(dependencies.learningRepository));
    expect(logic.pronunciationService, same(dependencies.pronunciationService));
  });
}
