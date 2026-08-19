import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/backup/backup_history_record.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_manifest.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_record_counts.dart';
import 'package:flutter_ielts_glossary/app/models/domain/backup_management_state.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_management_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/backup_repository.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_transfer_service.dart';

void main() {
  test('历史查询区分空列表、成功和失败，并在失败时保留旧数据', () async {
    final repository = _FakeBackupRepository();
    final logic = BackupManagementLogic(
      backupRepository: repository,
      transferService: _FakeTransferService(),
      autoLoadHistory: false,
    );
    addTearDown(logic.onClose);

    await logic.loadHistory();
    expect(logic.historyState.phase, BackupHistoryPhase.empty);

    repository.history = [_history];
    await logic.loadHistory();
    expect(logic.historyState.phase, BackupHistoryPhase.loaded);
    expect(logic.historyState.records, [_history]);

    repository.failHistory = true;
    await logic.loadHistory();
    expect(logic.historyState.phase, BackupHistoryPhase.error);
    expect(logic.historyState.errorCode, BackupHistoryErrorCodes.loadFailed);
    expect(logic.historyState.records, [_history]);
  });

  test('删除历史记录成功后移除当前项，失败时保留原记录并标记对应错误', () async {
    final repository = _FakeBackupRepository()
      ..history = [_history, _secondHistory];
    final logic = BackupManagementLogic(
      backupRepository: repository,
      transferService: _FakeTransferService(),
      autoLoadHistory: false,
    );
    addTearDown(logic.onClose);

    await logic.loadHistory();
    await logic.deleteHistoryRecord(_history.id);

    expect(repository.deletedHistoryIds, [_history.id]);
    expect(logic.historyState.phase, BackupHistoryPhase.loaded);
    expect(logic.historyState.records, [_secondHistory]);
    expect(logic.historyState.deletingRecordId, isNull);

    repository.failDeleteHistory = true;
    await logic.deleteHistoryRecord(_secondHistory.id);

    expect(logic.historyState.records, [_secondHistory]);
    expect(logic.historyState.errorCode, BackupHistoryErrorCodes.deleteFailed);
    expect(logic.historyState.errorRecordId, _secondHistory.id);
  });

  test('导出成功只保留清单摘要、调用系统分享并刷新历史', () async {
    final repository = _FakeBackupRepository()..history = [_history];
    final transfer = _FakeTransferService();
    final logic = BackupManagementLogic(
      backupRepository: repository,
      transferService: transfer,
      autoLoadHistory: false,
    );
    addTearDown(logic.onClose);

    await logic.exportAndShare();

    expect(logic.exportState.phase, BackupExportPhase.completed);
    expect(logic.exportState.fileName, _export.fileName);
    expect(logic.exportState.manifest, same(_manifest));
    expect(logic.exportState.errorCode, isNull);
    expect(repository.exportCount, 1);
    expect(transfer.shared, same(_export));
    expect(logic.historyState.records, [_history]);
  });

  test('关闭分享面板是正常结果，平台不可用使用稳定错误码', () async {
    final repository = _FakeBackupRepository();
    final transfer = _FakeTransferService()
      ..shareStatus = BackupShareStatus.dismissed;
    final logic = BackupManagementLogic(
      backupRepository: repository,
      transferService: transfer,
      autoLoadHistory: false,
    );
    addTearDown(logic.onClose);

    await logic.exportAndShare();
    expect(logic.exportState.phase, BackupExportPhase.dismissed);
    expect(logic.exportState.errorCode, isNull);

    transfer.shareStatus = BackupShareStatus.unavailable;
    await logic.exportAndShare();
    expect(logic.exportState.phase, BackupExportPhase.error);
    expect(
      logic.exportState.errorCode,
      BackupExportErrorCodes.shareUnavailable,
    );
  });

  test('导出和分享异常使用不同错误码且可重新执行', () async {
    final repository = _FakeBackupRepository()..failExport = true;
    final transfer = _FakeTransferService();
    final logic = BackupManagementLogic(
      backupRepository: repository,
      transferService: transfer,
      autoLoadHistory: false,
    );
    addTearDown(logic.onClose);

    await logic.exportAndShare();
    expect(logic.exportState.errorCode, BackupExportErrorCodes.exportFailed);
    expect(transfer.shareCount, 0);

    repository.failExport = false;
    transfer.failShare = true;
    await logic.exportAndShare();
    expect(logic.exportState.errorCode, BackupExportErrorCodes.shareFailed);
    expect(transfer.shareCount, 1);
  });

  test('关闭后忽略晚返回导出且不调用平台分享', () async {
    final repository = _FakeBackupRepository()..blockNextExport();
    final transfer = _FakeTransferService();
    final logic = BackupManagementLogic(
      backupRepository: repository,
      transferService: transfer,
      autoLoadHistory: false,
    );

    final pending = logic.exportAndShare();
    await repository.exportEntered!.future;
    logic.onClose();
    repository.releaseExport();
    await pending;

    expect(logic.exportState.phase, BackupExportPhase.exporting);
    expect(transfer.shareCount, 0);
  });
}

