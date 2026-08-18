/// 持久化学习事件类型；值进入备份协议后不得随类名重命名。
abstract final class LearningEventTypes {
  static const String studyCompleted = 'study_completed';
  static const String review = 'review';
  static const String practiceAnswered = 'practice_answered';
}
