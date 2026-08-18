import 'package:get/get.dart';

import '../../repositories/content_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../services/audio/audio_playback_service.dart';
import 'word_details_logic.dart';

/// 仅在进入单词详情页时创建页面 Logic，应用级服务由 InitialBinding 提供。
final class WordDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WordDetailsLogic>(
      () => WordDetailsLogic(
        contentRepository: Get.find<ContentRepository>(),
        favoriteRepository: Get.find<FavoriteRepository>(),
        pronunciationService: Get.find<PronunciationService>(),
        learningRepository: Get.find<LearningRepository>(),
      ),
    );
  }
}
