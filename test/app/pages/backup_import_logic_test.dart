import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/backup/backup_manifest.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_record_counts.dart';
import 'package:flutter_ielts_glossary/app/models/domain/backup_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_history_record.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_import_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/backup_repository.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_transfer_service.dart';

void main() {
  test('取消选择保持 idle，成功预检后确认导入并清理暂存文件', () async {
    final root = await _createTestRoot();
    addTearDown(() => _deleteTestRoot(root));
    final transfer = _FakeTransfer(root);
    final repository = _FakeRepository();
    final logic = BackupImportLogic(
      backupRepository: repository,
      transferService: transfer,
    );
    addTearDown(logic.onClose);

    await logic.pickAndPreview();
    expect(logic.state.phase, BackupRunPhase.awaitingConfirmation);
    expect(logic.state.preview?.canImport, isTrue);
    final staged = transfer.selection!.stagedFile;
    await logic.confirm(BackupImportMode.merge);

    expect(logic.state.phase, BackupRunPhase.completed);
    expect(logic.state.report?.mode, BackupImportMode.merge);
    expect(repository.importModes, [BackupImportMode.merge]);
    expect(await staged.exists(), isFalse);
  });

  test('取消选择不调用预检，未来版本只展示不可导入状态', () async {
    final root = await _createTestRoot();
    addTearDown(() => _deleteTestRoot(root));
    final transfer = _FakeTransfer(root, returnNull: true);
    final repository = _FakeRepository();
    final logic = BackupImportLogic(
      backupRepository: repository,
      transferService: transfer,
    );
    addTearDown(logic.onClose);
    await logic.pickAndPreview();
    expect(logic.state.phase, BackupRunPhase.idle);
    expect(repository.previewCount, 0);

    transfer.returnNull = false;
    repository.futurePreview = true;
    await logic.pickAndPreview();
    expect(logic.state.phase, BackupRunPhase.awaitingConfirmation);
    expect(logic.state.errorCode, BackupRunErrorCodes.futureVersion);
    expect(logic.state.preview?.canImport, isFalse);
    expect(
      () => logic.confirm(BackupImportMode.overwrite),
      throwsA(isA<StateError>()),
    );
  });

  test('预检失败可复用当前暂存文件重试，导入失败保留预览', () async {
    final root = await _createTestRoot();
    addTearDown(() => _deleteTestRoot(root));
    final transfer = _FakeTransfer(root);
    final repository = _FakeRepository()..failPreview = true;
    final logic = BackupImportLogic(
      backupRepository: repository,
      transferService: transfer,
    );
    addTearDown(logic.onClose);

    await logic.pickAndPreview();
    expect(logic.state.phase, BackupRunPhase.error);
    expect(logic.state.errorCode, BackupRunErrorCodes.previewFailed);
    repository.failPreview = false;
    await logic.retry();
    expect(logic.state.phase, BackupRunPhase.awaitingConfirmation);

    repository.failImport = true;
    await logic.confirm(BackupImportMode.overwrite);
    expect(logic.state.phase, BackupRunPhase.error);
    expect(logic.state.errorCode, BackupRunErrorCodes.importFailed);
    expect(transfer.selection, isNotNull);
  });

  test('预检进行中取消后忽略晚返回结果并清理暂存文件', () async {
    final root = await _createTestRoot();
    addTearDown(() => _deleteTestRoot(root));
    final transfer = _FakeTransfer(root);
    final repository = _FakeRepository()
      ..nextProgress = const BackupProgress(
        stage: BackupProgressStage.analyzing,
        fraction: 0.5,
      )
      ..blockNextPreview();
    final logic = BackupImportLogic(
      backupRepository: repository,
      transferService: transfer,
    );
    addTearDown(logic.onClose);

    final pending = logic.pickAndPreview();
    await repository.previewEntered!.future;
    expect(logic.state.progress?.fraction, 0.5);
    final staged = transfer.selection!.stagedFile;
    await logic.cancel();
    repository.releasePreview();
    await pending;

    expect(logic.state.phase, BackupRunPhase.idle);
    expect(await staged.exists(), isFalse);
  });

  test('导入进行中取消后保持 idle 且不写入晚返回报告', () async {
    final root = await _createTestRoot();
    addTearDown(() => _deleteTestRoot(root));
    final transfer = _FakeTransfer(root);
    final repository = _FakeRepository();
    final logic = BackupImportLogic(
      backupRepository: repository,
      transferService: transfer,
    );
    addTearDown(logic.onClose);

    await logic.pickAndPreview();
    repository.blockNextImport();
    final staged = transfer.selection!.stagedFile;
    final pending = logic.confirm(BackupImportMode.merge);
    await repository.importEntered!.future;
    await logic.cancel();
    repository.releaseImport();
    await pending;

    expect(logic.state.phase, BackupRunPhase.idle);
    expect(logic.state.report, isNull);
    expect(await staged.exists(), isFalse);
  });
}

