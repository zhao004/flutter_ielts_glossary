import '../../models/domain/pronunciation_assessment_config.dart';
import '../../models/domain/pronunciation_assessment_platform.dart';
import 'pronunciation_evaluator.dart';
import 'xfyun_ise_evaluator.dart';
import 'youdao_assess_evaluator.dart';

/// 依据第三方评测配置创建对应平台的评测器。
///
/// 配置未选平台或凭据不完整时返回空，由调用方回退到本地文字匹配。
class PronunciationEvaluatorFactory {
  const PronunciationEvaluatorFactory();

  PronunciationEvaluatorPort? create(PronunciationAssessmentConfig config) {
    if (!config.isReady) {
      return null;
    }
    return switch (config.platform) {
      PronunciationAssessmentPlatform.off => null,
      PronunciationAssessmentPlatform.xfyun => XfyunIseEvaluator(
        credentials: XfyunIseCredentials(
          appId: config.xfyunAppId.trim(),
          apiKey: config.xfyunApiKey.trim(),
          apiSecret: config.xfyunApiSecret.trim(),
        ),
      ),
      PronunciationAssessmentPlatform.youdao => YoudaoAssessEvaluator(
        credentials: YoudaoAssessCredentials(
          appKey: config.youdaoAppKey.trim(),
          appSecret: config.youdaoAppSecret.trim(),
        ),
      ),
    };
  }
}
