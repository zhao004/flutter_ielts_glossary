import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/tts_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_platform.dart';
import 'package:flutter_ielts_glossary/app/services/tts/tts_synthesizer_factory.dart';
import 'package:flutter_ielts_glossary/app/services/tts/xfyun_tts_synthesizer.dart';
import 'package:flutter_ielts_glossary/app/services/tts/youdao_tts_synthesizer.dart';

void main() {
  const factory = TtsSynthesizerFactory();

  test('未选平台或凭据不完整时返回空，表示服务不可用', () {
    expect(factory.create(TtsConfig.defaults()), isNull);
    expect(
      factory.create(
        const TtsConfig(
          platform: TtsPlatform.xfyun,
          xfyunAppId: 'app',
        ),
      ),
      isNull,
    );
    expect(
      factory.create(
        const TtsConfig(
          platform: TtsPlatform.youdao,
          youdaoAppKey: 'key',
        ),
      ),
      isNull,
    );
  });

  test('凭据完整时创建对应平台的合成器', () {
    expect(
      factory.create(
        const TtsConfig(
          platform: TtsPlatform.xfyun,
          xfyunAppId: 'app',
          xfyunApiKey: 'key',
          xfyunApiSecret: 'secret',
        ),
      ),
      isA<XfyunTtsSynthesizer>(),
    );
    expect(
      factory.create(
        const TtsConfig(
          platform: TtsPlatform.youdao,
          youdaoAppKey: 'key',
          youdaoAppSecret: 'secret',
        ),
      ),
      isA<YoudaoTtsSynthesizer>(),
    );
  });
}
