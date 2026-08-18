import '../domain/review_rating.dart';

/// 用户库中可导出的单词学习状态。
final class BackupUserWordState {
  const BackupUserWordState({
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

/// 用户库中的单词收藏。
final class BackupFavoriteWord {
  const BackupFavoriteWord({
    required this.id,
    required this.wordId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int wordId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// 用户库中的例句收藏。
final class BackupFavoriteSentence {
  const BackupFavoriteSentence({
    required this.id,
    required this.sentenceId,
    required this.wordId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int sentenceId;
  final int wordId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// 已开始或已完成的练习会话。
final class BackupPracticeSession {
  const BackupPracticeSession({
    required this.id,
    required this.type,
    required this.configJson,
    required this.startedAt,
    required this.finishedAt,
    required this.totalQuestionCount,
    required this.correctCount,
    required this.elapsedMilliseconds,
  });

  final String id;
  final String type;
  final String configJson;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int totalQuestionCount;
  final int correctCount;
  final int elapsedMilliseconds;
}

/// 练习会话中的不可变答案记录。
final class BackupPracticeAnswer {
  const BackupPracticeAnswer({
    required this.id,
    required this.sessionId,
    required this.wordId,
    required this.sentenceId,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTimeMilliseconds,
    required this.answeredAt,
  });

  final String id;
  final String sessionId;
  final int wordId;
  final int? sentenceId;
  final String userAnswer;
  final bool isCorrect;
  final int responseTimeMilliseconds;
  final DateTime answeredAt;
}

/// 用于统计和日历的不可变学习事件。
final class BackupLearningEvent {
  const BackupLearningEvent({
    required this.id,
    required this.eventType,
    required this.wordId,
    required this.sessionId,
    required this.isCorrect,
    required this.reviewRating,
    required this.occurredAt,
  });

  final String id;
  final String eventType;
  final int wordId;
  final String? sessionId;
  final bool? isCorrect;
  final ReviewRating? reviewRating;
  final DateTime occurredAt;
}

/// 用户库中的唯一应用设置。
final class BackupAppSettings {
  const BackupAppSettings({
    required this.id,
    required this.dailyGoal,
    required this.pronunciationAccent,
    required this.autoPlayPronunciation,
    required this.themeMode,
    this.accentColor = 'indigo',
    required this.updatedAt,
  });

  final int id;
  final int dailyGoal;
  final String pronunciationAccent;
  final bool autoPlayPronunciation;
  final String themeMode;
  final String accentColor;
  final DateTime updatedAt;
}

/// 一致性读事务得到的用户数据快照；BackupHistory 有意排除在外。
final class BackupSnapshot {
  BackupSnapshot({
    required List<BackupUserWordState> userWordStates,
    required List<BackupFavoriteWord> favoriteWords,
    required List<BackupFavoriteSentence> favoriteSentences,
    required List<BackupPracticeSession> practiceSessions,
    required List<BackupPracticeAnswer> practiceAnswers,
    required List<BackupLearningEvent> learningEvents,
    required this.appSettings,
  }) : userWordStates = List.unmodifiable(userWordStates),
       favoriteWords = List.unmodifiable(favoriteWords),
       favoriteSentences = List.unmodifiable(favoriteSentences),
       practiceSessions = List.unmodifiable(practiceSessions),
       practiceAnswers = List.unmodifiable(practiceAnswers),
       learningEvents = List.unmodifiable(learningEvents);

  final List<BackupUserWordState> userWordStates;
  final List<BackupFavoriteWord> favoriteWords;
  final List<BackupFavoriteSentence> favoriteSentences;
  final List<BackupPracticeSession> practiceSessions;
  final List<BackupPracticeAnswer> practiceAnswers;
  final List<BackupLearningEvent> learningEvents;
  final BackupAppSettings? appSettings;
}
