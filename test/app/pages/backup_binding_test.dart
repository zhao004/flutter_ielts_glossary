import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_import_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_management_logic.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('备份 Binding 延迟创建管理和导入 Logic 并复用应用级依赖', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();
    BackupBinding(autoLoadHistory: false).dependencies();

    final management = Get.find<BackupManagementLogic>();
    final importLogic = Get.find<BackupImportLogic>();
    expect(management.backupRepository, same(dependencies.backupRepository));
    expect(
      management.transferService,
      same(dependencies.backupTransferService),
    );
    expect(importLogic.backupRepository, same(dependencies.backupRepository));
    expect(
      importLogic.transferService,
      same(dependencies.backupTransferService),
    );
  });
}
