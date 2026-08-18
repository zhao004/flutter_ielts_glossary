import '../../models/domain/tts_config.dart';
import '../../models/domain/tts_platform.dart';
import 'tts_synthesizer.dart';
import 'xfyun_tts_synthesizer.dart';
import 'youdao_tts_synthesizer.dart';

/// 依据第三方 TTS 配置创建对应平台的合成器。
///
/// 配置未选平台或凭据不完整时返回空，由调用方报告发音不可用。
class TtsSynthesizerFactory {
  const TtsSynthesizerFactory();

  TtsSynthesizerPort? create(TtsConfig config) {
    if (!config.isReady) {
      return null;
    }
    return switch (config.platform) {
      TtsPlatform.off => null,
      TtsPlatform.xfyun => XfyunTtsSynthesizer(
        credentials: XfyunTtsCredentials(
          appId: config.xfyunAppId.trim(),
          apiKey: config.xfyunApiKey.trim(),
          apiSecret: config.xfyunApiSecret.trim(),
        ),
        voice: config.xfyunVoice.trim(),
        speed: config.speed,
        volume: config.volume,
        pitch: config.pitch,
      ),
      TtsPlatform.youdao => YoudaoTtsSynthesizer(
        credentials: YoudaoTtsCredentials(
          appKey: config.youdaoAppKey.trim(),
          appSecret: config.youdaoAppSecret.trim(),
        ),
        voice: config.youdaoVoice.trim(),
      ),
    };
  }
}
