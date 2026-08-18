import 'question_config.dart';

/// 一次会话中的题目基类，题型专属字段由子类保证有效性。
sealed class QuizQuestion {
  QuizQuestion({required this.id, required this.type, required this.wordId}) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', '题目 ID 不能为空');
    }
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '题目单词 ID 必须为正整数');
    }
  }

  final String id;
  final QuestionType type;
  final int wordId;

  /// 与题目事实直接关联的例句 ID；非例句题返回 null。
  int? get sentenceId;
}

/// 选择题中的一个唯一选项。
final class ChoiceOption {
  ChoiceOption({required String id, required String text})
    : id = id.trim(),
      text = text.trim() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', '选项 ID 不能为空');
    }
    if (this.text.isEmpty) {
      throw ArgumentError.value(text, 'text', '选项内容不能为空');
    }
  }

  final String id;
  final String text;
}

/// 四选一题目；构造时即保证选项 ID、内容和正确答案唯一有效。
final class ChoiceQuestion extends QuizQuestion {
  ChoiceQuestion({
    required super.id,
    required super.type,
    required super.wordId,
    required String prompt,
    required List<ChoiceOption> options,
    required this.correctOptionId,
    this.sentenceId,
  }) : prompt = prompt.trim(),
       options = List<ChoiceOption>.unmodifiable(options) {
    if (type != QuestionType.choiceEnglishToChinese &&
        type != QuestionType.choiceChineseToEnglish &&
        type != QuestionType.choiceWordToSentence) {
      throw ArgumentError.value(type, 'type', 'ChoiceQuestion 只能使用选择题类型');
    }
    if (this.prompt.isEmpty) {
      throw ArgumentError.value(prompt, 'prompt', '题干不能为空');
    }
    if (this.options.length < 2) {
      throw ArgumentError.value(options, 'options', '选择题至少需要两个选项');
    }
    final optionIds = this.options.map((option) => option.id).toSet();
    if (optionIds.length != this.options.length) {
      throw ArgumentError.value(options, 'options', '选项 ID 必须唯一');
    }
    final normalizedTexts = this.options
        .map((option) => _normalizeComparableText(option.text))
        .toSet();
    if (normalizedTexts.length != this.options.length) {
      throw ArgumentError.value(options, 'options', '选项内容必须唯一');
    }
    if (!optionIds.contains(correctOptionId)) {
      throw ArgumentError.value(
        correctOptionId,
        'correctOptionId',
        '正确答案必须存在于选项中',
      );
    }
    if (type == QuestionType.choiceWordToSentence) {
      if (sentenceId == null || sentenceId! <= 0) {
        throw ArgumentError.value(
          sentenceId,
          'sentenceId',
          '例句选择题必须提供正确关联例句 ID',
        );
      }
    } else if (sentenceId != null) {
      throw ArgumentError('只有例句选择题可以关联 sentenceId');
    }
  }

  final String prompt;
  final List<ChoiceOption> options;
  final String correctOptionId;

  @override
  final int? sentenceId;

  ChoiceOption get correctOption {
    return options.firstWhere((option) => option.id == correctOptionId);
  }
}

/// 拼写题同时携带三类提示所需的最小字段，页面按 promptType 展示。
final class SpellingQuestion extends QuizQuestion {
  SpellingQuestion({
    required super.id,
    required super.wordId,
    required this.promptType,
    required String expectedAnswer,
    String? promptText,
    String? audioUkAsset,
    String? audioUsAsset,
  }) : expectedAnswer = expectedAnswer.trim(),
       promptText = _normalizeOptionalText(promptText),
       audioUkAsset = _normalizeOptionalText(audioUkAsset),
       audioUsAsset = _normalizeOptionalText(audioUsAsset),
       super(type: QuestionType.spelling) {
    if (this.expectedAnswer.isEmpty) {
      throw ArgumentError.value(expectedAnswer, 'expectedAnswer', '拼写答案不能为空');
    }
    if (promptType == SpellingPromptType.audio) {
      if (this.audioUkAsset == null && this.audioUsAsset == null) {
        throw ArgumentError('听音拼写题必须至少提供一个本地音频资源');
      }
    } else if (this.promptText == null) {
      throw ArgumentError('文字或音标拼写题必须提供 promptText');
    }
  }

  final SpellingPromptType promptType;
  final String expectedAnswer;
  final String? promptText;
  final String? audioUkAsset;
  final String? audioUsAsset;

  @override
  int? get sentenceId => null;
}

/// 例句填空题保留实际词形、原句和出处，便于答后完整回显。
final class ClozeQuestion extends QuizQuestion {
  ClozeQuestion({
    required super.id,
    required super.wordId,
    required this.sentenceId,
    required String maskedSentence,
    required String originalSentence,
    required String targetWord,
    required String expectedAnswer,
    String? translationZh,
    String? source,
    String? location,
  }) : maskedSentence = maskedSentence.trim(),
       originalSentence = originalSentence.trim(),
       targetWord = targetWord.trim(),
       expectedAnswer = expectedAnswer.trim(),
       translationZh = _normalizeOptionalText(translationZh),
       source = _normalizeOptionalText(source),
       location = _normalizeOptionalText(location),
       super(type: QuestionType.cloze) {
    if (sentenceId <= 0) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '例句 ID 必须为正整数');
    }
    if (this.maskedSentence.isEmpty || this.originalSentence.isEmpty) {
      throw ArgumentError('填空题原句和挖空句不能为空');
    }
    if (this.targetWord.isEmpty || this.expectedAnswer.isEmpty) {
      throw ArgumentError('填空题目标词和答案不能为空');
    }
  }

  @override
  final int sentenceId;
  final String maskedSentence;
  final String originalSentence;
  final String targetWord;
  final String expectedAnswer;
  final String? translationZh;
  final String? source;
  final String? location;

  int get answerLength => expectedAnswer.runes.length;

  String get firstLetterHint => String.fromCharCode(expectedAnswer.runes.first);

  /// 按字母数量逐级揭示答案，空格和连字符等分隔符始终保留。
  String hintForRevealedLetters(int revealedLetters) {
    if (revealedLetters < 0) {
      throw ArgumentError.value(
        revealedLetters,
        'revealedLetters',
        '揭示字母数量不能小于 0',
      );
    }
    var remaining = revealedLetters;
    final buffer = StringBuffer();
    for (final rune in expectedAnswer.runes) {
      final character = String.fromCharCode(rune);
      if (_isAsciiLetter(rune)) {
        if (remaining > 0) {
          buffer.write(character);
          remaining--;
        } else {
          buffer.write('_');
        }
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }
}

String _normalizeComparableText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

bool _isAsciiLetter(int rune) {
  return (rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122);
}
