import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/content/content_database.dart';
import '../database/user/daos/user_data_dao.dart';
import '../database/user/user_database.dart';
import '../models/backup/backup_history_record.dart';
import '../models/backup/backup_operation.dart';
import '../models/backup/backup_record_counts.dart';
import '../models/backup/backup_snapshot.dart';
import '../models/domain/review_rating.dart';
import '../services/backup/backup_package_codec.dart';
import '../services/clock/app_clock.dart';
import '../services/id/id_generator.dart';
import 'backup_repository.dart';

/// 可选的自动保护备份落盘回调；文件选择和分享由上层平台适配器负责。
typedef BackupProtectionSink = Future<void> Function(BackupExport backup);

/// 负责用户数据快照、内容 ID 预检和单事务导入。
final class LocalBackupRepository
    implements BackupRepository, UserDataResetRepository {
  LocalBackupRepository(
    this._contentDatabase,
    this._userDatabase, {
    required this.appVersion,
    required this.contentVersion,
    this.clock = const SystemAppClock(),
    this.idGenerator = const UuidIdGenerator(),
    this.packageCodec = const BackupPackageCodec(),
    this.protectionSink,
  });

  final ContentDatabase _contentDatabase;
  final UserDatabase _userDatabase;
  final String appVersion;
  final String contentVersion;
  final AppClock clock;
  final IdGenerator idGenerator;
  final BackupPackageCodec packageCodec;
  final BackupProtectionSink? protectionSink;

  @override
  Future<BackupExport> exportBackup() {
    return _createExport(type: 'export', recordHistory: true);
  }

  @override
  Future<UserDataResetResult> resetUserData({
    BackupProgressCallback? onProgress,
  }) async {
    final sink = protectionSink;
    if (sink == null) {
      throw StateError('清除用户数据前必须配置保护备份落盘能力');
    }
    BackupExport? protection;
    try {
      _notifyProgress(
        onProgress,
        const BackupProgress(
          stage: BackupProgressStage.protecting,
          fraction: 0,
        ),
      );
      protection = await _createExport(
        type: 'protection',
        recordHistory: false,
      );
      await sink(protection);
      _notifyProgress(
        onProgress,
        const BackupProgress(
          stage: BackupProgressStage.writing,
          fraction: 0.55,
        ),
      );
      await _userDatabase.transaction(
        _userDatabase.userDataDao.clearRecoverableData,
      );
      await _recordHistory(
        type: 'reset',
        fileName: protection.fileName,
        result: 'success',
        summary: jsonEncode(protection.manifest.recordCounts.toJson()),
      );
      _notifyProgress(
        onProgress,
        const BackupProgress(stage: BackupProgressStage.completed, fraction: 1),
      );
      return UserDataResetResult(
        fileName: protection.fileName,
        clearedCounts: protection.manifest.recordCounts,
        resetAtUtc: clock.nowUtc().toUtc(),
      );
    } on Object {
      await _recordHistory(
        type: 'reset',
        fileName: protection?.fileName ?? 'user-data-reset.ieltsbackup',
        result: 'failed',
        summary: '{}',
      );
      rethrow;
    }
  }

  @override
  Future<BackupImportPreview> previewImport(
    List<int> bytes, {
    BackupProgressCallback? onProgress,
  }) async {
    _notifyProgress(
      onProgress,
      const BackupProgress(stage: BackupProgressStage.decoding, fraction: 0),
    );
    final decoded = await packageCodec.decodeInBackground(
      bytes,
      allowFutureFormat: true,
    );
    if (decoded.isFutureFormat) {
      _notifyProgress(
        onProgress,
        const BackupProgress(
          stage: BackupProgressStage.analyzing,
          fraction: 0.5,
        ),
      );
      final existing = await _userDatabase.transaction(
        _userDatabase.userDataDao.readBackupRows,
      );
      final preview = BackupImportPreview(
        manifest: decoded.manifest,
        recordCounts: decoded.manifest.recordCounts,
        existingRecordCount: _recordCount(existing),
        conflictCount: 0,
        missingWordIds: const {},
        missingSentenceIds: const {},
        rejectedRecordCount: 0,
        canImport: false,
        isFutureFormat: true,
      );
      _notifyProgress(
        onProgress,
        const BackupProgress(stage: BackupProgressStage.completed, fraction: 1),
      );
      return preview;
    }
    final snapshot = decoded.snapshot;
    if (snapshot == null) {
      throw StateError('当前格式备份缺少已解析快照');
    }
    _notifyProgress(
      onProgress,
      const BackupProgress(stage: BackupProgressStage.analyzing, fraction: 0.5),
    );
    final analysis = await _analyze(snapshot);
    final preview = BackupImportPreview(
      manifest: decoded.manifest,
      recordCounts: decoded.manifest.recordCounts,
      existingRecordCount: _recordCount(analysis.existing),
      conflictCount: analysis.conflictCount,
      missingWordIds: analysis.missingWordIds,
      missingSentenceIds: analysis.missingSentenceIds,
      rejectedRecordCount: analysis.rejectedRecordCount,
      canImport: true,
      isFutureFormat: false,
    );
    _notifyProgress(
      onProgress,
      const BackupProgress(stage: BackupProgressStage.completed, fraction: 1),
    );
    return preview;
  }

  @override
  Future<BackupImportReport> importBackup(
    List<int> bytes, {
    required BackupImportMode mode,
    BackupProgressCallback? onProgress,
  }) async {
    _notifyProgress(
      onProgress,
      const BackupProgress(stage: BackupProgressStage.decoding, fraction: 0),
    );
    final decoded = await packageCodec.decodeInBackground(bytes);
    final snapshot = decoded.snapshot;
    if (snapshot == null || decoded.isFutureFormat) {
      throw StateError('高版本备份只允许预览，不能导入');
    }
    _notifyProgress(
      onProgress,
      const BackupProgress(
        stage: BackupProgressStage.analyzing,
        fraction: 0.25,
      ),
    );
    final analysis = await _analyze(snapshot);
    _notifyProgress(
      onProgress,
      const BackupProgress(
        stage: BackupProgressStage.protecting,
        fraction: 0.45,
      ),
    );
    final protection = await _createExport(
      type: 'protection',
      recordHistory: true,
    );
    if (protectionSink != null) {
      await protectionSink!(protection);
    }

    try {
      _notifyProgress(
        onProgress,
        const BackupProgress(
          stage: BackupProgressStage.writing,
          fraction: 0.55,
        ),
      );
      final applied = await _userDatabase.transaction(() async {
        if (mode == BackupImportMode.overwrite) {
          await _userDatabase.userDataDao.clearRecoverableData();
        }
        return _applySnapshot(
          snapshot,
          mode: mode,
          analysis: analysis,
          onProgress: (fraction) {
            _notifyProgress(
              onProgress,
              BackupProgress(
                stage: BackupProgressStage.writing,
                fraction: 0.55 + fraction * 0.45,
              ),
            );
          },
        );
      });
      await _recordHistory(
        type: 'import',
        fileName: 'imported.ieltsbackup',
        result: 'success',
        summary: _summaryJson(
          mode: mode,
          importedCounts: applied.importedCounts,
          skippedCounts: applied.skippedCounts,
          conflictCount: analysis.conflictCount,
        ),
      );
      final report = BackupImportReport(
        mode: mode,
        importedCounts: applied.importedCounts,
        skippedCounts: applied.skippedCounts,
        conflictCount: analysis.conflictCount,
        missingWordIds: analysis.missingWordIds,
        missingSentenceIds: analysis.missingSentenceIds,
        protectionBackupBytes: protection.bytes,
      );
      _notifyProgress(
        onProgress,
        const BackupProgress(stage: BackupProgressStage.completed, fraction: 1),
      );
      return report;
    } on Object {
      await _recordHistory(
        type: 'import',
        fileName: 'imported.ieltsbackup',
        result: 'failed',
        summary: jsonEncode({'mode': mode.name}),
      );
      rethrow;
    }
  }

  @override
  Future<List<BackupHistoryRecord>> findHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _userDatabase.userDataDao.findBackupHistory(
      limit: limit,
      offset: offset,
    );
    return rows
        .map(
          (row) => BackupHistoryRecord(
            id: row.id,
            type: row.type,
            fileName: row.fileName,
            summaryJson: row.summaryJson,
            result: row.result,
            occurredAt: row.occurredAt.toUtc(),
          ),
        )
        .toList(growable: false);
  }

  Future<BackupExport> _createExport({
    required String type,
    required bool recordHistory,
  }) async {
    final exportedAt = clock.nowUtc().toUtc();
    try {
      final snapshot = await _userDatabase.transaction(() async {
        final rows = await _userDatabase.userDataDao.readBackupRows();
        return _toSnapshot(rows);
      });
      final bytes = packageCodec.encode(
        appVersion: appVersion,
        userSchemaVersion: _userDatabase.schemaVersion,
        contentVersion: contentVersion,
        exportedAt: exportedAt,
        snapshot: snapshot,
      );
      final decoded = packageCodec.decode(bytes);
      final manifest = decoded.manifest;
      final backup = BackupExport(
        bytes: bytes,
        fileName: _fileName(exportedAt),
        manifest: manifest,
      );
      if (recordHistory) {
        await _recordHistory(
          type: type,
          fileName: backup.fileName,
          result: 'success',
          summary: jsonEncode(manifest.recordCounts.toJson()),
        );
      }
      return backup;
    } on Object {
      if (recordHistory) {
        await _recordHistory(
          type: type,
          fileName: _fileName(exportedAt),
          result: 'failed',
          summary: '{}',
        );
      }
      rethrow;
    }
  }

  BackupSnapshot _toSnapshot(UserBackupRows rows) {
    return BackupSnapshot(
      userWordStates: rows.userWordStates
          .map(
            (row) => BackupUserWordState(
              wordId: row.wordId,
              masteryLevel: row.masteryLevel,
              studiedCount: row.studiedCount,
              correctCount: row.correctCount,
              wrongCount: row.wrongCount,
              correctStreak: row.correctStreak,
              consecutiveForgottenCount: row.consecutiveForgottenCount,
              lastStudiedAt: row.lastStudiedAt?.toUtc(),
              lastReviewedAt: row.lastReviewedAt?.toUtc(),
              nextReviewAt: row.nextReviewAt?.toUtc(),
              updatedAt: row.updatedAt.toUtc(),
            ),
          )
          .toList(growable: false),
      favoriteWords: rows.favoriteWords
          .map(
            (row) => BackupFavoriteWord(
              id: row.id,
              wordId: row.wordId,
              createdAt: row.createdAt.toUtc(),
              updatedAt: row.updatedAt.toUtc(),
            ),
          )
          .toList(growable: false),
      favoriteSentences: rows.favoriteSentences
          .map(
            (row) => BackupFavoriteSentence(
              id: row.id,
              sentenceId: row.sentenceId,
              wordId: row.wordId,
              createdAt: row.createdAt.toUtc(),
              updatedAt: row.updatedAt.toUtc(),
            ),
          )
          .toList(growable: false),
      practiceSessions: rows.practiceSessions
          .map(
            (row) => BackupPracticeSession(
              id: row.id,
              type: row.type,
              configJson: row.configJson,
              startedAt: row.startedAt.toUtc(),
              finishedAt: row.finishedAt?.toUtc(),
              totalQuestionCount: row.totalQuestionCount,
              correctCount: row.correctCount,
              elapsedMilliseconds: row.elapsedMilliseconds,
            ),
          )
          .toList(growable: false),
      practiceAnswers: rows.practiceAnswers
          .map(
            (row) => BackupPracticeAnswer(
              id: row.id,
              sessionId: row.sessionId,
              wordId: row.wordId,
              sentenceId: row.sentenceId,
              userAnswer: row.userAnswer,
              isCorrect: row.isCorrect,
              responseTimeMilliseconds: row.responseTimeMilliseconds,
              answeredAt: row.answeredAt.toUtc(),
            ),
          )
          .toList(growable: false),
      learningEvents: rows.learningEvents
          .map(
            (row) => BackupLearningEvent(
              id: row.id,
              eventType: row.eventType,
              wordId: row.wordId,
              sessionId: row.sessionId,
              isCorrect: row.isCorrect,
              reviewRating: row.reviewRating == null
                  ? null
                  : ReviewRating.values.byName(row.reviewRating!),
              occurredAt: row.occurredAt.toUtc(),
            ),
          )
          .toList(growable: false),
      appSettings: rows.appSettings == null
          ? null
          : BackupAppSettings(
              id: rows.appSettings!.id,
              dailyGoal: rows.appSettings!.dailyGoal,
              pronunciationAccent: rows.appSettings!.pronunciationAccent,
              autoPlayPronunciation: rows.appSettings!.autoPlayPronunciation,
              themeMode: rows.appSettings!.themeMode,
              accentColor: rows.appSettings!.accentColor,
              updatedAt: rows.appSettings!.updatedAt.toUtc(),
            ),
    );
  }

  Future<_ImportAnalysis> _analyze(BackupSnapshot snapshot) async {
    final wordIds = <int>{
      ...snapshot.userWordStates.map((row) => row.wordId),
      ...snapshot.favoriteWords.map((row) => row.wordId),
      ...snapshot.favoriteSentences.map((row) => row.wordId),
      ...snapshot.practiceAnswers.map((row) => row.wordId),
      ...snapshot.learningEvents.map((row) => row.wordId),
    };
    final sentenceIds = <int>{
      ...snapshot.favoriteSentences.map((row) => row.sentenceId),
      ...snapshot.practiceAnswers.map((row) => row.sentenceId).whereType<int>(),
    };
    final wordRows = await _findWords(wordIds);
    final sentenceRows = await _findSentences(sentenceIds);
    final validWordIds = wordRows.map((row) => row.id).toSet();
    final sentenceWordIds = <int, int>{
      for (final row in sentenceRows) row.id: row.wordId,
    };
    final missingWordIds = wordIds.difference(validWordIds);
    final missingSentenceIds = sentenceIds.difference(
      sentenceWordIds.keys.toSet(),
    );
    final rejectedRecordCount = _countRejected(
      snapshot,
      validWordIds: validWordIds,
      sentenceWordIds: sentenceWordIds,
    );
    final existing = await _userDatabase.transaction(
      _userDatabase.userDataDao.readBackupRows,
    );
    return _ImportAnalysis(
      missingWordIds: missingWordIds,
      missingSentenceIds: missingSentenceIds,
      validWordIds: validWordIds,
      sentenceWordIds: sentenceWordIds,
      existing: existing,
      rejectedRecordCount: rejectedRecordCount,
      conflictCount: _countConflicts(snapshot, existing),
    );
  }

  Future<List<Word>> _findWords(Set<int> ids) async {
    final result = <Word>[];
    for (final chunk in _chunks(ids)) {
      result.addAll(await _contentDatabase.contentDao.findWordsByIds(chunk));
    }
    return result;
  }

  Future<List<Sentence>> _findSentences(Set<int> ids) async {
    final result = <Sentence>[];
    for (final chunk in _chunks(ids)) {
      result.addAll(
        await _contentDatabase.contentDao.findSentencesByIds(chunk),
      );
    }
    return result;
  }

  int _recordCount(UserBackupRows rows) {
    return rows.userWordStates.length +
        rows.favoriteWords.length +
        rows.favoriteSentences.length +
        rows.practiceSessions.length +
        rows.practiceAnswers.length +
        rows.learningEvents.length +
        (rows.appSettings == null ? 0 : 1);
  }

  Iterable<Set<int>> _chunks(Set<int> ids) sync* {
    if (ids.isEmpty) {
      return;
    }
    final sorted = ids.toList()..sort();
    for (var index = 0; index < sorted.length; index += 500) {
      final end = (index + 500).clamp(0, sorted.length);
      yield sorted.sublist(index, end).toSet();
    }
  }

  int _countRejected(
    BackupSnapshot snapshot, {
    required Set<int> validWordIds,
    required Map<int, int> sentenceWordIds,
  }) {
    var rejected = 0;
    rejected += snapshot.userWordStates
        .where((row) => !validWordIds.contains(row.wordId))
        .length;
    rejected += snapshot.favoriteWords
        .where((row) => !validWordIds.contains(row.wordId))
        .length;
    rejected += snapshot.favoriteSentences
        .where(
          (row) =>
              !validWordIds.contains(row.wordId) ||
              sentenceWordIds[row.sentenceId] != row.wordId,
        )
        .length;
    rejected += snapshot.practiceAnswers
        .where(
          (row) =>
              !validWordIds.contains(row.wordId) ||
              (row.sentenceId != null &&
                  sentenceWordIds[row.sentenceId] != row.wordId),
        )
        .length;
    rejected += snapshot.learningEvents
        .where((row) => !validWordIds.contains(row.wordId))
        .length;
    return rejected;
  }

  int _countConflicts(BackupSnapshot snapshot, UserBackupRows existing) {
    final existingStateIds = existing.userWordStates
        .map((row) => row.wordId)
        .toSet();
    final existingFavoriteWordIds = existing.favoriteWords
        .map((row) => row.wordId)
        .toSet();
    final existingFavoriteSentenceIds = existing.favoriteSentences
        .map((row) => row.sentenceId)
        .toSet();
    final existingSessionIds = existing.practiceSessions
        .map((row) => row.id)
        .toSet();
    final existingAnswerIds = existing.practiceAnswers
        .map((row) => row.id)
        .toSet();
    final existingEventIds = existing.learningEvents
        .map((row) => row.id)
        .toSet();
    var count = 0;
    count += snapshot.userWordStates
        .where((row) => existingStateIds.contains(row.wordId))
        .length;
    count += snapshot.favoriteWords
        .where((row) => existingFavoriteWordIds.contains(row.wordId))
        .length;
    count += snapshot.favoriteSentences
        .where((row) => existingFavoriteSentenceIds.contains(row.sentenceId))
        .length;
    count += snapshot.practiceSessions
        .where((row) => existingSessionIds.contains(row.id))
        .length;
    count += snapshot.practiceAnswers
        .where((row) => existingAnswerIds.contains(row.id))
        .length;
    count += snapshot.learningEvents
        .where((row) => existingEventIds.contains(row.id))
        .length;
    if (snapshot.appSettings != null && existing.appSettings != null) {
      count++;
    }
    return count;
  }

  Future<_AppliedCounts> _applySnapshot(
    BackupSnapshot snapshot, {
    required BackupImportMode mode,
    required _ImportAnalysis analysis,
    void Function(double fraction)? onProgress,
  }) async {
    final imported = _MutableCounts();
    final skipped = _MutableCounts();
    final dao = _userDatabase.userDataDao;
    final existing = mode == BackupImportMode.overwrite
        ? const UserBackupRows(
            userWordStates: [],
            favoriteWords: [],
            favoriteSentences: [],
            practiceSessions: [],
            practiceAnswers: [],
            learningEvents: [],
            appSettings: null,
          )
        : analysis.existing;
    final existingStates = {
      for (final row in existing.userWordStates) row.wordId: row,
    };
    final existingFavoriteWords = {
      for (final row in existing.favoriteWords) row.wordId: row,
    };
    final existingFavoriteWordsById = {
      for (final row in existing.favoriteWords) row.id: row,
    };
    final existingFavoriteSentences = {
      for (final row in existing.favoriteSentences) row.sentenceId: row,
    };
    final existingFavoriteSentencesById = {
      for (final row in existing.favoriteSentences) row.id: row,
    };
    final existingSessions = {
      for (final row in existing.practiceSessions) row.id: row,
    };
    final existingAnswers = {
      for (final row in existing.practiceAnswers) row.id: row,
    };
    final existingEvents = {
      for (final row in existing.learningEvents) row.id: row,
    };
    final totalRecords =
        snapshot.userWordStates.length +
        snapshot.favoriteWords.length +
        snapshot.favoriteSentences.length +
        snapshot.practiceSessions.length +
        snapshot.practiceAnswers.length +
        snapshot.learningEvents.length +
        (snapshot.appSettings == null ? 0 : 1);
    var processedRecords = 0;
    void advanceProgress() {
      processedRecords++;
      if (onProgress == null ||
          totalRecords == 0 ||
          (processedRecords != totalRecords && processedRecords % 100 != 0)) {
        return;
      }
      onProgress((processedRecords / totalRecords).clamp(0, 1).toDouble());
    }

    for (final row in snapshot.userWordStates) {
      if (!analysis.validWordIds.contains(row.wordId)) {
        skipped.userWordStates++;
        advanceProgress();
        continue;
      }
      final merged = mode == BackupImportMode.overwrite
          ? row
          : _mergeWordState(existingStates[row.wordId], row);
      await dao.upsertWordState(_wordStateCompanion(merged));
      imported.userWordStates++;
      advanceProgress();
    }
    for (final row in snapshot.favoriteWords) {
      if (!analysis.validWordIds.contains(row.wordId)) {
        skipped.favoriteWords++;
        advanceProgress();
        continue;
      }
      final idCollision = existingFavoriteWordsById[row.id];
      if (mode == BackupImportMode.merge &&
          idCollision != null &&
          idCollision.wordId != row.wordId) {
        skipped.favoriteWords++;
        advanceProgress();
        continue;
      }
      final existingRow = existingFavoriteWords[row.wordId];
      if (mode == BackupImportMode.merge &&
          existingRow != null &&
          !row.updatedAt.isAfter(existingRow.updatedAt)) {
        skipped.favoriteWords++;
        advanceProgress();
        continue;
      }
      if (existingRow != null && existingRow.id != row.id) {
        await dao.deleteFavoriteWordByRecordId(existingRow.id);
      }
      await dao.upsertFavoriteWord(_favoriteWordCompanion(row));
      imported.favoriteWords++;
      advanceProgress();
    }
    for (final row in snapshot.favoriteSentences) {
      if (!_validFavoriteSentence(row, analysis)) {
        skipped.favoriteSentences++;
        advanceProgress();
        continue;
      }
      final idCollision = existingFavoriteSentencesById[row.id];
      if (mode == BackupImportMode.merge &&
          idCollision != null &&
          idCollision.sentenceId != row.sentenceId) {
        skipped.favoriteSentences++;
        advanceProgress();
        continue;
      }
      final existingRow = existingFavoriteSentences[row.sentenceId];
      if (mode == BackupImportMode.merge &&
          existingRow != null &&
          !row.updatedAt.isAfter(existingRow.updatedAt)) {
        skipped.favoriteSentences++;
        advanceProgress();
        continue;
      }
      if (existingRow != null && existingRow.id != row.id) {
        await dao.deleteFavoriteSentenceByRecordId(existingRow.id);
      }
      await dao.upsertFavoriteSentence(_favoriteSentenceCompanion(row));
      imported.favoriteSentences++;
      advanceProgress();
    }
    for (final row in snapshot.practiceSessions) {
      if (mode == BackupImportMode.merge &&
          existingSessions.containsKey(row.id)) {
        skipped.practiceSessions++;
        advanceProgress();
        continue;
      }
      await dao.insertPracticeSessionIfAbsent(_practiceSessionCompanion(row));
      imported.practiceSessions++;
      advanceProgress();
    }
    final availableSessionIds = <String>{
      ...existingSessions.keys,
      ...snapshot.practiceSessions.map((row) => row.id),
    };
    for (final row in snapshot.practiceAnswers) {
      if (!availableSessionIds.contains(row.sessionId) ||
          !_validAnswer(row, analysis)) {
        skipped.practiceAnswers++;
        advanceProgress();
        continue;
      }
      if (mode == BackupImportMode.merge &&
          existingAnswers.containsKey(row.id)) {
        skipped.practiceAnswers++;
        advanceProgress();
        continue;
      }
      await dao.insertPracticeAnswerIfAbsent(_practiceAnswerCompanion(row));
      imported.practiceAnswers++;
      advanceProgress();
    }
    for (final row in snapshot.learningEvents) {
      if (!analysis.validWordIds.contains(row.wordId)) {
        skipped.learningEvents++;
        advanceProgress();
        continue;
      }
      if (mode == BackupImportMode.merge &&
          existingEvents.containsKey(row.id)) {
        skipped.learningEvents++;
        advanceProgress();
        continue;
      }
      await dao.insertLearningEventIfAbsent(_learningEventCompanion(row));
      imported.learningEvents++;
      advanceProgress();
    }
    final settings = snapshot.appSettings;
    if (settings != null) {
      final existingSettings = mode == BackupImportMode.overwrite
          ? null
          : existing.appSettings;
      if (existingSettings != null &&
          !settings.updatedAt.isAfter(existingSettings.updatedAt)) {
        skipped.appSettings++;
      } else {
        await dao.upsertAppSetting(_settingsCompanion(settings));
        imported.appSettings++;
      }
      advanceProgress();
    }
    return _AppliedCounts(
      importedCounts: imported.toRecordCounts(),
      skippedCounts: skipped.toRecordCounts(),
    );
  }

  bool _validFavoriteSentence(
    BackupFavoriteSentence row,
    _ImportAnalysis analysis,
  ) {
    return analysis.validWordIds.contains(row.wordId) &&
        analysis.sentenceWordIds[row.sentenceId] == row.wordId;
  }

  bool _validAnswer(BackupPracticeAnswer row, _ImportAnalysis analysis) {
    return analysis.validWordIds.contains(row.wordId) &&
        (row.sentenceId == null ||
            analysis.sentenceWordIds[row.sentenceId] == row.wordId);
  }

  BackupUserWordState _mergeWordState(
    UserWordState? existing,
    BackupUserWordState incoming,
  ) {
    if (existing == null) {
      return incoming;
    }
    final latestIncoming = !incoming.updatedAt.isBefore(existing.updatedAt);
    return BackupUserWordState(
      wordId: incoming.wordId,
      masteryLevel: latestIncoming
          ? incoming.masteryLevel
          : existing.masteryLevel,
      studiedCount: _max(incoming.studiedCount, existing.studiedCount),
      correctCount: _max(incoming.correctCount, existing.correctCount),
      wrongCount: _max(incoming.wrongCount, existing.wrongCount),
      correctStreak: _max(incoming.correctStreak, existing.correctStreak),
      consecutiveForgottenCount: _max(
        incoming.consecutiveForgottenCount,
        existing.consecutiveForgottenCount,
      ),
      lastStudiedAt: latestIncoming
          ? incoming.lastStudiedAt
          : existing.lastStudiedAt,
      lastReviewedAt: latestIncoming
          ? incoming.lastReviewedAt
          : existing.lastReviewedAt,
      nextReviewAt: latestIncoming
          ? incoming.nextReviewAt
          : existing.nextReviewAt,
      updatedAt: latestIncoming ? incoming.updatedAt : existing.updatedAt,
    );
  }

  int _max(int left, int right) => left > right ? left : right;

  UserWordStatesCompanion _wordStateCompanion(BackupUserWordState row) {
    return UserWordStatesCompanion.insert(
      wordId: Value(row.wordId),
      masteryLevel: Value(row.masteryLevel),
      studiedCount: Value(row.studiedCount),
      correctCount: Value(row.correctCount),
      wrongCount: Value(row.wrongCount),
      correctStreak: Value(row.correctStreak),
      consecutiveForgottenCount: Value(row.consecutiveForgottenCount),
      lastStudiedAt: Value(row.lastStudiedAt),
      lastReviewedAt: Value(row.lastReviewedAt),
      nextReviewAt: Value(row.nextReviewAt),
      updatedAt: row.updatedAt,
    );
  }

  FavoriteWordsCompanion _favoriteWordCompanion(BackupFavoriteWord row) {
    return FavoriteWordsCompanion.insert(
      id: row.id,
      wordId: row.wordId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  FavoriteSentencesCompanion _favoriteSentenceCompanion(
    BackupFavoriteSentence row,
  ) {
    return FavoriteSentencesCompanion.insert(
      id: row.id,
      sentenceId: row.sentenceId,
      wordId: row.wordId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  PracticeSessionsCompanion _practiceSessionCompanion(
    BackupPracticeSession row,
  ) {
    return PracticeSessionsCompanion.insert(
      id: row.id,
      type: row.type,
      configJson: row.configJson,
      startedAt: row.startedAt,
      finishedAt: Value(row.finishedAt),
      totalQuestionCount: Value(row.totalQuestionCount),
      correctCount: Value(row.correctCount),
      elapsedMilliseconds: Value(row.elapsedMilliseconds),
    );
  }

  PracticeAnswersCompanion _practiceAnswerCompanion(BackupPracticeAnswer row) {
    return PracticeAnswersCompanion.insert(
      id: row.id,
      sessionId: row.sessionId,
      wordId: row.wordId,
      sentenceId: Value(row.sentenceId),
      userAnswer: row.userAnswer,
      isCorrect: row.isCorrect,
      responseTimeMilliseconds: row.responseTimeMilliseconds,
      answeredAt: row.answeredAt,
    );
  }

  LearningEventsCompanion _learningEventCompanion(BackupLearningEvent row) {
    return LearningEventsCompanion.insert(
      id: row.id,
      eventType: row.eventType,
      wordId: row.wordId,
      sessionId: Value(row.sessionId),
      isCorrect: Value(row.isCorrect),
      reviewRating: Value(row.reviewRating?.name),
      occurredAt: row.occurredAt,
    );
  }

  AppSettingsCompanion _settingsCompanion(BackupAppSettings row) {
    return AppSettingsCompanion.insert(
      id: const Value(1),
      dailyGoal: row.dailyGoal,
      pronunciationAccent: row.pronunciationAccent,
      autoPlayPronunciation: row.autoPlayPronunciation,
      themeMode: row.themeMode,
      accentColor: Value(row.accentColor),
      updatedAt: row.updatedAt,
    );
  }

  void _notifyProgress(
    BackupProgressCallback? onProgress,
    BackupProgress progress,
  ) {
    try {
      onProgress?.call(progress);
    } on Object {
      // 进度观察器不是备份结果的一部分，观察器异常不应改变事务结果。
    }
  }

  Future<void> _recordHistory({
    required String type,
    required String fileName,
    required String result,
    required String summary,
  }) async {
    try {
      await _userDatabase.userDataDao.insertBackupHistory(
        BackupHistoryCompanion.insert(
          id: _nextId(),
          type: type,
          fileName: fileName,
          summaryJson: summary,
          result: result,
          occurredAt: clock.nowUtc().toUtc(),
        ),
      );
    } on Object {
      // 历史记录不能覆盖导出或导入的原始结果。
    }
  }

  String _nextId() {
    final id = idGenerator.nextId().trim();
    if (id.isEmpty || id.length > 64) {
      throw StateError('备份历史 ID 生成器返回了无效值');
    }
    return id;
  }

  String _fileName(DateTime date) {
    final utc = date.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'ielts_vocab_${utc.year.toString().padLeft(4, '0')}'
        '${two(utc.month)}${two(utc.day)}_${two(utc.hour)}'
        '${two(utc.minute)}${two(utc.second)}.ieltsbackup';
  }

  String _summaryJson({
    required BackupImportMode mode,
    required BackupRecordCounts importedCounts,
    required BackupRecordCounts skippedCounts,
    required int conflictCount,
  }) {
    return jsonEncode({
      'mode': mode.name,
      'imported': importedCounts.toJson(),
      'skipped': skippedCounts.toJson(),
      'conflictCount': conflictCount,
    });
  }
}

final class _ImportAnalysis {
  const _ImportAnalysis({
    required this.missingWordIds,
    required this.missingSentenceIds,
    required this.validWordIds,
    required this.sentenceWordIds,
    required this.existing,
    required this.rejectedRecordCount,
    required this.conflictCount,
  });

  final Set<int> missingWordIds;
  final Set<int> missingSentenceIds;
  final Set<int> validWordIds;
  final Map<int, int> sentenceWordIds;
  final UserBackupRows existing;
  final int rejectedRecordCount;
  final int conflictCount;
}

final class _AppliedCounts {
  const _AppliedCounts({
    required this.importedCounts,
    required this.skippedCounts,
  });

  final BackupRecordCounts importedCounts;
  final BackupRecordCounts skippedCounts;
}

final class _MutableCounts {
  int userWordStates = 0;
  int favoriteWords = 0;
  int favoriteSentences = 0;
  int practiceSessions = 0;
  int practiceAnswers = 0;
  int learningEvents = 0;
  int appSettings = 0;

  BackupRecordCounts toRecordCounts() {
    return BackupRecordCounts(
      userWordStates: userWordStates,
      favoriteWords: favoriteWords,
      favoriteSentences: favoriteSentences,
      practiceSessions: practiceSessions,
      practiceAnswers: practiceAnswers,
      learningEvents: learningEvents,
      appSettings: appSettings,
    );
  }
}
