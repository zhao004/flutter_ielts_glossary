import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/xfyun_ise_evaluator.dart';

void main() {
  const parser = XfyunIseResponseParser();

  test('解析 read_word 完成帧中的 Base64 XML 评分', () {
    const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<xml>
  <read_word>
    <rec_paper>
      <read_word total_score="88.5" />
    </rec_paper>
  </read_word>
</xml>
''';
    final message = jsonEncode({
      'code': 0,
      'data': {'status': 2, 'data': base64Encode(utf8.encode(xml))},
    });

    final score = parser.parse(message);

    expect(score?.totalScore, 88.5);
    expect(score?.accuracyScore, 88.5);
    expect(score?.fluencyScore, 88.5);
    expect(score?.integrityScore, 88.5);
  });

  test('完成帧缺少评分字段时返回稳定解析错误', () {
    final message = jsonEncode({
      'code': 0,
      'data': {
        'status': 2,
        'data': base64Encode(utf8.encode('<xml><read_word /></xml>')),
      },
    });

    expect(
      () => parser.parse(message),
      throwsA(
        isA<PronunciationEvaluationException>().having(
          (error) => error.code,
          'code',
          'malformed_result',
        ),
      ),
    );
  });

  test('非零服务错误码不会被当作等待中的数据帧', () {
    expect(
      () => parser.parse(jsonEncode({'code': 10105})),
      throwsA(
        isA<PronunciationEvaluationException>().having(
          (error) => error.code,
          'code',
          'xfyun_10105',
        ),
      ),
    );
  });
}
