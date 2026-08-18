import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/services/question/practice_answer_evaluator.dart';

void main() {
  const evaluator = PracticeAnswerEvaluator();

  test('拼写判定忽略首尾空格和大小写但仍要求完全匹配', () {
    final correct = evaluator.evaluate(
      userAnswer: '  ApPlE ',
      expectedAnswer: 'apple',
    );
    final approximate = evaluator.evaluate(
      userAnswer: 'appel',
      expectedAnswer: 'apple',
    );

    expect(correct.isCorrect, isTrue);
    expect(correct.similarity, 1);
    expect(approximate.isCorrect, isFalse);
    expect(approximate.similarity, closeTo(0.6, 0.0001));
  });

  test('相似度支持空输入并使用 Unicode 字符序列计算', () {
    expect(evaluator.similarity('', ''), 1);
    expect(evaluator.similarity('', '词'), 0);
    expect(evaluator.similarity('学习', '学习'), 1);
  });
}
