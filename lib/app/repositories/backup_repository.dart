import '../models/backup/backup_operation.dart';
import '../models/backup/backup_history_record.dart';

/// 用户数据备份的导出、只读预检和事务化恢复接口。
abstract interface class BackupRepository {
  Future<BackupExport> exportBackup();

  Future<BackupImportPreview> previewImport(
    List<int> bytes, {
    BackupProgressCallback? onProgress,
  });

  Future<BackupImportReport> importBackup(
    List<int> bytes, {
    required BackupImportMode mode,
    BackupProgressCallback? onProgress,
  });

  Future<List<BackupHistoryRecord>> findHistory({
    int limit = 20,
    int offset = 0,
  });
}

/// 具备保护备份前提下清除用户业务数据的可选仓储能力。
abstract interface class UserDataResetRepository {
  Future<UserDataResetResult> resetUserData({
    BackupProgressCallback? onProgress,
  });
}
