import 'package:get/get.dart';

import '../../services/content/content_installation.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/statistics_report_repository.dart';
import '../../repositories/backup_repository.dart';
import '../statistics/statistics_logic.dart';
import 'settings_logic.dart';
import 'user_data_reset_logic.dart';

/// 仅在进入设置页时创建 Logic，应用级 Repository 和语音适配器由 InitialBinding 提供。
final class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsLogic>(
      () => SettingsLogic(
        settingsRepository: Get.find<SettingsRepository>(),
        contentInstallResult: Get.find<ContentInstallResult>(),
      ),
    );
    Get.lazyPut<StatisticsLogic>(
      () => StatisticsLogic(
        statisticsReportRepository: Get.find<StatisticsReportRepository>(),
        calendarDays: 365,
        trendDays: 30,
      ),
    );
    final backupRepository = Get.find<BackupRepository>();
    if (backupRepository is UserDataResetRepository) {
      Get.lazyPut<UserDataResetLogic>(
        () => UserDataResetLogic(
          repository: backupRepository as UserDataResetRepository,
        ),
      );
    }
  }
}
