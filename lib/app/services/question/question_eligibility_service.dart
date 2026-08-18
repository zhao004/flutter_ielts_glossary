import '../../models/domain/question_candidate.dart';
import '../../models/domain/question_config.dart';

/// 已定位到例句中的有效目标词形，保留原始大小写作为正确答案。
final class ClozeSentenceMatch {
  const ClozeSentenceMatch({
    required this.sentence,
    required this.start,
    required this.end,
    required this.matchedText,
  });

  final QuestionSentenceCandidate sentence;
  final int start;
  final int end;
  final String matchedText;
}

/// 集中实现各题型的字段资格判断，数据库查询和 UI 不复制这些规则。
final class QuestionEligibilityService {
  const QuestionEligibilityService();

  bool isEligible(QuestionCandidate candidate, QuestionConfig config) {
    if (!config.includesFrequencyGroup(candidate.frequencyGroupId)) {
      return false;
    }
    return switch (config.type) {
      QuestionType.choiceEnglishToChinese ||
      QuestionType.choiceChineseToEnglish => candidate.translationZh != null,
      QuestionType.choiceWordToSentence => candidate.sentences.isNotEmpty,
      QuestionType.spelling => _isSpellingEligible(candidate, config),
      QuestionType.cloze => validClozeMatches(candidate).isNotEmpty,
    };
  }

  List<ClozeSentenceMatch> validClozeMatches(QuestionCandidate candidate) {
    final matches = <ClozeSentenceMatch>[];
    for (final sentence in candidate.sentences) {
      final match = _findStandaloneTarget(sentence);
      if (match != null) {
        matches.add(match);
      }
    }
    return List<ClozeSentenceMatch>.unmodifiable(matches);
  }

  bool _isSpellingEligible(QuestionCandidate candidate, QuestionConfig config) {
    if (!config.allowSpellingPhrases &&
        !_singleEnglishToken.hasMatch(candidate.word)) {
      return false;
    }
    return switch (config.spellingPromptType!) {
      SpellingPromptType.translation => candidate.translationZh != null,
      SpellingPromptType.definition => candidate.definitionEn != null,
      SpellingPromptType.phonetic =>
        candidate.phoneticUk != null || candidate.phoneticUs != null,
      SpellingPromptType.audio => candidate.hasLocalAudio,
    };
  }

  ClozeSentenceMatch? _findStandaloneTarget(
    QuestionSentenceCandidate sentence,
  ) {
    final pattern = RegExp(
      RegExp.escape(sentence.targetForm),
      caseSensitive: false,
    );
    for (final match in pattern.allMatches(sentence.sentenceEn)) {
      final hasValidStart =
          match.start == 0 ||
          !_isAsciiLetterOrDigit(
            sentence.sentenceEn.codeUnitAt(match.start - 1),
          );
      final hasValidEnd =
          match.end == sentence.sentenceEn.length ||
          !_isAsciiLetterOrDigit(sentence.sentenceEn.codeUnitAt(match.end));
      if (hasValidStart && hasValidEnd) {
        return ClozeSentenceMatch(
          sentence: sentence,
          start: match.start,
          end: match.end,
          matchedText: sentence.sentenceEn.substring(match.start, match.end),
        );
      }
    }
    return null;
  }
}

final RegExp _singleEnglishToken = RegExp(r"^[A-Za-z]+(?:['’-][A-Za-z]+)*$");

bool _isAsciiLetterOrDigit(int codeUnit) {
  return (codeUnit >= 48 && codeUnit <= 57) ||
      (codeUnit >= 65 && codeUnit <= 90) ||
      (codeUnit >= 97 && codeUnit <= 122);
}
