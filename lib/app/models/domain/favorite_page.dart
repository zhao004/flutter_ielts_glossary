import 'favorite_record.dart';
import 'word_details.dart';
import 'word_learning_state.dart';
import 'word_summary.dart';

/// 收藏页展示的内容类型。
enum FavoriteCollectionType { words, sentences }

/// 收藏内容的字母排序方向。
enum FavoriteSortOrder { alphabetAscending, alphabetDescending }

/// 收藏页跨库筛选和分页条件。
final class FavoriteFilter {
  FavoriteFilter({
    this.type = FavoriteCollectionType.words,
    Set<int> frequencyGroupIds = const {},
    String? firstLetter,
    String? keyword,
    this.masteryLevel,
    this.sortOrder = FavoriteSortOrder.alphabetAscending,
    this.page = 1,
    this.pageSize = 20,
  }) : frequencyGroupIds = Set<int>.unmodifiable(frequencyGroupIds),
       firstLetter = _normalizeFirstLetter(firstLetter),
       keyword = _normalizeKeyword(keyword) {
    if (frequencyGroupIds.length > 6 ||
        frequencyGroupIds.any((groupId) => groupId <= 0 || groupId > 6)) {
      throw ArgumentError.value(
        frequencyGroupIds,
        'frequencyGroupIds',
        '词频组必须是 1-6 的受限集合',
      );
    }
    if (masteryLevel != null && (masteryLevel! < 0 || masteryLevel! > 5)) {
      throw ArgumentError.value(masteryLevel, 'masteryLevel', '掌握等级必须在 0-5 之间');
    }
    if (page <= 0 || page > 1000) {
      throw ArgumentError.value(page, 'page', '收藏页码必须在 1-1000 之间');
    }
    if (pageSize <= 0 || pageSize > 100) {
      throw ArgumentError.value(pageSize, 'pageSize', '收藏页大小必须在 1-100 之间');
    }
  }

  final FavoriteCollectionType type;
  final Set<int> frequencyGroupIds;
  final String? firstLetter;
  final String? keyword;
  final int? masteryLevel;
  final FavoriteSortOrder sortOrder;
  final int page;
  final int pageSize;

  int get offset => (page - 1) * pageSize;

  FavoriteFilter copyWith({
    FavoriteCollectionType? type,
    Set<int>? frequencyGroupIds,
    Object? firstLetter = _unset,
    Object? keyword = _unset,
    Object? masteryLevel = _unset,
    FavoriteSortOrder? sortOrder,
    int? page,
    int? pageSize,
  }) {
    return FavoriteFilter(
      type: type ?? this.type,
      frequencyGroupIds: frequencyGroupIds ?? this.frequencyGroupIds,
      firstLetter: identical(firstLetter, _unset)
          ? this.firstLetter
          : firstLetter as String?,
      keyword: identical(keyword, _unset) ? this.keyword : keyword as String?,
      masteryLevel: identical(masteryLevel, _unset)
          ? this.masteryLevel
          : masteryLevel as int?,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  bool matchesWord(WordSummary word, WordLearningState? learningState) {
    if (frequencyGroupIds.isNotEmpty &&
        !frequencyGroupIds.contains(word.frequencyGroupId)) {
      return false;
    }
    if (firstLetter != null && word.firstLetter != firstLetter) {
      return false;
    }
    if (masteryLevel != null &&
        (learningState?.masteryLevel ?? 0) != masteryLevel) {
      return false;
    }
    final search = keyword;
    if (search != null &&
        !word.word.toLowerCase().contains(search) &&
        !(word.translationZh?.toLowerCase().contains(search) ?? false)) {
      return false;
    }
    return true;
  }

  /// 例句收藏除关联单词外，还匹配英文例句、译文和目标词形。
  bool matchesSentence(
    SentenceDetails sentence,
    WordSummary word,
    WordLearningState? learningState,
  ) {
    final search = keyword;
    if (search == null) {
      return matchesWord(word, learningState);
    }
    final wordFilter = copyWith(keyword: null);
    if (!wordFilter.matchesWord(word, learningState)) {
      return false;
    }
    return word.word.toLowerCase().contains(search) ||
        (word.translationZh?.toLowerCase().contains(search) ?? false) ||
        sentence.sentenceEn.toLowerCase().contains(search) ||
        (sentence.translationZh?.toLowerCase().contains(search) ?? false) ||
        sentence.targetForm.toLowerCase().contains(search);
  }
}

/// 收藏页结果项基类；页面按具体类型渲染单词或例句。
sealed class FavoriteListItem {
  int get contentId;

  int get wordId;

  WordLearningState? get learningState;
}

/// 收藏单词及其当前学习状态。
final class FavoriteWordItem extends FavoriteListItem {
  FavoriteWordItem({
    required this.favorite,
    required this.word,
    required this.learningState,
  });

  final FavoriteWordRecord favorite;
  final WordSummary word;
  @override
  final WordLearningState? learningState;

  @override
  int get contentId => word.id;

  @override
  int get wordId => word.id;
}

/// 收藏例句、关联单词摘要及其学习状态。
final class FavoriteSentenceItem extends FavoriteListItem {
  FavoriteSentenceItem({
    required this.favorite,
    required this.sentence,
    required this.word,
    required this.learningState,
  });

  final FavoriteSentenceRecord favorite;
  final SentenceDetails sentence;
  final WordSummary word;
  @override
  final WordLearningState? learningState;

  @override
  int get contentId => sentence.id;

  @override
  int get wordId => word.id;
}

/// 收藏列表查询结果；缺失内容 ID 供页面展示词库升级提示。
final class FavoritePageResult {
  FavoritePageResult({
    required this.filter,
    required List<FavoriteListItem> items,
    required this.hasMore,
    required List<int> missingContentIds,
    int? totalCount,
  }) : items = List<FavoriteListItem>.unmodifiable(items),
       missingContentIds = List<int>.unmodifiable(missingContentIds),
       totalCount = totalCount ?? items.length {
    if (items.length > filter.pageSize) {
      throw ArgumentError('收藏结果不能超过请求页大小');
    }
    if (missingContentIds.any((id) => id <= 0)) {
      throw ArgumentError('缺失内容 ID 必须为正整数');
    }
  }

  final FavoriteFilter filter;
  final List<FavoriteListItem> items;
  final bool hasMore;
  final List<int> missingContentIds;
  final int totalCount;
}

String? _normalizeFirstLetter(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (!RegExp(r'^[A-Z]$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'firstLetter', '首字母必须为 A-Z');
  }
  return normalized;
}

String? _normalizeKeyword(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.length > 100) {
    throw ArgumentError.value(value, 'keyword', '收藏搜索关键词不能超过 100 个字符');
  }
  return normalized;
}

const _unset = Object();
