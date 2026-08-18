/// 一次文字答案判定结果；相似度只用于提示，不改变完全匹配结论。
final class PracticeAnswerEvaluation {
  const PracticeAnswerEvaluation({
    required this.isCorrect,
    required this.similarity,
    required this.normalizedUserAnswer,
    required this.normalizedExpectedAnswer,
  });

  final bool isCorrect;
  final double similarity;
  final String normalizedUserAnswer;
  final String normalizedExpectedAnswer;
}

/// 按首期规则忽略首尾空格和大小写，并计算 Levenshtein 提示相似度。
final class PracticeAnswerEvaluator {
  const PracticeAnswerEvaluator();

  PracticeAnswerEvaluation evaluate({
    required String userAnswer,
    required String expectedAnswer,
  }) {
    final normalizedUserAnswer = normalize(userAnswer);
    final normalizedExpectedAnswer = normalize(expectedAnswer);
    return PracticeAnswerEvaluation(
      isCorrect: normalizedUserAnswer == normalizedExpectedAnswer,
      similarity: similarity(normalizedUserAnswer, normalizedExpectedAnswer),
      normalizedUserAnswer: normalizedUserAnswer,
      normalizedExpectedAnswer: normalizedExpectedAnswer,
    );
  }

  String normalize(String value) => value.trim().toLowerCase();

  double similarity(String first, String second) {
    final firstRunes = first.runes.toList(growable: false);
    final secondRunes = second.runes.toList(growable: false);
    final longestLength = firstRunes.length > secondRunes.length
        ? firstRunes.length
        : secondRunes.length;
    if (longestLength == 0) {
      return 1;
    }
    return 1 - (_levenshteinDistance(firstRunes, secondRunes) / longestLength);
  }

  int _levenshteinDistance(List<int> first, List<int> second) {
    if (first.isEmpty) {
      return second.length;
    }
    if (second.isEmpty) {
      return first.length;
    }

    var previous = List<int>.generate(second.length + 1, (index) => index);
    for (var firstIndex = 0; firstIndex < first.length; firstIndex++) {
      final current = List<int>.filled(second.length + 1, 0);
      current[0] = firstIndex + 1;
      for (var secondIndex = 0; secondIndex < second.length; secondIndex++) {
        final substitutionCost = first[firstIndex] == second[secondIndex]
            ? 0
            : 1;
        final deletion = previous[secondIndex + 1] + 1;
        final insertion = current[secondIndex] + 1;
        final substitution = previous[secondIndex] + substitutionCost;
        current[secondIndex + 1] = _minimum(deletion, insertion, substitution);
      }
      previous = current;
    }
    return previous.last;
  }

  int _minimum(int first, int second, int third) {
    var result = first < second ? first : second;
    if (third < result) {
      result = third;
    }
    return result;
  }
}
