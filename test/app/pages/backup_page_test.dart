import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_history_record.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_manifest.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_record_counts.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_page.dart';
import 'package:flutter_ielts_glossary/app/repositories/backup_repository.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_transfer_service.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  testWidgets('覆盖恢复显示替换数量并要求二次确认', (tester) async {
    final dependencies = await createTestAppDependencies();
    final repository = _PageBackupRepository();
    final transfer = _PageBackupTransferService();
    addTearDown(() async {
      Get.reset();
      await transfer.dispose();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    Get.replace<BackupRepository>(repository);
    Get.replace<BackupTransferService>(transfer);
    expect(Get.find<BackupTransferService>(), same(transfer));
    BackupBinding(autoLoadHistory: false).dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: BackupPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('选择备份文件'));
    await tester.pumpAndSettle();
    expect(find.text('当前数据 4 条'), findsOneWidget);

    await tester.tap(find.text('覆盖恢复'));
    await tester.pumpAndSettle();
    expect(find.text('确认覆盖恢复？'), findsOneWidget);
    expect(find.textContaining('将替换当前 4 条用户数据'), findsOneWidget);
    expect(repository.importModes, isEmpty);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('确认覆盖恢复？'), findsNothing);
    expect(repository.importModes, isEmpty);

    await tester.tap(find.text('覆盖恢复'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认覆盖'));
    await tester.pump();
    expect(repository.importModes, [BackupImportMode.overwrite]);
  });

  testWidgets('顶部使用原生 Material 3 AppBar，最近备份记录可确认删除', (tester) async {
    final dependencies = await createTestAppDependencies();
    final repository = _PageBackupRepository()..history = [_history];
    final transfer = _PageBackupTransferService();
    addTearDown(() async {
      Get.reset();
      await transfer.dispose();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    Get.replace<BackupRepository>(repository);
    Get.replace<BackupTransferService>(transfer);
    BackupBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: BackupPage()));
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, isNull);
    expect(appBar.centerTitle, isNull);
    expect(appBar.systemOverlayStyle, isNull);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    final delete = find.byKey(
      const ValueKey('backup-history-delete-history-1'),
    );
    expect(delete, findsOneWidget);
    expect(tester.widget<IconButton>(delete).onPressed, isNotNull);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('删除备份记录？'), findsOneWidget);
    expect(find.text('仅删除此历史记录，不会删除已保存或已分享的备份文件。'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(repository.deletedHistoryIds, ['history-1']);
    expect(find.text(_history.fileName), findsNothing);
    expect(find.text('还没有备份操作记录。'), findsOneWidget);
  });
}

final class _PageBackupRepository implements BackupRepository {
  final List<BackupImportMode> importModes = [];
  List<BackupHistoryRecord> history = [];
  final List<String> deletedHistoryIds = [];

  @override
  Future<BackupExport> exportBackup() => throw UnimplementedError();

  @override
  Future<List<BackupHistoryRecord>> findHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return history.take(limit).toList(growable: false);
  }

  @override
  Future<void> deleteHistoryRecord(String id) async {
    deletedHistoryIds.add(id);
    history = history.where((record) => record.id != id).toList();
  }

  @override
  Future<BackupImportPreview> previewImport(
    List<int> bytes, {
    BackupProgressCallback? onProgress,
  }) async {
    return BackupImportPreview(
      manifest: _manifest,
      recordCounts: _counts,
      existingRecordCount: 4,
      conflictCount: 1,
      missingWordIds: const {},
      missingSentenceIds: const {},
      rejectedRecordCount: 0,
      canImport: true,
      isFutureFormat: false,
    );
  }

  @override
  Future<BackupImportReport> importBackup(
    List<int> bytes, {
    required BackupImportMode mode,
    BackupProgressCallback? onProgress,
  }) async {
    importModes.add(mode);
    return BackupImportReport(
      mode: mode,
      importedCounts: _counts,
      skippedCounts: _emptyCounts,
      conflictCount: 1,
      missingWordIds: const {},
      missingSentenceIds: const {},
      protectionBackupBytes: Uint8List.fromList([1]),
    );
  }
}

final class _PageBackupTransferService implements BackupTransferService {
  final File file = File('.cache/backup-page-unused.ieltsbackup');

  @override
  Future<BackupImportSelection?> pickImport({
    BackupTransferProgressCallback? onProgress,
  }) {
    return Future.value(
      BackupImportSelection(
        fileName: 'selected.ieltsbackup',
        bytes: Uint8List.fromList([1, 2, 3]),
        stagedFile: file,
      ),
    );
  }

  @override
  Future<BackupShareStatus> shareExport(BackupExport backup) async {
    return BackupShareStatus.success;
  }

  Future<void> dispose() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final _manifest = BackupManifest(
  formatVersion: 1,
  appVersion: 'test',
  userSchemaVersion: 1,
  contentVersion: 'test',
  exportedAt: DateTime.utc(2026, 8, 15),
  recordCounts: _counts,
  dataSha256:
      '0000000000000000000000000000000000000000000000000000000000000000',
);

final _history = BackupHistoryRecord(
  id: 'history-1',
  type: 'export',
  fileName: 'history-export.ieltsbackup',
  summaryJson: '{}',
  result: 'success',
  occurredAt: DateTime.utc(2026, 8, 15),
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