Future<Directory> _createTestRoot() async {
  final cacheDirectory = Directory('.cache');
  await cacheDirectory.create(recursive: true);
  return cacheDirectory.createTemp('backup-import-logic-test-');
}

Future<void> _deleteTestRoot(Directory root) async {
  if (await root.exists()) {
    try {
      await root.delete(recursive: true);
    } on PathNotFoundException {
      // 生命周期清理可能同时移除目录；目录已不存在时视为清理完成。
    }
  }
}

final class _FakeTransfer implements BackupTransferService {
  _FakeTransfer(this.root, {this.returnNull = false});

  final Directory root;
  bool returnNull;
  BackupImportSelection? selection;

  @override
  Future<BackupImportSelection?> pickImport({
    BackupTransferProgressCallback? onProgress,
  }) async {
    if (returnNull) {
      return null;
    }
    final stagedFile = File('${root.path}/selected.ieltsbackup');
    await stagedFile.writeAsBytes([1, 2, 3]);
    selection = BackupImportSelection(
      fileName: 'selected.ieltsbackup',
      bytes: Uint8List.fromList([1, 2, 3]),
      stagedFile: stagedFile,
    );
    return selection;
  }

  @override
  Future<BackupShareStatus> shareExport(BackupExport backup) async {
    return BackupShareStatus.success;
  }
}

final class _FakeRepository implements BackupRepository {
  bool failPreview = false;
  bool failImport = false;
  bool futurePreview = false;
  BackupProgress? nextProgress;
  int previewCount = 0;
  final List<BackupImportMode> importModes = [];
  Completer<void>? previewEntered;
  Completer<void>? _previewRelease;
  Completer<void>? importEntered;
  Completer<void>? _importRelease;

  @override
  Future<BackupExport> exportBackup() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackupHistoryRecord>> findHistory({
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BackupImportReport> importBackup(
    List<int> bytes, {
    required BackupImportMode mode,
    BackupProgressCallback? onProgress,
  }) async {
    importModes.add(mode);
    if (nextProgress != null) {
      onProgress?.call(nextProgress!);
    }
    final entered = importEntered;
    final release = _importRelease;
    if (entered != null && release != null) {
      entered.complete();
      await release.future;
    }
    if (failImport) {
      throw Exception('import failed');
    }
    return BackupImportReport(
      mode: mode,
      importedCounts: _counts,
      skippedCounts: _emptyCounts,
      conflictCount: 0,
      missingWordIds: const {},
      missingSentenceIds: const {},
      protectionBackupBytes: Uint8List.fromList([9]),
    );
  }

  @override
  Future<BackupImportPreview> previewImport(
    List<int> bytes, {
    BackupProgressCallback? onProgress,
  }) async {
    previewCount++;
    if (nextProgress != null) {
      onProgress?.call(nextProgress!);
    }
    final entered = previewEntered;
    final release = _previewRelease;
    if (entered != null && release != null) {
      entered.complete();
      await release.future;
    }
    if (failPreview) {
      throw Exception('preview failed');
    }
    return BackupImportPreview(
      manifest: _manifest,
      recordCounts: _counts,
      existingRecordCount: 7,
      conflictCount: 0,
      missingWordIds: const {},
      missingSentenceIds: const {},
      rejectedRecordCount: 0,
      canImport: !futurePreview,
      isFutureFormat: futurePreview,
    );
  }

  void blockNextPreview() {
    previewEntered = Completer<void>();
    _previewRelease = Completer<void>();
  }

  void releasePreview() {
    final release = _previewRelease;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }

  void blockNextImport() {
    importEntered = Completer<void>();
    _importRelease = Completer<void>();
  }

  void releaseImport() {
    final release = _importRelease;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
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

const _emptyCounts = BackupRecordCounts(
  userWordStates: 0,
  favoriteWords: 0,
  favoriteSentences: 0,
  practiceSessions: 0,
  practiceAnswers: 0,
  learningEvents: 0,
  appSettings: 0,
);

const _counts = BackupRecordCounts(
  userWordStates: 1,
  favoriteWords: 0,
  favoriteSentences: 0,
  practiceSessions: 0,
  practiceAnswers: 0,
  learningEvents: 0,
  appSettings: 0,
);
