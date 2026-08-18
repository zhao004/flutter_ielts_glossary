import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_score.dart';

void main() {
  test('按总分划分评分等级', () {
    PronunciationScore score(double total) => PronunciationScore(
      totalScore: total,
      accuracyScore: total,
      fluencyScore: total,
      integrityScore: total,
    );

    expect(score(95).level, PronunciationScoreLevel.excellent);
    expect(score(90).level, PronunciationScoreLevel.excellent);
    expect(score(89.9).level, PronunciationScoreLevel.good);
    expect(score(75).level, PronunciationScoreLevel.good);
    expect(score(74.9).level, PronunciationScoreLevel.fair);
    expect(score(60).level, PronunciationScoreLevel.fair);
    expect(score(59.9).level, PronunciationScoreLevel.poor);
    expect(score(0).level, PronunciationScoreLevel.poor);
  });
}
