import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../database/content/content_database_connection.dart';
import '../database/user/user_database_connection.dart';
import '../services/content/content_installer.dart';
import '../services/content/flutter_content_asset_reader.dart';
import '../services/backup/backup_file_store.dart';
import '../services/backup/backup_transfer_service.dart';
import '../services/backup/platform_backup_clients.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/audio/just_audio_local_player.dart';
import '../services/audio/record_audio_recorder.dart';
import '../services/tts/tts_synthesizer_factory.dart';
import '../repositories/local_pronunciation_assessment_config_repository.dart';
import '../repositories/local_tts_config_repository.dart';
import '../services/user/user_database_recovery.dart';
import 'application_bootstrap_service.dart';

/// 创建使用 Flutter 资产和应用支持目录的生产启动服务。
Future<ApplicationBootstrapService> createPlatformApplicationBootstrap({
  AssetBundle? bundle,
}) async {
  final supportDirectory = await getApplicationSupportDirectory();
  final installer = ContentInstaller(
    applicationSupportDirectory: supportDirectory,
    assetReader: FlutterContentAssetReader(bundle: bundle),
  );
  final backupFileStore = LocalBackupFileStore(
    directoryProvider: () async => supportDirectory,
  );
  final ttsConfigRepository = LocalTtsConfigRepository(
    directoryProvider: () async => supportDirectory,
  );
  return ApplicationBootstrapService(
    contentInstallation: installer,
    openContentDatabase: () => openInstalledContentDatabase(
      applicationSupportDirectory: supportDirectory,
    ),
    openUserDatabase: () =>
        openUserDatabase(applicationSupportDirectory: supportDirectory),
    backupFileStore: backupFileStore,
    backupTransferService: PlatformBackupTransferService(
      pickerClient: const FilePickerBackupClient(),
      shareClient: const SharePlusBackupClient(),
      fileStore: backupFileStore,
      temporaryDirectoryProvider: getTemporaryDirectory,
    ),
    userDatabaseRecovery: LocalUserDatabaseRecovery(
      applicationSupportDirectory: supportDirectory,
    ),
    pronunciationService: PronunciationService(
      localPlayer: JustAudioLocalPlayer(),
      ttsConfigRepository: ttsConfigRepository,
      ttsSynthesizerFactory: const TtsSynthesizerFactory(),
    ),
    audioRecorder: RecordAudioRecorder(),
    pronunciationAssessmentConfigRepository:
        LocalPronunciationAssessmentConfigRepository(
          directoryProvider: () async => supportDirectory,
        ),
    ttsConfigRepository: ttsConfigRepository,
  );
}
