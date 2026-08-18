import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/vocabulary/vocabulary_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/vocabulary/vocabulary_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('词库 Binding 延迟创建页面 Logic 并复用跨库 Repository', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    VocabularyBinding().dependencies();

    final logic = Get.find<VocabularyLogic>();
    expect(logic.vocabularyRepository, same(dependencies.vocabularyRepository));
    expect(logic.favoriteRepository, same(dependencies.favoriteRepository));
  });
}
