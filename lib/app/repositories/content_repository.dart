import '../models/domain/frequency_group_summary.dart';
import '../models/domain/word_details.dart';
import '../models/domain/word_filter.dart';
import '../models/domain/word_summary.dart';

/// 为上层提供与 Drift 解耦的词库读取接口。
abstract interface class ContentRepository {
  Future<List<WordSummary>> findWords(WordFilter filter);

  /// 按受限稳定 ID 批量读取词库摘要，供跨库列表组合使用。
  Future<List<WordSummary>> findWordSummariesByIds(Set<int> wordIds);

  /// 按受限稳定 ID 批量读取例句，供收藏列表组合使用。
  Future<List<SentenceDetails>> findSentenceDetailsByIds(Set<int> sentenceIds);

  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups();

  Future<WordDetails?> findWordDetails(int wordId);
}
