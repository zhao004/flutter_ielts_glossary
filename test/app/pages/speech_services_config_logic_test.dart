import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_platform.dart';
import 'package:flutter_ielts_glossary/app/models/domain/speech_services_config_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_platform.dart';
import 'package:flutter_ielts_glossary/app/pages/speech_services_config/speech_services_config_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/tts_config_repository.dart';

void main() {
  test('并行加载 TTS 与评测配置', () async {
    final ttsRepository = _MemoryTtsRepository(
      const TtsConfig(
        platform: TtsPlatform.youdao,
        youdaoAppKey: 'tts-key',
        youdaoAppSecret: 'tts-secret',
      ),
    );
    final assessmentRepository = _MemoryAssessmentRepository(
      const PronunciationAssessmentConfig(
        platform: PronunciationAssessmentPlatform.xfyun,
        xfyunAppId: 'assessment-app',
        xfyunApiKey: 'assessment-key',
        xfyunApiSecret: 'assessment-secret',
      ),
    );
    final logic = SpeechServicesConfigLogic(
      ttsConfigRepository: ttsRepository,
      assessmentConfigRepository: assessmentRepository,
    );
    addTearDown(logic.onClose);

    await logic.load();

    expect(logic.state.phase, SpeechServicesConfigPhase.loaded);
    expect(logic.state.ttsConfig.platform, TtsPlatform.youdao);
    expect(
      logic.state.assessmentConfig.platform,
      PronunciationAssessmentPlatform.xfyun,
    );
  });

  test('分别保存两个服务配置并更新对应快照', () async {
    final ttsRepository = _MemoryTtsRepository(TtsConfig.defaults());
    final assessmentRepository = _MemoryAssessmentRepository(
      PronunciationAssessmentConfig.defaults(),
    );
    final logic = SpeechServicesConfigLogic(
      ttsConfigRepository: ttsRepository,
      assessmentConfigRepository: assessmentRepository,
    );
    addTearDown(logic.onClose);
    await logic.load();

    await logic.saveTts(
      const TtsConfig(
        platform: TtsPlatform.xfyun,
        xfyunAppId: 'tts-app',
        xfyunApiKey: 'tts-key',
        xfyunApiSecret: 'tts-secret',
      ),
    );
    await logic.saveAssessment(
      const PronunciationAssessmentConfig(
        platform: PronunciationAssessmentPlatform.youdao,
        youdaoAppKey: 'assessment-key',
        youdaoAppSecret: 'assessment-secret',
      ),
    );

    expect(logic.state.ttsConfig.platform, TtsPlatform.xfyun);
    expect(
      logic.state.assessmentConfig.platform,
      PronunciationAssessmentPlatform.youdao,
    );
    expect(logic.state.isSavingTts, isFalse);
    expect(logic.state.isSavingAssessment, isFalse);
  });

  test('读取或保存失败时使用稳定错误码', () async {
    final failedLoad = SpeechServicesConfigLogic(
      ttsConfigRepository: _ThrowingTtsRepository(),
      assessmentConfigRepository: _MemoryAssessmentRepository(
        PronunciationAssessmentConfig.defaults(),
      ),
    );
    addTearDown(failedLoad.onClose);
    await failedLoad.load();
    expect(failedLoad.state.phase, SpeechServicesConfigPhase.error);
    expect(
      failedLoad.state.errorCode,
      SpeechServicesConfigErrorCodes.loadFailed,
    );

    final failedSaveRepository = _MemoryTtsRepository(TtsConfig.defaults())
      ..failSave = true;
    final logic = SpeechServicesConfigLogic(
      ttsConfigRepository: failedSaveRepository,
      assessmentConfigRepository: _MemoryAssessmentRepository(
        PronunciationAssessmentConfig.defaults(),
      ),
    );
    addTearDown(logic.onClose);
    await logic.load();
    await logic.saveTts(TtsConfig.defaults());
    expect(
      logic.state.ttsErrorCode,
      SpeechServicesConfigErrorCodes.ttsSaveFailed,
    );
  });
}

final class _MemoryTtsRepository implements TtsConfigRepository {
  _MemoryTtsRepository(this.value);

  TtsConfig value;
  bool failSave = false;

  @override
  Future<TtsConfig> load() async => value;

  @override
  Future<TtsConfig> save(TtsConfig config) async {
    if (failSave) {
      throw UnsupportedTtsConfigException('测试失败');
    }
    value = config;
    return value;
  }
}

final class _MemoryAssessmentRepository
    implements PronunciationAssessmentConfigRepository {
  _MemoryAssessmentRepository(this.value);

  PronunciationAssessmentConfig value;

  @override
  Future<PronunciationAssessmentConfig> load() async => value;

  @override
  Future<PronunciationAssessmentConfig> save(
    PronunciationAssessmentConfig config,
  ) async {
    value = config;
    return value;
  }
}

final class _ThrowingTtsRepository implements TtsConfigRepository {
  @override
  Future<TtsConfig> load() async {
    throw UnsupportedTtsConfigException('测试失败');
  }

  @override
  Future<TtsConfig> save(TtsConfig config) async => config;
}
