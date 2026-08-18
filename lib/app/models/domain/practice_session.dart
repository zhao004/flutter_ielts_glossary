import 'question_config.dart';

/// 页面可消费的练习会话快照，不暴露 Drift 数据类。
final class PracticeSessionRecord {
  PracticeSessionRecord({
    required String id,
    required this.config,
    required DateTime startedAt,
    required DateTime? finishedAt,
    required this.answeredQuestionCount,
    required this.correctCount,
    required this.elapsed,
  }) : id = _requireRecordId(id, 'id'),
       startedAt = startedAt.toUtc(),
       finishedAt = finishedAt?.toUtc() {
    if (answeredQuestionCount < 0 ||
        answeredQuestionCount > config.questionCount) {
      throw ArgumentError.value(
        answeredQuestionCount,
        'answeredQuestionCount',
        '已答题数量超出会话范围',
      );
    }
    if (correctCount < 0 || correctCount > answeredQuestionCount) {
      throw ArgumentError.value(correctCount, 'correctCount', '正确数量无效');
    }
    if (elapsed.isNegative) {
      throw ArgumentError.value(elapsed, 'elapsed', '会话耗时不能为负数');
    }
    if (this.finishedAt != null && this.finishedAt!.isBefore(this.startedAt)) {
      throw ArgumentError('会话结束时间不能早于开始时间');
    }
  }

  final String id;
  final QuestionConfig config;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int answeredQuestionCount;
  final int correctCount;
  final Duration elapsed;

  int get totalQuestionCount => config.questionCount;
  bool get isFinished => finishedAt != null;
  double get accuracy =>
      answeredQuestionCount == 0 ? 0 : correctCount / answeredQuestionCount;
}

/// 已持久化的单题作答事实。
final class PracticeAnswerRecord {
  PracticeAnswerRecord({
    required String id,
    required String sessionId,
    required this.wordId,
    required this.sentenceId,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTime,
    required DateTime answeredAt,
  }) : id = _requireRecordId(id, 'id'),
       sessionId = _requireRecordId(sessionId, 'sessionId'),
       answeredAt = answeredAt.toUtc() {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    if (sentenceId != null && sentenceId! <= 0) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '例句 ID 必须为正整数');
    }
    if (responseTime.isNegative) {
      throw ArgumentError.value(responseTime, 'responseTime', '单题响应耗时不能为负数');
    }
  }

  final String id;
  final String sessionId;
  final int wordId;
  final int? sentenceId;
  final String userAnswer;
  final bool isCorrect;
  final Duration responseTime;
  final DateTime answeredAt;
}

String _requireRecordId(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 64) {
    throw ArgumentError.value(value, name, '记录 ID 长度必须在 1-64 之间');
  }
  return normalized;
}
