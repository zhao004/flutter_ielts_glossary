import 'word_learning_state.dart';
import 'word_summary.dart';

/// 复习页使用的单词和到期状态组合。
final class ReviewQueueItem {
  ReviewQueueItem({required this.word, required this.learningState}) {
    if (word.id != learningState.wordId) {
      throw ArgumentError('复习单词与学习状态 ID 必须一致');
    }
  }

  final WordSummary word;
  final WordLearningState learningState;
}

/// 复习队列快照；词库升级后缺失的稳定 ID 会被显式保留给 UI 提示。
final class ReviewQueueSnapshot {
  ReviewQueueSnapshot({
    required List<ReviewQueueItem> items,
    required List<int> missingWordIds,
  }) : items = List<ReviewQueueItem>.unmodifiable(items),
       missingWordIds = List<int>.unmodifiable(missingWordIds) {
    if (this.missingWordIds.any((id) => id <= 0)) {
      throw ArgumentError.value(
        missingWordIds,
        'missingWordIds',
        '缺失单词 ID 必须为正整数',
      );
    }
    if (this.missingWordIds.toSet().length != this.missingWordIds.length) {
      throw ArgumentError.value(
        missingWordIds,
        'missingWordIds',
        '缺失单词 ID 不能重复',
      );
    }
    final itemIds = this.items.map((item) => item.word.id).toSet();
    if (itemIds.length != this.items.length) {
      throw ArgumentError('复习队列不能包含重复单词');
    }
  }

  final List<ReviewQueueItem> items;
  final List<int> missingWordIds;
}
