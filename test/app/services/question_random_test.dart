import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  test('固定种子产生可复现的无放回抽样', () {
    final first = QuestionRandomSampler(
      DartQuestionRandomSource(seed: 20260814),
    ).sampleWithoutReplacement(List.generate(10, (index) => index + 1), 6);
    final second = QuestionRandomSampler(
      DartQuestionRandomSource(seed: 20260814),
    ).sampleWithoutReplacement(List.generate(10, (index) => index + 1), 6);

    expect(first, second);
    expect(first.toSet(), hasLength(6));
  });

  test('候选池不足时立即拒绝而不是重复随机', () {
    final sampler = QuestionRandomSampler(DartQuestionRandomSource(seed: 1));

    expect(
      () => sampler.sampleWithoutReplacement(const [1, 2], 3),
      throwsRangeError,
    );
  });
}
