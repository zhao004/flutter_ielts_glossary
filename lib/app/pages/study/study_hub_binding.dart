import 'package:get/get.dart';

import '../../repositories/statistics_repository.dart';
import 'study_hub_logic.dart';

/// 学习中心页面级依赖，仅创建轻量统计 Logic。
final class StudyHubBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudyHubLogic>(
      () =>
          StudyHubLogic(statisticsRepository: Get.find<StatisticsRepository>()),
    );
  }
}
