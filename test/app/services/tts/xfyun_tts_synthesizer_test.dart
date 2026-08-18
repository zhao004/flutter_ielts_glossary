import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/services/tts/tts_synthesizer.dart';
import 'package:flutter_ielts_glossary/app/services/tts/xfyun_tts_synthesizer.dart';

void main() {
  test('发音人口音不匹配时在网络请求前明确拒绝', () async {
    final synthesizer = XfyunTtsSynthesizer(
      credentials: const XfyunTtsCredentials(
        appId: 'app',
        apiKey: 'key',
        apiSecret: 'secret',
      ),
      voice: 'catherine',
      supportedAccent: PronunciationAccent.us,
    );

    await expectLater(
      synthesizer.synthesize('word', accent: PronunciationAccent.uk),
      throwsA(
        isA<TtsSynthesisException>().having(
          (error) => error.code,
          'code',
          'unsupported_accent',
        ),
      ),
    );
  });
}
