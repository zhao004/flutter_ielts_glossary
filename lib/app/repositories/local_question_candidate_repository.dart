import '../database/content/content_database.dart';
import '../database/content/daos/content_dao.dart';
import '../database/user/daos/user_data_dao.dart';
import '../models/domain/question_candidate.dart';
import '../models/domain/question_config.dart';
import '../services/question/question_random.dart';
import 'question_candidate_repository.dart';

/// 使用受限候选池组合两个物理数据库，不在 Dart 内存加载完整词库。
final class LocalQuestionCandidateRepository
    implements QuestionCandidateRepository {
  LocalQuestionCandidateRepository(
    this._contentDao,
    this._userDataDao, {
    QuestionRandomSource? randomSource,
  }) : _randomSource = randomSource ?? DartQuestionRandomSource();

  static const int minimumPoolSize = QuestionCandidatePoolLimits.minimum;
  static const int poolSizeMultiplier = 10;
  static const int maximumPoolSize = QuestionCandidatePoolLimits.maximum;
  static const int wrongHistoryPageSize = 500;
  static const int maximumOrderSeed = 1 << 30;

  final ContentDao _contentDao;
  final UserDataDao _userDataDao;
  final QuestionRandomSource _randomSource;

  @override
  Future<QuestionCandidateBatch> loadCandidateBatch(
    QuestionConfig config, {
    int? minimumPoolLimit,
  }) async {
    final poolLimit = _poolLimit(
      config.questionCount,
      minimumPoolLimit: minimumPoolLimit,
    );
    final orderSeed = _randomSource.nextInt(maximumOrderSeed);
    final databaseQualifiedWordCount = await _contentDao.countQuestionWords(
      config,
    );
    final targetWordIds = config.isTargeted ? config.targetWordIds : null;
    final selectedWords = <int, Word>{};

    if (config.wrongFirst) {
      await _appendHistoricalWrongWords(
        config: config,
        orderSeed: orderSeed,
        targetCount: config.questionCount,
        selectedWords: selectedWords,
      );
    }

    final remaining = poolLimit - selectedWords.length;
    if (remaining > 0) {
      final regularWords = await _contentDao.findQuestionWords(
        config: config,
        limit: remaining,
        orderSeed: orderSeed,
        includedWordIds: targetWordIds,
        excludedWordIds: selectedWords.keys.toSet(),
      );
      for (final word in regularWords) {
        selectedWords.putIfAbsent(word.id, () => word);
      }
    }

    final selectedWordIds = selectedWords.keys.toSet();
    final wrongWordIds = await _userDataDao.findHistoricallyWrongWordIds(
      selectedWordIds,
    );
    final sentences = _needsSentences(config.type)
        ? await _contentDao.findSentencesByWordIds(selectedWordIds)
        : const <Sentence>[];
    final sentencesByWordId = <int, List<Sentence>>{};
    for (final sentence in sentences) {
      sentencesByWordId.putIfAbsent(sentence.wordId, () => []).add(sentence);
    }

    final candidates = selectedWords.values
        .map(
          (word) => QuestionCandidate(
            wordId: word.id,
            word: word.word,
            frequencyGroupId: word.frequencyGroupId,
            translationZh: word.translationZh,
            definitionEn: word.definitionEn,
            phoneticUk: word.phoneticUk,
            phoneticUs: word.phoneticUs,
            audioUkAsset: word.audioUkAsset,
            audioUsAsset: word.audioUsAsset,
            isWrong: wrongWordIds.contains(word.id),
            sentences: (sentencesByWordId[word.id] ?? const <Sentence>[])
                .map(_toSentenceCandidate)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    return QuestionCandidateBatch(
      candidates: candidates,
      databaseQualifiedWordCount: databaseQualifiedWordCount,
      poolLimit: poolLimit,
    );
  }

  Future<void> _appendHistoricalWrongWords({
    required QuestionConfig config,
    required int orderSeed,
    required int targetCount,
    required Map<int, Word> selectedWords,
  }) async {
    var offset = 0;
    while (selectedWords.length < targetCount) {
      final wrongWordIds = await _userDataDao.findRecentWrongWordIds(
        limit: wrongHistoryPageSize,
        offset: offset,
      );
      if (wrongWordIds.isEmpty) {
        return;
      }
      final matchingWords = await _contentDao.findQuestionWords(
        config: config,
        limit: targetCount - selectedWords.length,
        orderSeed: orderSeed,
        includedWordIds: wrongWordIds.toSet(),
        excludedWordIds: selectedWords.keys.toSet(),
      );
      for (final word in matchingWords) {
        selectedWords.putIfAbsent(word.id, () => word);
      }
      offset += wrongWordIds.length;
      if (wrongWordIds.length < wrongHistoryPageSize) {
        return;
      }
    }
  }

  int _poolLimit(int questionCount, {int? minimumPoolLimit}) {
    if (minimumPoolLimit != null &&
        (minimumPoolLimit <= 0 || minimumPoolLimit > maximumPoolSize)) {
      throw ArgumentError.value(
        minimumPoolLimit,
        'minimumPoolLimit',
        '候选池下限必须在 1-$maximumPoolSize 之间',
      );
    }
    final scaled = questionCount * poolSizeMultiplier;
    final defaultLimit = scaled.clamp(minimumPoolSize, maximumPoolSize);
    return minimumPoolLimit != null && minimumPoolLimit > defaultLimit
        ? minimumPoolLimit
        : defaultLimit;
  }

  QuestionSentenceCandidate _toSentenceCandidate(Sentence sentence) {
    return QuestionSentenceCandidate(
      id: sentence.id,
      targetForm: sentence.targetForm,
      sentenceEn: sentence.sentenceEn,
      translationZh: sentence.translationZh,
      source: sentence.source,
      location: sentence.location,
    );
  }

  bool _needsSentences(QuestionType type) {
    return type == QuestionType.choiceWordToSentence ||
        type == QuestionType.cloze;
  }
}
