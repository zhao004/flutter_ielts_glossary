// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $UserWordStatesTable extends UserWordStates
    with TableInfo<$UserWordStatesTable, UserWordState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _masteryLevelMeta = const VerificationMeta(
    'masteryLevel',
  );
  @override
  late final GeneratedColumn<int> masteryLevel = GeneratedColumn<int>(
    'mastery_level',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('mastery_level BETWEEN 0 AND 5'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _studiedCountMeta = const VerificationMeta(
    'studiedCount',
  );
  @override
  late final GeneratedColumn<int> studiedCount = GeneratedColumn<int>(
    'studied_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('studied_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('correct_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('wrong_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctStreakMeta = const VerificationMeta(
    'correctStreak',
  );
  @override
  late final GeneratedColumn<int> correctStreak = GeneratedColumn<int>(
    'correct_streak',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('correct_streak >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _consecutiveForgottenCountMeta =
      const VerificationMeta('consecutiveForgottenCount');
  @override
  late final GeneratedColumn<int> consecutiveForgottenCount =
      GeneratedColumn<int>(
        'consecutive_forgotten_count',
        aliasedName,
        false,
        check: () =>
            const CustomExpression<bool>('consecutive_forgotten_count >= 0'),
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastStudiedAt =
      GeneratedColumn<int>(
        'last_studied_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWordStatesTable.$converterlastStudiedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastReviewedAt =
      GeneratedColumn<int>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserWordStatesTable.$converterlastReviewedAtn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> nextReviewAt =
      GeneratedColumn<int>(
        'next_review_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWordStatesTable.$converternextReviewAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($UserWordStatesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    masteryLevel,
    studiedCount,
    correctCount,
    wrongCount,
    correctStreak,
    consecutiveForgottenCount,
    lastStudiedAt,
    lastReviewedAt,
    nextReviewAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_word_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWordState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
        _masteryLevelMeta,
        masteryLevel.isAcceptableOrUnknown(
          data['mastery_level']!,
          _masteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('studied_count')) {
      context.handle(
        _studiedCountMeta,
        studiedCount.isAcceptableOrUnknown(
          data['studied_count']!,
          _studiedCountMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    }
    if (data.containsKey('correct_streak')) {
      context.handle(
        _correctStreakMeta,
        correctStreak.isAcceptableOrUnknown(
          data['correct_streak']!,
          _correctStreakMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_forgotten_count')) {
      context.handle(
        _consecutiveForgottenCountMeta,
        consecutiveForgottenCount.isAcceptableOrUnknown(
          data['consecutive_forgotten_count']!,
          _consecutiveForgottenCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  UserWordState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWordState(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      masteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_level'],
      )!,
      studiedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}studied_count'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      correctStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_streak'],
      )!,
      consecutiveForgottenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_forgotten_count'],
      )!,
      lastStudiedAt: $UserWordStatesTable.$converterlastStudiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_studied_at'],
        ),
      ),
      lastReviewedAt: $UserWordStatesTable.$converterlastReviewedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_reviewed_at'],
        ),
      ),
      nextReviewAt: $UserWordStatesTable.$converternextReviewAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}next_review_at'],
        ),
      ),
      updatedAt: $UserWordStatesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $UserWordStatesTable createAlias(String alias) {
    return $UserWordStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterlastStudiedAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime?, int?> $converterlastStudiedAtn =
      NullAwareTypeConverter.wrap($converterlastStudiedAt);
  static TypeConverter<DateTime, int> $converterlastReviewedAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime?, int?> $converterlastReviewedAtn =
      NullAwareTypeConverter.wrap($converterlastReviewedAt);
  static TypeConverter<DateTime, int> $converternextReviewAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime?, int?> $converternextReviewAtn =
      NullAwareTypeConverter.wrap($converternextReviewAt);
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeMillisecondsConverter();
}

class UserWordState extends DataClass implements Insertable<UserWordState> {
  final int wordId;
  final int masteryLevel;
  final int studiedCount;
  final int correctCount;
  final int wrongCount;
  final int correctStreak;
  final int consecutiveForgottenCount;
  final DateTime? lastStudiedAt;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final DateTime updatedAt;
  const UserWordState({
    required this.wordId,
    required this.masteryLevel,
    required this.studiedCount,
    required this.correctCount,
    required this.wrongCount,
    required this.correctStreak,
    required this.consecutiveForgottenCount,
    this.lastStudiedAt,
    this.lastReviewedAt,
    this.nextReviewAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['mastery_level'] = Variable<int>(masteryLevel);
    map['studied_count'] = Variable<int>(studiedCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    map['correct_streak'] = Variable<int>(correctStreak);
    map['consecutive_forgotten_count'] = Variable<int>(
      consecutiveForgottenCount,
    );
    if (!nullToAbsent || lastStudiedAt != null) {
      map['last_studied_at'] = Variable<int>(
        $UserWordStatesTable.$converterlastStudiedAtn.toSql(lastStudiedAt),
      );
    }
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<int>(
        $UserWordStatesTable.$converterlastReviewedAtn.toSql(lastReviewedAt),
      );
    }
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<int>(
        $UserWordStatesTable.$converternextReviewAtn.toSql(nextReviewAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $UserWordStatesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  UserWordStatesCompanion toCompanion(bool nullToAbsent) {
    return UserWordStatesCompanion(
      wordId: Value(wordId),
      masteryLevel: Value(masteryLevel),
      studiedCount: Value(studiedCount),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      correctStreak: Value(correctStreak),
      consecutiveForgottenCount: Value(consecutiveForgottenCount),
      lastStudiedAt: lastStudiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStudiedAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserWordState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWordState(
      wordId: serializer.fromJson<int>(json['wordId']),
      masteryLevel: serializer.fromJson<int>(json['masteryLevel']),
      studiedCount: serializer.fromJson<int>(json['studiedCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      correctStreak: serializer.fromJson<int>(json['correctStreak']),
      consecutiveForgottenCount: serializer.fromJson<int>(
        json['consecutiveForgottenCount'],
      ),
      lastStudiedAt: serializer.fromJson<DateTime?>(json['lastStudiedAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'masteryLevel': serializer.toJson<int>(masteryLevel),
      'studiedCount': serializer.toJson<int>(studiedCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'correctStreak': serializer.toJson<int>(correctStreak),
      'consecutiveForgottenCount': serializer.toJson<int>(
        consecutiveForgottenCount,
      ),
      'lastStudiedAt': serializer.toJson<DateTime?>(lastStudiedAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserWordState copyWith({
    int? wordId,
    int? masteryLevel,
    int? studiedCount,
    int? correctCount,
    int? wrongCount,
    int? correctStreak,
    int? consecutiveForgottenCount,
    Value<DateTime?> lastStudiedAt = const Value.absent(),
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    Value<DateTime?> nextReviewAt = const Value.absent(),
    DateTime? updatedAt,
  }) => UserWordState(
    wordId: wordId ?? this.wordId,
    masteryLevel: masteryLevel ?? this.masteryLevel,
    studiedCount: studiedCount ?? this.studiedCount,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    correctStreak: correctStreak ?? this.correctStreak,
    consecutiveForgottenCount:
        consecutiveForgottenCount ?? this.consecutiveForgottenCount,
    lastStudiedAt: lastStudiedAt.present
        ? lastStudiedAt.value
        : this.lastStudiedAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserWordState copyWithCompanion(UserWordStatesCompanion data) {
    return UserWordState(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      studiedCount: data.studiedCount.present
          ? data.studiedCount.value
          : this.studiedCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      correctStreak: data.correctStreak.present
          ? data.correctStreak.value
          : this.correctStreak,
      consecutiveForgottenCount: data.consecutiveForgottenCount.present
          ? data.consecutiveForgottenCount.value
          : this.consecutiveForgottenCount,
      lastStudiedAt: data.lastStudiedAt.present
          ? data.lastStudiedAt.value
          : this.lastStudiedAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWordState(')
          ..write('wordId: $wordId, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('studiedCount: $studiedCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('consecutiveForgottenCount: $consecutiveForgottenCount, ')
          ..write('lastStudiedAt: $lastStudiedAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    masteryLevel,
    studiedCount,
    correctCount,
    wrongCount,
    correctStreak,
    consecutiveForgottenCount,
    lastStudiedAt,
    lastReviewedAt,
    nextReviewAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWordState &&
          other.wordId == this.wordId &&
          other.masteryLevel == this.masteryLevel &&
          other.studiedCount == this.studiedCount &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.correctStreak == this.correctStreak &&
          other.consecutiveForgottenCount == this.consecutiveForgottenCount &&
          other.lastStudiedAt == this.lastStudiedAt &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.nextReviewAt == this.nextReviewAt &&
          other.updatedAt == this.updatedAt);
}

class UserWordStatesCompanion extends UpdateCompanion<UserWordState> {
  final Value<int> wordId;
  final Value<int> masteryLevel;
  final Value<int> studiedCount;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<int> correctStreak;
  final Value<int> consecutiveForgottenCount;
  final Value<DateTime?> lastStudiedAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime> updatedAt;
  const UserWordStatesCompanion({
    this.wordId = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.studiedCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.correctStreak = const Value.absent(),
    this.consecutiveForgottenCount = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserWordStatesCompanion.insert({
    this.wordId = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.studiedCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.correctStreak = const Value.absent(),
    this.consecutiveForgottenCount = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<UserWordState> custom({
    Expression<int>? wordId,
    Expression<int>? masteryLevel,
    Expression<int>? studiedCount,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<int>? correctStreak,
    Expression<int>? consecutiveForgottenCount,
    Expression<int>? lastStudiedAt,
    Expression<int>? lastReviewedAt,
    Expression<int>? nextReviewAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (studiedCount != null) 'studied_count': studiedCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (correctStreak != null) 'correct_streak': correctStreak,
      if (consecutiveForgottenCount != null)
        'consecutive_forgotten_count': consecutiveForgottenCount,
      if (lastStudiedAt != null) 'last_studied_at': lastStudiedAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserWordStatesCompanion copyWith({
    Value<int>? wordId,
    Value<int>? masteryLevel,
    Value<int>? studiedCount,
    Value<int>? correctCount,
    Value<int>? wrongCount,
    Value<int>? correctStreak,
    Value<int>? consecutiveForgottenCount,
    Value<DateTime?>? lastStudiedAt,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime?>? nextReviewAt,
    Value<DateTime>? updatedAt,
  }) {
    return UserWordStatesCompanion(
      wordId: wordId ?? this.wordId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      studiedCount: studiedCount ?? this.studiedCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      correctStreak: correctStreak ?? this.correctStreak,
      consecutiveForgottenCount:
          consecutiveForgottenCount ?? this.consecutiveForgottenCount,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<int>(masteryLevel.value);
    }
    if (studiedCount.present) {
      map['studied_count'] = Variable<int>(studiedCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (correctStreak.present) {
      map['correct_streak'] = Variable<int>(correctStreak.value);
    }
    if (consecutiveForgottenCount.present) {
      map['consecutive_forgotten_count'] = Variable<int>(
        consecutiveForgottenCount.value,
      );
    }
    if (lastStudiedAt.present) {
      map['last_studied_at'] = Variable<int>(
        $UserWordStatesTable.$converterlastStudiedAtn.toSql(
          lastStudiedAt.value,
        ),
      );
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<int>(
        $UserWordStatesTable.$converterlastReviewedAtn.toSql(
          lastReviewedAt.value,
        ),
      );
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<int>(
        $UserWordStatesTable.$converternextReviewAtn.toSql(nextReviewAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $UserWordStatesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordStatesCompanion(')
          ..write('wordId: $wordId, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('studiedCount: $studiedCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('consecutiveForgottenCount: $consecutiveForgottenCount, ')
          ..write('lastStudiedAt: $lastStudiedAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteWordsTable extends FavoriteWords
    with TableInfo<$FavoriteWordsTable, FavoriteWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($FavoriteWordsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($FavoriteWordsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, wordId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      createdAt: $FavoriteWordsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $FavoriteWordsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $FavoriteWordsTable createAlias(String alias) {
    return $FavoriteWordsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeMillisecondsConverter();
}

class FavoriteWord extends DataClass implements Insertable<FavoriteWord> {
  final String id;
  final int wordId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FavoriteWord({
    required this.id,
    required this.wordId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['word_id'] = Variable<int>(wordId);
    {
      map['created_at'] = Variable<int>(
        $FavoriteWordsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $FavoriteWordsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  FavoriteWordsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteWordsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FavoriteWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteWord(
      id: serializer.fromJson<String>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wordId': serializer.toJson<int>(wordId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FavoriteWord copyWith({
    String? id,
    int? wordId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FavoriteWord(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FavoriteWord copyWithCompanion(FavoriteWordsCompanion data) {
    return FavoriteWord(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteWord(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteWord &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FavoriteWordsCompanion extends UpdateCompanion<FavoriteWord> {
  final Value<String> id;
  final Value<int> wordId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FavoriteWordsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteWordsCompanion.insert({
    required String id,
    required int wordId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wordId = Value(wordId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FavoriteWord> custom({
    Expression<String>? id,
    Expression<int>? wordId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteWordsCompanion copyWith({
    Value<String>? id,
    Value<int>? wordId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FavoriteWordsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $FavoriteWordsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $FavoriteWordsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteWordsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteSentencesTable extends FavoriteSentences
    with TableInfo<$FavoriteSentencesTable, FavoriteSentence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteSentencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<int> sentenceId = GeneratedColumn<int>(
    'sentence_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($FavoriteSentencesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($FavoriteSentencesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sentenceId,
    wordId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_sentences';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteSentence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteSentence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteSentence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentence_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      createdAt: $FavoriteSentencesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $FavoriteSentencesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $FavoriteSentencesTable createAlias(String alias) {
    return $FavoriteSentencesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeMillisecondsConverter();
}

class FavoriteSentence extends DataClass
    implements Insertable<FavoriteSentence> {
  final String id;
  final int sentenceId;
  final int wordId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FavoriteSentence({
    required this.id,
    required this.sentenceId,
    required this.wordId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sentence_id'] = Variable<int>(sentenceId);
    map['word_id'] = Variable<int>(wordId);
    {
      map['created_at'] = Variable<int>(
        $FavoriteSentencesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $FavoriteSentencesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  FavoriteSentencesCompanion toCompanion(bool nullToAbsent) {
    return FavoriteSentencesCompanion(
      id: Value(id),
      sentenceId: Value(sentenceId),
      wordId: Value(wordId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FavoriteSentence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteSentence(
      id: serializer.fromJson<String>(json['id']),
      sentenceId: serializer.fromJson<int>(json['sentenceId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sentenceId': serializer.toJson<int>(sentenceId),
      'wordId': serializer.toJson<int>(wordId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FavoriteSentence copyWith({
    String? id,
    int? sentenceId,
    int? wordId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FavoriteSentence(
    id: id ?? this.id,
    sentenceId: sentenceId ?? this.sentenceId,
    wordId: wordId ?? this.wordId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FavoriteSentence copyWithCompanion(FavoriteSentencesCompanion data) {
    return FavoriteSentence(
      id: data.id.present ? data.id.value : this.id,
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteSentence(')
          ..write('id: $id, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sentenceId, wordId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteSentence &&
          other.id == this.id &&
          other.sentenceId == this.sentenceId &&
          other.wordId == this.wordId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FavoriteSentencesCompanion extends UpdateCompanion<FavoriteSentence> {
  final Value<String> id;
  final Value<int> sentenceId;
  final Value<int> wordId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FavoriteSentencesCompanion({
    this.id = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteSentencesCompanion.insert({
    required String id,
    required int sentenceId,
    required int wordId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sentenceId = Value(sentenceId),
       wordId = Value(wordId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FavoriteSentence> custom({
    Expression<String>? id,
    Expression<int>? sentenceId,
    Expression<int>? wordId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (wordId != null) 'word_id': wordId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteSentencesCompanion copyWith({
    Value<String>? id,
    Value<int>? sentenceId,
    Value<int>? wordId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FavoriteSentencesCompanion(
      id: id ?? this.id,
      sentenceId: sentenceId ?? this.sentenceId,
      wordId: wordId ?? this.wordId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sentenceId.present) {
      map['sentence_id'] = Variable<int>(sentenceId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $FavoriteSentencesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $FavoriteSentencesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteSentencesCompanion(')
          ..write('id: $id, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeSessionsTable extends PracticeSessions
    with TableInfo<$PracticeSessionsTable, PracticeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 2),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PracticeSessionsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> finishedAt =
      GeneratedColumn<int>(
        'finished_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PracticeSessionsTable.$converterfinishedAtn);
  static const VerificationMeta _totalQuestionCountMeta =
      const VerificationMeta('totalQuestionCount');
  @override
  late final GeneratedColumn<int> totalQuestionCount = GeneratedColumn<int>(
    'total_question_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('total_question_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('correct_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elapsedMillisecondsMeta =
      const VerificationMeta('elapsedMilliseconds');
  @override
  late final GeneratedColumn<int> elapsedMilliseconds = GeneratedColumn<int>(
    'elapsed_milliseconds',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('elapsed_milliseconds >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    configJson,
    startedAt,
    finishedAt,
    totalQuestionCount,
    correctCount,
    elapsedMilliseconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('total_question_count')) {
      context.handle(
        _totalQuestionCountMeta,
        totalQuestionCount.isAcceptableOrUnknown(
          data['total_question_count']!,
          _totalQuestionCountMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('elapsed_milliseconds')) {
      context.handle(
        _elapsedMillisecondsMeta,
        elapsedMilliseconds.isAcceptableOrUnknown(
          data['elapsed_milliseconds']!,
          _elapsedMillisecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      startedAt: $PracticeSessionsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      finishedAt: $PracticeSessionsTable.$converterfinishedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}finished_at'],
        ),
      ),
      totalQuestionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_question_count'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      elapsedMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_milliseconds'],
      )!,
    );
  }

  @override
  $PracticeSessionsTable createAlias(String alias) {
    return $PracticeSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartedAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime, int> $converterfinishedAt =
      const UtcDateTimeMillisecondsConverter();
  static TypeConverter<DateTime?, int?> $converterfinishedAtn =
      NullAwareTypeConverter.wrap($converterfinishedAt);
}

class PracticeSession extends DataClass implements Insertable<PracticeSession> {
  final String id;
  final String type;
  final String configJson;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int totalQuestionCount;
  final int correctCount;
  final int elapsedMilliseconds;
  const PracticeSession({
    required this.id,
    required this.type,
    required this.configJson,
    required this.startedAt,
    this.finishedAt,
    required this.totalQuestionCount,
    required this.correctCount,
    required this.elapsedMilliseconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['config_json'] = Variable<String>(configJson);
    {
      map['started_at'] = Variable<int>(
        $PracticeSessionsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(
        $PracticeSessionsTable.$converterfinishedAtn.toSql(finishedAt),
      );
    }
    map['total_question_count'] = Variable<int>(totalQuestionCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['elapsed_milliseconds'] = Variable<int>(elapsedMilliseconds);
    return map;
  }

  PracticeSessionsCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionsCompanion(
      id: Value(id),
      type: Value(type),
      configJson: Value(configJson),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      totalQuestionCount: Value(totalQuestionCount),
      correctCount: Value(correctCount),
      elapsedMilliseconds: Value(elapsedMilliseconds),
    );
  }

  factory PracticeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSession(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      configJson: serializer.fromJson<String>(json['configJson']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      totalQuestionCount: serializer.fromJson<int>(json['totalQuestionCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      elapsedMilliseconds: serializer.fromJson<int>(
        json['elapsedMilliseconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'configJson': serializer.toJson<String>(configJson),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'totalQuestionCount': serializer.toJson<int>(totalQuestionCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'elapsedMilliseconds': serializer.toJson<int>(elapsedMilliseconds),
    };
  }

  PracticeSession copyWith({
    String? id,
    String? type,
    String? configJson,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    int? totalQuestionCount,
    int? correctCount,
    int? elapsedMilliseconds,
  }) => PracticeSession(
    id: id ?? this.id,
    type: type ?? this.type,
    configJson: configJson ?? this.configJson,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    totalQuestionCount: totalQuestionCount ?? this.totalQuestionCount,
    correctCount: correctCount ?? this.correctCount,
    elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
  );
  PracticeSession copyWithCompanion(PracticeSessionsCompanion data) {
    return PracticeSession(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      totalQuestionCount: data.totalQuestionCount.present
          ? data.totalQuestionCount.value
          : this.totalQuestionCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      elapsedMilliseconds: data.elapsedMilliseconds.present
          ? data.elapsedMilliseconds.value
          : this.elapsedMilliseconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSession(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('configJson: $configJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('totalQuestionCount: $totalQuestionCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('elapsedMilliseconds: $elapsedMilliseconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    configJson,
    startedAt,
    finishedAt,
    totalQuestionCount,
    correctCount,
    elapsedMilliseconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSession &&
          other.id == this.id &&
          other.type == this.type &&
          other.configJson == this.configJson &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.totalQuestionCount == this.totalQuestionCount &&
          other.correctCount == this.correctCount &&
          other.elapsedMilliseconds == this.elapsedMilliseconds);
}

class PracticeSessionsCompanion extends UpdateCompanion<PracticeSession> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> configJson;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> totalQuestionCount;
  final Value<int> correctCount;
  final Value<int> elapsedMilliseconds;
  final Value<int> rowid;
  const PracticeSessionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.configJson = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.totalQuestionCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.elapsedMilliseconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeSessionsCompanion.insert({
    required String id,
    required String type,
    required String configJson,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.totalQuestionCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.elapsedMilliseconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       configJson = Value(configJson),
       startedAt = Value(startedAt);
  static Insertable<PracticeSession> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? configJson,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<int>? totalQuestionCount,
    Expression<int>? correctCount,
    Expression<int>? elapsedMilliseconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (configJson != null) 'config_json': configJson,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (totalQuestionCount != null)
        'total_question_count': totalQuestionCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (elapsedMilliseconds != null)
        'elapsed_milliseconds': elapsedMilliseconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? configJson,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? totalQuestionCount,
    Value<int>? correctCount,
    Value<int>? elapsedMilliseconds,
    Value<int>? rowid,
  }) {
    return PracticeSessionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      configJson: configJson ?? this.configJson,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      totalQuestionCount: totalQuestionCount ?? this.totalQuestionCount,
      correctCount: correctCount ?? this.correctCount,
      elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $PracticeSessionsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(
        $PracticeSessionsTable.$converterfinishedAtn.toSql(finishedAt.value),
      );
    }
    if (totalQuestionCount.present) {
      map['total_question_count'] = Variable<int>(totalQuestionCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (elapsedMilliseconds.present) {
      map['elapsed_milliseconds'] = Variable<int>(elapsedMilliseconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('configJson: $configJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('totalQuestionCount: $totalQuestionCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('elapsedMilliseconds: $elapsedMilliseconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeAnswersTable extends PracticeAnswers
    with TableInfo<$PracticeAnswersTable, PracticeAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<int> sentenceId = GeneratedColumn<int>(
    'sentence_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userAnswerMeta = const VerificationMeta(
    'userAnswer',
  );
  @override
  late final GeneratedColumn<String> userAnswer = GeneratedColumn<String>(
    'user_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _responseTimeMillisecondsMeta =
      const VerificationMeta('responseTimeMilliseconds');
  @override
  late final GeneratedColumn<int> responseTimeMilliseconds =
      GeneratedColumn<int>(
        'response_time_milliseconds',
        aliasedName,
        false,
        check: () =>
            const CustomExpression<bool>('response_time_milliseconds >= 0'),
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> answeredAt =
      GeneratedColumn<int>(
        'answered_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PracticeAnswersTable.$converteransweredAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    wordId,
    sentenceId,
    userAnswer,
    isCorrect,
    responseTimeMilliseconds,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    }
    if (data.containsKey('user_answer')) {
      context.handle(
        _userAnswerMeta,
        userAnswer.isAcceptableOrUnknown(data['user_answer']!, _userAnswerMeta),
      );
    } else if (isInserting) {
      context.missing(_userAnswerMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('response_time_milliseconds')) {
      context.handle(
        _responseTimeMillisecondsMeta,
        responseTimeMilliseconds.isAcceptableOrUnknown(
          data['response_time_milliseconds']!,
          _responseTimeMillisecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseTimeMillisecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeAnswer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentence_id'],
      ),
      userAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_answer'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      responseTimeMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_time_milliseconds'],
      )!,
      answeredAt: $PracticeAnswersTable.$converteransweredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}answered_at'],
        )!,
      ),
    );
  }

  @override
  $PracticeAnswersTable createAlias(String alias) {
    return $PracticeAnswersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteransweredAt =
      const UtcDateTimeMillisecondsConverter();
}

class PracticeAnswer extends DataClass implements Insertable<PracticeAnswer> {
  final String id;
  final String sessionId;
  final int wordId;
  final int? sentenceId;
  final String userAnswer;
  final bool isCorrect;
  final int responseTimeMilliseconds;
  final DateTime answeredAt;
  const PracticeAnswer({
    required this.id,
    required this.sessionId,
    required this.wordId,
    this.sentenceId,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTimeMilliseconds,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['word_id'] = Variable<int>(wordId);
    if (!nullToAbsent || sentenceId != null) {
      map['sentence_id'] = Variable<int>(sentenceId);
    }
    map['user_answer'] = Variable<String>(userAnswer);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['response_time_milliseconds'] = Variable<int>(responseTimeMilliseconds);
    {
      map['answered_at'] = Variable<int>(
        $PracticeAnswersTable.$converteransweredAt.toSql(answeredAt),
      );
    }
    return map;
  }

  PracticeAnswersCompanion toCompanion(bool nullToAbsent) {
    return PracticeAnswersCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      wordId: Value(wordId),
      sentenceId: sentenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sentenceId),
      userAnswer: Value(userAnswer),
      isCorrect: Value(isCorrect),
      responseTimeMilliseconds: Value(responseTimeMilliseconds),
      answeredAt: Value(answeredAt),
    );
  }

  factory PracticeAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeAnswer(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      sentenceId: serializer.fromJson<int?>(json['sentenceId']),
      userAnswer: serializer.fromJson<String>(json['userAnswer']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      responseTimeMilliseconds: serializer.fromJson<int>(
        json['responseTimeMilliseconds'],
      ),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'wordId': serializer.toJson<int>(wordId),
      'sentenceId': serializer.toJson<int?>(sentenceId),
      'userAnswer': serializer.toJson<String>(userAnswer),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'responseTimeMilliseconds': serializer.toJson<int>(
        responseTimeMilliseconds,
      ),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  PracticeAnswer copyWith({
    String? id,
    String? sessionId,
    int? wordId,
    Value<int?> sentenceId = const Value.absent(),
    String? userAnswer,
    bool? isCorrect,
    int? responseTimeMilliseconds,
    DateTime? answeredAt,
  }) => PracticeAnswer(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    wordId: wordId ?? this.wordId,
    sentenceId: sentenceId.present ? sentenceId.value : this.sentenceId,
    userAnswer: userAnswer ?? this.userAnswer,
    isCorrect: isCorrect ?? this.isCorrect,
    responseTimeMilliseconds:
        responseTimeMilliseconds ?? this.responseTimeMilliseconds,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  PracticeAnswer copyWithCompanion(PracticeAnswersCompanion data) {
    return PracticeAnswer(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      userAnswer: data.userAnswer.present
          ? data.userAnswer.value
          : this.userAnswer,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      responseTimeMilliseconds: data.responseTimeMilliseconds.present
          ? data.responseTimeMilliseconds.value
          : this.responseTimeMilliseconds,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeAnswer(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('wordId: $wordId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('responseTimeMilliseconds: $responseTimeMilliseconds, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    wordId,
    sentenceId,
    userAnswer,
    isCorrect,
    responseTimeMilliseconds,
    answeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeAnswer &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.wordId == this.wordId &&
          other.sentenceId == this.sentenceId &&
          other.userAnswer == this.userAnswer &&
          other.isCorrect == this.isCorrect &&
          other.responseTimeMilliseconds == this.responseTimeMilliseconds &&
          other.answeredAt == this.answeredAt);
}

class PracticeAnswersCompanion extends UpdateCompanion<PracticeAnswer> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> wordId;
  final Value<int?> sentenceId;
  final Value<String> userAnswer;
  final Value<bool> isCorrect;
  final Value<int> responseTimeMilliseconds;
  final Value<DateTime> answeredAt;
  final Value<int> rowid;
  const PracticeAnswersCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.responseTimeMilliseconds = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeAnswersCompanion.insert({
    required String id,
    required String sessionId,
    required int wordId,
    this.sentenceId = const Value.absent(),
    required String userAnswer,
    required bool isCorrect,
    required int responseTimeMilliseconds,
    required DateTime answeredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       wordId = Value(wordId),
       userAnswer = Value(userAnswer),
       isCorrect = Value(isCorrect),
       responseTimeMilliseconds = Value(responseTimeMilliseconds),
       answeredAt = Value(answeredAt);
  static Insertable<PracticeAnswer> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? wordId,
    Expression<int>? sentenceId,
    Expression<String>? userAnswer,
    Expression<bool>? isCorrect,
    Expression<int>? responseTimeMilliseconds,
    Expression<int>? answeredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (wordId != null) 'word_id': wordId,
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (userAnswer != null) 'user_answer': userAnswer,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (responseTimeMilliseconds != null)
        'response_time_milliseconds': responseTimeMilliseconds,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeAnswersCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? wordId,
    Value<int?>? sentenceId,
    Value<String>? userAnswer,
    Value<bool>? isCorrect,
    Value<int>? responseTimeMilliseconds,
    Value<DateTime>? answeredAt,
    Value<int>? rowid,
  }) {
    return PracticeAnswersCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      wordId: wordId ?? this.wordId,
      sentenceId: sentenceId ?? this.sentenceId,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      responseTimeMilliseconds:
          responseTimeMilliseconds ?? this.responseTimeMilliseconds,
      answeredAt: answeredAt ?? this.answeredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (sentenceId.present) {
      map['sentence_id'] = Variable<int>(sentenceId.value);
    }
    if (userAnswer.present) {
      map['user_answer'] = Variable<String>(userAnswer.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (responseTimeMilliseconds.present) {
      map['response_time_milliseconds'] = Variable<int>(
        responseTimeMilliseconds.value,
      );
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<int>(
        $PracticeAnswersTable.$converteransweredAt.toSql(answeredAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeAnswersCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('wordId: $wordId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('responseTimeMilliseconds: $responseTimeMilliseconds, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningEventsTable extends LearningEvents
    with TableInfo<$LearningEventsTable, LearningEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reviewRatingMeta = const VerificationMeta(
    'reviewRating',
  );
  @override
  late final GeneratedColumn<String> reviewRating = GeneratedColumn<String>(
    'review_rating',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> occurredAt =
      GeneratedColumn<int>(
        'occurred_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LearningEventsTable.$converteroccurredAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    wordId,
    sessionId,
    isCorrect,
    reviewRating,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    }
    if (data.containsKey('review_rating')) {
      context.handle(
        _reviewRatingMeta,
        reviewRating.isAcceptableOrUnknown(
          data['review_rating']!,
          _reviewRatingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      ),
      reviewRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_rating'],
      ),
      occurredAt: $LearningEventsTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}occurred_at'],
        )!,
      ),
    );
  }

  @override
  $LearningEventsTable createAlias(String alias) {
    return $LearningEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteroccurredAt =
      const UtcDateTimeMillisecondsConverter();
}

class LearningEvent extends DataClass implements Insertable<LearningEvent> {
  final String id;
  final String eventType;
  final int wordId;
  final String? sessionId;
  final bool? isCorrect;
  final String? reviewRating;
  final DateTime occurredAt;
  const LearningEvent({
    required this.id,
    required this.eventType,
    required this.wordId,
    this.sessionId,
    this.isCorrect,
    this.reviewRating,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['word_id'] = Variable<int>(wordId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || isCorrect != null) {
      map['is_correct'] = Variable<bool>(isCorrect);
    }
    if (!nullToAbsent || reviewRating != null) {
      map['review_rating'] = Variable<String>(reviewRating);
    }
    {
      map['occurred_at'] = Variable<int>(
        $LearningEventsTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    return map;
  }

  LearningEventsCompanion toCompanion(bool nullToAbsent) {
    return LearningEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      wordId: Value(wordId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      isCorrect: isCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrect),
      reviewRating: reviewRating == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewRating),
      occurredAt: Value(occurredAt),
    );
  }

  factory LearningEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningEvent(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      wordId: serializer.fromJson<int>(json['wordId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      isCorrect: serializer.fromJson<bool?>(json['isCorrect']),
      reviewRating: serializer.fromJson<String?>(json['reviewRating']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'wordId': serializer.toJson<int>(wordId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'isCorrect': serializer.toJson<bool?>(isCorrect),
      'reviewRating': serializer.toJson<String?>(reviewRating),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  LearningEvent copyWith({
    String? id,
    String? eventType,
    int? wordId,
    Value<String?> sessionId = const Value.absent(),
    Value<bool?> isCorrect = const Value.absent(),
    Value<String?> reviewRating = const Value.absent(),
    DateTime? occurredAt,
  }) => LearningEvent(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    wordId: wordId ?? this.wordId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    isCorrect: isCorrect.present ? isCorrect.value : this.isCorrect,
    reviewRating: reviewRating.present ? reviewRating.value : this.reviewRating,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  LearningEvent copyWithCompanion(LearningEventsCompanion data) {
    return LearningEvent(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      reviewRating: data.reviewRating.present
          ? data.reviewRating.value
          : this.reviewRating,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningEvent(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('wordId: $wordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('reviewRating: $reviewRating, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventType,
    wordId,
    sessionId,
    isCorrect,
    reviewRating,
    occurredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningEvent &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.wordId == this.wordId &&
          other.sessionId == this.sessionId &&
          other.isCorrect == this.isCorrect &&
          other.reviewRating == this.reviewRating &&
          other.occurredAt == this.occurredAt);
}

class LearningEventsCompanion extends UpdateCompanion<LearningEvent> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<int> wordId;
  final Value<String?> sessionId;
  final Value<bool?> isCorrect;
  final Value<String?> reviewRating;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const LearningEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.wordId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.reviewRating = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningEventsCompanion.insert({
    required String id,
    required String eventType,
    required int wordId,
    this.sessionId = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.reviewRating = const Value.absent(),
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       wordId = Value(wordId),
       occurredAt = Value(occurredAt);
  static Insertable<LearningEvent> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<int>? wordId,
    Expression<String>? sessionId,
    Expression<bool>? isCorrect,
    Expression<String>? reviewRating,
    Expression<int>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (wordId != null) 'word_id': wordId,
      if (sessionId != null) 'session_id': sessionId,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (reviewRating != null) 'review_rating': reviewRating,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventType,
    Value<int>? wordId,
    Value<String?>? sessionId,
    Value<bool?>? isCorrect,
    Value<String?>? reviewRating,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return LearningEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      wordId: wordId ?? this.wordId,
      sessionId: sessionId ?? this.sessionId,
      isCorrect: isCorrect ?? this.isCorrect,
      reviewRating: reviewRating ?? this.reviewRating,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (reviewRating.present) {
      map['review_rating'] = Variable<String>(reviewRating.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(
        $LearningEventsTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('wordId: $wordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('reviewRating: $reviewRating, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('id = 1'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dailyGoalMeta = const VerificationMeta(
    'dailyGoal',
  );
  @override
  late final GeneratedColumn<int> dailyGoal = GeneratedColumn<int>(
    'daily_goal',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('daily_goal > 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pronunciationAccentMeta =
      const VerificationMeta('pronunciationAccent');
  @override
  late final GeneratedColumn<String> pronunciationAccent =
      GeneratedColumn<String>(
        'pronunciation_accent',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 2,
          maxTextLength: 2,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _autoPlayPronunciationMeta =
      const VerificationMeta('autoPlayPronunciation');
  @override
  late final GeneratedColumn<bool> autoPlayPronunciation =
      GeneratedColumn<bool>(
        'auto_play_pronunciation',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_play_pronunciation" IN (0, 1))',
        ),
      );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 6,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accentColorMeta = const VerificationMeta(
    'accentColor',
  );
  @override
  late final GeneratedColumn<String> accentColor = GeneratedColumn<String>(
    'accent_color',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('indigo'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AppSettingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyGoal,
    pronunciationAccent,
    autoPlayPronunciation,
    themeMode,
    accentColor,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('daily_goal')) {
      context.handle(
        _dailyGoalMeta,
        dailyGoal.isAcceptableOrUnknown(data['daily_goal']!, _dailyGoalMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyGoalMeta);
    }
    if (data.containsKey('pronunciation_accent')) {
      context.handle(
        _pronunciationAccentMeta,
        pronunciationAccent.isAcceptableOrUnknown(
          data['pronunciation_accent']!,
          _pronunciationAccentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pronunciationAccentMeta);
    }
    if (data.containsKey('auto_play_pronunciation')) {
      context.handle(
        _autoPlayPronunciationMeta,
        autoPlayPronunciation.isAcceptableOrUnknown(
          data['auto_play_pronunciation']!,
          _autoPlayPronunciationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoPlayPronunciationMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('accent_color')) {
      context.handle(
        _accentColorMeta,
        accentColor.isAcceptableOrUnknown(
          data['accent_color']!,
          _accentColorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dailyGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_goal'],
      )!,
      pronunciationAccent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronunciation_accent'],
      )!,
      autoPlayPronunciation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_play_pronunciation'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      accentColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_color'],
      )!,
      updatedAt: $AppSettingsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeMillisecondsConverter();
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final int dailyGoal;
  final String pronunciationAccent;
  final bool autoPlayPronunciation;
  final String themeMode;
  final String accentColor;
  final DateTime updatedAt;
  const AppSetting({
    required this.id,
    required this.dailyGoal,
    required this.pronunciationAccent,
    required this.autoPlayPronunciation,
    required this.themeMode,
    required this.accentColor,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['daily_goal'] = Variable<int>(dailyGoal);
    map['pronunciation_accent'] = Variable<String>(pronunciationAccent);
    map['auto_play_pronunciation'] = Variable<bool>(autoPlayPronunciation);
    map['theme_mode'] = Variable<String>(themeMode);
    map['accent_color'] = Variable<String>(accentColor);
    {
      map['updated_at'] = Variable<int>(
        $AppSettingsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      dailyGoal: Value(dailyGoal),
      pronunciationAccent: Value(pronunciationAccent),
      autoPlayPronunciation: Value(autoPlayPronunciation),
      themeMode: Value(themeMode),
      accentColor: Value(accentColor),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      dailyGoal: serializer.fromJson<int>(json['dailyGoal']),
      pronunciationAccent: serializer.fromJson<String>(
        json['pronunciationAccent'],
      ),
      autoPlayPronunciation: serializer.fromJson<bool>(
        json['autoPlayPronunciation'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      accentColor: serializer.fromJson<String>(json['accentColor']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dailyGoal': serializer.toJson<int>(dailyGoal),
      'pronunciationAccent': serializer.toJson<String>(pronunciationAccent),
      'autoPlayPronunciation': serializer.toJson<bool>(autoPlayPronunciation),
      'themeMode': serializer.toJson<String>(themeMode),
      'accentColor': serializer.toJson<String>(accentColor),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({
    int? id,
    int? dailyGoal,
    String? pronunciationAccent,
    bool? autoPlayPronunciation,
    String? themeMode,
    String? accentColor,
    DateTime? updatedAt,
  }) => AppSetting(
    id: id ?? this.id,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    pronunciationAccent: pronunciationAccent ?? this.pronunciationAccent,
    autoPlayPronunciation: autoPlayPronunciation ?? this.autoPlayPronunciation,
    themeMode: themeMode ?? this.themeMode,
    accentColor: accentColor ?? this.accentColor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      dailyGoal: data.dailyGoal.present ? data.dailyGoal.value : this.dailyGoal,
      pronunciationAccent: data.pronunciationAccent.present
          ? data.pronunciationAccent.value
          : this.pronunciationAccent,
      autoPlayPronunciation: data.autoPlayPronunciation.present
          ? data.autoPlayPronunciation.value
          : this.autoPlayPronunciation,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      accentColor: data.accentColor.present
          ? data.accentColor.value
          : this.accentColor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('pronunciationAccent: $pronunciationAccent, ')
          ..write('autoPlayPronunciation: $autoPlayPronunciation, ')
          ..write('themeMode: $themeMode, ')
          ..write('accentColor: $accentColor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyGoal,
    pronunciationAccent,
    autoPlayPronunciation,
    themeMode,
    accentColor,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.dailyGoal == this.dailyGoal &&
          other.pronunciationAccent == this.pronunciationAccent &&
          other.autoPlayPronunciation == this.autoPlayPronunciation &&
          other.themeMode == this.themeMode &&
          other.accentColor == this.accentColor &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<int> dailyGoal;
  final Value<String> pronunciationAccent;
  final Value<bool> autoPlayPronunciation;
  final Value<String> themeMode;
  final Value<String> accentColor;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.dailyGoal = const Value.absent(),
    this.pronunciationAccent = const Value.absent(),
    this.autoPlayPronunciation = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required int dailyGoal,
    required String pronunciationAccent,
    required bool autoPlayPronunciation,
    required String themeMode,
    this.accentColor = const Value.absent(),
    required DateTime updatedAt,
  }) : dailyGoal = Value(dailyGoal),
       pronunciationAccent = Value(pronunciationAccent),
       autoPlayPronunciation = Value(autoPlayPronunciation),
       themeMode = Value(themeMode),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<int>? dailyGoal,
    Expression<String>? pronunciationAccent,
    Expression<bool>? autoPlayPronunciation,
    Expression<String>? themeMode,
    Expression<String>? accentColor,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyGoal != null) 'daily_goal': dailyGoal,
      if (pronunciationAccent != null)
        'pronunciation_accent': pronunciationAccent,
      if (autoPlayPronunciation != null)
        'auto_play_pronunciation': autoPlayPronunciation,
      if (themeMode != null) 'theme_mode': themeMode,
      if (accentColor != null) 'accent_color': accentColor,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? dailyGoal,
    Value<String>? pronunciationAccent,
    Value<bool>? autoPlayPronunciation,
    Value<String>? themeMode,
    Value<String>? accentColor,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      pronunciationAccent: pronunciationAccent ?? this.pronunciationAccent,
      autoPlayPronunciation:
          autoPlayPronunciation ?? this.autoPlayPronunciation,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dailyGoal.present) {
      map['daily_goal'] = Variable<int>(dailyGoal.value);
    }
    if (pronunciationAccent.present) {
      map['pronunciation_accent'] = Variable<String>(pronunciationAccent.value);
    }
    if (autoPlayPronunciation.present) {
      map['auto_play_pronunciation'] = Variable<bool>(
        autoPlayPronunciation.value,
      );
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (accentColor.present) {
      map['accent_color'] = Variable<String>(accentColor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AppSettingsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('pronunciationAccent: $pronunciationAccent, ')
          ..write('autoPlayPronunciation: $autoPlayPronunciation, ')
          ..write('themeMode: $themeMode, ')
          ..write('accentColor: $accentColor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BackupHistoryTable extends BackupHistory
    with TableInfo<$BackupHistoryTable, BackupHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 2),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> occurredAt =
      GeneratedColumn<int>(
        'occurred_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BackupHistoryTable.$converteroccurredAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    fileName,
    summaryJson,
    result,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summaryJsonMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      occurredAt: $BackupHistoryTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}occurred_at'],
        )!,
      ),
    );
  }

  @override
  $BackupHistoryTable createAlias(String alias) {
    return $BackupHistoryTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteroccurredAt =
      const UtcDateTimeMillisecondsConverter();
}

class BackupHistoryData extends DataClass
    implements Insertable<BackupHistoryData> {
  final String id;
  final String type;
  final String fileName;
  final String summaryJson;
  final String result;
  final DateTime occurredAt;
  const BackupHistoryData({
    required this.id,
    required this.type,
    required this.fileName,
    required this.summaryJson,
    required this.result,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['file_name'] = Variable<String>(fileName);
    map['summary_json'] = Variable<String>(summaryJson);
    map['result'] = Variable<String>(result);
    {
      map['occurred_at'] = Variable<int>(
        $BackupHistoryTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    return map;
  }

  BackupHistoryCompanion toCompanion(bool nullToAbsent) {
    return BackupHistoryCompanion(
      id: Value(id),
      type: Value(type),
      fileName: Value(fileName),
      summaryJson: Value(summaryJson),
      result: Value(result),
      occurredAt: Value(occurredAt),
    );
  }

  factory BackupHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupHistoryData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      fileName: serializer.fromJson<String>(json['fileName']),
      summaryJson: serializer.fromJson<String>(json['summaryJson']),
      result: serializer.fromJson<String>(json['result']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'fileName': serializer.toJson<String>(fileName),
      'summaryJson': serializer.toJson<String>(summaryJson),
      'result': serializer.toJson<String>(result),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  BackupHistoryData copyWith({
    String? id,
    String? type,
    String? fileName,
    String? summaryJson,
    String? result,
    DateTime? occurredAt,
  }) => BackupHistoryData(
    id: id ?? this.id,
    type: type ?? this.type,
    fileName: fileName ?? this.fileName,
    summaryJson: summaryJson ?? this.summaryJson,
    result: result ?? this.result,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  BackupHistoryData copyWithCompanion(BackupHistoryCompanion data) {
    return BackupHistoryData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      result: data.result.present ? data.result.value : this.result,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupHistoryData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('fileName: $fileName, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('result: $result, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, fileName, summaryJson, result, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupHistoryData &&
          other.id == this.id &&
          other.type == this.type &&
          other.fileName == this.fileName &&
          other.summaryJson == this.summaryJson &&
          other.result == this.result &&
          other.occurredAt == this.occurredAt);
}

class BackupHistoryCompanion extends UpdateCompanion<BackupHistoryData> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> fileName;
  final Value<String> summaryJson;
  final Value<String> result;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const BackupHistoryCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.fileName = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.result = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupHistoryCompanion.insert({
    required String id,
    required String type,
    required String fileName,
    required String summaryJson,
    required String result,
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       fileName = Value(fileName),
       summaryJson = Value(summaryJson),
       result = Value(result),
       occurredAt = Value(occurredAt);
  static Insertable<BackupHistoryData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? fileName,
    Expression<String>? summaryJson,
    Expression<String>? result,
    Expression<int>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (fileName != null) 'file_name': fileName,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (result != null) 'result': result,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? fileName,
    Value<String>? summaryJson,
    Value<String>? result,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return BackupHistoryCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      summaryJson: summaryJson ?? this.summaryJson,
      result: result ?? this.result,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(
        $BackupHistoryTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupHistoryCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('fileName: $fileName, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('result: $result, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $UserWordStatesTable userWordStates = $UserWordStatesTable(this);
  late final $FavoriteWordsTable favoriteWords = $FavoriteWordsTable(this);
  late final $FavoriteSentencesTable favoriteSentences =
      $FavoriteSentencesTable(this);
  late final $PracticeSessionsTable practiceSessions = $PracticeSessionsTable(
    this,
  );
  late final $PracticeAnswersTable practiceAnswers = $PracticeAnswersTable(
    this,
  );
  late final $LearningEventsTable learningEvents = $LearningEventsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BackupHistoryTable backupHistory = $BackupHistoryTable(this);
  late final Index userWordStatesNextReviewAt = Index(
    'user_word_states_next_review_at',
    'CREATE INDEX user_word_states_next_review_at ON user_word_states (next_review_at)',
  );
  late final Index favoriteWordsWordId = Index(
    'favorite_words_word_id',
    'CREATE UNIQUE INDEX favorite_words_word_id ON favorite_words (word_id)',
  );
  late final Index favoriteSentencesSentenceId = Index(
    'favorite_sentences_sentence_id',
    'CREATE UNIQUE INDEX favorite_sentences_sentence_id ON favorite_sentences (sentence_id)',
  );
  late final Index practiceAnswersSessionId = Index(
    'practice_answers_session_id',
    'CREATE INDEX practice_answers_session_id ON practice_answers (session_id)',
  );
  late final Index learningEventsOccurredAt = Index(
    'learning_events_occurred_at',
    'CREATE INDEX learning_events_occurred_at ON learning_events (occurred_at)',
  );
  late final UserDataDao userDataDao = UserDataDao(this as UserDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userWordStates,
    favoriteWords,
    favoriteSentences,
    practiceSessions,
    practiceAnswers,
    learningEvents,
    appSettings,
    backupHistory,
    userWordStatesNextReviewAt,
    favoriteWordsWordId,
    favoriteSentencesSentenceId,
    practiceAnswersSessionId,
    learningEventsOccurredAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_answers', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UserWordStatesTableCreateCompanionBuilder =
    UserWordStatesCompanion Function({
      Value<int> wordId,
      Value<int> masteryLevel,
      Value<int> studiedCount,
      Value<int> correctCount,
      Value<int> wrongCount,
      Value<int> correctStreak,
      Value<int> consecutiveForgottenCount,
      Value<DateTime?> lastStudiedAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> nextReviewAt,
      required DateTime updatedAt,
    });
typedef $$UserWordStatesTableUpdateCompanionBuilder =
    UserWordStatesCompanion Function({
      Value<int> wordId,
      Value<int> masteryLevel,
      Value<int> studiedCount,
      Value<int> correctCount,
      Value<int> wrongCount,
      Value<int> correctStreak,
      Value<int> consecutiveForgottenCount,
      Value<DateTime?> lastStudiedAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> nextReviewAt,
      Value<DateTime> updatedAt,
    });

class $$UserWordStatesTableFilterComposer
    extends Composer<_$UserDatabase, $UserWordStatesTable> {
  $$UserWordStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get studiedCount => $composableBuilder(
    column: $table.studiedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveForgottenCount => $composableBuilder(
    column: $table.consecutiveForgottenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastStudiedAt =>
      $composableBuilder(
        column: $table.lastStudiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastReviewedAt =>
      $composableBuilder(
        column: $table.lastReviewedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get nextReviewAt =>
      $composableBuilder(
        column: $table.nextReviewAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserWordStatesTableOrderingComposer
    extends Composer<_$UserDatabase, $UserWordStatesTable> {
  $$UserWordStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get studiedCount => $composableBuilder(
    column: $table.studiedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveForgottenCount => $composableBuilder(
    column: $table.consecutiveForgottenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserWordStatesTableAnnotationComposer
    extends Composer<_$UserDatabase, $UserWordStatesTable> {
  $$UserWordStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get studiedCount => $composableBuilder(
    column: $table.studiedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveForgottenCount => $composableBuilder(
    column: $table.consecutiveForgottenCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastStudiedAt =>
      $composableBuilder(
        column: $table.lastStudiedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastReviewedAt =>
      $composableBuilder(
        column: $table.lastReviewedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get nextReviewAt =>
      $composableBuilder(
        column: $table.nextReviewAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserWordStatesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UserWordStatesTable,
          UserWordState,
          $$UserWordStatesTableFilterComposer,
          $$UserWordStatesTableOrderingComposer,
          $$UserWordStatesTableAnnotationComposer,
          $$UserWordStatesTableCreateCompanionBuilder,
          $$UserWordStatesTableUpdateCompanionBuilder,
          (
            UserWordState,
            BaseReferences<_$UserDatabase, $UserWordStatesTable, UserWordState>,
          ),
          UserWordState,
          PrefetchHooks Function()
        > {
  $$UserWordStatesTableTableManager(
    _$UserDatabase db,
    $UserWordStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<int> masteryLevel = const Value.absent(),
                Value<int> studiedCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                Value<int> consecutiveForgottenCount = const Value.absent(),
                Value<DateTime?> lastStudiedAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserWordStatesCompanion(
                wordId: wordId,
                masteryLevel: masteryLevel,
                studiedCount: studiedCount,
                correctCount: correctCount,
                wrongCount: wrongCount,
                correctStreak: correctStreak,
                consecutiveForgottenCount: consecutiveForgottenCount,
                lastStudiedAt: lastStudiedAt,
                lastReviewedAt: lastReviewedAt,
                nextReviewAt: nextReviewAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<int> masteryLevel = const Value.absent(),
                Value<int> studiedCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                Value<int> consecutiveForgottenCount = const Value.absent(),
                Value<DateTime?> lastStudiedAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                required DateTime updatedAt,
              }) => UserWordStatesCompanion.insert(
                wordId: wordId,
                masteryLevel: masteryLevel,
                studiedCount: studiedCount,
                correctCount: correctCount,
                wrongCount: wrongCount,
                correctStreak: correctStreak,
                consecutiveForgottenCount: consecutiveForgottenCount,
                lastStudiedAt: lastStudiedAt,
                lastReviewedAt: lastReviewedAt,
                nextReviewAt: nextReviewAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserWordStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UserWordStatesTable,
      UserWordState,
      $$UserWordStatesTableFilterComposer,
      $$UserWordStatesTableOrderingComposer,
      $$UserWordStatesTableAnnotationComposer,
      $$UserWordStatesTableCreateCompanionBuilder,
      $$UserWordStatesTableUpdateCompanionBuilder,
      (
        UserWordState,
        BaseReferences<_$UserDatabase, $UserWordStatesTable, UserWordState>,
      ),
      UserWordState,
      PrefetchHooks Function()
    >;
typedef $$FavoriteWordsTableCreateCompanionBuilder =
    FavoriteWordsCompanion Function({
      required String id,
      required int wordId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FavoriteWordsTableUpdateCompanionBuilder =
    FavoriteWordsCompanion Function({
      Value<String> id,
      Value<int> wordId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FavoriteWordsTableFilterComposer
    extends Composer<_$UserDatabase, $FavoriteWordsTable> {
  $$FavoriteWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$FavoriteWordsTableOrderingComposer
    extends Composer<_$UserDatabase, $FavoriteWordsTable> {
  $$FavoriteWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteWordsTableAnnotationComposer
    extends Composer<_$UserDatabase, $FavoriteWordsTable> {
  $$FavoriteWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FavoriteWordsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $FavoriteWordsTable,
          FavoriteWord,
          $$FavoriteWordsTableFilterComposer,
          $$FavoriteWordsTableOrderingComposer,
          $$FavoriteWordsTableAnnotationComposer,
          $$FavoriteWordsTableCreateCompanionBuilder,
          $$FavoriteWordsTableUpdateCompanionBuilder,
          (
            FavoriteWord,
            BaseReferences<_$UserDatabase, $FavoriteWordsTable, FavoriteWord>,
          ),
          FavoriteWord,
          PrefetchHooks Function()
        > {
  $$FavoriteWordsTableTableManager(_$UserDatabase db, $FavoriteWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteWordsCompanion(
                id: id,
                wordId: wordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int wordId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoriteWordsCompanion.insert(
                id: id,
                wordId: wordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $FavoriteWordsTable,
      FavoriteWord,
      $$FavoriteWordsTableFilterComposer,
      $$FavoriteWordsTableOrderingComposer,
      $$FavoriteWordsTableAnnotationComposer,
      $$FavoriteWordsTableCreateCompanionBuilder,
      $$FavoriteWordsTableUpdateCompanionBuilder,
      (
        FavoriteWord,
        BaseReferences<_$UserDatabase, $FavoriteWordsTable, FavoriteWord>,
      ),
      FavoriteWord,
      PrefetchHooks Function()
    >;
typedef $$FavoriteSentencesTableCreateCompanionBuilder =
    FavoriteSentencesCompanion Function({
      required String id,
      required int sentenceId,
      required int wordId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FavoriteSentencesTableUpdateCompanionBuilder =
    FavoriteSentencesCompanion Function({
      Value<String> id,
      Value<int> sentenceId,
      Value<int> wordId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FavoriteSentencesTableFilterComposer
    extends Composer<_$UserDatabase, $FavoriteSentencesTable> {
  $$FavoriteSentencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$FavoriteSentencesTableOrderingComposer
    extends Composer<_$UserDatabase, $FavoriteSentencesTable> {
  $$FavoriteSentencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteSentencesTableAnnotationComposer
    extends Composer<_$UserDatabase, $FavoriteSentencesTable> {
  $$FavoriteSentencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FavoriteSentencesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $FavoriteSentencesTable,
          FavoriteSentence,
          $$FavoriteSentencesTableFilterComposer,
          $$FavoriteSentencesTableOrderingComposer,
          $$FavoriteSentencesTableAnnotationComposer,
          $$FavoriteSentencesTableCreateCompanionBuilder,
          $$FavoriteSentencesTableUpdateCompanionBuilder,
          (
            FavoriteSentence,
            BaseReferences<
              _$UserDatabase,
              $FavoriteSentencesTable,
              FavoriteSentence
            >,
          ),
          FavoriteSentence,
          PrefetchHooks Function()
        > {
  $$FavoriteSentencesTableTableManager(
    _$UserDatabase db,
    $FavoriteSentencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteSentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteSentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteSentencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> sentenceId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteSentencesCompanion(
                id: id,
                sentenceId: sentenceId,
                wordId: wordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int sentenceId,
                required int wordId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoriteSentencesCompanion.insert(
                id: id,
                sentenceId: sentenceId,
                wordId: wordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteSentencesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $FavoriteSentencesTable,
      FavoriteSentence,
      $$FavoriteSentencesTableFilterComposer,
      $$FavoriteSentencesTableOrderingComposer,
      $$FavoriteSentencesTableAnnotationComposer,
      $$FavoriteSentencesTableCreateCompanionBuilder,
      $$FavoriteSentencesTableUpdateCompanionBuilder,
      (
        FavoriteSentence,
        BaseReferences<
          _$UserDatabase,
          $FavoriteSentencesTable,
          FavoriteSentence
        >,
      ),
      FavoriteSentence,
      PrefetchHooks Function()
    >;
typedef $$PracticeSessionsTableCreateCompanionBuilder =
    PracticeSessionsCompanion Function({
      required String id,
      required String type,
      required String configJson,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> totalQuestionCount,
      Value<int> correctCount,
      Value<int> elapsedMilliseconds,
      Value<int> rowid,
    });
typedef $$PracticeSessionsTableUpdateCompanionBuilder =
    PracticeSessionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> configJson,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> totalQuestionCount,
      Value<int> correctCount,
      Value<int> elapsedMilliseconds,
      Value<int> rowid,
    });

final class $$PracticeSessionsTableReferences
    extends
        BaseReferences<
          _$UserDatabase,
          $PracticeSessionsTable,
          PracticeSession
        > {
  $$PracticeSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PracticeAnswersTable, List<PracticeAnswer>>
  _practiceAnswersRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.practiceAnswers,
    aliasName: 'practice_sessions__id__practice_answers__session_id',
  );

  $$PracticeAnswersTableProcessedTableManager get practiceAnswersRefs {
    final manager = $$PracticeAnswersTableTableManager(
      $_db,
      $_db.practiceAnswers,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceAnswersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeSessionsTableFilterComposer
    extends Composer<_$UserDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get finishedAt =>
      $composableBuilder(
        column: $table.finishedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get totalQuestionCount => $composableBuilder(
    column: $table.totalQuestionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMilliseconds => $composableBuilder(
    column: $table.elapsedMilliseconds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> practiceAnswersRefs(
    Expression<bool> Function($$PracticeAnswersTableFilterComposer f) f,
  ) {
    final $$PracticeAnswersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAnswers,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAnswersTableFilterComposer(
            $db: $db,
            $table: $db.practiceAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableOrderingComposer
    extends Composer<_$UserDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestionCount => $composableBuilder(
    column: $table.totalQuestionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMilliseconds => $composableBuilder(
    column: $table.elapsedMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeSessionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get finishedAt =>
      $composableBuilder(
        column: $table.finishedAt,
        builder: (column) => column,
      );

  GeneratedColumn<int> get totalQuestionCount => $composableBuilder(
    column: $table.totalQuestionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMilliseconds => $composableBuilder(
    column: $table.elapsedMilliseconds,
    builder: (column) => column,
  );

  Expression<T> practiceAnswersRefs<T extends Object>(
    Expression<T> Function($$PracticeAnswersTableAnnotationComposer a) f,
  ) {
    final $$PracticeAnswersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAnswers,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAnswersTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $PracticeSessionsTable,
          PracticeSession,
          $$PracticeSessionsTableFilterComposer,
          $$PracticeSessionsTableOrderingComposer,
          $$PracticeSessionsTableAnnotationComposer,
          $$PracticeSessionsTableCreateCompanionBuilder,
          $$PracticeSessionsTableUpdateCompanionBuilder,
          (PracticeSession, $$PracticeSessionsTableReferences),
          PracticeSession,
          PrefetchHooks Function({bool practiceAnswersRefs})
        > {
  $$PracticeSessionsTableTableManager(
    _$UserDatabase db,
    $PracticeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> totalQuestionCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> elapsedMilliseconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionsCompanion(
                id: id,
                type: type,
                configJson: configJson,
                startedAt: startedAt,
                finishedAt: finishedAt,
                totalQuestionCount: totalQuestionCount,
                correctCount: correctCount,
                elapsedMilliseconds: elapsedMilliseconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String configJson,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> totalQuestionCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> elapsedMilliseconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionsCompanion.insert(
                id: id,
                type: type,
                configJson: configJson,
                startedAt: startedAt,
                finishedAt: finishedAt,
                totalQuestionCount: totalQuestionCount,
                correctCount: correctCount,
                elapsedMilliseconds: elapsedMilliseconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({practiceAnswersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (practiceAnswersRefs) db.practiceAnswers,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (practiceAnswersRefs)
                    await $_getPrefetchedData<
                      PracticeSession,
                      $PracticeSessionsTable,
                      PracticeAnswer
                    >(
                      currentTable: table,
                      referencedTable: $$PracticeSessionsTableReferences
                          ._practiceAnswersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PracticeSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).practiceAnswersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PracticeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $PracticeSessionsTable,
      PracticeSession,
      $$PracticeSessionsTableFilterComposer,
      $$PracticeSessionsTableOrderingComposer,
      $$PracticeSessionsTableAnnotationComposer,
      $$PracticeSessionsTableCreateCompanionBuilder,
      $$PracticeSessionsTableUpdateCompanionBuilder,
      (PracticeSession, $$PracticeSessionsTableReferences),
      PracticeSession,
      PrefetchHooks Function({bool practiceAnswersRefs})
    >;
typedef $$PracticeAnswersTableCreateCompanionBuilder =
    PracticeAnswersCompanion Function({
      required String id,
      required String sessionId,
      required int wordId,
      Value<int?> sentenceId,
      required String userAnswer,
      required bool isCorrect,
      required int responseTimeMilliseconds,
      required DateTime answeredAt,
      Value<int> rowid,
    });
typedef $$PracticeAnswersTableUpdateCompanionBuilder =
    PracticeAnswersCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> wordId,
      Value<int?> sentenceId,
      Value<String> userAnswer,
      Value<bool> isCorrect,
      Value<int> responseTimeMilliseconds,
      Value<DateTime> answeredAt,
      Value<int> rowid,
    });

final class $$PracticeAnswersTableReferences
    extends
        BaseReferences<_$UserDatabase, $PracticeAnswersTable, PracticeAnswer> {
  $$PracticeAnswersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeSessionsTable _sessionIdTable(_$UserDatabase db) => db
      .practiceSessions
      .createAlias('practice_answers__session_id__practice_sessions__id');

  $$PracticeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PracticeAnswersTableFilterComposer
    extends Composer<_$UserDatabase, $PracticeAnswersTable> {
  $$PracticeAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseTimeMilliseconds => $composableBuilder(
    column: $table.responseTimeMilliseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get answeredAt =>
      $composableBuilder(
        column: $table.answeredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$PracticeSessionsTableFilterComposer get sessionId {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeAnswersTableOrderingComposer
    extends Composer<_$UserDatabase, $PracticeAnswersTable> {
  $$PracticeAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseTimeMilliseconds => $composableBuilder(
    column: $table.responseTimeMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableOrderingComposer get sessionId {
    final $$PracticeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeAnswersTableAnnotationComposer
    extends Composer<_$UserDatabase, $PracticeAnswersTable> {
  $$PracticeAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<int> get responseTimeMilliseconds => $composableBuilder(
    column: $table.responseTimeMilliseconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get answeredAt =>
      $composableBuilder(
        column: $table.answeredAt,
        builder: (column) => column,
      );

  $$PracticeSessionsTableAnnotationComposer get sessionId {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeAnswersTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $PracticeAnswersTable,
          PracticeAnswer,
          $$PracticeAnswersTableFilterComposer,
          $$PracticeAnswersTableOrderingComposer,
          $$PracticeAnswersTableAnnotationComposer,
          $$PracticeAnswersTableCreateCompanionBuilder,
          $$PracticeAnswersTableUpdateCompanionBuilder,
          (PracticeAnswer, $$PracticeAnswersTableReferences),
          PracticeAnswer,
          PrefetchHooks Function({bool sessionId})
        > {
  $$PracticeAnswersTableTableManager(
    _$UserDatabase db,
    $PracticeAnswersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int?> sentenceId = const Value.absent(),
                Value<String> userAnswer = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<int> responseTimeMilliseconds = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeAnswersCompanion(
                id: id,
                sessionId: sessionId,
                wordId: wordId,
                sentenceId: sentenceId,
                userAnswer: userAnswer,
                isCorrect: isCorrect,
                responseTimeMilliseconds: responseTimeMilliseconds,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int wordId,
                Value<int?> sentenceId = const Value.absent(),
                required String userAnswer,
                required bool isCorrect,
                required int responseTimeMilliseconds,
                required DateTime answeredAt,
                Value<int> rowid = const Value.absent(),
              }) => PracticeAnswersCompanion.insert(
                id: id,
                sessionId: sessionId,
                wordId: wordId,
                sentenceId: sentenceId,
                userAnswer: userAnswer,
                isCorrect: isCorrect,
                responseTimeMilliseconds: responseTimeMilliseconds,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeAnswersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$PracticeAnswersTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$PracticeAnswersTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PracticeAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $PracticeAnswersTable,
      PracticeAnswer,
      $$PracticeAnswersTableFilterComposer,
      $$PracticeAnswersTableOrderingComposer,
      $$PracticeAnswersTableAnnotationComposer,
      $$PracticeAnswersTableCreateCompanionBuilder,
      $$PracticeAnswersTableUpdateCompanionBuilder,
      (PracticeAnswer, $$PracticeAnswersTableReferences),
      PracticeAnswer,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$LearningEventsTableCreateCompanionBuilder =
    LearningEventsCompanion Function({
      required String id,
      required String eventType,
      required int wordId,
      Value<String?> sessionId,
      Value<bool?> isCorrect,
      Value<String?> reviewRating,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$LearningEventsTableUpdateCompanionBuilder =
    LearningEventsCompanion Function({
      Value<String> id,
      Value<String> eventType,
      Value<int> wordId,
      Value<String?> sessionId,
      Value<bool?> isCorrect,
      Value<String?> reviewRating,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

class $$LearningEventsTableFilterComposer
    extends Composer<_$UserDatabase, $LearningEventsTable> {
  $$LearningEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewRating => $composableBuilder(
    column: $table.reviewRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$LearningEventsTableOrderingComposer
    extends Composer<_$UserDatabase, $LearningEventsTable> {
  $$LearningEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewRating => $composableBuilder(
    column: $table.reviewRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningEventsTableAnnotationComposer
    extends Composer<_$UserDatabase, $LearningEventsTable> {
  $$LearningEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<String> get reviewRating => $composableBuilder(
    column: $table.reviewRating,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => column,
      );
}

class $$LearningEventsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $LearningEventsTable,
          LearningEvent,
          $$LearningEventsTableFilterComposer,
          $$LearningEventsTableOrderingComposer,
          $$LearningEventsTableAnnotationComposer,
          $$LearningEventsTableCreateCompanionBuilder,
          $$LearningEventsTableUpdateCompanionBuilder,
          (
            LearningEvent,
            BaseReferences<_$UserDatabase, $LearningEventsTable, LearningEvent>,
          ),
          LearningEvent,
          PrefetchHooks Function()
        > {
  $$LearningEventsTableTableManager(
    _$UserDatabase db,
    $LearningEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<bool?> isCorrect = const Value.absent(),
                Value<String?> reviewRating = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningEventsCompanion(
                id: id,
                eventType: eventType,
                wordId: wordId,
                sessionId: sessionId,
                isCorrect: isCorrect,
                reviewRating: reviewRating,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventType,
                required int wordId,
                Value<String?> sessionId = const Value.absent(),
                Value<bool?> isCorrect = const Value.absent(),
                Value<String?> reviewRating = const Value.absent(),
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => LearningEventsCompanion.insert(
                id: id,
                eventType: eventType,
                wordId: wordId,
                sessionId: sessionId,
                isCorrect: isCorrect,
                reviewRating: reviewRating,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $LearningEventsTable,
      LearningEvent,
      $$LearningEventsTableFilterComposer,
      $$LearningEventsTableOrderingComposer,
      $$LearningEventsTableAnnotationComposer,
      $$LearningEventsTableCreateCompanionBuilder,
      $$LearningEventsTableUpdateCompanionBuilder,
      (
        LearningEvent,
        BaseReferences<_$UserDatabase, $LearningEventsTable, LearningEvent>,
      ),
      LearningEvent,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required int dailyGoal,
      required String pronunciationAccent,
      required bool autoPlayPronunciation,
      required String themeMode,
      Value<String> accentColor,
      required DateTime updatedAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<int> dailyGoal,
      Value<String> pronunciationAccent,
      Value<bool> autoPlayPronunciation,
      Value<String> themeMode,
      Value<String> accentColor,
      Value<DateTime> updatedAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyGoal => $composableBuilder(
    column: $table.dailyGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronunciationAccent => $composableBuilder(
    column: $table.pronunciationAccent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPlayPronunciation => $composableBuilder(
    column: $table.autoPlayPronunciation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyGoal => $composableBuilder(
    column: $table.dailyGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronunciationAccent => $composableBuilder(
    column: $table.pronunciationAccent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPlayPronunciation => $composableBuilder(
    column: $table.autoPlayPronunciation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dailyGoal =>
      $composableBuilder(column: $table.dailyGoal, builder: (column) => column);

  GeneratedColumn<String> get pronunciationAccent => $composableBuilder(
    column: $table.pronunciationAccent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPlayPronunciation => $composableBuilder(
    column: $table.autoPlayPronunciation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$UserDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$UserDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyGoal = const Value.absent(),
                Value<String> pronunciationAccent = const Value.absent(),
                Value<bool> autoPlayPronunciation = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> accentColor = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                dailyGoal: dailyGoal,
                pronunciationAccent: pronunciationAccent,
                autoPlayPronunciation: autoPlayPronunciation,
                themeMode: themeMode,
                accentColor: accentColor,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dailyGoal,
                required String pronunciationAccent,
                required bool autoPlayPronunciation,
                required String themeMode,
                Value<String> accentColor = const Value.absent(),
                required DateTime updatedAt,
              }) => AppSettingsCompanion.insert(
                id: id,
                dailyGoal: dailyGoal,
                pronunciationAccent: pronunciationAccent,
                autoPlayPronunciation: autoPlayPronunciation,
                themeMode: themeMode,
                accentColor: accentColor,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$UserDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$BackupHistoryTableCreateCompanionBuilder =
    BackupHistoryCompanion Function({
      required String id,
      required String type,
      required String fileName,
      required String summaryJson,
      required String result,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$BackupHistoryTableUpdateCompanionBuilder =
    BackupHistoryCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> fileName,
      Value<String> summaryJson,
      Value<String> result,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

class $$BackupHistoryTableFilterComposer
    extends Composer<_$UserDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$BackupHistoryTableOrderingComposer
    extends Composer<_$UserDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupHistoryTableAnnotationComposer
    extends Composer<_$UserDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => column,
      );
}

class $$BackupHistoryTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $BackupHistoryTable,
          BackupHistoryData,
          $$BackupHistoryTableFilterComposer,
          $$BackupHistoryTableOrderingComposer,
          $$BackupHistoryTableAnnotationComposer,
          $$BackupHistoryTableCreateCompanionBuilder,
          $$BackupHistoryTableUpdateCompanionBuilder,
          (
            BackupHistoryData,
            BaseReferences<
              _$UserDatabase,
              $BackupHistoryTable,
              BackupHistoryData
            >,
          ),
          BackupHistoryData,
          PrefetchHooks Function()
        > {
  $$BackupHistoryTableTableManager(_$UserDatabase db, $BackupHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> summaryJson = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupHistoryCompanion(
                id: id,
                type: type,
                fileName: fileName,
                summaryJson: summaryJson,
                result: result,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String fileName,
                required String summaryJson,
                required String result,
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => BackupHistoryCompanion.insert(
                id: id,
                type: type,
                fileName: fileName,
                summaryJson: summaryJson,
                result: result,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $BackupHistoryTable,
      BackupHistoryData,
      $$BackupHistoryTableFilterComposer,
      $$BackupHistoryTableOrderingComposer,
      $$BackupHistoryTableAnnotationComposer,
      $$BackupHistoryTableCreateCompanionBuilder,
      $$BackupHistoryTableUpdateCompanionBuilder,
      (
        BackupHistoryData,
        BaseReferences<_$UserDatabase, $BackupHistoryTable, BackupHistoryData>,
      ),
      BackupHistoryData,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$UserWordStatesTableTableManager get userWordStates =>
      $$UserWordStatesTableTableManager(_db, _db.userWordStates);
  $$FavoriteWordsTableTableManager get favoriteWords =>
      $$FavoriteWordsTableTableManager(_db, _db.favoriteWords);
  $$FavoriteSentencesTableTableManager get favoriteSentences =>
      $$FavoriteSentencesTableTableManager(_db, _db.favoriteSentences);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(_db, _db.practiceSessions);
  $$PracticeAnswersTableTableManager get practiceAnswers =>
      $$PracticeAnswersTableTableManager(_db, _db.practiceAnswers);
  $$LearningEventsTableTableManager get learningEvents =>
      $$LearningEventsTableTableManager(_db, _db.learningEvents);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BackupHistoryTableTableManager get backupHistory =>
      $$BackupHistoryTableTableManager(_db, _db.backupHistory);
}
