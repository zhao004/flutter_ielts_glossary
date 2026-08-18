import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/home/home_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/home/home_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('首页 Binding 复用应用级统计 Repository', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    HomeBinding(autoLoad: false).dependencies();

    final logic = Get.find<HomeLogic>();
    expect(logic.statisticsRepository, same(dependencies.statisticsRepository));
  });
}
