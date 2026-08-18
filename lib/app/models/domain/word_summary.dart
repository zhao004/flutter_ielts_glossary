/// 词库列表使用的只读领域模型，不向页面暴露 Drift 数据对象。
class WordSummary {
  const WordSummary({
    required this.id,
    required this.word,
    required this.phoneticUk,
    this.phoneticUs,
    required this.translationZh,
    required this.occurrences,
    required this.frequencyGroupId,
    this.audioUkAsset,
    this.audioUsAsset,
  });

  final int id;
  final String word;
  final String? phoneticUk;
  final String? phoneticUs;
  final String? translationZh;
  final int occurrences;
  final int frequencyGroupId;
  final String? audioUkAsset;
  final String? audioUsAsset;

  /// 词库摘要未重复存储首字母，按规范化单词首字符提供筛选值。
  String get firstLetter =>
      word.trim().isEmpty ? '' : word.trim().substring(0, 1).toUpperCase();
}
