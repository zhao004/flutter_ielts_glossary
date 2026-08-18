import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/favorites/favorites_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/favorites/favorites_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('收藏 Binding 复用跨库列表 Repository 和收藏 Repository', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    FavoritesBinding().dependencies();

    final logic = Get.find<FavoritesLogic>();
    expect(
      logic.favoriteListRepository,
      same(dependencies.favoriteListRepository),
    );
    expect(logic.favoriteRepository, same(dependencies.favoriteRepository));
  });
}
