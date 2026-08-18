import 'package:get/get.dart';

import '../home/home_binding.dart';
import '../review/review_binding.dart';
import '../settings/settings_binding.dart';
import '../study/study_hub_binding.dart';
import '../vocabulary/vocabulary_binding.dart';

/// 注册五个一级入口的页面级 Logic；全部使用 lazyPut，
/// 只有在对应页面首次构建时才真正创建实例，避免启动时全量加载。
final class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    VocabularyBinding().dependencies();
    StudyHubBinding().dependencies();
    ReviewBinding().dependencies();
    SettingsBinding().dependencies();
  }
}
