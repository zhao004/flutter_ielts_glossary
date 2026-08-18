/// 单词详情中的例句领域模型。
final class SentenceDetails {
  SentenceDetails({
    required this.id,
    required this.wordId,
    required this.targetForm,
    required this.sentenceEn,
    required this.translationZh,
    required this.source,
    required this.location,
  }) {
    if (id <= 0 || wordId <= 0) {
      throw ArgumentError('例句和关联单词 ID 必须为正整数');
    }
    if (targetForm.trim().isEmpty || sentenceEn.trim().isEmpty) {
      throw ArgumentError('例句目标词形和英文句子不能为空');
    }
  }

  final int id;
  final int wordId;
  final String targetForm;
  final String sentenceEn;
  final String? translationZh;
  final String? source;
  final String? location;
}

/// 词库详情页使用的只读单词领域模型，不暴露 Drift 数据对象。
final class WordDetails {
  WordDetails({
    required this.id,
    required this.word,
    required this.phoneticUk,
    required this.phoneticUs,
    required this.translationZh,
    required this.definitionEn,
    required this.mnemonic,
    required this.occurrences,
    required this.frequencyGroupId,
    required this.firstLetter,
    required this.audioUkAsset,
    required this.audioUsAsset,
    required List<SentenceDetails> sentences,
  }) : sentences = List<SentenceDetails>.unmodifiable(sentences) {
    if (id <= 0 || frequencyGroupId <= 0) {
      throw ArgumentError('单词和词频组 ID 必须为正整数');
    }
    if (word.trim().isEmpty || word.length > 200) {
      throw ArgumentError.value(word, 'word', '单词长度必须在 1-200 之间');
    }
    if (occurrences < 0) {
      throw ArgumentError.value(occurrences, 'occurrences', '词频不能为负数');
    }
    if (!RegExp(r'^[A-Z]$').hasMatch(firstLetter)) {
      throw ArgumentError.value(firstLetter, 'firstLetter', '首字母必须为 A-Z');
    }
    final sentenceIds = this.sentences.map((sentence) => sentence.id).toSet();
    if (sentenceIds.length != this.sentences.length ||
        this.sentences.any((sentence) => sentence.wordId != id)) {
      throw ArgumentError.value(sentences, 'sentences', '例句必须唯一且属于当前单词');
    }
  }

  final int id;
  final String word;
  final String? phoneticUk;
  final String? phoneticUs;
  final String? translationZh;
  final String? definitionEn;
  final String? mnemonic;
  final int occurrences;
  final int frequencyGroupId;
  final String firstLetter;
  final String? audioUkAsset;
  final String? audioUsAsset;
  final List<SentenceDetails> sentences;
}
