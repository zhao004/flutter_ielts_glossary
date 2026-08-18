import '../models/domain/frequency_group_summary.dart';
import '../models/domain/vocabulary_page.dart';
import '../models/domain/word_filter.dart';

/// 词库页面所需的内容、收藏和掌握状态跨库读取接口。
abstract interface class VocabularyRepository {
  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups();

  Future<VocabularyPageResult> findPage(WordFilter filter);
}
