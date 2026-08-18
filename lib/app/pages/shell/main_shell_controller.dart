import 'package:get/get.dart';

/// 底部导航外壳的持久控制器，持有当前一级入口下标，
/// 并统一处理“从任意二级页面返回某个一级入口”的弹栈与切换。
final class MainShellController extends GetxController {
  static const int homeIndex = 0;
  static const int vocabularyIndex = 1;
  static const int studyIndex = 2;
  static const int reviewIndex = 3;
  static const int settingsIndex = 4;

  int _currentIndex = homeIndex;
  int get currentIndex => _currentIndex;

  /// 在外壳内切换一级入口，不触发路由重建，导航栏保持不变。
  void select(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      update();
    }
  }

  /// 先弹栈回到外壳，再切换到 [index]，用于二级页面“返回某个一级页”。
  void switchToTab(int index) {
    Get.until((route) => route.isFirst);
    select(index);
  }

  void switchToHome() => switchToTab(homeIndex);
  void switchToStudy() => switchToTab(studyIndex);
  void switchToSettings() => switchToTab(settingsIndex);
}
