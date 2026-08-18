import 'package:get/get.dart';

import '../../repositories/pronunciation_assessment_config_repository.dart';
import '../../services/assessment/pronunciation_evaluator_factory.dart';
import '../../services/audio/audio_recorder.dart';
import 'pronunciation_practice_logic.dart';

/// 仅在进入发音练习页时创建会话 Logic，复用应用级录音器和第三方评分器。
final class PronunciationPracticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PronunciationPracticeLogic>(
      () => PronunciationPracticeLogic(
        audioRecorder: Get.find<AudioRecorderPort>(),
        configRepository: Get.find<PronunciationAssessmentConfigRepository>(),
        evaluatorFactory: Get.find<PronunciationEvaluatorFactory>(),
      ),
    );
  }
}
