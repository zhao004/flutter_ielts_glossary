/// 页面和领域服务使用的单词学习状态，不暴露 Drift 数据类。
final class WordLearningState {
  const WordLearningState({
    required this.wordId,
    required this.masteryLevel,
    required this.studiedCount,
    required this.correctCount,
    required this.wrongCount,
    required this.correctStreak,
    required this.consecutiveForgottenCount,
    required this.lastStudiedAt,
    required this.lastReviewedAt,
    required this.nextReviewAt,
    required this.updatedAt,
  });

  final int wordId;
  final int masteryLevel;
  final int studiedCount;
  final int correctCount;
  final int wrongCount;
  final int correctStreak;
  final int consecutiveForgottenCount;
  final DateTime? lastStudiedAt;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final DateTime updatedAt;
}
