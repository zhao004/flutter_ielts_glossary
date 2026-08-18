import 'package:drift/drift.dart';

import '../tables/app_settings.dart';
import '../tables/backup_history.dart';
import '../tables/favorite_sentences.dart';
import '../tables/favorite_words.dart';
import '../tables/learning_events.dart';
import '../tables/practice_answers.dart';
import '../tables/practice_sessions.dart';
import '../tables/user_word_states.dart';
import '../user_database.dart';
import '../../../models/domain/learning_event_fact.dart';

part 'user_data_dao.g.dart';

/// DAO 层返回的复习结果计数，由 Repository 转换为领域记忆率。
final class ReviewOutcomeCounts {
  const ReviewOutcomeCounts({required this.correct, required this.completed});

  final int correct;
  final int completed;
}

/// 单个练习会话的答案计数和累计响应耗时。
final class PracticeAnswerCounts {
  const PracticeAnswerCounts({
    required this.answered,
    required this.correct,
    required this.responseTimeMilliseconds,
  });

  final int answered;
  final int correct;
  final int responseTimeMilliseconds;
}

/// 首页所需的用户状态和收藏计数。
final class UserStatisticsCounts {
  const UserStatisticsCounts({
    required this.dueReviewCount,
    required this.masteredWordCount,
    required this.learningWordCount,
    required this.favoriteWordCount,
    required this.favoriteSentenceCount,
  });

  final int dueReviewCount;
  final int masteredWordCount;
  final int learningWordCount;
  final int favoriteWordCount;
  final int favoriteSentenceCount;
}

/// 备份导出的一致性用户库行快照；BackupHistory 不包含在内。
final class UserBackupRows {
  const UserBackupRows({
    required this.userWordStates,
    required this.favoriteWords,
    required this.favoriteSentences,
    required this.practiceSessions,
    required this.practiceAnswers,
    required this.learningEvents,
    required this.appSettings,
  });

  final List<UserWordState> userWordStates;
  final List<FavoriteWord> favoriteWords;
  final List<FavoriteSentence> favoriteSentences;
  final List<PracticeSession> practiceSessions;
  final List<PracticeAnswer> practiceAnswers;
  final List<LearningEvent> learningEvents;
  final AppSetting? appSettings;
}

