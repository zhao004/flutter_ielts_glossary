import 'package:get/get.dart';

import '../../repositories/favorite_repository.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/question_candidate_repository.dart';
import '../../models/domain/question_config.dart';
import '../../services/clock/monotonic_clock.dart';
import '../../services/audio/audio_playback_service.dart';
import '../../services/question/practice_answer_evaluator.dart';
import '../../services/question/question_engine.dart';
import 'practice_setup_logic.dart';
import 'practice_session_logic.dart';

/// 练习页面的页面级依赖；只在路由进入时创建配置和会话 Logic。
final class PracticeBinding extends Bindings {
  PracticeBinding({QuestionConfig? initialConfig})
    : initialConfig =
          initialConfig ??
          QuestionConfig.defaultsFor(QuestionType.choiceEnglishToChinese);

  final QuestionConfig initialConfig;

  @override
  void dependencies() {
    Get.lazyPut<PracticeSessionLogic>(
      () => PracticeSessionLogic(
        questionCandidateRepository: Get.find<QuestionCandidateRepository>(),
        questionEngine: Get.find<QuestionEngine>(),
        practiceRepository: Get.find<PracticeRepository>(),
        favoriteRepository: Get.find<FavoriteRepository>(),
        answerEvaluator: Get.find<PracticeAnswerEvaluator>(),
        monotonicClock: Get.find<MonotonicClock>(),
        pronunciationService: Get.find<PronunciationService>(),
      ),
    );
    Get.lazyPut<PracticeSetupLogic>(
      () => PracticeSetupLogic(
        practiceSessionStarter: Get.find<PracticeSessionLogic>(),
        initialConfig: initialConfig,
      ),
    );
  }
}
