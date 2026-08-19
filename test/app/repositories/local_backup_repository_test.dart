import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_snapshot.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_backup_repository.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_data_codec.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_package_codec.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_config_codec.dart';

void main() {
  late ContentDatabase contentDatabase;
  late UserDatabase userDatabase;

  setUp(() async {
    contentDatabase = ContentDatabase.forExecutor(NativeDatabase.memory());
    userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    await contentDatabase
        .into(contentDatabase.frequencyGroups)
        .insert(
          FrequencyGroupsCompanion.insert(
            id: const Value(1),
            name: '第一组',
            rank: 1,
            minOccurrences: 100,
            maxOccurrences: const Value(1000),
          ),
        );
    await contentDatabase
        .into(contentDatabase.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            word: 'alpha',
            occurrences: 100,
            frequencyGroupId: 1,
            firstLetter: 'a',
            translationZh: const Value('阿尔法'),
          ),
        );
    await contentDatabase
        .into(contentDatabase.sentences)
        .insert(
          SentencesCompanion.insert(
            id: const Value(1),
            wordId: 1,
            targetForm: 'alpha',
            sentenceEn: 'Alpha is first.',
          ),
        );
    await contentDatabase
        .into(contentDatabase.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(2),
            word: 'beta',
            occurrences: 100,
            frequencyGroupId: 1,
            firstLetter: 'b',
            translationZh: const Value('贝塔'),
          ),
        );
    await contentDatabase
        .into(contentDatabase.sentences)
        .insert(
          SentencesCompanion.insert(
            id: const Value(2),
            wordId: 2,
            targetForm: 'beta',
            sentenceEn: 'Beta is second.',
          ),
        );
  });

  tearDown(() async {
    await userDatabase.close();
    await contentDatabase.close();
  });

  LocalBackupRepository createRepository() {
    return LocalBackupRepository(
      contentDatabase,
      userDatabase,
      appVersion: 'test-app-v1',
      contentVersion: 'content-v1',
    );
  }

  BackupSnapshot snapshot({
    int wordId = 1,
    int sentenceId = 1,
    DateTime? updatedAt,
    String stateEventId = 'event-1',
  }) {
    final time = updatedAt ?? DateTime.utc(2026, 8, 15, 12);
    final practiceConfig = QuestionConfig.targetedSpelling(wordId: wordId);
    return BackupSnapshot(
      userWordStates: [
        BackupUserWordState(
          wordId: wordId,
          masteryLevel: 4,
          studiedCount: 5,
          correctCount: 4,
          wrongCount: 1,
          correctStreak: 3,
          consecutiveForgottenCount: 0,
          lastStudiedAt: time,
          lastReviewedAt: time,
          nextReviewAt: time.add(const Duration(days: 1)),
          updatedAt: time,
        ),
      ],
      favoriteWords: [
        BackupFavoriteWord(
          id: 'favorite-word-$wordId',
          wordId: wordId,
          createdAt: time,
          updatedAt: time,
        ),
      ],
      favoriteSentences: [
        BackupFavoriteSentence(
          id: 'favorite-sentence-$sentenceId',
          sentenceId: sentenceId,
          wordId: wordId,
          createdAt: time,
          updatedAt: time,
        ),
      ],
      practiceSessions: [
        BackupPracticeSession(
          id: 'session-$stateEventId',
          type: QuestionTypeStorage.encode(practiceConfig.type),
          configJson: const QuestionConfigCodec().encode(practiceConfig),
          startedAt: time,
          finishedAt: time,
          totalQuestionCount: 1,
          correctCount: 1,
          elapsedMilliseconds: 300,
        ),
      ],
      practiceAnswers: [
        BackupPracticeAnswer(
          id: 'answer-$stateEventId',
          sessionId: 'session-$stateEventId',
          wordId: wordId,
          sentenceId: sentenceId,
          userAnswer: 'alpha',
          isCorrect: true,
          responseTimeMilliseconds: 300,
          answeredAt: time,
        ),
      ],
      learningEvents: [
        BackupLearningEvent(
          id: stateEventId,
          eventType: 'practice_answered',
          wordId: wordId,
          sessionId: 'session-$stateEventId',
          isCorrect: true,
          reviewRating: null,
          occurredAt: time,
        ),
      ],
      appSettings: BackupAppSettings(
        id: 1,
        dailyGoal: 20,
        pronunciationAccent: 'uk',
        autoPlayPronunciation: true,
        themeMode: 'dark',
        updatedAt: time,
      ),
    );
  }

  List<int> encode(BackupSnapshot value) {
    return BackupPackageCodec().encode(
      appVersion: 'source-app-v1',
      userSchemaVersion: 1,
      contentVersion: 'content-v1',
      exportedAt: DateTime.utc(2026, 8, 15, 12),
      snapshot: value,
    );
  }

  test('导出包含全部用户业务表但不嵌套 BackupHistory', () async {
    final now = DateTime.utc(2026, 8, 15, 10);
    final practiceConfig = QuestionConfig.targetedSpelling(wordId: 1);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(1),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'favorite-existing',
        wordId: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertPracticeSession(
      PracticeSessionsCompanion.insert(
        id: 'session-existing',
        type: QuestionTypeStorage.encode(practiceConfig.type),
        configJson: const QuestionConfigCodec().encode(practiceConfig),
        startedAt: now,
        finishedAt: Value(now),
        totalQuestionCount: const Value(1),
        correctCount: const Value(1),
        elapsedMilliseconds: const Value(100),
      ),
    );
    await userDatabase.userDataDao.insertPracticeAnswer(
      PracticeAnswersCompanion.insert(
        id: 'answer-existing',
        sessionId: 'session-existing',
        wordId: 1,
        userAnswer: 'alpha',
        isCorrect: true,
        responseTimeMilliseconds: 100,
        answeredAt: now,
      ),
    );
    await userDatabase.userDataDao.insertLearningEvent(
      LearningEventsCompanion.insert(
        id: 'event-existing',
        eventType: 'practice_answered',
        wordId: 1,
        sessionId: const Value('session-existing'),
        isCorrect: const Value(true),
        occurredAt: now,
      ),
    );
    await userDatabase.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 10,
        pronunciationAccent: 'uk',
        autoPlayPronunciation: false,
        themeMode: 'system',
        updatedAt: now,
      ),
    );

    final result = await createRepository().exportBackup();
    final decoded = BackupPackageCodec().decode(result.bytes);
    expect(decoded.manifest.recordCounts.userWordStates, 1);
    expect(decoded.manifest.recordCounts.favoriteWords, 1);
    expect(decoded.manifest.recordCounts.practiceAnswers, 1);
    expect(decoded.manifest.recordCounts.appSettings, 1);
    expect(
      await userDatabase.select(userDatabase.backupHistory).get(),
      hasLength(1),
    );
    expect((await createRepository().findHistory()).single.type, 'export');
  });

  test('删除备份历史只移除指定记录，并保持用户学习数据', () async {
    final now = DateTime.utc(2026, 8, 15, 10);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(1),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertBackupHistory(
      BackupHistoryCompanion.insert(
        id: 'history-delete',
        type: 'export',
        fileName: 'delete.ieltsbackup',
        summaryJson: '{}',
        result: 'success',
        occurredAt: now,
      ),
    );
    await userDatabase.userDataDao.insertBackupHistory(
      BackupHistoryCompanion.insert(
        id: 'history-retain',
        type: 'import',
        fileName: 'retain.ieltsbackup',
        summaryJson: '{}',
        result: 'success',
        occurredAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    final repository = createRepository();

    await repository.deleteHistoryRecord('history-delete');
    await repository.deleteHistoryRecord('history-delete');

    expect((await repository.findHistory()).map((record) => record.id), [
      'history-retain',
    ]);
    expect(
      await userDatabase.userDataDao.findWordState(1),
      isNot(equals(null)),
    );
  });

  test('预检报告缺失内容 ID 和现有冲突但不写入数据库', () async {
    final repository = createRepository();
    final preview = await repository.previewImport(
      encode(snapshot(wordId: 999, sentenceId: 999)),
    );

    expect(preview.canImport, isTrue);
    expect(preview.missingWordIds, contains(999));
    expect(preview.missingSentenceIds, contains(999));
    expect(preview.rejectedRecordCount, greaterThanOrEqualTo(4));
    expect(
      await userDatabase.select(userDatabase.userWordStates).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.backupHistory).get(),
      isEmpty,
    );
  });

  test('预检和事务导入报告阶段与百分比进度', () async {
    final bytes = encode(snapshot());
    final previewProgress = <BackupProgress>[];
    final importProgress = <BackupProgress>[];
    final repository = createRepository();

    await repository.previewImport(bytes, onProgress: previewProgress.add);
    await repository.importBackup(
      bytes,
      mode: BackupImportMode.merge,
      onProgress: importProgress.add,
    );

    expect(
      previewProgress.map((item) => item.stage),
      containsAllInOrder([
        BackupProgressStage.decoding,
        BackupProgressStage.analyzing,
        BackupProgressStage.completed,
      ]),
    );
    expect(
      importProgress.map((item) => item.stage),
      containsAllInOrder([
        BackupProgressStage.decoding,
        BackupProgressStage.analyzing,
        BackupProgressStage.protecting,
        BackupProgressStage.writing,
        BackupProgressStage.completed,
      ]),
    );
    expect(importProgress.last.fraction, 1);
  });

  test('预检统计当前可覆盖业务记录但排除备份历史', () async {
    final now = DateTime.utc(2026, 8, 15, 10);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(2),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'preview-favorite',
        wordId: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertBackupHistory(
      BackupHistoryCompanion.insert(
        id: 'preview-history',
        type: 'export',
        fileName: 'preview.ieltsbackup',
        summaryJson: '{}',
        result: 'success',
        occurredAt: now,
      ),
    );

    final preview = await createRepository().previewImport(encode(snapshot()));

    expect(preview.existingRecordCount, 2);
  });

  test('未来格式只读预览仍显示当前可覆盖记录数量', () async {
    final now = DateTime.utc(2026, 8, 15, 10);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(1),
        updatedAt: now,
      ),
    );
    final source = encode(snapshot(stateEventId: 'future-preview-event'));
    final archive = archiveFrom(source);
    final futureBytes = encodeFutureFormat(archive, 99);

    final preview = await createRepository().previewImport(futureBytes);

    expect(preview.isFutureFormat, isTrue);
    expect(preview.existingRecordCount, 1);
  });

  test('预检报告统计跨单词例句引用并在导入时跳过', () async {
    final repository = createRepository();
    final preview = await repository.previewImport(
      encode(snapshot(sentenceId: 2)),
    );

    expect(preview.missingWordIds, isEmpty);
    expect(preview.missingSentenceIds, isEmpty);
    expect(preview.rejectedRecordCount, 2);

    final report = await repository.importBackup(
      encode(snapshot(sentenceId: 2)),
      mode: BackupImportMode.overwrite,
    );
    expect(report.skippedCounts.favoriteSentences, 1);
    expect(report.skippedCounts.practiceAnswers, 1);
    expect(
      await userDatabase.select(userDatabase.favoriteSentences).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.practiceAnswers).get(),
      isEmpty,
    );
  });

  test('合并按内容唯一键、UUID 去重，状态数字取较大值且可重复导入', () async {
    final old = DateTime.utc(2026, 8, 14, 12);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        masteryLevel: const Value(2),
        studiedCount: const Value(10),
        correctCount: const Value(8),
        wrongCount: const Value(2),
        correctStreak: const Value(4),
        updatedAt: old,
      ),
    );
    await userDatabase.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'old-favorite',
        wordId: 1,
        createdAt: old,
        updatedAt: old,
      ),
    );

    final repository = createRepository();
    final bytes = encode(
      snapshot(
        updatedAt: DateTime.utc(2026, 8, 15, 12),
        stateEventId: 'event-new',
      ),
    );
    final report = await repository.importBackup(
      bytes,
      mode: BackupImportMode.merge,
    );
    expect(report.importedCounts.userWordStates, 1);
    expect(report.protectionBackup, isNotEmpty);

    final state = await userDatabase.userDataDao.findWordState(1);
    expect(state?.masteryLevel, 4);
    expect(state?.studiedCount, 10);
    expect(
      await userDatabase.select(userDatabase.favoriteWords).get(),
      hasLength(1),
    );
    expect(
      await userDatabase.select(userDatabase.practiceSessions).get(),
      hasLength(1),
    );
    expect(
      await userDatabase.select(userDatabase.practiceAnswers).get(),
      hasLength(1),
    );
    expect(
      await userDatabase.select(userDatabase.learningEvents).get(),
      hasLength(1),
    );

    final repeated = await repository.importBackup(
      bytes,
      mode: BackupImportMode.merge,
    );
    expect(repeated.skippedCounts.practiceSessions, 1);
    expect(
      await userDatabase.select(userDatabase.practiceSessions).get(),
      hasLength(1),
    );
    expect(
      await userDatabase.select(userDatabase.learningEvents).get(),
      hasLength(1),
    );
  });

  test('覆盖模式先清空旧业务记录，再恢复输入快照', () async {
    final now = DateTime.utc(2026, 8, 15, 12);
    await userDatabase.userDataDao.upsertWordState(
      UserWordStatesCompanion.insert(
        wordId: const Value(1),
        studiedCount: const Value(99),
        updatedAt: now,
      ),
    );
    await userDatabase.userDataDao.insertFavoriteWord(
      FavoriteWordsCompanion.insert(
        id: 'old-favorite',
        wordId: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final repository = createRepository();
    await repository.importBackup(
      encode(snapshot(stateEventId: 'replacement-event')),
      mode: BackupImportMode.overwrite,
    );

    final state = await userDatabase.userDataDao.findWordState(1);
    expect(state?.studiedCount, 5);
    expect(
      (await userDatabase.select(userDatabase.favoriteWords).get()).single.id,
      'favorite-word-1',
    );
    expect(
      await userDatabase.select(userDatabase.backupHistory).get(),
      hasLength(2),
    );
  });

  test('导出包导入全新用户库后全部业务数据保持等价', () async {
    final sourceRepository = createRepository();
    await sourceRepository.importBackup(
      encode(snapshot(stateEventId: 'roundtrip-event')),
      mode: BackupImportMode.merge,
    );
    final exported = await sourceRepository.exportBackup();

    final targetUserDatabase = UserDatabase.forExecutor(
      NativeDatabase.memory(),
    );
    addTearDown(targetUserDatabase.close);
    final targetRepository = LocalBackupRepository(
      contentDatabase,
      targetUserDatabase,
      appVersion: 'target-app-v1',
      contentVersion: 'content-v1',
    );

    final report = await targetRepository.importBackup(
      exported.bytes,
      mode: BackupImportMode.overwrite,
    );
    expect(report.importedCounts.userWordStates, 1);
    expect(report.importedCounts.favoriteWords, 1);
    expect(report.importedCounts.favoriteSentences, 1);
    expect(report.importedCounts.practiceSessions, 1);
    expect(report.importedCounts.practiceAnswers, 1);
    expect(report.importedCounts.learningEvents, 1);
    expect(report.importedCounts.appSettings, 1);

    final sourceSnapshot = BackupPackageCodec().decode(exported.bytes).snapshot;
    final targetExport = await targetRepository.exportBackup();
    final targetSnapshot = BackupPackageCodec()
        .decode(targetExport.bytes)
        .snapshot;
    const dataCodec = BackupDataCodec();
    expect(
      dataCodec.encode(targetSnapshot!),
      dataCodec.encode(sourceSnapshot!),
    );
  });

  test('清除用户数据前保存保护备份并保留词库与备份历史', () async {
    await createRepository().importBackup(
      encode(snapshot(stateEventId: 'reset-event')),
      mode: BackupImportMode.merge,
    );
    BackupExport? savedProtection;
    final repository = LocalBackupRepository(
      contentDatabase,
      userDatabase,
      appVersion: 'test-app-v1',
      contentVersion: 'content-v1',
      protectionSink: (backup) async => savedProtection = backup,
    );

    final result = await repository.resetUserData();

    expect(savedProtection, isNot(equals(null)));
    expect(result.fileName, savedProtection!.fileName);
    expect(result.clearedCounts.userWordStates, 1);
    expect(result.clearedCounts.favoriteWords, 1);
    expect(
      BackupPackageCodec().decode(savedProtection!.bytes).snapshot,
      isNot(equals(null)),
    );
    final rows = await userDatabase.userDataDao.readBackupRows();
    expect(rows.userWordStates, isEmpty);
    expect(rows.favoriteWords, isEmpty);
    expect(rows.favoriteSentences, isEmpty);
    expect(rows.practiceSessions, isEmpty);
    expect(rows.practiceAnswers, isEmpty);
    expect(rows.learningEvents, isEmpty);
    expect(rows.appSettings, equals(null));
    expect(
      await contentDatabase.contentDao.findWordById(1),
      isNot(equals(null)),
    );
    expect((await repository.findHistory()).first.type, 'reset');
  });

  test('保护备份落盘失败时拒绝清除任何用户数据', () async {
    await createRepository().importBackup(
      encode(snapshot(stateEventId: 'failed-reset-event')),
      mode: BackupImportMode.merge,
    );
    final repository = LocalBackupRepository(
      contentDatabase,
      userDatabase,
      appVersion: 'test-app-v1',
      contentVersion: 'content-v1',
      protectionSink: (_) async => throw StateError('disk unavailable'),
    );

    await expectLater(repository.resetUserData(), throwsStateError);

    final rows = await userDatabase.userDataDao.readBackupRows();
    expect(rows.userWordStates, hasLength(1));
    expect(rows.favoriteWords, hasLength(1));
    expect(rows.favoriteSentences, hasLength(1));
    expect(rows.practiceSessions, hasLength(1));
    expect(rows.practiceAnswers, hasLength(1));
    expect(rows.learningEvents, hasLength(1));
    expect(rows.appSettings, isNot(equals(null)));
  });

  test('保护备份后若事务约束失败，所有导入写入整体回滚', () async {
    final repository = LocalBackupRepository(
      contentDatabase,
      userDatabase,
      appVersion: 'test-app-v1',
      contentVersion: 'content-v1',
      protectionSink: (_) async {
        // 模拟预检后到事务开始前另一个写入者占用了唯一内容键。
        await userDatabase.userDataDao.insertFavoriteWord(
          FavoriteWordsCompanion.insert(
            id: 'race-favorite',
            wordId: 1,
            createdAt: DateTime.utc(2026, 8, 15),
            updatedAt: DateTime.utc(2026, 8, 15),
          ),
        );
      },
    );

    await expectLater(
      repository.importBackup(
        encode(snapshot(stateEventId: 'rollback-event')),
        mode: BackupImportMode.merge,
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      await userDatabase.select(userDatabase.userWordStates).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.practiceSessions).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.practiceAnswers).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.learningEvents).get(),
      isEmpty,
    );
    expect(
      await userDatabase.select(userDatabase.favoriteWords).get(),
      hasLength(1),
    );
  });
}

Archive archiveFrom(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

List<int> encodeFutureFormat(Archive source, int formatVersion) {
  final futureArchive = Archive();
  for (final file in source) {
    final content = file.name == 'manifest.json'
        ? (() {
            final manifest = jsonDecode(utf8.decode(file.content)) as Map;
            manifest['formatVersion'] = formatVersion;
            return utf8.encode(jsonEncode(manifest));
          })()
        : file.content;
    futureArchive.addFile(ArchiveFile(file.name, content.length, content));
  }
  return ZipEncoder().encode(futureArchive);
}
