import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/core_navigation_flow.dart';
import '../support/test_app_dependencies.dart';

void main() {
  testWidgets('首页、词库详情和我的页面可以完成一条核心导航路径', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    await runCoreNavigationFlow(tester, dependencies);
  });
}
