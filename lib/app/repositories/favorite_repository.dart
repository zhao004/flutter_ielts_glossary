import '../models/domain/favorite_record.dart';

/// 收藏指向的只读词库内容已经不存在。
final class FavoriteContentNotFoundException implements Exception {
  const FavoriteContentNotFoundException({
    required this.contentType,
    required this.contentId,
  });

  final String contentType;
  final int contentId;

  @override
  String toString() => 'favorite_content_not_found: $contentType/$contentId';
}

/// 单词和例句收藏的领域接口；添加和删除均保持幂等。
abstract interface class FavoriteRepository {
  Future<FavoriteWordRecord?> setWordFavorite({
    required int wordId,
    required bool isFavorite,
  });

  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  });

  Future<bool> isWordFavorite(int wordId);

  Future<bool> isSentenceFavorite(int sentenceId);

  Future<Set<int>> findFavoriteWordIds(Set<int> wordIds);

  Future<Set<int>> findFavoriteSentenceIds(Set<int> sentenceIds);

  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  });

  Future<List<FavoriteSentenceRecord>> findFavoriteSentences({
    int limit = 100,
    int offset = 0,
  });
}

/// 支持在单条收藏接口之外原子删除当前页面选择的内容。
abstract interface class FavoriteBatchRepository {
  Future<int> removeWordFavorites(Set<int> wordIds);

  Future<int> removeSentenceFavorites(Set<int> sentenceIds);
}
