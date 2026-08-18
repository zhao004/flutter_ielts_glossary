import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/question_candidate.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/quiz_question.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_engine.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  group('QuestionEngine 范围与抽样', () {
    test('错题优先只抽取当前范围内错题并从普通候选补足', () {
      final candidates = [
        _candidate(1, groupId: 1, isWrong: true),
        _candidate(2, groupId: 1, isWrong: true),
        _candidate(3, groupId: 1),
        _candidate(4, groupId: 1),
        _candidate(5, groupId: 1),
        _candidate(6, groupId: 2, isWrong: true),
        _candidate(7, groupId: 2),
      ];
      final config = QuestionConfig(
        type: QuestionType.choiceEnglishToChinese,
        frequencyGroupIds: const {1},
        wrongFirst: true,
        questionCount: 5,
      );

      final session = _engine(
        seed: 7,
      ).createSession(config: config, candidates: candidates);
      final selectedIds = session.questions
          .map((question) => question.wordId)
          .toList(growable: false);

      expect(session.availability.scopedCandidateCount, 5);
      expect(session.availability.wrongCandidateCount, 2);
      expect(selectedIds.take(2).toSet(), {1, 2});
      expect(selectedIds, isNot(contains(6)));
      expect(selectedIds.toSet(), hasLength(5));
    });

    test('相同种子复现题目顺序、干扰项和选项顺序', () {
      final candidates = _candidates(8);
      final config = QuestionConfig(
        type: QuestionType.choiceChineseToEnglish,
        questionCount: 5,
      );

      final first = _engine(
        seed: 42,
      ).createSession(config: config, candidates: candidates);
      final second = _engine(
        seed: 42,
      ).createSession(config: config, candidates: candidates);

      expect(
        _serializeChoices(first.questions),
        _serializeChoices(second.questions),
      );
    });

    test('候选或唯一干扰项不足时在会话开始前报告可用数量', () {
      final candidates = List.generate(
        5,
        (index) => _candidate(index + 1, translation: '重复释义'),
      );
      final config = QuestionConfig(
        type: QuestionType.choiceEnglishToChinese,
        questionCount: 5,
      );
      final engine = _engine(seed: 1);

      final availability = engine.inspectAvailability(
        config: config,
        candidates: candidates,
      );

      expect(availability.scopedCandidateCount, 5);
      expect(availability.availableCandidateCount, 0);
      expect(
        () => engine.createSession(config: config, candidates: candidates),
        throwsA(
          isA<InsufficientQuestionCandidatesException>()
              .having((error) => error.requestedCount, 'requestedCount', 5)
              .having((error) => error.availableCount, 'availableCount', 0),
        ),
      );
    });

    test('重复单词 ID 被视为输入错误', () {
      final candidate = _candidate(1);
      final config = QuestionConfig(
        type: QuestionType.choiceEnglishToChinese,
        questionCount: 5,
      );

      expect(
        () => _engine(seed: 1).inspectAvailability(
          config: config,
          candidates: [candidate, candidate],
        ),
        throwsArgumentError,
      );
    });
  });

  group('QuestionEngine 选择题', () {
    test('干扰项内容唯一并优先使用同组且长度相近的单词', () {
      final candidates = [
        _candidate(1, word: 'apple', groupId: 1),
        _candidate(2, word: 'angle', groupId: 1),
        _candidate(3, word: 'ample', groupId: 1),
        _candidate(4, word: 'banana', groupId: 2),
        _candidate(5, word: 'cedar', groupId: 2),
        _candidate(6, word: 'delta', groupId: 2),
      ];
      final session = _engine(seed: 10, choiceOptionCount: 3).createSession(
        config: QuestionConfig(
          type: QuestionType.choiceChineseToEnglish,
          questionCount: 6,
        ),
        candidates: candidates,
      );
      final question = session.questions
          .whereType<ChoiceQuestion>()
          .singleWhere((item) => item.wordId == 1);

      expect(question.options.map((option) => option.id).toSet(), {
        'word:1',
        'word:2',
        'word:3',
      });
      expect(
        question.options.map((option) => option.text.toLowerCase()).toSet(),
        hasLength(question.options.length),
      );
    });

    test('重复中文释义不会生成重复选项', () {
      final candidates = [
        _candidate(1, translation: '相同释义'),
        _candidate(2, translation: '相同释义'),
        _candidate(3, translation: '释义三'),
        _candidate(4, translation: '释义四'),
        _candidate(5, translation: '释义五'),
        _candidate(6, translation: '释义六'),
      ];
      final session = _engine(seed: 8).createSession(
        config: QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          questionCount: 5,
        ),
        candidates: candidates,
      );

      for (final question in session.questions.whereType<ChoiceQuestion>()) {
        final normalizedOptions = question.options
            .map((option) => option.text.trim().toLowerCase())
            .toSet();
        expect(normalizedOptions, hasLength(question.options.length));
        expect(question.options, contains(question.correctOption));
      }
    });

    test('例句题正确选项真实关联目标单词', () {
      final candidates = _candidates(5);
      final session = _engine(seed: 9).createSession(
        config: QuestionConfig(
          type: QuestionType.choiceWordToSentence,
          questionCount: 5,
        ),
        candidates: candidates,
      );

      for (final question in session.questions.whereType<ChoiceQuestion>()) {
        expect(question.correctOptionId, 'sentence:${question.wordId * 10}');
        expect(question.sentenceId, question.wordId * 10);
        expect(question.correctOption.text, contains(_word(question.wordId)));
      }
    });
  });

  group('QuestionEngine 拼写与填空', () {
    test('拼写题按提示类型生成所需字段并默认排除多词短语', () {
      final candidates = [..._candidates(5), _candidate(6, word: 'ice cream')];
      final baseConfig = QuestionConfig(
        type: QuestionType.spelling,
        spellingPromptType: SpellingPromptType.translation,
        questionCount: 5,
      );
      final engine = _engine(seed: 3);

      expect(
        engine
            .inspectAvailability(config: baseConfig, candidates: candidates)
            .availableCandidateCount,
        5,
      );
      expect(
        engine
            .inspectAvailability(
              config: QuestionConfig(
                type: QuestionType.spelling,
                spellingPromptType: SpellingPromptType.translation,
                allowSpellingPhrases: true,
                questionCount: 5,
              ),
              candidates: candidates,
            )
            .availableCandidateCount,
        6,
      );

      final translationSession = _engine(
        seed: 3,
      ).createSession(config: baseConfig, candidates: candidates);
      final phoneticSession = _engine(seed: 3).createSession(
        config: QuestionConfig(
          type: QuestionType.spelling,
          spellingPromptType: SpellingPromptType.phonetic,
          questionCount: 5,
        ),
        candidates: candidates,
      );
      final definitionSession = _engine(seed: 3).createSession(
        config: QuestionConfig(
          type: QuestionType.spelling,
          spellingPromptType: SpellingPromptType.definition,
          questionCount: 5,
        ),
        candidates: candidates,
      );
      final audioSession = _engine(seed: 3).createSession(
        config: QuestionConfig(
          type: QuestionType.spelling,
          spellingPromptType: SpellingPromptType.audio,
          questionCount: 5,
        ),
        candidates: candidates,
      );

      expect(
        translationSession.questions.whereType<SpellingQuestion>(),
        everyElement(
          isA<SpellingQuestion>().having(
            (question) => question.promptText,
            'promptText',
            isNotNull,
          ),
        ),
      );
      expect(
        phoneticSession.questions.whereType<SpellingQuestion>(),
        everyElement(
          isA<SpellingQuestion>().having(
            (question) => question.promptText,
            'promptText',
            startsWith('/'),
          ),
        ),
      );
      expect(
        definitionSession.questions.whereType<SpellingQuestion>(),
        everyElement(
          isA<SpellingQuestion>().having(
            (question) => question.promptText,
            'promptText',
            startsWith('definition'),
          ),
        ),
      );
      expect(
        audioSession.questions.whereType<SpellingQuestion>(),
        everyElement(
          isA<SpellingQuestion>().having(
            (question) => question.audioUkAsset,
            'audioUkAsset',
            isNotNull,
          ),
        ),
      );
    });

    test('填空题排除子串伪匹配并保留例句中的实际大小写词形', () {
      final candidates = [
        _candidate(
          1,
          word: 'import',
          sentences: [
            QuestionSentenceCandidate(
              id: 10,
              targetForm: 'import',
              sentenceEn: 'This is an important point.',
            ),
          ],
        ),
        _candidate(
          2,
          word: 'export',
          sentences: [
            QuestionSentenceCandidate(
              id: 20,
              targetForm: 'export',
              sentenceEn: 'We EXPORT goods every day.',
              translationZh: '我们每天出口商品。',
              source: 'Cambridge',
              location: 'Test 1',
            ),
          ],
        ),
        ..._candidates(4, startId: 3),
      ];
      final config = QuestionConfig(type: QuestionType.cloze, questionCount: 5);
      final engine = _engine(seed: 5);

      final availability = engine.inspectAvailability(
        config: config,
        candidates: candidates,
      );
      final session = engine.createSession(
        config: config,
        candidates: candidates,
      );
      final exportQuestion = session.questions
          .whereType<ClozeQuestion>()
          .singleWhere((question) => question.wordId == 2);

      expect(availability.scopedCandidateCount, 6);
      expect(availability.availableCandidateCount, 5);
      expect(
        session.questions.map((question) => question.wordId),
        isNot(contains(1)),
      );
      expect(exportQuestion.expectedAnswer, 'EXPORT');
      expect(exportQuestion.maskedSentence, 'We ______ goods every day.');
      expect(exportQuestion.firstLetterHint, 'E');
      expect(exportQuestion.answerLength, 6);
      expect(exportQuestion.hintForRevealedLetters(2), 'EX____');
      expect(exportQuestion.translationZh, '我们每天出口商品。');
    });
  });
}

