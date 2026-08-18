/// 词库列表支持的固定排序方式。
enum WordSortOrder {
  frequencyDescending,
  frequencyAscending,
  alphabetAscending,
  alphabetDescending,
}

/// 词库分页查询条件。
class WordFilter {
  WordFilter({
    Set<int> frequencyGroupIds = const <int>{},
    String? firstLetter,
    String? keyword,
    this.sortOrder = WordSortOrder.frequencyDescending,
    this.page = firstPage,
    this.pageSize = defaultPageSize,
  }) : frequencyGroupIds = Set<int>.unmodifiable(frequencyGroupIds),
       firstLetter = _normalizeFirstLetter(firstLetter),
       keyword = _normalizeKeyword(keyword) {
    if (frequencyGroupIds.any((id) => id <= 0)) {
      throw ArgumentError.value(
        frequencyGroupIds,
        'frequencyGroupIds',
        '词频组 ID 必须为正整数',
      );
    }
    if (page < firstPage) {
      throw ArgumentError.value(page, 'page', '页码必须从 1 开始');
    }
    if (pageSize < minPageSize || pageSize > maxPageSize) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        '每页数量必须在 $minPageSize-$maxPageSize 之间',
      );
    }
  }

  static const int firstPage = 1;
  static const int minPageSize = 1;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int maxKeywordLength = 100;

  final Set<int> frequencyGroupIds;
  final String? firstLetter;
  final String? keyword;
  final WordSortOrder sortOrder;
  final int page;
  final int pageSize;

  int get offset => (page - firstPage) * pageSize;

  static String? _normalizeFirstLetter(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[A-Z]$').hasMatch(normalized)) {
      throw ArgumentError.value(value, 'firstLetter', '首字母必须为 A-Z');
    }
    return normalized;
  }

  static String? _normalizeKeyword(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.length > maxKeywordLength) {
      throw ArgumentError.value(
        value,
        'keyword',
        '关键词不能超过 $maxKeywordLength 个字符',
      );
    }
    return normalized;
  }
}
