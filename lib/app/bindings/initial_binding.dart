import 'package:get/get.dart';

import '../bootstrap/app_dependencies.dart';
import '../database/content/content_database.dart';
import '../database/user/user_database.dart';
import '../repositories/content_repository.dart';
import '../repositories/backup_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/favorite_list_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/practice_repository.dart';
import '../repositories/question_candidate_repository.dart';
import '../repositories/review_queue_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/study_candidate_repository.dart';
import '../services/content/content_installation.dart';
import '../services/backup/backup_file_store.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/audio/audio_recorder.dart';
import '../services/assessment/pronunciation_evaluator_factory.dart';
import '../services/backup/backup_transfer_service.dart';
import '../services/clock/monotonic_clock.dart';
import '../services/question/practice_answer_evaluator.dart';
import '../services/question/question_engine.dart';
import '../repositories/statistics_repository.dart';
import '../repositories/statistics_report_repository.dart';
import '../repositories/vocabulary_repository.dart';
import '../repositories/pronunciation_assessment_config_repository.dart';
import '../repositories/tts_config_repository.dart';
import '../pages/shell/main_shell_controller.dart';

/// 注册已经完成异步初始化的应用级依赖，不在 Binding 内执行文件或数据库操作。
final class InitialBinding extends Bindings {
  InitialBinding(this.appDependencies);

  final AppDependencies appDependencies;

  @override
  void dependencies() {
    Get
      ..put<AppDependencies>(appDependencies, permanent: true)
      ..put<ContentDatabase>(appDependencies.contentDatabase, permanent: true)
      ..put<UserDatabase>(appDependencies.userDatabase, permanent: true)
      ..put<ContentRepository>(
        appDependencies.contentRepository,
        permanent: true,
      )
      ..put<BackupRepository>(appDependencies.backupRepository, permanent: true)
      ..put<BackupFileStore>(appDependencies.backupFileStore, permanent: true)
      ..put<BackupTransferService>(
        appDependencies.backupTransferService,
        permanent: true,
      )
      ..put<PronunciationService>(
        appDependencies.pronunciationService,
        permanent: true,
      )
      ..put<AudioRecorderPort>(
        appDependencies.audioRecorder,
        permanent: true,
      )
      ..put<PronunciationAssessmentConfigRepository>(
        appDependencies.pronunciationAssessmentConfigRepository,
        permanent: true,
      )
      ..put<TtsConfigRepository>(
        appDependencies.ttsConfigRepository,
        permanent: true,
      )
      ..put<PronunciationEvaluatorFactory>(
        const PronunciationEvaluatorFactory(),
        permanent: true,
      )
      ..put<FavoriteRepository>(
        appDependencies.favoriteRepository,
        permanent: true,
      )
      ..put<FavoriteListRepository>(
        appDependencies.favoriteListRepository,
        permanent: true,
      )
      ..put<LearningRepository>(
        appDependencies.learningRepository,
        permanent: true,
      )
      ..put<QuestionCandidateRepository>(
        appDependencies.questionCandidateRepository,
        permanent: true,
      )
      ..put<ReviewQueueRepository>(
        appDependencies.reviewQueueRepository,
        permanent: true,
      )
      ..put<SettingsRepository>(
        appDependencies.settingsRepository,
        permanent: true,
      )
      ..put<StudyCandidateRepository>(
        appDependencies.studyCandidateRepository,
        permanent: true,
      )
      ..put<PracticeRepository>(
        appDependencies.practiceRepository,
        permanent: true,
      )
      ..put<StatisticsRepository>(
        appDependencies.statisticsRepository,
        permanent: true,
      )
      ..put<StatisticsReportRepository>(
        appDependencies.statisticsReportRepository,
        permanent: true,
      )
      ..put<VocabularyRepository>(
        appDependencies.vocabularyRepository,
        permanent: true,
      )
      ..put<MonotonicClock>(appDependencies.monotonicClock, permanent: true)
      ..put<QuestionEngine>(appDependencies.questionEngine, permanent: true)
      ..put<PracticeAnswerEvaluator>(
        appDependencies.practiceAnswerEvaluator,
        permanent: true,
      )
      ..put<ContentInstallResult>(
        appDependencies.contentInstallResult,
        permanent: true,
      )
      ..put<MainShellController>(MainShellController(), permanent: true);
  }
}
