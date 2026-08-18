import 'package:get/get.dart';

import '../../repositories/backup_repository.dart';
import '../../services/backup/backup_transfer_service.dart';
import 'backup_import_logic.dart';
import 'backup_management_logic.dart';

/// 仅在进入备份页面时创建导入 Logic，离开页面后由 GetX 释放暂存清理任务。
final class BackupBinding extends Bindings {
  BackupBinding({this.autoLoadHistory = true});

  final bool autoLoadHistory;

  @override
  void dependencies() {
    Get.lazyPut<BackupManagementLogic>(
      () => BackupManagementLogic(
        backupRepository: Get.find<BackupRepository>(),
        transferService: Get.find<BackupTransferService>(),
        autoLoadHistory: autoLoadHistory,
      ),
    );
    Get.lazyPut<BackupImportLogic>(
      () => BackupImportLogic(
        backupRepository: Get.find<BackupRepository>(),
        transferService: Get.find<BackupTransferService>(),
      ),
    );
  }
}
