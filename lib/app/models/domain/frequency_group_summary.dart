/// 词库页面使用的有效词频组领域模型。
final class FrequencyGroupSummary {
  FrequencyGroupSummary({
    required this.id,
    required this.name,
    required this.rank,
    required this.minOccurrences,
    required this.maxOccurrences,
  }) {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', '词频组 ID 必须为正整数');
    }
    if (rank < 1 || rank > 6) {
      throw ArgumentError.value(rank, 'rank', '有效词频组等级必须在 1-6 之间');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '词频组名称不能为空');
    }
    if (minOccurrences < 0 ||
        (maxOccurrences != null && maxOccurrences! < minOccurrences)) {
      throw ArgumentError('词频组出现次数范围无效');
    }
  }

  final int id;
  final String name;
  final int rank;
  final int minOccurrences;
  final int? maxOccurrences;
}
