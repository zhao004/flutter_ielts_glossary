import 'package:drift/drift.dart';

import '../database/user/daos/user_data_dao.dart';
import '../database/user/user_database.dart';
import '../models/domain/learning_event_types.dart';
import '../models/domain/practice_session.dart';
import '../models/domain/question_config.dart';
import '../services/clock/app_clock.dart';
import '../services/id/id_generator.dart';
import '../services/question/question_config_codec.dart';
import 'practice_repository.dart';

final class PracticeSessionNotFoundException implements Exception {
  const PracticeSessionNotFoundException(this.sessionId);

  final String sessionId;
}

final class PracticeSessionFinishedException implements Exception {
  const PracticeSessionFinishedException(this.sessionId);

  final String sessionId;
}

final class DuplicatePracticeAnswerException implements Exception {
  const DuplicatePracticeAnswerException({
    required this.sessionId,
    required this.wordId,
  });

  final String sessionId;
  final int wordId;
}

final class IncompletePracticeSessionException implements Exception {
  const IncompletePracticeSessionException({
    required this.sessionId,
    required this.answeredCount,
    required this.requiredCount,
  });

  final String sessionId;
  final int answeredCount;
  final int requiredCount;
}

/// 事务化保存会话、答案和学习事件；普通练习暂不改变掌握等级。
final class LocalPracticeRepository implements PracticeRepository {
  LocalPracticeRepository(
    this._database, {
    this.clock = const SystemAppClock(),
    this.idGenerator = const UuidIdGenerator(),
    this.configCodec = const QuestionConfigCodec(),
  });

  static const int maximumUserAnswerLength = 1000;
  static const Duration maximumResponseTime = Duration(hours: 24);
  static const Duration maximumSessionElapsed = Duration(days: 7);

  final UserDatabase _database;
  final AppClock clock;
  final IdGenerator idGenerator;
  final QuestionConfigCodec configCodec;

  @override
  Future<PracticeSessionRecord> startSession(QuestionConfig config) async {
    final sessionId = _nextId('sessionId');
    final startedAt = clock.nowUtc().toUtc();
    final configJson = configCodec.encode(config);
    await _database.userDataDao.insertPracticeSession(
      PracticeSessionsCompanion.insert(
        id: sessionId,
        type: QuestionTypeStorage.encode(config.type),
        configJson: configJson,
        startedAt: startedAt,
        totalQuestionCount: Value(config.questionCount),
      ),
    );
    return PracticeSessionRecord(
      id: sessionId,
      config: config,
      startedAt: startedAt,
      finishedAt: null,
      answeredQuestionCount: 0,
      correctCount: 0,
      elapsed: Duration.zero,
    );
  }

  @override
  Future<PracticeAnswerRecord> recordAnswer({
    required String sessionId,
    required int wordId,
    int? sentenceId,
    required String userAnswer,
    required bool isCorrect,
    required Duration responseTime,
  }) async {
    final normalizedSessionId = _normalizeRecordId(sessionId, 'sessionId');
    _validateAnswer(
      wordId: wordId,
      sentenceId: sentenceId,
      userAnswer: userAnswer,
      responseTime: responseTime,
    );
    final answerId = _nextId('answerId');
    final eventId = _nextId('eventId');
    final answeredAt = clock.nowUtc().toUtc();
    return _database.transaction(() async {
      final session = await _requiredSession(normalizedSessionId);
      if (session.finishedAt != null) {
        throw PracticeSessionFinishedException(normalizedSessionId);
      }
      final duplicate = await _database.userDataDao.findPracticeAnswerByWord(
        sessionId: normalizedSessionId,
        wordId: wordId,
      );
      if (duplicate != null) {
        throw DuplicatePracticeAnswerException(
          sessionId: normalizedSessionId,
          wordId: wordId,
        );
      }
      final counts = await _database.userDataDao.countPracticeAnswers(
        normalizedSessionId,
      );
      if (counts.answered >= session.totalQuestionCount) {
        throw PracticeSessionFinishedException(normalizedSessionId);
      }

      await _database.userDataDao.insertPracticeAnswer(
        PracticeAnswersCompanion.insert(
          id: answerId,
          sessionId: normalizedSessionId,
          wordId: wordId,
          sentenceId: Value(sentenceId),
          userAnswer: userAnswer,
          isCorrect: isCorrect,
          responseTimeMilliseconds: responseTime.inMilliseconds,
          answeredAt: answeredAt,
        ),
      );
      await _database.userDataDao.insertLearningEvent(
        LearningEventsCompanion.insert(
          id: eventId,
          eventType: LearningEventTypes.practiceAnswered,
          wordId: wordId,
          sessionId: Value(normalizedSessionId),
          isCorrect: Value(isCorrect),
          occurredAt: answeredAt,
        ),
      );
      return PracticeAnswerRecord(
        id: answerId,
        sessionId: normalizedSessionId,
        wordId: wordId,
        sentenceId: sentenceId,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        responseTime: responseTime,
        answeredAt: answeredAt,
      );
    });
  }

