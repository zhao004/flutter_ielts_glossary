import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/settings/settings_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/settings/settings_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('设置 Binding 延迟创建 Logic 并复用应用级 Repository', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    SettingsBinding().dependencies();

    final logic = Get.find<SettingsLogic>();
    expect(logic.settingsRepository, same(dependencies.settingsRepository));
    expect(logic.aboutInfo.contentVersion, 'test-v1');
    expect(logic.aboutInfo.wordCount, 1);
  });
}
