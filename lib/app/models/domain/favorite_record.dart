/// 单词收藏关系的只读领域记录。
final class FavoriteWordRecord {
  FavoriteWordRecord({
    required this.id,
    required this.wordId,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validateFavoriteRecord(
      id: id,
      contentId: wordId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final int wordId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// 例句收藏关系的只读领域记录。
final class FavoriteSentenceRecord {
  FavoriteSentenceRecord({
    required this.id,
    required this.sentenceId,
    required this.wordId,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validateFavoriteRecord(
      id: id,
      contentId: sentenceId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
  }

  final String id;
  final int sentenceId;
  final int wordId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

void _validateFavoriteRecord({
  required String id,
  required int contentId,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  final normalizedId = id.trim();
  if (normalizedId.isEmpty || normalizedId.length > 64) {
    throw ArgumentError.value(id, 'id', '收藏记录 ID 长度必须在 1-64 之间');
  }
  if (contentId <= 0) {
    throw ArgumentError.value(contentId, 'contentId', '内容 ID 必须为正整数');
  }
  if (updatedAt.toUtc().isBefore(createdAt.toUtc())) {
    throw ArgumentError('收藏更新时间不能早于创建时间');
  }
}
