import '../../models/domain/question_candidate.dart';
import '../../models/domain/question_config.dart';
import '../../models/domain/question_session.dart';
import '../../models/domain/quiz_question.dart';
import 'question_eligibility_service.dart';
import 'question_random.dart';

/// 候选不足时在创建会话前返回可展示的稳定数量信息。
final class InsufficientQuestionCandidatesException implements Exception {
  const InsufficientQuestionCandidatesException({
    required this.type,
    required this.requestedCount,
    required this.availableCount,
    required this.scopedCount,
  });

  final QuestionType type;
  final int requestedCount;
  final int availableCount;
  final int scopedCount;

  @override
  String toString() {
    return 'insufficient_question_candidates: '
        '${type.name}/$availableCount/$requestedCount';
  }
}

/// 统一完成范围过滤、错题优先、无放回抽样和各题型内容生成。
final class QuestionEngine {
  QuestionEngine({
    QuestionRandomSource? randomSource,
    this.eligibilityService = const QuestionEligibilityService(),
    this.choiceOptionCount = defaultChoiceOptionCount,
  }) : _sampler = QuestionRandomSampler(
         randomSource ?? DartQuestionRandomSource(),
       ) {
    if (choiceOptionCount < 2) {
      throw ArgumentError.value(
        choiceOptionCount,
        'choiceOptionCount',
        '选择题选项数量至少为 2',
      );
    }
  }

  static const int defaultChoiceOptionCount = 4;

  final QuestionEligibilityService eligibilityService;
  final int choiceOptionCount;
  final QuestionRandomSampler _sampler;

  /// 纯计算可用数量，不消耗随机数，可直接驱动配置页的候选不足提示。
  QuestionAvailability inspectAvailability({
    required QuestionConfig config,
    required Iterable<QuestionCandidate> candidates,
  }) {
    final pool = _validatedCandidates(candidates);
    return _preparePool(config, pool).availability;
  }

  /// 候选充足时生成完整会话；不足时不会返回半成品或进入重试循环。
  QuestionSession createSession({
    required QuestionConfig config,
    required Iterable<QuestionCandidate> candidates,
  }) {
    final pool = _validatedCandidates(candidates);
    final prepared = _preparePool(config, pool);
    if (prepared.buildableCandidates.length < config.questionCount) {
      throw InsufficientQuestionCandidatesException(
        type: config.type,
        requestedCount: config.questionCount,
        availableCount: prepared.buildableCandidates.length,
        scopedCount: prepared.availability.scopedCandidateCount,
      );
    }

    final selectedCandidates = _selectCandidates(
      prepared.buildableCandidates,
      config,
    );
    final questions = <QuizQuestion>[];
    for (var index = 0; index < selectedCandidates.length; index++) {
      questions.add(
        _buildQuestion(
          id: 'question-${index + 1}-${selectedCandidates[index].wordId}',
          target: selectedCandidates[index],
          distractorPool: prepared.eligibleCandidates,
          config: config,
        ),
      );
    }
    return QuestionSession(
      config: config,
      questions: questions,
      availability: prepared.availability,
    );
  }

  _PreparedQuestionPool _preparePool(
    QuestionConfig config,
    List<QuestionCandidate> candidates,
  ) {
    final scopedCandidates = candidates
        .where(
          (candidate) =>
              config.includesFrequencyGroup(candidate.frequencyGroupId),
        )
        .toList(growable: false);
    final eligibleCandidates = scopedCandidates
        .where((candidate) => eligibilityService.isEligible(candidate, config))
        .toList(growable: false);
    final buildableCandidates = _isChoiceType(config.type)
        ? eligibleCandidates
              .where(
                (candidate) => _canBuildChoiceQuestion(
                  target: candidate,
                  candidates: eligibleCandidates,
                  type: config.type,
                ),
              )
              .toList(growable: false)
        : eligibleCandidates;
    return _PreparedQuestionPool(
      eligibleCandidates: eligibleCandidates,
      buildableCandidates: buildableCandidates,
      availability: QuestionAvailability(
        scopedCandidateCount: scopedCandidates.length,
        availableCandidateCount: buildableCandidates.length,
        wrongCandidateCount: buildableCandidates
            .where((candidate) => candidate.isWrong)
            .length,
      ),
    );
  }

