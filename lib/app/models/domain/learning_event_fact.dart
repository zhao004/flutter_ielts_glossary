/// 统计服务需要的最小学习事件投影，不暴露 Drift 数据对象或用户答案正文。
final class LearningEventFact {
  LearningEventFact({required DateTime occurredAt, required this.isCorrect})
    : occurredAtUtc = occurredAt.toUtc();

  final DateTime occurredAtUtc;
  final bool? isCorrect;
}
