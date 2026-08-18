import '../database/content/content_database.dart';
import '../database/user/user_database.dart';
import '../models/domain/app_settings_state.dart';
import '../repositories/local_content_repository.dart';
import '../repositories/local_backup_repository.dart';
import '../repositories/local_favorite_repository.dart';
import '../repositories/local_favorite_list_repository.dart';
import '../repositories/local_learning_repository.dart';
import '../repositories/local_practice_repository.dart';
import '../repositories/local_question_candidate_repository.dart';
import '../repositories/local_statistics_repository.dart';
import '../repositories/local_statistics_report_repository.dart';
import '../repositories/local_review_queue_repository.dart';
import '../repositories/local_settings_repository.dart';
import '../repositories/local_study_candidate_repository.dart';
import '../repositories/local_vocabulary_repository.dart';
import '../repositories/pronunciation_assessment_config_repository.dart';
import '../repositories/tts_config_repository.dart';
import '../services/clock/monotonic_clock.dart';
import '../services/backup/backup_file_store.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/audio/audio_recorder.dart';
import '../services/content/content_installation.dart';
import '../models/app/app_build_info.dart';
import '../services/content/content_validation.dart';
import '../services/question/practice_answer_evaluator.dart';
import '../services/question/question_engine.dart';
import '../services/backup/backup_transfer_service.dart';
import '../services/user/user_database_recovery.dart';
import 'app_dependencies.dart';

typedef ContentDatabaseFactory = ContentDatabase Function();
typedef UserDatabaseFactory = UserDatabase Function();

enum ApplicationBootstrapStage {
  installingContent,
  openingContentDatabase,
  openingUserDatabase,
  creatingRepositories,
}

/// 启动初始化当前阶段及可选的内容复制百分比。
final class ApplicationBootstrapProgress {
  const ApplicationBootstrapProgress({required this.stage, this.fraction});

  final ApplicationBootstrapStage stage;
  final double? fraction;
}

typedef ApplicationBootstrapProgressCallback =
    void Function(ApplicationBootstrapProgress progress);

/// 启动错误页可执行的一次性恢复动作。
typedef ApplicationBootstrapRecoveryAction = Future<void> Function();

/// 启动失败的稳定阶段和错误码，不向界面暴露底层异常正文。
final class ApplicationBootstrapException implements Exception {
  const ApplicationBootstrapException({
    required this.stage,
    required this.code,
    required this.message,
    this.recoveryAction,
  });

  final ApplicationBootstrapStage stage;
  final String code;
  final String message;
  final ApplicationBootstrapRecoveryAction? recoveryAction;

  @override
  String toString() => '${stage.name}/$code: $message';
}

/// 按内容安装、内容库、用户库、Repository 的固定顺序初始化应用。
final class ApplicationBootstrapService {
  const ApplicationBootstrapService({
    required this.contentInstallation,
    required this.openContentDatabase,
    required this.openUserDatabase,
    required this.backupFileStore,
    required this.backupTransferService,
    required this.pronunciationService,
    required this.audioRecorder,
    required this.pronunciationAssessmentConfigRepository,
    required this.ttsConfigRepository,
    this.userDatabaseRecovery,
  });

  final ContentInstallationService contentInstallation;
  final ContentDatabaseFactory openContentDatabase;
  final UserDatabaseFactory openUserDatabase;
  final BackupFileStore backupFileStore;
  final BackupTransferService backupTransferService;
  final PronunciationService pronunciationService;
  final AudioRecorderPort audioRecorder;
  final PronunciationAssessmentConfigRepository
  pronunciationAssessmentConfigRepository;
  final TtsConfigRepository ttsConfigRepository;
  final UserDatabaseRecovery? userDatabaseRecovery;

