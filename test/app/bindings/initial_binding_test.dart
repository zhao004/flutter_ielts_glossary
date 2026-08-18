import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/bootstrap/app_dependencies.dart';
import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/repositories/content_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/backup_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/favorite_list_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/practice_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/question_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/statistics_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/statistics_report_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/review_queue_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/settings_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/study_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/vocabulary_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/tts_config_repository.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_installation.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_file_store.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_transfer_service.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_recorder.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator_factory.dart';
import 'package:flutter_ielts_glossary/app/services/clock/monotonic_clock.dart';
import 'package:flutter_ielts_glossary/app/services/question/practice_answer_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_engine.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('同步注册已经初始化的应用级依赖', () async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    InitialBinding(dependencies).dependencies();

    expect(Get.find<AppDependencies>(), same(dependencies));
    expect(Get.find<ContentDatabase>(), same(dependencies.contentDatabase));
    expect(Get.find<UserDatabase>(), same(dependencies.userDatabase));
    expect(Get.find<ContentRepository>(), same(dependencies.contentRepository));
    expect(Get.find<BackupRepository>(), same(dependencies.backupRepository));
    expect(Get.find<BackupFileStore>(), same(dependencies.backupFileStore));
    expect(
      Get.find<BackupTransferService>(),
      same(dependencies.backupTransferService),
    );
    expect(
      Get.find<PronunciationService>(),
      same(dependencies.pronunciationService),
    );
    expect(
      Get.find<AudioRecorderPort>(),
      same(dependencies.audioRecorder),
    );
    expect(
      Get.find<PronunciationAssessmentConfigRepository>(),
      same(dependencies.pronunciationAssessmentConfigRepository),
    );
    expect(
      Get.find<TtsConfigRepository>(),
      same(dependencies.ttsConfigRepository),
    );
    expect(Get.find<PronunciationEvaluatorFactory>(), isNotNull);
    expect(
      Get.find<FavoriteRepository>(),
      same(dependencies.favoriteRepository),
    );
    expect(
      Get.find<FavoriteListRepository>(),
      same(dependencies.favoriteListRepository),
    );
    expect(
      Get.find<LearningRepository>(),
      same(dependencies.learningRepository),
    );
    expect(
      Get.find<QuestionCandidateRepository>(),
      same(dependencies.questionCandidateRepository),
    );
    expect(
      Get.find<ReviewQueueRepository>(),
      same(dependencies.reviewQueueRepository),
    );
    expect(
      Get.find<SettingsRepository>(),
      same(dependencies.settingsRepository),
    );
    expect(
      Get.find<StudyCandidateRepository>(),
      same(dependencies.studyCandidateRepository),
    );
    expect(
      Get.find<PracticeRepository>(),
      same(dependencies.practiceRepository),
    );
    expect(
      Get.find<StatisticsRepository>(),
      same(dependencies.statisticsRepository),
    );
    expect(
      Get.find<StatisticsReportRepository>(),
      same(dependencies.statisticsReportRepository),
    );
    expect(
      Get.find<VocabularyRepository>(),
      same(dependencies.vocabularyRepository),
    );
    expect(Get.find<MonotonicClock>(), same(dependencies.monotonicClock));
    expect(Get.find<QuestionEngine>(), same(dependencies.questionEngine));
    expect(
      Get.find<PracticeAnswerEvaluator>(),
      same(dependencies.practiceAnswerEvaluator),
    );
    expect(
      Get.find<ContentInstallResult>(),
      same(dependencies.contentInstallResult),
    );
  });
}
