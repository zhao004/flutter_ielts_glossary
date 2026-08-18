import 'package:get/get.dart';

import '../../repositories/statistics_report_repository.dart';
import 'statistics_logic.dart';

/// 仅在进入完整统计页时创建 Logic，聚合 Repository 由 InitialBinding 提供。
final class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatisticsLogic>(
      () => StatisticsLogic(
        statisticsReportRepository: Get.find<StatisticsReportRepository>(),
      ),
    );
  }
}
