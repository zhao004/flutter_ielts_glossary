import 'package:flex_color_scheme/flex_color_scheme.dart';

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
import '../repositories/statistics_repository.dart';
import '../repositories/statistics_report_repository.dart';
import '../repositories/vocabulary_repository.dart';
import '../repositories/pronunciation_assessment_config_repository.dart';
import '../repositories/tts_config_repository.dart';
import '../services/content/content_installation.dart';
import '../services/clock/monotonic_clock.dart';
import '../services/question/practice_answer_evaluator.dart';
import '../services/question/question_engine.dart';
import '../services/backup/backup_file_store.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/audio/audio_recorder.dart';
import '../services/backup/backup_transfer_service.dart';
import '../models/domain/app_settings_state.dart';

/// 已完成初始化、可注册到 GetX 的应用级依赖集合。
final class AppDependencies {
  AppDependencies({
    required this.contentDatabase,
    required this.userDatabase,
    required this.contentRepository,
    required this.backupRepository,
    required this.backupFileStore,
    required this.backupTransferService,
    required this.pronunciationService,
    required this.audioRecorder,
    required this.pronunciationAssessmentConfigRepository,
    required this.ttsConfigRepository,
    required this.favoriteRepository,
    required this.favoriteListRepository,
    required this.learningRepository,
    required this.questionCandidateRepository,
    required this.reviewQueueRepository,
    required this.settingsRepository,
    required this.studyCandidateRepository,
    required this.practiceRepository,
    required this.statisticsRepository,
    required this.statisticsReportRepository,
    required this.vocabularyRepository,
    required this.monotonicClock,
    required this.questionEngine,
    required this.practiceAnswerEvaluator,
    required this.contentInstallResult,
    this.initialThemePreference = AppThemePreference.system,
    this.initialAccentPreference = FlexScheme.indigo,
  });

  final ContentDatabase contentDatabase;
  final UserDatabase userDatabase;
  final ContentRepository contentRepository;
  final BackupRepository backupRepository;
  final BackupFileStore backupFileStore;
  final BackupTransferService backupTransferService;
  final PronunciationService pronunciationService;
  final AudioRecorderPort audioRecorder;
  final PronunciationAssessmentConfigRepository
  pronunciationAssessmentConfigRepository;
  final TtsConfigRepository ttsConfigRepository;
  final FavoriteRepository favoriteRepository;
  final FavoriteListRepository favoriteListRepository;
  final LearningRepository learningRepository;
  final QuestionCandidateRepository questionCandidateRepository;
  final ReviewQueueRepository reviewQueueRepository;
  final SettingsRepository settingsRepository;
  final StudyCandidateRepository studyCandidateRepository;
  final PracticeRepository practiceRepository;
  final StatisticsRepository statisticsRepository;
  final StatisticsReportRepository statisticsReportRepository;
  final VocabularyRepository vocabularyRepository;
  final MonotonicClock monotonicClock;
  final QuestionEngine questionEngine;
  final PracticeAnswerEvaluator practiceAnswerEvaluator;
  final ContentInstallResult contentInstallResult;

  /// 启动时从用户库恢复的主题偏好；设置页后续更新仍通过 GetX 即时生效。
  final AppThemePreference initialThemePreference;

  /// 启动时从用户库恢复的品牌强调色；设置页后续更新仍通过 GetX 即时生效。
  final FlexScheme initialAccentPreference;

  bool _closed = false;

  bool get isClosed => _closed;

  /// 关闭应用级数据库连接；重复调用不会重复释放资源。
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await Future.wait([
        pronunciationService.dispose(),
        audioRecorder.dispose(),
      ]);
    } finally {
      await Future.wait([userDatabase.close(), contentDatabase.close()]);
    }
  }
}