QuestionEngine _engine({required int seed, int choiceOptionCount = 4}) {
  return QuestionEngine(
    randomSource: DartQuestionRandomSource(seed: seed),
    choiceOptionCount: choiceOptionCount,
  );
}

List<QuestionCandidate> _candidates(int count, {int startId = 1}) {
  return List.generate(
    count,
    (index) => _candidate(startId + index),
    growable: false,
  );
}

QuestionCandidate _candidate(
  int id, {
  String? word,
  int groupId = 1,
  String? translation,
  bool isWrong = false,
  List<QuestionSentenceCandidate>? sentences,
}) {
  final resolvedWord = word ?? _word(id);
  return QuestionCandidate(
    wordId: id,
    word: resolvedWord,
    frequencyGroupId: groupId,
    translationZh: translation ?? '释义$id',
    definitionEn: 'definition$id',
    phoneticUk: '/phonetic$id/',
    audioUkAsset: 'assets/audio/$id.mp3',
    isWrong: isWrong,
    sentences:
        sentences ??
        [
          QuestionSentenceCandidate(
            id: id * 10,
            targetForm: resolvedWord,
            sentenceEn: 'We use $resolvedWord in context.',
            translationZh: '例句$id',
          ),
        ],
  );
}

String _word(int id) {
  const words = [
    'apple',
    'banana',
    'cedar',
    'delta',
    'eagle',
    'forest',
    'garden',
    'harbor',
    'island',
    'jungle',
    'kitten',
    'lemon',
  ];
  return words[(id - 1) % words.length];
}

List<String> _serializeChoices(List<QuizQuestion> questions) {
  return questions
      .whereType<ChoiceQuestion>()
      .map((question) {
        final options = question.options
            .map((option) => '${option.id}:${option.text}')
            .join('|');
        return '${question.wordId}/${question.correctOptionId}/$options';
      })
      .toList(growable: false);
}
