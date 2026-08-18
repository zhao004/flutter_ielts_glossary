import '../models/domain/favorite_page.dart';

/// 将用户库收藏关系与只读词库、学习状态组合为收藏页结果。
abstract interface class FavoriteListRepository {
  Future<FavoritePageResult> findPage(FavoriteFilter filter);
}
