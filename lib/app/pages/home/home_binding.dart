import 'package:get/get.dart';

import '../../repositories/statistics_repository.dart';
import 'home_logic.dart';

/// 仅在进入首页时创建页面级 Logic。
class HomeBinding extends Bindings {
  HomeBinding({this.autoLoad = true});

  final bool autoLoad;

  @override
  void dependencies() {
    Get.lazyPut<HomeLogic>(
      () => HomeLogic(
        statisticsRepository: Get.find<StatisticsRepository>(),
        autoLoad: autoLoad,
      ),
    );
  }
}