/// 集中管理用户库的基础读写；跨表业务事务由 Repository 编排。
@DriftAccessor(
  tables: [
    UserWordStates,
    FavoriteWords,
    FavoriteSentences,
    PracticeSessions,
    PracticeAnswers,
    LearningEvents,
    AppSettings,
    BackupHistory,
  ],
)
class UserDataDao extends DatabaseAccessor<UserDatabase>
    with _$UserDataDaoMixin {
  UserDataDao(super.attachedDatabase);

  static const int defaultQueryLimit = 100;
  static const int maxQueryLimit = 500;

  /// 在调用方事务中按固定顺序读取所有可备份用户表。
  Future<UserBackupRows> readBackupRows() async {
    return UserBackupRows(
      userWordStates: await select(userWordStates).get(),
      favoriteWords: await select(favoriteWords).get(),
      favoriteSentences: await select(favoriteSentences).get(),
      practiceSessions: await select(practiceSessions).get(),
      practiceAnswers: await select(practiceAnswers).get(),
      learningEvents: await select(learningEvents).get(),
      appSettings: await (select(
        appSettings,
      )..where((row) => row.id.equals(1))).getSingleOrNull(),
    );
  }

  /// 清空可恢复业务表；保留 BackupHistory 供结果追踪和审计。
  Future<void> clearRecoverableData() async {
    await delete(practiceAnswers).go();
    await delete(learningEvents).go();
    await delete(practiceSessions).go();
    await delete(favoriteWords).go();
    await delete(favoriteSentences).go();
    await delete(userWordStates).go();
    await delete(appSettings).go();
  }

  /// 插入或覆盖同一稳定 wordId 的学习状态。
  Future<void> upsertWordState(UserWordStatesCompanion state) async {
    await into(userWordStates).insertOnConflictUpdate(state);
  }

  /// 查询指定稳定 wordId 的用户学习状态。
  Future<UserWordState?> findWordState(int wordId) {
    _validateContentId(wordId, 'wordId');
    return (select(
      userWordStates,
    )..where((row) => row.wordId.equals(wordId))).getSingleOrNull();
  }

  /// 在当前列表页的受限单词集合内批量查询学习状态。
  Future<List<UserWordState>> findWordStatesByIds(Set<int> wordIds) {
    _validateContentIds(wordIds, 'wordIds');
    if (wordIds.isEmpty) {
      return Future.value(const <UserWordState>[]);
    }
    final query = select(userWordStates)
      ..where((row) => row.wordId.isIn(wordIds))
      ..orderBy([(row) => OrderingTerm.asc(row.wordId)]);
    return query.get();
  }

  /// 按最近一次答错时间分页返回历史错题单词 ID。
  Future<List<int>> findRecentWrongWordIds({
    int limit = defaultQueryLimit,
    int offset = 0,
  }) async {
    _validateLimit(limit);
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', '查询偏移不能小于 0');
    }
    final rows = await customSelect(
      '''
        SELECT word_id, MAX(answered_at) AS last_wrong_at
        FROM practice_answers
        WHERE is_correct = 0
        GROUP BY word_id
        ORDER BY last_wrong_at DESC, word_id ASC
        LIMIT ? OFFSET ?
      ''',
      variables: [Variable<int>(limit), Variable<int>(offset)],
      readsFrom: {practiceAnswers},
    ).get();
    return rows.map((row) => row.read<int>('word_id')).toList(growable: false);
  }

  /// 只在给定受限候选池内查询历史错题状态。
  Future<Set<int>> findHistoricallyWrongWordIds(Set<int> wordIds) async {
    if (wordIds.isEmpty) {
      return const <int>{};
    }
    if (wordIds.length > maxQueryLimit || wordIds.any((id) => id <= 0)) {
      throw ArgumentError.value(wordIds, 'wordIds', '错题状态查询 ID 集合无效');
    }
    final query = selectOnly(practiceAnswers, distinct: true)
      ..addColumns([practiceAnswers.wordId])
      ..where(
        practiceAnswers.wordId.isIn(wordIds) &
            practiceAnswers.isCorrect.equals(false),
      );
    final rows = await query.get();
    return rows
        .map((row) => row.read(practiceAnswers.wordId))
        .whereType<int>()
        .toSet();
  }

  /// 新建尚未完成的练习会话。
  Future<void> insertPracticeSession(PracticeSessionsCompanion session) async {
    await into(practiceSessions).insert(session);
  }

  /// 导入合并时按 UUID 忽略已经存在的练习会话。
  Future<void> insertPracticeSessionIfAbsent(
    PracticeSessionsCompanion session,
  ) async {
    await into(
      practiceSessions,
    ).insert(session, mode: InsertMode.insertOrIgnore);
  }

  /// 按稳定 ID 查询练习会话。
  Future<PracticeSession?> findPracticeSession(String sessionId) {
    final normalizedId = _normalizeRecordId(sessionId, 'sessionId');
    return (select(
      practiceSessions,
    )..where((row) => row.id.equals(normalizedId))).getSingleOrNull();
  }

  /// 写入不可变的单题答案。
  Future<void> insertPracticeAnswer(PracticeAnswersCompanion answer) async {
    await into(practiceAnswers).insert(answer);
  }

  /// 导入合并时按 UUID 忽略已经存在的答案。
  Future<void> insertPracticeAnswerIfAbsent(
    PracticeAnswersCompanion answer,
  ) async {
    await into(practiceAnswers).insert(answer, mode: InsertMode.insertOrIgnore);
  }

  /// 查询同一会话是否已经回答过指定单词。
  Future<PracticeAnswer?> findPracticeAnswerByWord({
    required String sessionId,
    required int wordId,
  }) {
    final normalizedId = _normalizeRecordId(sessionId, 'sessionId');
    _validateContentId(wordId, 'wordId');
    return (select(practiceAnswers)..where(
          (row) =>
              row.sessionId.equals(normalizedId) & row.wordId.equals(wordId),
        ))
        .getSingleOrNull();
  }

  /// 汇总会话已答题数、正确数和逐题响应耗时。
  Future<PracticeAnswerCounts> countPracticeAnswers(String sessionId) async {
    final normalizedId = _normalizeRecordId(sessionId, 'sessionId');
    final row = await customSelect(
      '''
        SELECT
          COUNT(*) AS answered_count,
          COALESCE(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END), 0)
            AS correct_count,
          COALESCE(SUM(response_time_milliseconds), 0)
            AS response_time_milliseconds
        FROM practice_answers
        WHERE session_id = ?
      ''',
      variables: [Variable<String>(normalizedId)],
      readsFrom: {practiceAnswers},
    ).getSingle();
    return PracticeAnswerCounts(
      answered: row.read<int>('answered_count'),
      correct: row.read<int>('correct_count'),
      responseTimeMilliseconds: row.read<int>('response_time_milliseconds'),
    );
  }

  /// 只允许把未完成会话更新为完成状态，返回实际更新行数。
  Future<int> completePracticeSession({
    required String sessionId,
    required DateTime finishedAt,
    required int correctCount,
    required int elapsedMilliseconds,
  }) {
    final normalizedId = _normalizeRecordId(sessionId, 'sessionId');
    if (correctCount < 0 || elapsedMilliseconds < 0) {
      throw ArgumentError('练习完成统计不能为负数');
    }
    return (update(practiceSessions)..where(
          (row) => row.id.equals(normalizedId) & row.finishedAt.isNull(),
        ))
        .write(
          PracticeSessionsCompanion(
            finishedAt: Value(finishedAt.toUtc()),
            correctCount: Value(correctCount),
            elapsedMilliseconds: Value(elapsedMilliseconds),
          ),
        );
  }

  /// 查询已经发生过学习且到期的复习项，按最早到期时间排序。
  Future<List<UserWordState>> findDueWordStates({
    required DateTime now,
    int limit = defaultQueryLimit,
  }) {
    _validateLimit(limit);
    final query = select(userWordStates)
      ..where(
        (row) =>
            row.studiedCount.isBiggerThanValue(0) &
            row.nextReviewAt.isNotNull() &
            row.nextReviewAt.isSmallerOrEqualValue(
              now.toUtc().millisecondsSinceEpoch,
            ),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.nextReviewAt)])
      ..limit(limit);
    return query.get();
  }

  /// 新增单词收藏；wordId 唯一约束阻止重复收藏。
  Future<void> insertFavoriteWord(FavoriteWordsCompanion favorite) async {
    await into(favoriteWords).insert(favorite);
  }

  /// 并发收藏时忽略已经存在的单词关系，其他字段错误仍由后续读取暴露。
  Future<void> insertFavoriteWordIfAbsent(
    FavoriteWordsCompanion favorite,
  ) async {
    await into(favoriteWords).insert(favorite, mode: InsertMode.insertOrIgnore);
  }

  /// 按稳定主键覆盖单词收藏；调用方应先按 wordId 处理唯一索引冲突。
  Future<void> upsertFavoriteWord(FavoriteWordsCompanion favorite) async {
    await into(favoriteWords).insertOnConflictUpdate(favorite);
  }

  /// 按稳定单词 ID 查询收藏关系。
  Future<FavoriteWord?> findFavoriteWord(int wordId) {
    _validateContentId(wordId, 'wordId');
    return (select(
      favoriteWords,
    )..where((row) => row.wordId.equals(wordId))).getSingleOrNull();
  }

  /// 按收藏记录 UUID 查询单词收藏，供导入冲突校验使用。
  Future<FavoriteWord?> findFavoriteWordByRecordId(String id) {
    final normalizedId = _normalizeRecordId(id, 'favoriteWordId');
    return (select(
      favoriteWords,
    )..where((row) => row.id.equals(normalizedId))).getSingleOrNull();
  }

  /// 在当前列表页的受限单词集合内批量查询收藏状态。
  Future<Set<int>> findFavoriteWordIds(Set<int> wordIds) async {
    _validateContentIds(wordIds, 'wordIds');
    if (wordIds.isEmpty) {
      return const <int>{};
    }
    final query = selectOnly(favoriteWords)
      ..addColumns([favoriteWords.wordId])
      ..where(favoriteWords.wordId.isIn(wordIds));
    final rows = await query.get();
    return rows
        .map((row) => row.read(favoriteWords.wordId))
        .whereType<int>()
        .toSet();
  }

  /// 按最近收藏时间分页返回单词收藏关系。
  Future<List<FavoriteWord>> findFavoriteWords({
    int limit = defaultQueryLimit,
    int offset = 0,
  }) {
    _validatePagination(limit: limit, offset: offset);
    final query = select(favoriteWords)
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAt),
        (row) => OrderingTerm.asc(row.id),
      ])
      ..limit(limit, offset: offset);
    return query.get();
  }

  /// 删除指定单词的收藏关系。
  Future<int> deleteFavoriteWord(int wordId) {
    _validateContentId(wordId, 'wordId');
    return (delete(
      favoriteWords,
    )..where((row) => row.wordId.equals(wordId))).go();
  }

  /// 在单条 SQL 中原子删除当前页面选择的单词收藏。
  Future<int> deleteFavoriteWords(Set<int> wordIds) {
    _validateContentIds(wordIds, 'wordIds');
    if (wordIds.isEmpty) {
      return Future<int>.value(0);
    }
    return (delete(
      favoriteWords,
    )..where((row) => row.wordId.isIn(wordIds))).go();
  }

  /// 按收藏记录 UUID 删除单词收藏，供导入替换唯一内容关系。
  Future<int> deleteFavoriteWordByRecordId(String id) {
    final normalizedId = _normalizeRecordId(id, 'favoriteWordId');
    return (delete(
      favoriteWords,
    )..where((row) => row.id.equals(normalizedId))).go();
  }

  /// 新增例句收藏；sentenceId 唯一约束阻止重复收藏。
  Future<void> insertFavoriteSentence(
    FavoriteSentencesCompanion favorite,
  ) async {
    await into(favoriteSentences).insert(favorite);
  }

  /// 并发收藏时忽略已经存在的例句关系。
  Future<void> insertFavoriteSentenceIfAbsent(
    FavoriteSentencesCompanion favorite,
  ) async {
    await into(
      favoriteSentences,
    ).insert(favorite, mode: InsertMode.insertOrIgnore);
  }

  /// 按稳定主键覆盖例句收藏；调用方应先按 sentenceId 处理唯一索引冲突。
  Future<void> upsertFavoriteSentence(
    FavoriteSentencesCompanion favorite,
  ) async {
    await into(favoriteSentences).insertOnConflictUpdate(favorite);
  }

  /// 按稳定例句 ID 查询收藏关系。
  Future<FavoriteSentence?> findFavoriteSentence(int sentenceId) {
    _validateContentId(sentenceId, 'sentenceId');
    return (select(
      favoriteSentences,
    )..where((row) => row.sentenceId.equals(sentenceId))).getSingleOrNull();
  }

  /// 按收藏记录 UUID 查询例句收藏，供导入冲突校验使用。
  Future<FavoriteSentence?> findFavoriteSentenceByRecordId(String id) {
    final normalizedId = _normalizeRecordId(id, 'favoriteSentenceId');
    return (select(
      favoriteSentences,
    )..where((row) => row.id.equals(normalizedId))).getSingleOrNull();
  }

  /// 在当前详情页的受限例句集合内批量查询收藏状态。
  Future<Set<int>> findFavoriteSentenceIds(Set<int> sentenceIds) async {
    _validateContentIds(sentenceIds, 'sentenceIds');
    if (sentenceIds.isEmpty) {
      return const <int>{};
    }
    final query = selectOnly(favoriteSentences)
      ..addColumns([favoriteSentences.sentenceId])
      ..where(favoriteSentences.sentenceId.isIn(sentenceIds));
    final rows = await query.get();
    return rows
        .map((row) => row.read(favoriteSentences.sentenceId))
        .whereType<int>()
        .toSet();
  }

  /// 按最近收藏时间分页返回例句收藏关系。
  Future<List<FavoriteSentence>> findFavoriteSentences({
    int limit = defaultQueryLimit,
    int offset = 0,
  }) {
    _validatePagination(limit: limit, offset: offset);
    final query = select(favoriteSentences)
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAt),
        (row) => OrderingTerm.asc(row.id),
      ])
      ..limit(limit, offset: offset);
    return query.get();
  }

  /// 删除指定例句的收藏关系。
  Future<int> deleteFavoriteSentence(int sentenceId) {
    _validateContentId(sentenceId, 'sentenceId');
    return (delete(
      favoriteSentences,
    )..where((row) => row.sentenceId.equals(sentenceId))).go();
  }

  /// 在单条 SQL 中原子删除当前页面选择的例句收藏。
  Future<int> deleteFavoriteSentences(Set<int> sentenceIds) {
    _validateContentIds(sentenceIds, 'sentenceIds');
    if (sentenceIds.isEmpty) {
      return Future<int>.value(0);
    }
    return (delete(
      favoriteSentences,
    )..where((row) => row.sentenceId.isIn(sentenceIds))).go();
  }

  /// 按收藏记录 UUID 删除例句收藏，供导入替换唯一内容关系。
  Future<int> deleteFavoriteSentenceByRecordId(String id) {
    final normalizedId = _normalizeRecordId(id, 'favoriteSentenceId');
    return (delete(
      favoriteSentences,
    )..where((row) => row.id.equals(normalizedId))).go();
  }

  /// 写入不可变学习事件，重复 UUID 会由数据库拒绝。
  Future<void> insertLearningEvent(LearningEventsCompanion event) async {
    await into(learningEvents).insert(event);
  }

  /// 导入合并时按 UUID 忽略已经存在的学习事件。
  Future<void> insertLearningEventIfAbsent(
    LearningEventsCompanion event,
  ) async {
    await into(learningEvents).insert(event, mode: InsertMode.insertOrIgnore);
  }

  /// 写入一次导出、导入或自动保护备份的结果记录。
  Future<void> insertBackupHistory(BackupHistoryCompanion history) async {
    await into(backupHistory).insert(history);
  }

  /// 按发生时间倒序读取最近备份历史；摘要正文由上层按需解析。
  Future<List<BackupHistoryData>> findBackupHistory({
    int limit = 20,
    int offset = 0,
  }) {
    _validatePagination(limit: limit, offset: offset);
    final query = select(backupHistory)
      ..orderBy([
        (row) => OrderingTerm.desc(row.occurredAt),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit, offset: offset);
    return query.get();
  }

  /// 统计指定事件类型的已完成数和正确数，时间下界按 UTC 包含计算。
  Future<ReviewOutcomeCounts> countReviewOutcomes({
    required String eventType,
    DateTime? since,
  }) async {
    final normalizedType = eventType.trim();
    if (normalizedType.isEmpty || normalizedType.length > 64) {
      throw ArgumentError.value(eventType, 'eventType', '事件类型长度必须在 1-64 之间');
    }
    final clauses = <String>['event_type = ?', 'is_correct IS NOT NULL'];
    final variables = <Variable>[Variable<String>(normalizedType)];
    if (since != null) {
      clauses.add('occurred_at >= ?');
      variables.add(Variable<int>(since.toUtc().millisecondsSinceEpoch));
    }
    final row = await customSelect(
      '''
        SELECT
          COUNT(*) AS completed_count,
          COALESCE(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END), 0)
            AS correct_count
        FROM learning_events
        WHERE ${clauses.join(' AND ')}
      ''',
      variables: variables,
      readsFrom: {learningEvents},
    ).getSingle();
    return ReviewOutcomeCounts(
      correct: row.read<int>('correct_count'),
      completed: row.read<int>('completed_count'),
    );
  }

  /// 统计首页状态卡片所需的用户库计数，避免把记录全部加载到 Dart。
  Future<UserStatisticsCounts> countUserStatistics({
    required DateTime now,
  }) async {
    final nowMilliseconds = now.toUtc().millisecondsSinceEpoch;
    final row = await customSelect(
      '''
        SELECT
          (SELECT COUNT(*) FROM user_word_states
            WHERE studied_count > 0
              AND next_review_at IS NOT NULL
              AND next_review_at <= ?1) AS due_review_count,
          (SELECT COUNT(*) FROM user_word_states
            WHERE mastery_level = 5) AS mastered_word_count,
          (SELECT COUNT(*) FROM user_word_states
            WHERE mastery_level BETWEEN 1 AND 4) AS learning_word_count,
          (SELECT COUNT(*) FROM favorite_words) AS favorite_word_count,
          (SELECT COUNT(*) FROM favorite_sentences) AS favorite_sentence_count
      ''',
      variables: [Variable<int>(nowMilliseconds)],
      readsFrom: {userWordStates, favoriteWords, favoriteSentences},
    ).getSingle();
    return UserStatisticsCounts(
      dueReviewCount: row.read<int>('due_review_count'),
      masteredWordCount: row.read<int>('mastered_word_count'),
      learningWordCount: row.read<int>('learning_word_count'),
      favoriteWordCount: row.read<int>('favorite_word_count'),
      favoriteSentenceCount: row.read<int>('favorite_sentence_count'),
    );
  }

  /// 分页读取统计所需的最小学习事件投影，答案正文永不离开用户库。
  Future<List<LearningEventFact>> findLearningEventFacts({
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = maxQueryLimit,
    int offset = 0,
    bool descending = false,
  }) async {
    _validatePagination(limit: limit, offset: offset);
    final clauses = <String>[];
    final variables = <Variable>[];
    if (fromUtc != null) {
      clauses.add('occurred_at >= ?');
      variables.add(Variable<int>(fromUtc.toUtc().millisecondsSinceEpoch));
    }
    if (toUtc != null) {
      clauses.add('occurred_at < ?');
      variables.add(Variable<int>(toUtc.toUtc().millisecondsSinceEpoch));
    }
    if (fromUtc != null && toUtc != null && !fromUtc.isBefore(toUtc)) {
      throw ArgumentError.value(toUtc, 'toUtc', '统计时间范围必须正向递增');
    }
    variables
      ..add(Variable<int>(limit))
      ..add(Variable<int>(offset));
    final whereClause = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final orderDirection = descending ? 'DESC' : 'ASC';
    final rows = await customSelect(
      '''
        SELECT occurred_at, is_correct
        FROM learning_events
        $whereClause
        ORDER BY occurred_at $orderDirection, id $orderDirection
        LIMIT ? OFFSET ?
      ''',
      variables: variables,
      readsFrom: {learningEvents},
    ).get();
    return rows
        .map(
          (row) => LearningEventFact(
            occurredAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('occurred_at'),
              isUtc: true,
            ),
            isCorrect: row.read<bool?>('is_correct'),
          ),
        )
        .toList(growable: false);
  }

  /// 读取唯一应用设置；尚未初始化时返回空。
  Future<AppSetting?> findAppSetting() {
    return (select(
      appSettings,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
  }

  /// 插入或覆盖唯一应用设置记录。
  Future<void> upsertAppSetting(AppSettingsCompanion setting) async {
    await into(
      appSettings,
    ).insertOnConflictUpdate(setting.copyWith(id: const Value(1)));
  }

  void _validateLimit(int limit) {
    if (limit <= 0 || limit > maxQueryLimit) {
      throw ArgumentError.value(limit, 'limit', '查询数量必须在 1-$maxQueryLimit 之间');
    }
  }

  void _validatePagination({required int limit, required int offset}) {
    _validateLimit(limit);
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', '查询偏移不能小于 0');
    }
  }

  void _validateContentIds(Set<int> ids, String name) {
    if (ids.length > maxQueryLimit || ids.any((id) => id <= 0)) {
      throw ArgumentError.value(ids, name, '内容 ID 集合无效');
    }
  }

  void _validateContentId(int id, String name) {
    if (id <= 0) {
      throw ArgumentError.value(id, name, '内容 ID 必须为正整数');
    }
  }

  String _normalizeRecordId(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 64) {
      throw ArgumentError.value(value, name, '记录 ID 长度必须在 1-64 之间');
    }
    return normalized;
  }
}