final class _FakeBackupRepository implements BackupRepository {
  bool failExport = false;
  bool failHistory = false;
  bool failDeleteHistory = false;
  int exportCount = 0;
  List<BackupHistoryRecord> history = [];
  final List<String> deletedHistoryIds = [];
  Completer<void>? exportEntered;
  Completer<void>? _exportRelease;

  @override
  Future<BackupExport> exportBackup() async {
    exportCount++;
    final entered = exportEntered;
    final release = _exportRelease;
    if (entered != null && release != null) {
      if (!entered.isCompleted) {
        entered.complete();
      }
      await release.future;
    }
    if (failExport) {
      throw Exception('export failed');
    }
    return _export;
  }

  @override
  Future<List<BackupHistoryRecord>> findHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    if (failHistory) {
      throw Exception('history failed');
    }
    return history.take(limit).toList(growable: false);
  }

  @override
  Future<void> deleteHistoryRecord(String id) async {
    deletedHistoryIds.add(id);
    if (failDeleteHistory) {
      throw Exception('delete history failed');
    }
    history = history.where((record) => record.id != id).toList();
  }

  @override
  Future<BackupImportReport> importBackup(
    List<int> bytes, {
    required BackupImportMode mode,
    BackupProgressCallback? onProgress,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BackupImportPreview> previewImport(
    List<int> bytes, {
    BackupProgressCallback? onProgress,
  }) {
    throw UnimplementedError();
  }

  void blockNextExport() {
    exportEntered = Completer<void>();
    _exportRelease = Completer<void>();
  }

  void releaseExport() {
    final release = _exportRelease;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }
}

final class _FakeTransferService implements BackupTransferService {
  BackupShareStatus shareStatus = BackupShareStatus.success;
  bool failShare = false;
  int shareCount = 0;
  BackupExport? shared;

  @override
  Future<BackupImportSelection?> pickImport({
    BackupTransferProgressCallback? onProgress,
  }) async => null;

  @override
  Future<BackupShareStatus> shareExport(BackupExport backup) async {
    shareCount++;
    shared = backup;
    if (failShare) {
      throw Exception('share failed');
    }
    return shareStatus;
  }
}

final _manifest = BackupManifest(
  formatVersion: 1,
  appVersion: 'test',
  userSchemaVersion: 1,
  contentVersion: 'test',
  exportedAt: DateTime.utc(2026, 8, 15),
  recordCounts: _emptyCounts,
  dataSha256:
      '0000000000000000000000000000000000000000000000000000000000000000',
);

final _export = BackupExport(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'ielts_vocab_20260815_000000.ieltsbackup',
  manifest: _manifest,
);

final _history = BackupHistoryRecord(
  id: 'history-1',
  type: 'export',
  fileName: _export.fileName,
  summaryJson: '{}',
  result: 'success',
  occurredAt: DateTime.utc(2026, 8, 15),
);

final _secondHistory = BackupHistoryRecord(
  id: 'history-2',
  type: 'import',
  fileName: 'imported.ieltsbackup',
  summaryJson: '{}',
  result: 'success',
  occurredAt: DateTime.utc(2026, 8, 14),
);

const _emptyCounts = BackupRecordCounts(
  userWordStates: 0,
  favoriteWords: 0,
  favoriteSentences: 0,
  practiceSessions: 0,
  practiceAnswers: 0,
  learningEvents: 0,
  appSettings: 0,
);