  List<QuestionCandidate> _selectCandidates(
    List<QuestionCandidate> candidates,
    QuestionConfig config,
  ) {
    if (!config.wrongFirst) {
      return _sampler.sampleWithoutReplacement(
        candidates,
        config.questionCount,
      );
    }

    final wrongCandidates = candidates
        .where((candidate) => candidate.isWrong)
        .toList(growable: false);
    final regularCandidates = candidates
        .where((candidate) => !candidate.isWrong)
        .toList(growable: false);
    final wrongCount = wrongCandidates.length < config.questionCount
        ? wrongCandidates.length
        : config.questionCount;
    final selectedWrong = _sampler.sampleWithoutReplacement(
      wrongCandidates,
      wrongCount,
    );
    final remainingCount = config.questionCount - selectedWrong.length;
    final selectedRegular = _sampler.sampleWithoutReplacement(
      regularCandidates,
      remainingCount,
    );
    return List<QuestionCandidate>.unmodifiable([
      ...selectedWrong,
      ...selectedRegular,
    ]);
  }

  QuizQuestion _buildQuestion({
    required String id,
    required QuestionCandidate target,
    required List<QuestionCandidate> distractorPool,
    required QuestionConfig config,
  }) {
    return switch (config.type) {
      QuestionType.choiceEnglishToChinese ||
      QuestionType.choiceChineseToEnglish ||
      QuestionType.choiceWordToSentence => _buildChoiceQuestion(
        id: id,
        target: target,
        candidates: distractorPool,
        type: config.type,
      ),
      QuestionType.spelling => _buildSpellingQuestion(
        id: id,
        target: target,
        promptType: config.spellingPromptType!,
      ),
      QuestionType.cloze => _buildClozeQuestion(id: id, target: target),
    };
  }

  bool _canBuildChoiceQuestion({
    required QuestionCandidate target,
    required List<QuestionCandidate> candidates,
    required QuestionType type,
  }) {
    final requiredDistractors = choiceOptionCount - 1;
    if (type == QuestionType.choiceWordToSentence) {
      return target.sentences.any(
        (sentence) =>
            _choiceSeeds(
              target: target,
              candidates: candidates,
              type: type,
              excludedOptionText: sentence.sentenceEn,
            ).length >=
            requiredDistractors,
      );
    }
    return _choiceSeeds(
          target: target,
          candidates: candidates,
          type: type,
          excludedOptionText: switch (type) {
            QuestionType.choiceEnglishToChinese => target.translationZh!,
            QuestionType.choiceChineseToEnglish => target.word,
            _ => throw StateError('不支持的选择题类型：${type.name}'),
          },
        ).length >=
        requiredDistractors;
  }

  ChoiceQuestion _buildChoiceQuestion({
    required String id,
    required QuestionCandidate target,
    required List<QuestionCandidate> candidates,
    required QuestionType type,
  }) {
    final correct = type == QuestionType.choiceWordToSentence
        ? _pickBuildableCorrectSentence(
            target: target,
            candidates: candidates,
            type: type,
          )
        : _correctChoiceSeed(target, type);
    final distractors = _selectPrioritizedDistractors(
      target: target,
      candidates: candidates,
      type: type,
      count: choiceOptionCount - 1,
      correctOptionText: correct.text,
      comparisonLength: correct.comparisonLength,
    );
    final options = _sampler.shuffled([
      correct.toOption(),
      ...distractors.map((seed) => seed.toOption()),
    ]);
    return ChoiceQuestion(
      id: id,
      type: type,
      wordId: target.wordId,
      prompt: switch (type) {
        QuestionType.choiceEnglishToChinese ||
        QuestionType.choiceWordToSentence => target.word,
        QuestionType.choiceChineseToEnglish => target.translationZh!,
        _ => throw StateError('不支持的选择题类型：${type.name}'),
      },
      options: options,
      correctOptionId: correct.id,
      sentenceId: correct.sentenceId,
    );
  }

