import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:flutter_ielts_glossary/app/bootstrap/app_dependencies.dart';
import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/content/content_asset_names.dart';
import 'package:flutter_ielts_glossary/app/models/content/content_manifest.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_content_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_backup_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_list_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_practice_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_question_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_statistics_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_statistics_report_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_review_queue_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_settings_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_study_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_vocabulary_repository.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_installation.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_file_store.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_transfer_service.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_operation.dart';
import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_recorder.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/repositories/tts_config_repository.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_config.dart';
import 'package:flutter_ielts_glossary/app/services/tts/tts_synthesizer_factory.dart';
import 'package:flutter_ielts_glossary/app/services/clock/monotonic_clock.dart';
import 'package:flutter_ielts_glossary/app/services/question/practice_answer_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_engine.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

const String testSha256 =
    '0000000000000000000000000000000000000000000000000000000000000000';

Future<ContentDatabase> createTestContentDatabase({
  String version = 'test-v1',
  bool includeMetadata = true,
}) async {
  final database = ContentDatabase.forExecutor(NativeDatabase.memory());
  if (includeMetadata) {
    await database
        .into(database.contentMetadata)
        .insert(
          ContentMetadataCompanion.insert(
            contentVersion: version,
            formatVersion: ContentManifest.currentFormatVersion,
            sourceRepository: 'https://example.invalid/test',
            sourceRevision: 'test-revision',
            generatedAt: DateTime.utc(2026, 8, 14, 12),
            wordCount: 1,
            sentenceCount: 1,
            licenseNotice: '仅用于自动化测试。',
            sha256: testSha256,
          ),
        );
  } else {
    await database.customSelect('SELECT 1 AS value').getSingle();
  }
  return database;
}

UserDatabase createTestUserDatabase() {
  return UserDatabase.forExecutor(NativeDatabase.memory());
}

PronunciationService createTestPronunciationService({
  TtsConfigRepository? ttsConfigRepository,
  TtsSynthesizerFactory? ttsSynthesizerFactory,
}) {
  return PronunciationService(
    localPlayer: _TestLocalAudioPlayer(),
    ttsConfigRepository: ttsConfigRepository ?? createTestTtsConfigRepository(),
    ttsSynthesizerFactory:
        ttsSynthesizerFactory ?? const TtsSynthesizerFactory(),
  );
}

AudioRecorderPort createTestAudioRecorder() => _TestAudioRecorder();

PronunciationAssessmentConfigRepository
createTestAssessmentConfigRepository() => _TestAssessmentConfigRepository();

TtsConfigRepository createTestTtsConfigRepository() =>
    _TestTtsConfigRepository();

BackupFileStore createTestBackupFileStore() {
  return LocalBackupFileStore(
    directoryProvider: () async => Directory('.cache/test-backups'),
  );
}

BackupTransferService createTestBackupTransferService() =>
    _TestBackupTransferService();

