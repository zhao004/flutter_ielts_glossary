import 'word_filter.dart';
import 'word_learning_state.dart';
import 'word_summary.dart';

/// 词库列表的一行跨库快照。
final class VocabularyWordItem {
  VocabularyWordItem({
    required this.word,
    required this.isFavorite,
    required this.learningState,
  }) {
    final state = learningState;
    if (state != null && state.wordId != word.id) {
      throw ArgumentError('词条与学习状态 ID 必须一致');
    }
  }

  final WordSummary word;
  final bool isFavorite;
  final WordLearningState? learningState;

  int get masteryLevel => learningState?.masteryLevel ?? 0;
  bool get isNew {
    final state = learningState;
    return state == null || state.studiedCount == 0;
  }

  VocabularyWordItem copyWith({bool? isFavorite}) {
    return VocabularyWordItem(
      word: word,
      isFavorite: isFavorite ?? this.isFavorite,
      learningState: learningState,
    );
  }
}

/// 单次词库分页结果；hasMore 由内容库前瞻记录计算。
final class VocabularyPageResult {
  VocabularyPageResult({
    required this.filter,
    required List<VocabularyWordItem> items,
    required this.hasMore,
    int? totalCount,
  }) : items = List<VocabularyWordItem>.unmodifiable(items) {
    this.totalCount = totalCount ?? items.length;
    if (items.length > filter.pageSize) {
      throw ArgumentError('分页结果不能超过请求页大小');
    }
    final wordIds = this.items.map((item) => item.word.id).toSet();
    if (wordIds.length != this.items.length) {
      throw ArgumentError('分页结果不能包含重复词条');
    }
  }

  final WordFilter filter;
  final List<VocabularyWordItem> items;
  final bool hasMore;
  late final int totalCount;
}
