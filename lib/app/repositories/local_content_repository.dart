import '../database/content/daos/content_dao.dart';
import '../models/domain/frequency_group_summary.dart';
import '../models/domain/word_details.dart';
import '../models/domain/word_filter.dart';
import '../models/domain/word_summary.dart';
import 'content_repository.dart';

/// 将本地内容 DAO 的记录映射为稳定领域模型。
class LocalContentRepository implements ContentRepository {
  const LocalContentRepository(this._contentDao);

  final ContentDao _contentDao;

  @override
  Future<List<WordSummary>> findWords(WordFilter filter) async {
    final records = await _contentDao.findWords(filter);
    return records
        .map(
          (record) => WordSummary(
            id: record.id,
            word: record.word,
            phoneticUk: record.phoneticUk,
            phoneticUs: record.phoneticUs,
            translationZh: record.translationZh,
            occurrences: record.occurrences,
            frequencyGroupId: record.frequencyGroupId,
            audioUkAsset: record.audioUkAsset,
            audioUsAsset: record.audioUsAsset,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<WordSummary>> findWordSummariesByIds(Set<int> wordIds) async {
    final records = await _contentDao.findWordsByIds(wordIds);
    return records
        .map(
          (record) => WordSummary(
            id: record.id,
            word: record.word,
            phoneticUk: record.phoneticUk,
            phoneticUs: record.phoneticUs,
            translationZh: record.translationZh,
            occurrences: record.occurrences,
            frequencyGroupId: record.frequencyGroupId,
            audioUkAsset: record.audioUkAsset,
            audioUsAsset: record.audioUsAsset,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SentenceDetails>> findSentenceDetailsByIds(
    Set<int> sentenceIds,
  ) async {
    final records = await _contentDao.findSentencesByIds(sentenceIds);
    return records
        .map(
          (sentence) => SentenceDetails(
            id: sentence.id,
            wordId: sentence.wordId,
            targetForm: sentence.targetForm,
            sentenceEn: sentence.sentenceEn,
            translationZh: sentence.translationZh,
            source: sentence.source,
            location: sentence.location,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<FrequencyGroupSummary>> findActiveFrequencyGroups() async {
    final records = await _contentDao.findActiveFrequencyGroups();
    return records
        .map(
          (record) => FrequencyGroupSummary(
            id: record.id,
            name: record.name,
            rank: record.rank,
            minOccurrences: record.minOccurrences,
            maxOccurrences: record.maxOccurrences,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WordDetails?> findWordDetails(int wordId) async {
    final word = await _contentDao.findWordById(wordId);
    if (word == null) {
      return null;
    }
    final sentences = await _contentDao.findSentencesByWordId(wordId);
    return WordDetails(
      id: word.id,
      word: word.word,
      phoneticUk: word.phoneticUk,
      phoneticUs: word.phoneticUs,
      translationZh: word.translationZh,
      definitionEn: word.definitionEn,
      mnemonic: word.mnemonic,
      occurrences: word.occurrences,
      frequencyGroupId: word.frequencyGroupId,
      firstLetter: word.firstLetter,
      audioUkAsset: word.audioUkAsset,
      audioUsAsset: word.audioUsAsset,
      sentences: sentences
          .map(
            (sentence) => SentenceDetails(
              id: sentence.id,
              wordId: sentence.wordId,
              targetForm: sentence.targetForm,
              sentenceEn: sentence.sentenceEn,
              translationZh: sentence.translationZh,
              source: sentence.source,
              location: sentence.location,
            ),
          )
          .toList(growable: false),
    );
  }
}
