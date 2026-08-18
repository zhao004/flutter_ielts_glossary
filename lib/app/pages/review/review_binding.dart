import 'package:get/get.dart';

import '../../repositories/favorite_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../repositories/review_queue_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/audio/audio_playback_service.dart';
import 'review_session_logic.dart';

/// 仅在进入复习页时创建会话 Logic，应用级 Repository 由 InitialBinding 提供。
final class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewSessionLogic>(
      () => ReviewSessionLogic(
        reviewQueueRepository: Get.find<ReviewQueueRepository>(),
        learningRepository: Get.find<LearningRepository>(),
        favoriteRepository: Get.find<FavoriteRepository>(),
        settingsRepository: Get.find<SettingsRepository>(),
        pronunciationService: Get.find<PronunciationService>(),
      ),
    );
  }
}
