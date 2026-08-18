import 'package:get/get.dart';

import '../../repositories/favorite_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/study_candidate_repository.dart';
import '../../services/audio/audio_playback_service.dart';
import 'study_session_logic.dart';
import 'study_setup_logic.dart';

/// 随机学习页面的页面级依赖，离开页面后释放配置和会话 Logic。
final class StudyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudySessionLogic>(
      () => StudySessionLogic(
        studyCandidateRepository: Get.find<StudyCandidateRepository>(),
        learningRepository: Get.find<LearningRepository>(),
        favoriteRepository: Get.find<FavoriteRepository>(),
        pronunciationService: Get.find<PronunciationService>(),
      ),
    );
    Get.lazyPut<StudySetupLogic>(
      () => StudySetupLogic(
        settingsRepository: Get.find<SettingsRepository>(),
        studySessionStarter: Get.find<StudySessionLogic>(),
      ),
    );
  }
}
