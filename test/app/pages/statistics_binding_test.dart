import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/statistics/statistics_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/statistics/statistics_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('完整统计 Binding 复用应用级聚合 Repository', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    StatisticsBinding().dependencies();

    final logic = Get.find<StatisticsLogic>();
    expect(
      logic.statisticsReportRepository,
      same(dependencies.statisticsReportRepository),
    );
  });
}
