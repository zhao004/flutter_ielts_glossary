import 'package:drift/drift.dart';

import '../database/user/user_database.dart';
import '../models/domain/learning_event_types.dart';
import '../models/domain/review_memory_rate.dart';
import '../models/domain/review_rating.dart';
import '../models/domain/study_rating.dart';
import '../models/domain/word_learning_state.dart';
import '../services/clock/app_clock.dart';
import '../services/id/id_generator.dart';
import '../services/review/review_scheduler.dart';
import '../services/review/study_rating_policy.dart';
import 'learning_repository.dart';

/// 用户尚未形成有效学习状态时不能提交复习结果。
final class ReviewStateNotFoundException implements Exception {
  const ReviewStateNotFoundException(this.wordId);

  final int wordId;

  @override
  String toString() => 'review_state_not_found: $wordId';
}

/// 尚未翻开学习卡时不能提交自评等级。
final class StudyStateNotFoundException implements Exception {
  const StudyStateNotFoundException(this.wordId);

  final int wordId;

  @override
  String toString() => 'study_state_not_found: $wordId';
}

/// 使用 UserDatabase 事务持久化状态变更和不可变学习事件。
final class LocalLearningRepository implements LearningRepository {
  LocalLearningRepository(
    this._database, {
    this.clock = const SystemAppClock(),
    this.scheduler = const ReviewScheduler(),
    this.idGenerator = const UuidIdGenerator(),
    this.ratingPolicy = const ReferenceStudyRatingPolicy(),
  });

  final UserDatabase _database;
  final AppClock clock;
  final ReviewScheduler scheduler;
  final IdGenerator idGenerator;
  final StudyRatingPolicy ratingPolicy;

  @override
  Future<WordLearningState?> findWordState(int wordId) async {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    final state = await _database.userDataDao.findWordState(wordId);
    return state == null ? null : _toDomain(state);
  }

  @override
  Future<List<WordLearningState>> findWordStatesByIds(Set<int> wordIds) async {
    if (wordIds.any((wordId) => wordId <= 0) || wordIds.length > 500) {
      throw ArgumentError.value(wordIds, 'wordIds', '单词 ID 集合无效');
    }
    final states = await _database.userDataDao.findWordStatesByIds(wordIds);
    return states.map(_toDomain).toList(growable: false);
  }

  @override
  Future<WordLearningState> recordStudyCompletion({
    required int wordId,
    String? sessionId,
  }) {
    final normalizedSessionId = _validateInput(wordId, sessionId);
    final now = clock.nowUtc().toUtc();
    final eventId = _nextEventId();
    return _database.transaction(() async {
      final existing = await _database.userDataDao.findWordState(wordId);
      final initial = scheduler.scheduleInitialStudy(now);
      final masteryLevel = existing?.masteryLevel ?? initial.masteryLevel;
      final nextReviewAt =
          existing?.nextReviewAt ??
          now.add(scheduler.intervalForLevel(masteryLevel));
      await _database.userDataDao.upsertWordState(
        UserWordStatesCompanion.insert(
          wordId: Value(wordId),
          masteryLevel: Value(masteryLevel),
          studiedCount: Value((existing?.studiedCount ?? 0) + 1),
          correctCount: Value(existing?.correctCount ?? 0),
          wrongCount: Value(existing?.wrongCount ?? 0),
          correctStreak: Value(existing?.correctStreak ?? 0),
          consecutiveForgottenCount: Value(
            existing?.consecutiveForgottenCount ?? 0,
          ),
          lastStudiedAt: Value(now),
          lastReviewedAt: Value(existing?.lastReviewedAt),
          nextReviewAt: Value(nextReviewAt),
          updatedAt: now,
        ),
      );
      await _insertLearningEvent(
        id: eventId,
        eventType: LearningEventTypes.studyCompleted,
        wordId: wordId,
        sessionId: normalizedSessionId,
        isCorrect: null,
        reviewRating: null,
        occurredAt: now,
      );
      return _readRequiredState(wordId);
    });
  }