  _ChoiceSeed _correctChoiceSeed(QuestionCandidate target, QuestionType type) {
    return switch (type) {
      QuestionType.choiceEnglishToChinese => _ChoiceSeed(
        id: 'word:${target.wordId}',
        text: target.translationZh!,
        frequencyGroupId: target.frequencyGroupId,
        comparisonLength: target.word.runes.length,
      ),
      QuestionType.choiceChineseToEnglish => _ChoiceSeed(
        id: 'word:${target.wordId}',
        text: target.word,
        frequencyGroupId: target.frequencyGroupId,
        comparisonLength: target.word.runes.length,
      ),
      _ => throw StateError('不支持的选择题类型：${type.name}'),
    };
  }

  _ChoiceSeed _pickBuildableCorrectSentence({
    required QuestionCandidate target,
    required List<QuestionCandidate> candidates,
    required QuestionType type,
  }) {
    final requiredDistractors = choiceOptionCount - 1;
    final sentences = target.sentences
        .where(
          (sentence) =>
              _choiceSeeds(
                target: target,
                candidates: candidates,
                type: type,
                excludedOptionText: sentence.sentenceEn,
              ).length >=
              requiredDistractors,
        )
        .toList(growable: false);
    return _sentenceSeed(target, _sampler.pick(sentences));
  }

  List<_ChoiceSeed> _selectPrioritizedDistractors({
    required QuestionCandidate target,
    required List<QuestionCandidate> candidates,
    required QuestionType type,
    required int count,
    required String correctOptionText,
    required int comparisonLength,
  }) {
    final seeds = _choiceSeeds(
      target: target,
      candidates: candidates,
      type: type,
      excludedOptionText: correctOptionText,
    );
    final selected = <_ChoiceSeed>[];
    final sameGroup = seeds
        .where((seed) => seed.frequencyGroupId == target.frequencyGroupId)
        .toList(growable: true);
    final otherGroups = seeds
        .where((seed) => seed.frequencyGroupId != target.frequencyGroupId)
        .toList(growable: true);
    _takeClosestRandomized(sameGroup, selected, count, comparisonLength);
    _takeClosestRandomized(otherGroups, selected, count, comparisonLength);
    if (selected.length != count) {
      throw StateError('候选预检通过后仍无法生成唯一干扰项');
    }
    return List<_ChoiceSeed>.unmodifiable(selected);
  }

  void _takeClosestRandomized(
    List<_ChoiceSeed> pool,
    List<_ChoiceSeed> selected,
    int targetCount,
    int comparisonLength,
  ) {
    while (selected.length < targetCount && pool.isNotEmpty) {
      var minimumDistance = _distance(
        pool.first.comparisonLength,
        comparisonLength,
      );
      for (final seed in pool.skip(1)) {
        final distance = _distance(seed.comparisonLength, comparisonLength);
        if (distance < minimumDistance) {
          minimumDistance = distance;
        }
      }
      final closest = pool
          .where(
            (seed) =>
                _distance(seed.comparisonLength, comparisonLength) ==
                minimumDistance,
          )
          .toList(growable: false);
      final picked = _sampler.pick(closest);
      selected.add(picked);
      pool.remove(picked);
    }
  }

  List<_ChoiceSeed> _choiceSeeds({
    required QuestionCandidate target,
    required List<QuestionCandidate> candidates,
    required QuestionType type,
    required String excludedOptionText,
  }) {
    final normalizedCorrectText = _normalizeOptionText(excludedOptionText);
    final uniqueSeeds = <String, _ChoiceSeed>{};
    for (final candidate in candidates) {
      if (candidate.wordId == target.wordId) {
        continue;
      }
      final candidateSeeds = switch (type) {
        QuestionType.choiceEnglishToChinese => [
          _ChoiceSeed(
            id: 'word:${candidate.wordId}',
            text: candidate.translationZh!,
            frequencyGroupId: candidate.frequencyGroupId,
            comparisonLength: candidate.word.runes.length,
          ),
        ],
        QuestionType.choiceChineseToEnglish => [
          _ChoiceSeed(
            id: 'word:${candidate.wordId}',
            text: candidate.word,
            frequencyGroupId: candidate.frequencyGroupId,
            comparisonLength: candidate.word.runes.length,
          ),
        ],
        QuestionType.choiceWordToSentence =>
          candidate.sentences
              .map((sentence) => _sentenceSeed(candidate, sentence))
              .toList(growable: false),
        _ => throw StateError('不支持的选择题类型：${type.name}'),
      };
      for (final seed in candidateSeeds) {
        final normalizedText = _normalizeOptionText(seed.text);
        if (normalizedText == normalizedCorrectText) {
          continue;
        }
        uniqueSeeds.putIfAbsent(normalizedText, () => seed);
      }
    }
    return List<_ChoiceSeed>.unmodifiable(uniqueSeeds.values);
  }

