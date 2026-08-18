import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/services/tts/tts_synthesizer.dart';
import 'package:flutter_ielts_glossary/app/services/tts/youdao_tts_synthesizer.dart';

void main() {
  group('YoudaoTtsSynthesizer', () {
    test('按官方 v3 表单签名并为英式发音选择对应 voiceName', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response.bytes(
          [1, 2, 3],
          200,
          headers: const {'content-type': 'audio/mp3'},
        );
      });
      final synthesizer = YoudaoTtsSynthesizer(
        credentials: const YoudaoTtsCredentials(
          appKey: 'app-key',
          appSecret: 'app-secret',
        ),
        usVoiceName: 'youmeimei',
        ukVoiceName: 'youyingying',
        speed: 50,
        volume: 50,
        client: client,
      );
      const text = 'have a wonderful day today';

      final audio = await synthesizer.synthesize(
        text,
        accent: PronunciationAccent.uk,
      );

      expect(capturedRequest.url, Uri.parse(YoudaoTtsSynthesizer.endpoint));
      expect(capturedRequest.method, 'POST');
      final form = capturedRequest.bodyFields;
      expect(form['q'], text);
      expect(form['voiceName'], 'youyingying');
      expect(form['format'], 'mp3');
      expect(form['speed'], '1.00');
      expect(form['volume'], '1.00');
      expect(form['signType'], 'v3');
      expect(form, isNot(contains('voice')));
      expect(form, isNot(contains('langType')));
      expect(form['salt'], matches(_uuidV4Pattern));
      expect(
        form['sign'],
        _expectedSign(
          appKey: 'app-key',
          q: text,
          salt: form['salt']!,
          curtime: form['curtime']!,
          appSecret: 'app-secret',
        ),
      );
      expect(audio.bytes, [1, 2, 3]);
      expect(audio.mimeType, 'audio/mpeg');
    });

    test('美式发音使用独立配置的 voiceName', () async {
      late Map<String, String> form;
      final client = MockClient((request) async {
        form = request.bodyFields;
        return http.Response.bytes(
          [1],
          200,
          headers: const {'content-type': 'audio/mp3'},
        );
      });
      final synthesizer = YoudaoTtsSynthesizer(
        credentials: const YoudaoTtsCredentials(
          appKey: 'app-key',
          appSecret: 'app-secret',
        ),
        usVoiceName: 'youmeimei',
        ukVoiceName: 'youyingying',
        client: client,
      );

      await synthesizer.synthesize('word', accent: PronunciationAccent.us);

      expect(form['voiceName'], 'youmeimei');
    });

    test('JSON 错误响应转换为稳定服务错误码', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'errorCode': 202}),
          200,
          headers: const {'content-type': 'application/json'},
        ),
      );
      final synthesizer = YoudaoTtsSynthesizer(
        credentials: const YoudaoTtsCredentials(
          appKey: 'app-key',
          appSecret: 'app-secret',
        ),
        usVoiceName: 'youmeimei',
        ukVoiceName: 'youyingying',
        client: client,
      );

      await expectLater(
        synthesizer.synthesize('word', accent: PronunciationAccent.us),
        throwsA(
          isA<TtsSynthesisException>().having(
            (error) => error.code,
            'code',
            'youdao_202',
          ),
        ),
      );
    });
  });
}

final RegExp _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

String _expectedSign({
  required String appKey,
  required String q,
  required String salt,
  required String curtime,
  required String appSecret,
}) {
  final input = q.length <= 20
      ? q
      : '${q.substring(0, 10)}${q.length}${q.substring(q.length - 10)}';
  return sha256
      .convert(utf8.encode('$appKey$input$salt$curtime$appSecret'))
      .toString();
}
