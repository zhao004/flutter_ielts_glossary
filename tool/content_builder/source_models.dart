/// 参考仓库中的词频组记录。
final class SourceFrequencyGroup {
  const SourceFrequencyGroup({
    required this.id,
    required this.name,
    required this.rank,
    required this.minOccurrences,
    required this.maxOccurrences,
    required this.wordCount,
  });

  final int id;
  final String name;
  final int rank;
  final int minOccurrences;
  final int maxOccurrences;
  final int wordCount;

  Object get equalityKey =>
      (id, name, rank, minOccurrences, maxOccurrences, wordCount);
}

/// `stats.json` 中用于校验分块统计的字段。
final class SourceStats {
  const SourceStats({
    required this.wordCount,
    required this.sentenceCount,
    required this.groupCount,
    required this.letters,
    required this.groups,
  });

  final int wordCount;
  final int sentenceCount;
  final int groupCount;
  final List<String> letters;
  final List<SourceFrequencyGroup> groups;
}

/// 参考仓库单词记录；远程音频地址仅用于缺失统计，不直接写入应用资产路径。
final class SourceWord {
  const SourceWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.phonetic,
    required this.englishDefinition,
    required this.mnemonic,
    required this.audioUk,
    required this.audioUs,
    required this.occurrences,
    required this.groupId,
    required this.firstLetter,
    required this.length,
    required this.sentenceCount,
  });

  final int id;
  final String word;
  final String? translation;
  final String? phonetic;
  final String? englishDefinition;
  final String? mnemonic;
  final String? audioUk;
  final String? audioUs;
  final int occurrences;
  final int groupId;
  final String firstLetter;
  final int length;
  final int sentenceCount;

  Object get equalityKey => (
    id,
    word,
    translation,
    phonetic,
    englishDefinition,
    mnemonic,
    audioUk,
    audioUs,
    occurrences,
    groupId,
    firstLetter,
    length,
    sentenceCount,
  );
}

/// 参考仓库真题例句记录。
final class SourceSentence {
  const SourceSentence({
    required this.id,
    required this.wordId,
    required this.targetForm,
    required this.sentence,
    required this.translation,
    required this.source,
    required this.location,
    this.sourceFile,
    this.sourceIndex,
  });

  final int id;
  final int wordId;
  final String targetForm;
  final String sentence;
  final String? translation;
  final String? source;
  final String? location;

  /// 原始分块中的来源位置，仅用于校验报告，不写入正式内容库。
  final String? sourceFile;
  final int? sourceIndex;

  Object get equalityKey =>
      (id, wordId, targetForm, sentence, translation, source, location);

  Object get contentEqualityKey =>
      (wordId, targetForm, sentence, translation, source, location);
}

/// 完成结构解析但尚未执行跨文件业务校验的内容集合。
final class ImportedContent {
  const ImportedContent({
    required this.groups,
    required this.stats,
    required this.words,
    required this.sentences,
    required this.sourceDataSha256,
  });

  final List<SourceFrequencyGroup> groups;
  final SourceStats stats;
  final List<SourceWord> words;
  final List<SourceSentence> sentences;
  final String sourceDataSha256;
}
