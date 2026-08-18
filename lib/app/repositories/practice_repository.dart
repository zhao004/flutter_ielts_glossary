import '../models/domain/practice_session.dart';
import '../models/domain/question_config.dart';

/// 练习会话、逐题答案和完成统计的领域接口。
abstract interface class PracticeRepository {
  Future<PracticeSessionRecord> startSession(QuestionConfig config);

  Future<PracticeAnswerRecord> recordAnswer({
    required String sessionId,
    required int wordId,
    int? sentenceId,
    required String userAnswer,
    required bool isCorrect,
    required Duration responseTime,
  });

  Future<PracticeSessionRecord> finishSession({
    required String sessionId,
    required Duration elapsed,
  });

  Future<PracticeSessionRecord?> findSession(String sessionId);
}
