import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/youdao_assess_evaluator.dart';

void main() {
  group('YoudaoAssessEvaluator', () {
    test('按官方 iseapi v2 协议上传 Base64 WAV 并解析顶层评分', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'errorCode': '0',
            'overall': 92.5,
            'pronunciation': 90,
            'fluency': 88.25,
            'integrity': 100,
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final evaluator = YoudaoAssessEvaluator(
        credentials: const YoudaoAssessCredentials(
          appKey: 'app-key',
          appSecret: 'app-secret',
        ),
        client: client,
      );

      final score = await evaluator.evaluate(
        PronunciationEvaluationRequest(
          referenceText: 'have a good day',
          pcmBytes: Uint8List.fromList([1, 0, 2, 0]),
        ),
      );

      expect(capturedRequest.url, Uri.parse(YoudaoAssessEvaluator.endpoint));
      expect(capturedRequest.method, 'POST');
      final form = capturedRequest.bodyFields;
      expect(form['text'], 'have a good day');
      expect(form['langType'], 'en');
      expect(form['signType'], 'v2');
      expect(form['format'], 'wav');
      expect(form['rate'], '16000');
      expect(form['channel'], '1');
      expect(form['type'], '1');
      expect(form, isNot(contains('data')));
      expect(form['salt'], matches(_uuidV4Pattern));

      final wav = base64Decode(form['q']!);
      expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
      expect(ascii.decode(wav.sublist(36, 40)), 'data');
      expect(wav.sublist(44), [1, 0, 2, 0]);
      expect(
        form['sign'],
        _expectedSign(
          appKey: 'app-key',
          q: form['q']!,
          salt: form['salt']!,
          curtime: form['curtime']!,
          appSecret: 'app-secret',
        ),
      );
      expect(score.totalScore, 92.5);
      expect(score.accuracyScore, 90);
      expect(score.fluencyScore, 88.25);
      expect(score.integrityScore, 100);
    });

    test('官方错误码不会被当作评分结果', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'errorCode': 202}), 200),
      );
      final evaluator = YoudaoAssessEvaluator(
        credentials: const YoudaoAssessCredentials(
          appKey: 'app-key',
          appSecret: 'app-secret',
        ),
        client: client,
      );

      await expectLater(
        evaluator.evaluate(
          PronunciationEvaluationRequest(
            referenceText: 'word',
            pcmBytes: Uint8List.fromList([1, 0]),
          ),
        ),
        throwsA(
          isA<PronunciationEvaluationException>().having(
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
