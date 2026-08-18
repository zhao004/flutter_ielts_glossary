import 'dart:convert';

import '../../models/domain/question_config.dart';

/// 无法解析或版本不受支持的持久化题目配置。
final class QuestionConfigFormatException implements Exception {
  const QuestionConfigFormatException(this.code);

  final String code;

  @override
  String toString() => 'question_config_format_error: $code';
}

/// 稳定的题型存储值，写入用户数据后不随 Dart 枚举名重命名。
abstract final class QuestionTypeStorage {
  static String encode(QuestionType type) => switch (type) {
    QuestionType.choiceEnglishToChinese => 'choice_english_to_chinese',
    QuestionType.choiceChineseToEnglish => 'choice_chinese_to_english',
    QuestionType.choiceWordToSentence => 'choice_word_to_sentence',
    QuestionType.spelling => 'spelling',
    QuestionType.cloze => 'cloze',
  };

  static QuestionType decode(String value) => switch (value) {
    'choice_english_to_chinese' => QuestionType.choiceEnglishToChinese,
    'choice_chinese_to_english' => QuestionType.choiceChineseToEnglish,
    'choice_word_to_sentence' => QuestionType.choiceWordToSentence,
    'spelling' => QuestionType.spelling,
    'cloze' => QuestionType.cloze,
    _ => throw const QuestionConfigFormatException('unsupported_type'),
  };
}

/// 将不可变配置编码为版本化 JSON，供练习会话和后续备份协议复用。
final class QuestionConfigCodec {
  const QuestionConfigCodec();

  static const int currentFormatVersion = 2;
  static const int maximumEncodedLength = 4096;

  String encode(QuestionConfig config) {
    final groupIds = config.frequencyGroupIds.toList()..sort();
    return jsonEncode({
      'formatVersion': currentFormatVersion,
      'type': QuestionTypeStorage.encode(config.type),
      'frequencyGroupIds': groupIds,
      'targetWordIds': config.targetWordIds.toList()..sort(),
      'difficulty': _encodeDifficulty(config.difficulty),
      'wrongFirst': config.wrongFirst,
      'questionCount': config.questionCount,
      'timed': config.timed,
      'spellingPromptType': _encodeSpellingPrompt(config.spellingPromptType),
      'allowSpellingPhrases': config.allowSpellingPhrases,
    });
  }

  QuestionConfig decode(String source) {
    if (source.isEmpty || source.length > maximumEncodedLength) {
      throw const QuestionConfigFormatException('invalid_length');
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw const QuestionConfigFormatException('invalid_root');
      }
      final formatVersion = decoded['formatVersion'];
      if (formatVersion is! int ||
          (formatVersion != 1 && formatVersion != currentFormatVersion)) {
        throw const QuestionConfigFormatException('unsupported_version');
      }
      final typeValue = decoded['type'];
      final groupValues = decoded['frequencyGroupIds'];
      final targetValues = formatVersion == 1
          ? const <Object>[]
          : decoded['targetWordIds'];
      final wrongFirst = decoded['wrongFirst'];
      final questionCount = decoded['questionCount'];
      final timed = decoded['timed'];
      final allowSpellingPhrases = decoded['allowSpellingPhrases'];
      if (typeValue is! String ||
          groupValues is! List ||
          targetValues is! List ||
          wrongFirst is! bool ||
          questionCount is! int ||
          timed is! bool ||
          allowSpellingPhrases is! bool) {
        throw const QuestionConfigFormatException('invalid_fields');
      }
      final groupIds = groupValues.whereType<int>().toSet();
      if (groupIds.length != groupValues.length) {
        throw const QuestionConfigFormatException('invalid_group_ids');
      }
      final targetWordIds = targetValues.whereType<int>().toSet();
      if (targetWordIds.length != targetValues.length) {
        throw const QuestionConfigFormatException('invalid_target_word_ids');
      }
      return QuestionConfig(
        type: QuestionTypeStorage.decode(typeValue),
        frequencyGroupIds: groupIds,
        targetWordIds: targetWordIds,
        difficulty: _decodeDifficulty(decoded['difficulty']),
        wrongFirst: wrongFirst,
        questionCount: questionCount,
        timed: timed,
        spellingPromptType: _decodeSpellingPrompt(
          decoded['spellingPromptType'],
        ),
        allowSpellingPhrases: allowSpellingPhrases,
      );
    } on QuestionConfigFormatException {
      rethrow;
    } on FormatException {
      throw const QuestionConfigFormatException('invalid_json');
    } on ArgumentError {
      throw const QuestionConfigFormatException('invalid_config');
    }
  }

  String? _encodeDifficulty(QuestionDifficulty? difficulty) {
    return switch (difficulty) {
      QuestionDifficulty.easy => 'easy',
      QuestionDifficulty.medium => 'medium',
      QuestionDifficulty.hard => 'hard',
      null => null,
    };
  }

  QuestionDifficulty? _decodeDifficulty(Object? value) {
    return switch (value) {
      'easy' => QuestionDifficulty.easy,
      'medium' => QuestionDifficulty.medium,
      'hard' => QuestionDifficulty.hard,
      null => null,
      _ => throw const QuestionConfigFormatException('invalid_difficulty'),
    };
  }

  String? _encodeSpellingPrompt(SpellingPromptType? promptType) {
    return switch (promptType) {
      SpellingPromptType.translation => 'translation',
      SpellingPromptType.phonetic => 'phonetic',
      SpellingPromptType.definition => 'definition',
      SpellingPromptType.audio => 'audio',
      null => null,
    };
  }

  SpellingPromptType? _decodeSpellingPrompt(Object? value) {
    return switch (value) {
      'translation' => SpellingPromptType.translation,
      'phonetic' => SpellingPromptType.phonetic,
      'definition' => SpellingPromptType.definition,
      'audio' => SpellingPromptType.audio,
      null => null,
      _ => throw const QuestionConfigFormatException('invalid_spelling_prompt'),
    };
  }
}