  _ChoiceSeed _sentenceSeed(
    QuestionCandidate candidate,
    QuestionSentenceCandidate sentence,
  ) {
    return _ChoiceSeed(
      id: 'sentence:${sentence.id}',
      text: sentence.sentenceEn,
      frequencyGroupId: candidate.frequencyGroupId,
      comparisonLength: sentence.sentenceEn.runes.length,
      sentenceId: sentence.id,
    );
  }

  SpellingQuestion _buildSpellingQuestion({
    required String id,
    required QuestionCandidate target,
    required SpellingPromptType promptType,
  }) {
    return SpellingQuestion(
      id: id,
      wordId: target.wordId,
      promptType: promptType,
      expectedAnswer: target.word,
      promptText: switch (promptType) {
        SpellingPromptType.translation => target.translationZh,
        SpellingPromptType.phonetic => target.phoneticUk ?? target.phoneticUs,
        SpellingPromptType.definition => target.definitionEn,
        SpellingPromptType.audio => null,
      },
      audioUkAsset: target.audioUkAsset,
      audioUsAsset: target.audioUsAsset,
    );
  }

  ClozeQuestion _buildClozeQuestion({
    required String id,
    required QuestionCandidate target,
  }) {
    final match = _sampler.pick(eligibilityService.validClozeMatches(target));
    final sentence = match.sentence;
    final mask = List.filled(match.matchedText.runes.length, '_').join();
    final maskedSentence = sentence.sentenceEn.replaceRange(
      match.start,
      match.end,
      mask,
    );
    return ClozeQuestion(
      id: id,
      wordId: target.wordId,
      sentenceId: sentence.id,
      maskedSentence: maskedSentence,
      originalSentence: sentence.sentenceEn,
      targetWord: target.word,
      expectedAnswer: match.matchedText,
      translationZh: sentence.translationZh,
      source: sentence.source,
      location: sentence.location,
    );
  }

  List<QuestionCandidate> _validatedCandidates(
    Iterable<QuestionCandidate> candidates,
  ) {
    final result = candidates.toList(growable: false);
    final wordIds = <int>{};
    final sentenceIds = <int>{};
    for (final candidate in result) {
      if (!wordIds.add(candidate.wordId)) {
        throw ArgumentError.value(
          candidate.wordId,
          'candidates',
          '候选单词 ID 不能重复',
        );
      }
      for (final sentence in candidate.sentences) {
        if (!sentenceIds.add(sentence.id)) {
          throw ArgumentError.value(
            sentence.id,
            'candidates',
            '候选例句 ID 不能跨单词重复',
          );
        }
      }
    }
    return result;
  }
}

final class _PreparedQuestionPool {
  const _PreparedQuestionPool({
    required this.eligibleCandidates,
    required this.buildableCandidates,
    required this.availability,
  });

  final List<QuestionCandidate> eligibleCandidates;
  final List<QuestionCandidate> buildableCandidates;
  final QuestionAvailability availability;
}

final class _ChoiceSeed {
  const _ChoiceSeed({
    required this.id,
    required this.text,
    required this.frequencyGroupId,
    required this.comparisonLength,
    this.sentenceId,
  });

  final String id;
  final String text;
  final int frequencyGroupId;
  final int comparisonLength;
  final int? sentenceId;

  ChoiceOption toOption() => ChoiceOption(id: id, text: text);
}

bool _isChoiceType(QuestionType type) {
  return type == QuestionType.choiceEnglishToChinese ||
      type == QuestionType.choiceChineseToEnglish ||
      type == QuestionType.choiceWordToSentence;
}

String _normalizeOptionText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

int _distance(int first, int second) {
  final result = first - second;
  return result < 0 ? -result : result;
}
