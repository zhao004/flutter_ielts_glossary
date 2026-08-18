import 'package:get/get.dart';

import '../../repositories/favorite_list_repository.dart';
import '../../repositories/favorite_repository.dart';
import 'favorites_logic.dart';

/// 仅在进入收藏页时创建 Logic，跨库 Repository 由 InitialBinding 提供。
final class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesLogic>(
      () => FavoritesLogic(
        favoriteListRepository: Get.find<FavoriteListRepository>(),
        favoriteRepository: Get.find<FavoriteRepository>(),
      ),
    );
  }
}
