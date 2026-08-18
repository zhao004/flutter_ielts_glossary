/// 参与出题的例句快照；只保留题目生成需要的内容字段。
final class QuestionSentenceCandidate {
  QuestionSentenceCandidate({
    required this.id,
    required String targetForm,
    required String sentenceEn,
    String? translationZh,
    String? source,
    String? location,
  }) : targetForm = _requireText(targetForm, 'targetForm'),
       sentenceEn = _requireText(sentenceEn, 'sentenceEn'),
       translationZh = _normalizeOptionalText(translationZh),
       source = _normalizeOptionalText(source),
       location = _normalizeOptionalText(location) {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', '例句 ID 必须为正整数');
    }
  }

  final int id;
  final String targetForm;
  final String sentenceEn;
  final String? translationZh;
  final String? source;
  final String? location;
}

/// 将只读词库内容和已经解析的错题状态组合为统一候选项。
final class QuestionCandidate {
  QuestionCandidate({
    required this.wordId,
    required String word,
    required this.frequencyGroupId,
    String? translationZh,
    String? definitionEn,
    String? phoneticUk,
    String? phoneticUs,
    String? audioUkAsset,
    String? audioUsAsset,
    this.isWrong = false,
    List<QuestionSentenceCandidate> sentences = const [],
  }) : word = _requireText(word, 'word'),
       translationZh = _normalizeOptionalText(translationZh),
       definitionEn = _normalizeOptionalText(definitionEn),
       phoneticUk = _normalizeOptionalText(phoneticUk),
       phoneticUs = _normalizeOptionalText(phoneticUs),
       audioUkAsset = _normalizeOptionalText(audioUkAsset),
       audioUsAsset = _normalizeOptionalText(audioUsAsset),
       sentences = List<QuestionSentenceCandidate>.unmodifiable(sentences) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    if (frequencyGroupId < 1 || frequencyGroupId > 6) {
      throw ArgumentError.value(
        frequencyGroupId,
        'frequencyGroupId',
        '词频组必须在 1-6 之间',
      );
    }
    final sentenceIds = <int>{};
    for (final sentence in this.sentences) {
      if (!sentenceIds.add(sentence.id)) {
        throw ArgumentError.value(sentence.id, 'sentences', '同一候选项不能包含重复例句 ID');
      }
    }
  }

  final int wordId;
  final String word;
  final int frequencyGroupId;
  final String? translationZh;
  final String? definitionEn;
  final String? phoneticUk;
  final String? phoneticUs;
  final String? audioUkAsset;
  final String? audioUsAsset;
  final bool isWrong;
  final List<QuestionSentenceCandidate> sentences;

  bool get hasLocalAudio => audioUkAsset != null || audioUsAsset != null;
}

String _requireText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '内容不能为空');
  }
  return normalized;
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
