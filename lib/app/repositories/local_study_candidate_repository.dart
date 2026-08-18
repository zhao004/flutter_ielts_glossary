import '../database/content/daos/content_dao.dart';
import '../database/content/content_database.dart';
import '../models/domain/study_candidate.dart';
import '../models/domain/study_config.dart';
import '../models/domain/word_details.dart';
import '../services/question/question_random.dart';
import 'study_candidate_repository.dart';

/// 使用数据库侧伪随机排序抽取学习卡片，不把完整词库加载到 Dart。
final class LocalStudyCandidateRepository implements StudyCandidateRepository {
  LocalStudyCandidateRepository(
    this._contentDao, {
    QuestionRandomSource? randomSource,
  }) : _randomSource = randomSource ?? DartQuestionRandomSource();

  static const int maximumOrderSeed = 1 << 30;

  final ContentDao _contentDao;
  final QuestionRandomSource _randomSource;

  @override
  Future<StudyCandidateBatch> loadCandidates(StudyConfig config) async {
    final groups = config.effectiveFrequencyGroupIds;
    final availableCount = await _contentDao.countStudyWords(groups);
    final orderSeed = _randomSource.nextInt(maximumOrderSeed);
    final words = await _contentDao.findRandomStudyWords(
      frequencyGroupIds: groups,
      limit: config.wordCount,
      orderSeed: orderSeed,
    );
    final sentences = await _contentDao.findSentencesByWordIds(
      words.map((word) => word.id).toSet(),
    );
    final sentencesByWordId = <int, List<Sentence>>{};
    for (final sentence in sentences) {
      sentencesByWordId.putIfAbsent(sentence.wordId, () => []).add(sentence);
    }
    final candidates = words
        .map(
          (word) => StudyCandidate(
            WordDetails(
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
              sentences: (sentencesByWordId[word.id] ?? const <Sentence>[])
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
            ),
          ),
        )
        .toList(growable: false);
    return StudyCandidateBatch(
      candidates: candidates,
      availableCount: availableCount,
      requestedCount: config.wordCount,
    );
  }
}