ContentInstallResult createTestInstallResult({String version = 'test-v1'}) {
  final manifest = ContentManifest(
    formatVersion: ContentManifest.currentFormatVersion,
    contentVersion: version,
    sourceRepository: 'https://example.invalid/test',
    sourceRevision: 'test-revision',
    generatedAt: DateTime.utc(2026, 8, 14, 12),
    databaseFile: ContentAssetNames.databaseFile,
    databaseBytes: 1,
    databaseSha256: testSha256,
    sourceDataSha256: testSha256,
    wordCount: 1,
    sentenceCount: 1,
    activeGroupCount: ContentManifest.expectedActiveGroupCount,
    groupWordCounts: const {1: 1, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
    licenseNotice: '仅用于自动化测试。',
  );
  return ContentInstallResult(
    status: ContentInstallStatus.alreadyCurrent,
    manifest: manifest,
    databaseFile: File('.cache/test-content/${ContentAssetNames.databaseFile}'),
    manifestFile: File('.cache/test-content/${ContentAssetNames.manifestFile}'),
    retainedBackupFiles: const [],
  );
}

Future<AppDependencies> createTestAppDependencies({
  String version = 'test-v1',
  AppThemePreference initialThemePreference = AppThemePreference.system,
  FlexScheme initialAccentPreference = FlexScheme.indigo,
}) async {
  final contentDatabase = await createTestContentDatabase(version: version);
  final userDatabase = createTestUserDatabase();
  final backupFileStore = createTestBackupFileStore();
  final backupTransferService = createTestBackupTransferService();
  final pronunciationService = createTestPronunciationService();
  final audioRecorder = createTestAudioRecorder();
  final assessmentConfigRepository = createTestAssessmentConfigRepository();
  final ttsConfigRepository = createTestTtsConfigRepository();
  final contentRepository = LocalContentRepository(contentDatabase.contentDao);
  final favoriteRepository = LocalFavoriteRepository(
    contentDatabase.contentDao,
    userDatabase.userDataDao,
  );
  final learningRepository = LocalLearningRepository(userDatabase);
  final statisticsRepository = LocalStatisticsRepository(
    userDatabase.userDataDao,
  );
  return AppDependencies(
    contentDatabase: contentDatabase,
    userDatabase: userDatabase,
    contentRepository: contentRepository,
    backupRepository: LocalBackupRepository(
      contentDatabase,
      userDatabase,
      appVersion: 'test-app-v1',
      contentVersion: version,
      protectionSink: backupFileStore.saveProtection,
    ),
    backupFileStore: backupFileStore,
    backupTransferService: backupTransferService,
    pronunciationService: pronunciationService,
    audioRecorder: audioRecorder,
    pronunciationAssessmentConfigRepository: assessmentConfigRepository,
    ttsConfigRepository: ttsConfigRepository,
    favoriteRepository: favoriteRepository,
    favoriteListRepository: LocalFavoriteListRepository(
      favoriteRepository,
      contentRepository,
      learningRepository,
    ),
    learningRepository: learningRepository,
    questionCandidateRepository: LocalQuestionCandidateRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
      randomSource: DartQuestionRandomSource(seed: 20260814),
    ),
    reviewQueueRepository: LocalReviewQueueRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
    ),
    settingsRepository: LocalSettingsRepository(userDatabase),
    studyCandidateRepository: LocalStudyCandidateRepository(
      contentDatabase.contentDao,
      randomSource: DartQuestionRandomSource(seed: 20260814),
    ),
    practiceRepository: LocalPracticeRepository(userDatabase),
    statisticsRepository: statisticsRepository,
    statisticsReportRepository: LocalStatisticsReportRepository(
      statisticsRepository,
      learningRepository,
    ),
    vocabularyRepository: LocalVocabularyRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
    ),
    monotonicClock: StopwatchMonotonicClock(),
    questionEngine: QuestionEngine(
      randomSource: DartQuestionRandomSource(seed: 20260814),
    ),
    practiceAnswerEvaluator: const PracticeAnswerEvaluator(),
    contentInstallResult: createTestInstallResult(version: version),
    initialThemePreference: initialThemePreference,
    initialAccentPreference: initialAccentPreference,
  );
}

final class _TestLocalAudioPlayer implements LocalAudioPlayer {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {}

  @override
  Future<void> stop() async {}
}

final class _TestBackupTransferService implements BackupTransferService {
  @override
  Future<BackupImportSelection?> pickImport({
    BackupTransferProgressCallback? onProgress,
  }) async => null;

  @override
  Future<BackupShareStatus> shareExport(BackupExport backup) async {
    return BackupShareStatus.unavailable;
  }
}

final class _TestAudioRecorder implements AudioRecorderPort {
  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<RecordedAudio> stop() async {
    return RecordedAudio(pcmBytes: Uint8List(0));
  }
}

final class _TestAssessmentConfigRepository
    implements PronunciationAssessmentConfigRepository {
  @override
  Future<PronunciationAssessmentConfig> load() async {
    return PronunciationAssessmentConfig.defaults();
  }

  @override
  Future<PronunciationAssessmentConfig> save(
    PronunciationAssessmentConfig config,
  ) async {
    return config;
  }
}

final class _TestTtsConfigRepository implements TtsConfigRepository {
  @override
  Future<TtsConfig> load() async {
    return TtsConfig.defaults();
  }

  @override
  Future<TtsConfig> save(TtsConfig config) async {
    return config;
  }
}