  @override
  Future<PracticeSessionRecord> finishSession({
    required String sessionId,
    required Duration elapsed,
  }) async {
    final normalizedSessionId = _normalizeRecordId(sessionId, 'sessionId');
    if (elapsed.isNegative || elapsed > maximumSessionElapsed) {
      throw ArgumentError.value(elapsed, 'elapsed', '会话耗时超出允许范围');
    }
    final currentTime = clock.nowUtc().toUtc();
    return _database.transaction(() async {
      final session = await _requiredSession(normalizedSessionId);
      if (session.finishedAt != null) {
        throw PracticeSessionFinishedException(normalizedSessionId);
      }
      final counts = await _database.userDataDao.countPracticeAnswers(
        normalizedSessionId,
      );
      if (counts.answered != session.totalQuestionCount) {
        throw IncompletePracticeSessionException(
          sessionId: normalizedSessionId,
          answeredCount: counts.answered,
          requiredCount: session.totalQuestionCount,
        );
      }
      if (elapsed.inMilliseconds < counts.responseTimeMilliseconds) {
        throw ArgumentError.value(elapsed, 'elapsed', '会话总耗时不能小于逐题响应耗时之和');
      }
      final finishedAt = currentTime.isBefore(session.startedAt)
          ? session.startedAt
          : currentTime;
      final updated = await _database.userDataDao.completePracticeSession(
        sessionId: normalizedSessionId,
        finishedAt: finishedAt,
        correctCount: counts.correct,
        elapsedMilliseconds: elapsed.inMilliseconds,
      );
      if (updated != 1) {
        throw PracticeSessionFinishedException(normalizedSessionId);
      }
      final completed = await _requiredSession(normalizedSessionId);
      return _toDomain(completed, counts);
    });
  }

  @override
  Future<PracticeSessionRecord?> findSession(String sessionId) async {
    final normalizedSessionId = _normalizeRecordId(sessionId, 'sessionId');
    final session = await _database.userDataDao.findPracticeSession(
      normalizedSessionId,
    );
    if (session == null) {
      return null;
    }
    final counts = await _database.userDataDao.countPracticeAnswers(
      normalizedSessionId,
    );
    return _toDomain(session, counts);
  }

  Future<PracticeSession> _requiredSession(String sessionId) async {
    final session = await _database.userDataDao.findPracticeSession(sessionId);
    if (session == null) {
      throw PracticeSessionNotFoundException(sessionId);
    }
    return session;
  }

  PracticeSessionRecord _toDomain(
    PracticeSession session,
    PracticeAnswerCounts counts,
  ) {
    final config = configCodec.decode(session.configJson);
    if (session.type != QuestionTypeStorage.encode(config.type) ||
        session.totalQuestionCount != config.questionCount) {
      throw StateError('练习会话类型或题量与配置不一致');
    }
    if (session.finishedAt != null && session.correctCount != counts.correct) {
      throw StateError('练习会话正确数与答案事实不一致');
    }
    return PracticeSessionRecord(
      id: session.id,
      config: config,
      startedAt: session.startedAt,
      finishedAt: session.finishedAt,
      answeredQuestionCount: counts.answered,
      correctCount: counts.correct,
      elapsed: Duration(milliseconds: session.elapsedMilliseconds),
    );
  }

  void _validateAnswer({
    required int wordId,
    required int? sentenceId,
    required String userAnswer,
    required Duration responseTime,
  }) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    if (sentenceId != null && sentenceId <= 0) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '例句 ID 必须为正整数');
    }
    if (userAnswer.length > maximumUserAnswerLength) {
      throw ArgumentError.value(
        userAnswer.length,
        'userAnswer',
        '用户答案长度不能超过 $maximumUserAnswerLength',
      );
    }
    if (responseTime.isNegative || responseTime > maximumResponseTime) {
      throw ArgumentError.value(responseTime, 'responseTime', '单题响应耗时超出允许范围');
    }
  }

  String _nextId(String name) {
    return _normalizeRecordId(idGenerator.nextId(), name);
  }

  String _normalizeRecordId(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 64) {
      throw ArgumentError.value(value, name, '记录 ID 长度必须在 1-64 之间');
    }
    return normalized;
  }
}
