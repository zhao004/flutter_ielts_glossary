import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';

void main() {
  group('QuestionDifficulty', () {
    test('三档难度分别映射两个有效词频组', () {
      expect(QuestionDifficulty.easy.frequencyGroupIds, {1, 2});
      expect(QuestionDifficulty.medium.frequencyGroupIds, {3, 4});
      expect(QuestionDifficulty.hard.frequencyGroupIds, {5, 6});
    });
  });

  group('QuestionConfig', () {
    test('题型默认配置、题量边界和复制操作共享同一领域规则', () {
      final spelling = QuestionConfig.defaultsFor(QuestionType.spelling);
      expect(spelling.spellingPromptType, SpellingPromptType.translation);
      expect(
        QuestionCountLimits.constrainFor(QuestionType.cloze, 50),
        QuestionCountLimits.maxCloze,
      );
      expect(
        QuestionCountLimits.minimumFor(QuestionType.cloze),
        QuestionCountLimits.minCloze,
      );

      final changed = spelling.copyWith(
        type: QuestionType.cloze,
        questionCount: 30,
        spellingPromptType: null,
      );
      expect(changed.type, QuestionType.cloze);
      expect(changed.spellingPromptType, isNull);
      expect(changed.questionCount, 30);
    });

    test('显式词频范围、难度和全范围分别生成正确有效范围', () {
      expect(
        QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          frequencyGroupIds: const {2, 4},
        ).effectiveFrequencyGroupIds,
        {2, 4},
      );
      expect(
        QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          difficulty: QuestionDifficulty.hard,
        ).effectiveFrequencyGroupIds,
        {5, 6},
      );
      expect(
        QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
        ).effectiveFrequencyGroupIds,
        {1, 2, 3, 4, 5, 6},
      );
    });

    test('拒绝同时启用词频范围和难度', () {
      expect(
        () => QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          frequencyGroupIds: const {1},
          difficulty: QuestionDifficulty.easy,
        ),
        throwsArgumentError,
      );
    });

    test('拒绝预留词频组和超出首期边界的题量', () {
      expect(
        () => QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          frequencyGroupIds: const {7},
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          questionCount: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestionConfig(type: QuestionType.cloze, questionCount: 31),
        throwsArgumentError,
      );
    });

    test('拼写提示类型只能用于拼写题且为必填项', () {
      expect(
        () => QuestionConfig(type: QuestionType.spelling),
        throwsArgumentError,
      );
      expect(
        () => QuestionConfig(
          type: QuestionType.cloze,
          spellingPromptType: SpellingPromptType.translation,
        ),
        throwsArgumentError,
      );
      expect(
        QuestionConfig(
          type: QuestionType.spelling,
          spellingPromptType: SpellingPromptType.phonetic,
        ).spellingPromptType,
        SpellingPromptType.phonetic,
      );
    });

    test('定向拼写允许单题，并拒绝与常规筛选或题型混用', () {
      final targeted = QuestionConfig.targetedSpelling(wordId: 12);

      expect(targeted.isTargeted, isTrue);
      expect(targeted.targetWordIds, {12});
      expect(targeted.questionCount, 1);
      expect(
        QuestionCountLimits.minimumFor(
          QuestionType.spelling,
          isTargetedSpelling: true,
        ),
        1,
      );
      expect(
        () => QuestionConfig(
          type: QuestionType.choiceEnglishToChinese,
          targetWordIds: const {12},
          questionCount: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestionConfig(
          type: QuestionType.spelling,
          targetWordIds: const {12},
          frequencyGroupIds: const {1},
          questionCount: 1,
          spellingPromptType: SpellingPromptType.translation,
        ),
        throwsArgumentError,
      );
    });
  });
}
