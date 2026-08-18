import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_config_codec.dart';

void main() {
  const codec = QuestionConfigCodec();

  test('定向拼写配置往返保留目标单词', () {
    final source = codec.encode(QuestionConfig.targetedSpelling(wordId: 12));
    final decodedJson = jsonDecode(source) as Map<String, Object?>;
    final decoded = codec.decode(source);

    expect(decodedJson['formatVersion'], 2);
    expect(decodedJson['targetWordIds'], [12]);
    expect(decoded.isTargeted, isTrue);
    expect(decoded.targetWordIds, {12});
    expect(decoded.questionCount, 1);
  });

  test('V1 常规练习配置仍可解码', () {
    final source = jsonEncode({
      'formatVersion': 1,
      'type': 'spelling',
      'frequencyGroupIds': <int>[],
      'difficulty': null,
      'wrongFirst': false,
      'questionCount': 10,
      'timed': false,
      'spellingPromptType': 'translation',
      'allowSpellingPhrases': false,
    });

    final decoded = codec.decode(source);

    expect(decoded.type, QuestionType.spelling);
    expect(decoded.isTargeted, isFalse);
    expect(decoded.targetWordIds, isEmpty);
  });
}