  @override
  Future<WordLearningState> recordReview({
    required int wordId,
    required ReviewRating rating,
    String? sessionId,
  }) {
    final normalizedSessionId = _validateInput(wordId, sessionId);
    final now = clock.nowUtc().toUtc();
    final eventId = _nextEventId();
    return _database.transaction(() async {
      final existing = await _database.userDataDao.findWordState(wordId);
      if (existing == null || existing.studiedCount <= 0) {
        throw ReviewStateNotFoundException(wordId);
      }
      final schedule = scheduler.scheduleReview(
        currentMasteryLevel: existing.masteryLevel,
        rating: rating,
        now: now,
      );
      final recalled = rating.recalled;
      final forgot = rating == ReviewRating.again;
      await _database.userDataDao.upsertWordState(
        UserWordStatesCompanion.insert(
          wordId: Value(wordId),
          masteryLevel: Value(schedule.masteryLevel),
          studiedCount: Value(existing.studiedCount + 1),
          correctCount: Value(existing.correctCount + (recalled ? 1 : 0)),
          wrongCount: Value(existing.wrongCount + (recalled ? 0 : 1)),
          correctStreak: Value(recalled ? existing.correctStreak + 1 : 0),
          consecutiveForgottenCount: Value(
            forgot ? existing.consecutiveForgottenCount + 1 : 0,
          ),
          lastStudiedAt: Value(now),
          lastReviewedAt: Value(now),
          nextReviewAt: Value(schedule.nextReviewAt),
          updatedAt: now,
        ),
      );
      await _insertLearningEvent(
        id: eventId,
        eventType: LearningEventTypes.review,
        wordId: wordId,
        sessionId: normalizedSessionId,
        isCorrect: recalled,
        reviewRating: rating,
        occurredAt: now,
      );
      return _readRequiredState(wordId);
    });
  }

  @override
  Future<WordLearningState> applyStudyRating({
    required int wordId,
    required StudyRating rating,
  }) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', 'wordId 必须为正整数');
    }
    final now = clock.nowUtc().toUtc();
    return _database.transaction(() async {
      final existing = await _database.userDataDao.findWordState(wordId);
      if (existing == null || existing.studiedCount <= 0) {
        throw StudyStateNotFoundException(wordId);
      }
      final masteryLevel = ratingPolicy.masteryLevelFor(rating);
      final nextReviewAt = now.add(scheduler.intervalForLevel(masteryLevel));
      await _database.userDataDao.upsertWordState(
        UserWordStatesCompanion.insert(
          wordId: Value(wordId),
          masteryLevel: Value(masteryLevel),
          studiedCount: Value(existing.studiedCount),
          correctCount: Value(existing.correctCount),
          wrongCount: Value(existing.wrongCount),
          correctStreak: Value(existing.correctStreak),
          consecutiveForgottenCount: Value(existing.consecutiveForgottenCount),
          lastStudiedAt: Value(existing.lastStudiedAt),
          lastReviewedAt: Value(existing.lastReviewedAt),
          nextReviewAt: Value(nextReviewAt),
          updatedAt: now,
        ),
      );
      return _readRequiredState(wordId);
    });
  }

  @override
  Future<List<WordLearningState>> findDueReviews({int limit = 100}) async {
    final rows = await _database.userDataDao.findDueWordStates(
      now: clock.nowUtc(),
      limit: limit,
    );
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<ReviewMemoryRate> getReviewMemoryRate({Duration? window}) async {
    if (window != null && window <= Duration.zero) {
      throw ArgumentError.value(window, 'window', '统计窗口必须大于 0');
    }
    final since = window == null
        ? null
        : clock.nowUtc().toUtc().subtract(window);
    final counts = await _database.userDataDao.countReviewOutcomes(
      eventType: LearningEventTypes.review,
      since: since,
    );
    return ReviewMemoryRate(
      correctReviews: counts.correct,
      completedReviews: counts.completed,
    );
  }

  Future<void> _insertLearningEvent({
    required String id,
    required String eventType,
    required int wordId,
    required String? sessionId,
    required bool? isCorrect,
    required ReviewRating? reviewRating,
    required DateTime occurredAt,
  }) {
    return _database.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: id,
        eventType: eventType,
        wordId: wordId,
        sessionId: Value(sessionId),
        isCorrect: Value(isCorrect),
        reviewRating: Value(reviewRating?.name),
        occurredAt: occurredAt,
      ),
    );
  }

  Future<WordLearningState> _readRequiredState(int wordId) async {
    final state = await _database.userDataDao.findWordState(wordId);
    if (state == null) {
      throw StateError('事务写入后缺少单词学习状态');
    }
    return _toDomain(state);
  }

  WordLearningState _toDomain(UserWordState state) {
    return WordLearningState(
      wordId: state.wordId,
      masteryLevel: state.masteryLevel,
      studiedCount: state.studiedCount,
      correctCount: state.correctCount,
      wrongCount: state.wrongCount,
      correctStreak: state.correctStreak,
      consecutiveForgottenCount: state.consecutiveForgottenCount,
      lastStudiedAt: state.lastStudiedAt,
      lastReviewedAt: state.lastReviewedAt,
      nextReviewAt: state.nextReviewAt,
      updatedAt: state.updatedAt,
    );
  }

  String _nextEventId() {
    final id = idGenerator.nextId().trim();
    if (id.isEmpty || id.length > 64) {
      throw StateError('ID 生成器返回了无效事件 ID');
    }
    return id;
  }

  String? _validateInput(int wordId, String? sessionId) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId != null &&
        (normalizedSessionId.isEmpty || normalizedSessionId.length > 64)) {
      throw ArgumentError.value(sessionId, 'sessionId', '会话 ID 长度必须在 1-64 之间');
    }
    return normalizedSessionId;
  }
}
