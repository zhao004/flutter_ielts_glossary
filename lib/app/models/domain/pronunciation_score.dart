/// 一次云端发音评测的量化结果，各字段均为 0-100 分。
final class PronunciationScore {
  const PronunciationScore({
    required this.totalScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.integrityScore,
  });

  /// 综合总分。
  final double totalScore;

  /// 准确度（音素/单词发音是否正确）。
  final double accuracyScore;

  /// 流利度（语速与停顿是否自然）。
  final double fluencyScore;

  /// 完整度（是否读完整参考文本）。
  final double integrityScore;

  /// 按总分划分的等级，供页面展示文案使用。
  PronunciationScoreLevel get level {
    if (totalScore >= 90) {
      return PronunciationScoreLevel.excellent;
    }
    if (totalScore >= 75) {
      return PronunciationScoreLevel.good;
    }
    if (totalScore >= 60) {
      return PronunciationScoreLevel.fair;
    }
    return PronunciationScoreLevel.poor;
  }
}

/// 云端评分等级。
enum PronunciationScoreLevel { excellent, good, fair, poor }
