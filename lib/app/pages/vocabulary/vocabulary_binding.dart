import 'package:get/get.dart';

import '../../repositories/favorite_repository.dart';
import '../../repositories/vocabulary_repository.dart';
import 'vocabulary_logic.dart';

/// 仅在进入词库页时创建页面 Logic，Repository 生命周期由 InitialBinding 管理。
final class VocabularyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VocabularyLogic>(
      () => VocabularyLogic(
        vocabularyRepository: Get.find<VocabularyRepository>(),
        favoriteRepository: Get.find<FavoriteRepository>(),
      ),
    );
  }
}
