import 'package:get/get.dart';

import '../../repositories/pronunciation_assessment_config_repository.dart';
import '../../repositories/tts_config_repository.dart';
import 'speech_services_config_logic.dart';

/// 进入统一语音服务配置页时创建 Logic，复用应用级凭据仓库。
final class SpeechServicesConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeechServicesConfigLogic>(
      () => SpeechServicesConfigLogic(
        ttsConfigRepository: Get.find<TtsConfigRepository>(),
        assessmentConfigRepository:
            Get.find<PronunciationAssessmentConfigRepository>(),
      ),
    );
  }
}
