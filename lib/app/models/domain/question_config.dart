/// 统一练习引擎支持的题型。
enum QuestionType {
  choiceEnglishToChinese,
  choiceChineseToEnglish,
  choiceWordToSentence,
  spelling,
  cloze,
}

/// 根据词频组聚合的三档练习难度。
enum QuestionDifficulty { easy, medium, hard }

/// 拼写题向用户提供的提示来源。
enum SpellingPromptType { translation, phonetic, definition, audio }

extension QuestionDifficultyFrequencyGroups on QuestionDifficulty {
  /// 难度只映射首期启用的六个词频组。
  Set<int> get frequencyGroupIds => switch (this) {
    QuestionDifficulty.easy => const {1, 2},
    QuestionDifficulty.medium => const {3, 4},
    QuestionDifficulty.hard => const {5, 6},
  };
}

/// 集中保存首期题量边界，产品确认后只需调整这一处。
abstract final class QuestionCountLimits {
  static const int defaultCount = 10;
  static const int minChoiceOrSpelling = 5;
  static const int maxChoiceOrSpelling = 50;
  static const int minCloze = 5;
  static const int maxCloze = 30;

  /// 返回指定题型允许的最小题量。
  static int minimumFor(QuestionType type, {bool isTargetedSpelling = false}) =>
      switch (type) {
        QuestionType.spelling when isTargetedSpelling => 1,
        QuestionType.cloze => minCloze,
        _ => minChoiceOrSpelling,
      };

  /// 返回指定题型允许的最大题量。
  static int maximumFor(QuestionType type) => switch (type) {
    QuestionType.cloze => maxCloze,
    _ => maxChoiceOrSpelling,
  };

  /// 切换题型时将已有题量限制到新题型的合法范围。
  static int constrainFor(QuestionType type, int value) {
    final minimum = minimumFor(type);
    final maximum = maximumFor(type);
    if (value < minimum) {
      return minimum;
    }
    if (value > maximum) {
      return maximum;
    }
    return value;
  }
}

/// 一次练习会话的不可变配置。
final class QuestionConfig {
  QuestionConfig({
    required this.type,
    Set<int> frequencyGroupIds = const {},
    Set<int> targetWordIds = const {},
    this.difficulty,
    this.wrongFirst = false,
    this.questionCount = QuestionCountLimits.defaultCount,
    this.timed = false,
    this.spellingPromptType,
    this.allowSpellingPhrases = false,
  }) : frequencyGroupIds = Set<int>.unmodifiable(frequencyGroupIds),
       targetWordIds = Set<int>.unmodifiable(targetWordIds) {
    _validate();
  }

  /// 为指定题型创建首期默认配置；拼写题默认使用中文释义提示。
  factory QuestionConfig.defaultsFor(QuestionType type) {
    return QuestionConfig(
      type: type,
      spellingPromptType: type == QuestionType.spelling
          ? SpellingPromptType.translation
          : null,
    );
  }

  /// 为复习页连续遗忘的单词创建单题拼写巩固配置。
  factory QuestionConfig.targetedSpelling({required int wordId}) {
    return QuestionConfig(
      type: QuestionType.spelling,
      targetWordIds: {wordId},
      questionCount: 1,
      spellingPromptType: SpellingPromptType.translation,
      allowSpellingPhrases: true,
    );
  }

  static const Set<int> activeFrequencyGroupIds = {1, 2, 3, 4, 5, 6};

  final QuestionType type;
  final Set<int> frequencyGroupIds;
  final Set<int> targetWordIds;
  final QuestionDifficulty? difficulty;
  final bool wrongFirst;
  final int questionCount;
  final bool timed;
  final SpellingPromptType? spellingPromptType;

  /// 首期默认排除含空格的多词短语；该开关为后续产品决策保留统一入口。
  final bool allowSpellingPhrases;

  /// 定向练习只允许使用指定单词，并采用单题拼写流程。
  bool get isTargeted => targetWordIds.isNotEmpty;

  /// 显式词频范围优先；未指定范围和难度时覆盖全部有效分组。
  Set<int> get effectiveFrequencyGroupIds {
    if (frequencyGroupIds.isNotEmpty) {
      return frequencyGroupIds;
    }
    return difficulty?.frequencyGroupIds ?? activeFrequencyGroupIds;
  }

  bool includesFrequencyGroup(int frequencyGroupId) {
    return effectiveFrequencyGroupIds.contains(frequencyGroupId);
  }

  /// 复制配置并重新执行全部领域校验，显式传入 `null` 可清除可空字段。
  QuestionConfig copyWith({
    QuestionType? type,
    Set<int>? frequencyGroupIds,
    Set<int>? targetWordIds,
    Object? difficulty = _unchanged,
    bool? wrongFirst,
    int? questionCount,
    bool? timed,
    Object? spellingPromptType = _unchanged,
    bool? allowSpellingPhrases,
  }) {
    return QuestionConfig(
      type: type ?? this.type,
      frequencyGroupIds: frequencyGroupIds ?? this.frequencyGroupIds,
      targetWordIds: targetWordIds ?? this.targetWordIds,
      difficulty: identical(difficulty, _unchanged)
          ? this.difficulty
          : difficulty as QuestionDifficulty?,
      wrongFirst: wrongFirst ?? this.wrongFirst,
      questionCount: questionCount ?? this.questionCount,
      timed: timed ?? this.timed,
      spellingPromptType: identical(spellingPromptType, _unchanged)
          ? this.spellingPromptType
          : spellingPromptType as SpellingPromptType?,
      allowSpellingPhrases: allowSpellingPhrases ?? this.allowSpellingPhrases,
    );
  }

  void _validate() {
    if (targetWordIds.length > 5 || targetWordIds.any((id) => id <= 0)) {
      throw ArgumentError.value(targetWordIds, 'targetWordIds', '定向单词集合无效');
    }
    final invalidGroupIds = frequencyGroupIds.difference(
      activeFrequencyGroupIds,
    );
    if (invalidGroupIds.isNotEmpty) {
      throw ArgumentError.value(
        frequencyGroupIds,
        'frequencyGroupIds',
        '词频组只能使用首期启用的 1-6 组',
      );
    }
    if (frequencyGroupIds.isNotEmpty && difficulty != null) {
      throw ArgumentError('frequencyGroupIds 与 difficulty 不能同时启用');
    }

    if (isTargeted &&
        (type != QuestionType.spelling ||
            frequencyGroupIds.isNotEmpty ||
            difficulty != null ||
            wrongFirst ||
            timed)) {
      throw ArgumentError('定向练习仅支持非计时的单题拼写流程');
    }

    final minimum = QuestionCountLimits.minimumFor(
      type,
      isTargetedSpelling: isTargeted,
    );
    final maximum = QuestionCountLimits.maximumFor(type);
    if (questionCount < minimum || questionCount > maximum) {
      throw ArgumentError.value(
        questionCount,
        'questionCount',
        '当前题型题量必须在 $minimum-$maximum 之间',
      );
    }
    if (isTargeted && questionCount != targetWordIds.length) {
      throw ArgumentError('定向练习题量必须与单词数量一致');
    }

    if (type == QuestionType.spelling && spellingPromptType == null) {
      throw ArgumentError('拼写题必须指定 spellingPromptType');
    }
    if (type != QuestionType.spelling && spellingPromptType != null) {
      throw ArgumentError('只有拼写题可以指定 spellingPromptType');
    }
    if (type != QuestionType.spelling && allowSpellingPhrases) {
      throw ArgumentError('只有拼写题可以启用多词短语');
    }
  }
}

const Object _unchanged = Object();