  Future<AppDependencies> initialize({
    ApplicationBootstrapProgressCallback? onProgress,
  }) async {
    var stage = ApplicationBootstrapStage.installingContent;
    ContentDatabase? contentDatabase;
    UserDatabase? userDatabase;
    try {
      _notifyProgress(onProgress, stage);
      final installResult = await contentInstallation.install(
        onProgress: (progress) {
          final fraction = progress.fraction;
          _notifyProgress(
            onProgress,
            stage,
            fraction: progress.phase == ContentInstallPhase.copyingDatabase
                ? fraction
                : progress.phase == ContentInstallPhase.publishing
                ? 1
                : null,
          );
        },
      );

      stage = ApplicationBootstrapStage.openingContentDatabase;
      _notifyProgress(onProgress, stage);
      contentDatabase = openContentDatabase();
      final metadata = await contentDatabase.contentDao.findMetadata();
      if (metadata == null) {
        throw const ApplicationBootstrapException(
          stage: ApplicationBootstrapStage.openingContentDatabase,
          code: 'missing_content_metadata',
          message: '已安装词库缺少内容元数据',
        );
      }

      stage = ApplicationBootstrapStage.openingUserDatabase;
      _notifyProgress(onProgress, stage);
      userDatabase = openUserDatabase();
      await userDatabase.customSelect('SELECT 1 AS value').getSingle();

      stage = ApplicationBootstrapStage.creatingRepositories;
      _notifyProgress(onProgress, stage);
      final contentRepository = LocalContentRepository(
        contentDatabase.contentDao,
      );
      final learningRepository = LocalLearningRepository(userDatabase);
      final settingsRepository = LocalSettingsRepository(userDatabase);
      final initialSettings = await _loadInitialSettings(settingsRepository);
      final favoriteRepository = LocalFavoriteRepository(
        contentDatabase.contentDao,
        userDatabase.userDataDao,
      );
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
          appVersion: AppBuildInfo.version,
          contentVersion: installResult.manifest.contentVersion,
          protectionSink: backupFileStore.saveProtection,
        ),
        backupFileStore: backupFileStore,
        backupTransferService: backupTransferService,
        pronunciationService: pronunciationService,
        audioRecorder: audioRecorder,
        pronunciationAssessmentConfigRepository:
            pronunciationAssessmentConfigRepository,
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
        ),
        reviewQueueRepository: LocalReviewQueueRepository(
          contentDatabase.contentDao,
          userDatabase.userDataDao,
        ),
        settingsRepository: settingsRepository,
        initialThemePreference: initialSettings.themePreference,
        initialAccentPreference: initialSettings.accentPreference,
        studyCandidateRepository: LocalStudyCandidateRepository(
          contentDatabase.contentDao,
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
        questionEngine: QuestionEngine(),
        practiceAnswerEvaluator: const PracticeAnswerEvaluator(),
        contentInstallResult: installResult,
      );
    } on ApplicationBootstrapException {
      await _closePartial(userDatabase, contentDatabase);
      rethrow;
    } on ContentValidationException catch (error) {
      await _closePartial(userDatabase, contentDatabase);
      throw ApplicationBootstrapException(
        stage: stage,
        code: error.issues.firstOrNull?.code ?? 'content_validation_failed',
        message: '本地词库完整性校验失败',
      );
    } on ContentInstallException catch (error) {
      await _closePartial(userDatabase, contentDatabase);
      throw ApplicationBootstrapException(
        stage: stage,
        code: error.code,
        message: '本地词库安装失败',
      );
    } on Exception {
      await _closePartial(userDatabase, contentDatabase);
      final canRecoverUserDatabase =
          stage == ApplicationBootstrapStage.openingUserDatabase &&
          userDatabaseRecovery != null;
      throw ApplicationBootstrapException(
        stage: stage,
        code: canRecoverUserDatabase
            ? 'user_database_open_failed'
            : '${stage.name}_failed',
        message: canRecoverUserDatabase ? '用户学习数据初始化失败' : '应用本地数据初始化失败',
        recoveryAction: canRecoverUserDatabase
            ? () async {
                await userDatabaseRecovery!.backupAndReset();
              }
            : null,
      );
    }
  }

  void _notifyProgress(
    ApplicationBootstrapProgressCallback? onProgress,
    ApplicationBootstrapStage stage, {
    double? fraction,
  }) {
    try {
      onProgress?.call(
        ApplicationBootstrapProgress(stage: stage, fraction: fraction),
      );
    } on Object {
      // 状态观察器是界面辅助能力，异常不应改变初始化结果。
    }
  }

  /// 主题和强调色只影响首屏展示；设置记录异常时回退领域默认值。
  Future<AppSettingsState> _loadInitialSettings(
    LocalSettingsRepository settingsRepository,
  ) async {
    try {
      return await settingsRepository.load();
    } on Object {
      return AppSettingsState.defaults();
    }
  }

  Future<void> _closePartial(
    UserDatabase? userDatabase,
    ContentDatabase? contentDatabase,
  ) async {
    try {
      await Future.wait([
        pronunciationService.dispose(),
        audioRecorder.dispose(),
      ]);
    } on Object {
      // 初始化失败时仍继续释放数据库连接。
    }
    try {
      await userDatabase?.close();
    } on Exception {
      // 初始化已经失败，继续关闭另一连接，避免单个释放错误造成额外泄漏。
    }
    try {
      await contentDatabase?.close();
    } on Exception {
      // 释放失败由平台日志处理，启动错误码保持原始失败阶段。
    }
  }
}
