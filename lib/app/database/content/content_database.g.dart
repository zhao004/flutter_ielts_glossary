// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_database.dart';

// ignore_for_file: type=lint
class $FrequencyGroupsTable extends FrequencyGroups
    with TableInfo<$FrequencyGroupsTable, FrequencyGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrequencyGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('rank BETWEEN 1 AND 7'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minOccurrencesMeta = const VerificationMeta(
    'minOccurrences',
  );
  @override
  late final GeneratedColumn<int> minOccurrences = GeneratedColumn<int>(
    'min_occurrences',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('min_occurrences >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxOccurrencesMeta = const VerificationMeta(
    'maxOccurrences',
  );
  @override
  late final GeneratedColumn<int> maxOccurrences = GeneratedColumn<int>(
    'max_occurrences',
    aliasedName,
    true,
    check: () => const CustomExpression<bool>(
      'max_occurrences IS NULL OR max_occurrences >= 0',
    ),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    rank,
    minOccurrences,
    maxOccurrences,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frequency_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrequencyGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    if (data.containsKey('min_occurrences')) {
      context.handle(
        _minOccurrencesMeta,
        minOccurrences.isAcceptableOrUnknown(
          data['min_occurrences']!,
          _minOccurrencesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minOccurrencesMeta);
    }
    if (data.containsKey('max_occurrences')) {
      context.handle(
        _maxOccurrencesMeta,
        maxOccurrences.isAcceptableOrUnknown(
          data['max_occurrences']!,
          _maxOccurrencesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FrequencyGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrequencyGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      minOccurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_occurrences'],
      )!,
      maxOccurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_occurrences'],
      ),
    );
  }

  @override
  $FrequencyGroupsTable createAlias(String alias) {
    return $FrequencyGroupsTable(attachedDatabase, alias);
  }
}

class FrequencyGroup extends DataClass implements Insertable<FrequencyGroup> {
  final int id;
  final String name;
  final int rank;
  final int minOccurrences;
  final int? maxOccurrences;
  const FrequencyGroup({
    required this.id,
    required this.name,
    required this.rank,
    required this.minOccurrences,
    this.maxOccurrences,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['rank'] = Variable<int>(rank);
    map['min_occurrences'] = Variable<int>(minOccurrences);
    if (!nullToAbsent || maxOccurrences != null) {
      map['max_occurrences'] = Variable<int>(maxOccurrences);
    }
    return map;
  }

  FrequencyGroupsCompanion toCompanion(bool nullToAbsent) {
    return FrequencyGroupsCompanion(
      id: Value(id),
      name: Value(name),
      rank: Value(rank),
      minOccurrences: Value(minOccurrences),
      maxOccurrences: maxOccurrences == null && nullToAbsent
          ? const Value.absent()
          : Value(maxOccurrences),
    );
  }

  factory FrequencyGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrequencyGroup(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rank: serializer.fromJson<int>(json['rank']),
      minOccurrences: serializer.fromJson<int>(json['minOccurrences']),
      maxOccurrences: serializer.fromJson<int?>(json['maxOccurrences']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'rank': serializer.toJson<int>(rank),
      'minOccurrences': serializer.toJson<int>(minOccurrences),
      'maxOccurrences': serializer.toJson<int?>(maxOccurrences),
    };
  }

  FrequencyGroup copyWith({
    int? id,
    String? name,
    int? rank,
    int? minOccurrences,
    Value<int?> maxOccurrences = const Value.absent(),
  }) => FrequencyGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    rank: rank ?? this.rank,
    minOccurrences: minOccurrences ?? this.minOccurrences,
    maxOccurrences: maxOccurrences.present
        ? maxOccurrences.value
        : this.maxOccurrences,
  );
  FrequencyGroup copyWithCompanion(FrequencyGroupsCompanion data) {
    return FrequencyGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rank: data.rank.present ? data.rank.value : this.rank,
      minOccurrences: data.minOccurrences.present
          ? data.minOccurrences.value
          : this.minOccurrences,
      maxOccurrences: data.maxOccurrences.present
          ? data.maxOccurrences.value
          : this.maxOccurrences,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrequencyGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rank: $rank, ')
          ..write('minOccurrences: $minOccurrences, ')
          ..write('maxOccurrences: $maxOccurrences')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, rank, minOccurrences, maxOccurrences);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrequencyGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.rank == this.rank &&
          other.minOccurrences == this.minOccurrences &&
          other.maxOccurrences == this.maxOccurrences);
}

class FrequencyGroupsCompanion extends UpdateCompanion<FrequencyGroup> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> rank;
  final Value<int> minOccurrences;
  final Value<int?> maxOccurrences;
  const FrequencyGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rank = const Value.absent(),
    this.minOccurrences = const Value.absent(),
    this.maxOccurrences = const Value.absent(),
  });
  FrequencyGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int rank,
    required int minOccurrences,
    this.maxOccurrences = const Value.absent(),
  }) : name = Value(name),
       rank = Value(rank),
       minOccurrences = Value(minOccurrences);
  static Insertable<FrequencyGroup> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? rank,
    Expression<int>? minOccurrences,
    Expression<int>? maxOccurrences,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rank != null) 'rank': rank,
      if (minOccurrences != null) 'min_occurrences': minOccurrences,
      if (maxOccurrences != null) 'max_occurrences': maxOccurrences,
    });
  }

  FrequencyGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? rank,
    Value<int>? minOccurrences,
    Value<int?>? maxOccurrences,
  }) {
    return FrequencyGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      minOccurrences: minOccurrences ?? this.minOccurrences,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (minOccurrences.present) {
      map['min_occurrences'] = Variable<int>(minOccurrences.value);
    }
    if (maxOccurrences.present) {
      map['max_occurrences'] = Variable<int>(maxOccurrences.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrequencyGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rank: $rank, ')
          ..write('minOccurrences: $minOccurrences, ')
          ..write('maxOccurrences: $maxOccurrences')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneticUkMeta = const VerificationMeta(
    'phoneticUk',
  );
  @override
  late final GeneratedColumn<String> phoneticUk = GeneratedColumn<String>(
    'phonetic_uk',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneticUsMeta = const VerificationMeta(
    'phoneticUs',
  );
  @override
  late final GeneratedColumn<String> phoneticUs = GeneratedColumn<String>(
    'phonetic_us',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translationZhMeta = const VerificationMeta(
    'translationZh',
  );
  @override
  late final GeneratedColumn<String> translationZh = GeneratedColumn<String>(
    'translation_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _definitionEnMeta = const VerificationMeta(
    'definitionEn',
  );
  @override
  late final GeneratedColumn<String> definitionEn = GeneratedColumn<String>(
    'definition_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mnemonicMeta = const VerificationMeta(
    'mnemonic',
  );
  @override
  late final GeneratedColumn<String> mnemonic = GeneratedColumn<String>(
    'mnemonic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrencesMeta = const VerificationMeta(
    'occurrences',
  );
  @override
  late final GeneratedColumn<int> occurrences = GeneratedColumn<int>(
    'occurrences',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('occurrences >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyGroupIdMeta = const VerificationMeta(
    'frequencyGroupId',
  );
  @override
  late final GeneratedColumn<int> frequencyGroupId = GeneratedColumn<int>(
    'frequency_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES frequency_groups (id)',
    ),
  );
  static const VerificationMeta _firstLetterMeta = const VerificationMeta(
    'firstLetter',
  );
  @override
  late final GeneratedColumn<String> firstLetter = GeneratedColumn<String>(
    'first_letter',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioUkAssetMeta = const VerificationMeta(
    'audioUkAsset',
  );
  @override
  late final GeneratedColumn<String> audioUkAsset = GeneratedColumn<String>(
    'audio_uk_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUsAssetMeta = const VerificationMeta(
    'audioUsAsset',
  );
  @override
  late final GeneratedColumn<String> audioUsAsset = GeneratedColumn<String>(
    'audio_us_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    phoneticUk,
    phoneticUs,
    translationZh,
    definitionEn,
    mnemonic,
    occurrences,
    frequencyGroupId,
    firstLetter,
    audioUkAsset,
    audioUsAsset,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('phonetic_uk')) {
      context.handle(
        _phoneticUkMeta,
        phoneticUk.isAcceptableOrUnknown(data['phonetic_uk']!, _phoneticUkMeta),
      );
    }
    if (data.containsKey('phonetic_us')) {
      context.handle(
        _phoneticUsMeta,
        phoneticUs.isAcceptableOrUnknown(data['phonetic_us']!, _phoneticUsMeta),
      );
    }
    if (data.containsKey('translation_zh')) {
      context.handle(
        _translationZhMeta,
        translationZh.isAcceptableOrUnknown(
          data['translation_zh']!,
          _translationZhMeta,
        ),
      );
    }
    if (data.containsKey('definition_en')) {
      context.handle(
        _definitionEnMeta,
        definitionEn.isAcceptableOrUnknown(
          data['definition_en']!,
          _definitionEnMeta,
        ),
      );
    }
    if (data.containsKey('mnemonic')) {
      context.handle(
        _mnemonicMeta,
        mnemonic.isAcceptableOrUnknown(data['mnemonic']!, _mnemonicMeta),
      );
    }
    if (data.containsKey('occurrences')) {
      context.handle(
        _occurrencesMeta,
        occurrences.isAcceptableOrUnknown(
          data['occurrences']!,
          _occurrencesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrencesMeta);
    }
    if (data.containsKey('frequency_group_id')) {
      context.handle(
        _frequencyGroupIdMeta,
        frequencyGroupId.isAcceptableOrUnknown(
          data['frequency_group_id']!,
          _frequencyGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_frequencyGroupIdMeta);
    }
    if (data.containsKey('first_letter')) {
      context.handle(
        _firstLetterMeta,
        firstLetter.isAcceptableOrUnknown(
          data['first_letter']!,
          _firstLetterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstLetterMeta);
    }
    if (data.containsKey('audio_uk_asset')) {
      context.handle(
        _audioUkAssetMeta,
        audioUkAsset.isAcceptableOrUnknown(
          data['audio_uk_asset']!,
          _audioUkAssetMeta,
        ),
      );
    }
    if (data.containsKey('audio_us_asset')) {
      context.handle(
        _audioUsAssetMeta,
        audioUsAsset.isAcceptableOrUnknown(
          data['audio_us_asset']!,
          _audioUsAssetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      phoneticUk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic_uk'],
      ),
      phoneticUs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic_us'],
      ),
      translationZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_zh'],
      ),
      definitionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_en'],
      ),
      mnemonic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mnemonic'],
      ),
      occurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrences'],
      )!,
      frequencyGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency_group_id'],
      )!,
      firstLetter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_letter'],
      )!,
      audioUkAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_uk_asset'],
      ),
      audioUsAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_us_asset'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final String word;
  final String? phoneticUk;
  final String? phoneticUs;
  final String? translationZh;
  final String? definitionEn;
  final String? mnemonic;
  final int occurrences;
  final int frequencyGroupId;
  final String firstLetter;
  final String? audioUkAsset;
  final String? audioUsAsset;
  const Word({
    required this.id,
    required this.word,
    this.phoneticUk,
    this.phoneticUs,
    this.translationZh,
    this.definitionEn,
    this.mnemonic,
    required this.occurrences,
    required this.frequencyGroupId,
    required this.firstLetter,
    this.audioUkAsset,
    this.audioUsAsset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || phoneticUk != null) {
      map['phonetic_uk'] = Variable<String>(phoneticUk);
    }
    if (!nullToAbsent || phoneticUs != null) {
      map['phonetic_us'] = Variable<String>(phoneticUs);
    }
    if (!nullToAbsent || translationZh != null) {
      map['translation_zh'] = Variable<String>(translationZh);
    }
    if (!nullToAbsent || definitionEn != null) {
      map['definition_en'] = Variable<String>(definitionEn);
    }
    if (!nullToAbsent || mnemonic != null) {
      map['mnemonic'] = Variable<String>(mnemonic);
    }
    map['occurrences'] = Variable<int>(occurrences);
    map['frequency_group_id'] = Variable<int>(frequencyGroupId);
    map['first_letter'] = Variable<String>(firstLetter);
    if (!nullToAbsent || audioUkAsset != null) {
      map['audio_uk_asset'] = Variable<String>(audioUkAsset);
    }
    if (!nullToAbsent || audioUsAsset != null) {
      map['audio_us_asset'] = Variable<String>(audioUsAsset);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      word: Value(word),
      phoneticUk: phoneticUk == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticUk),
      phoneticUs: phoneticUs == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticUs),
      translationZh: translationZh == null && nullToAbsent
          ? const Value.absent()
          : Value(translationZh),
      definitionEn: definitionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(definitionEn),
      mnemonic: mnemonic == null && nullToAbsent
          ? const Value.absent()
          : Value(mnemonic),
      occurrences: Value(occurrences),
      frequencyGroupId: Value(frequencyGroupId),
      firstLetter: Value(firstLetter),
      audioUkAsset: audioUkAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUkAsset),
      audioUsAsset: audioUsAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUsAsset),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      phoneticUk: serializer.fromJson<String?>(json['phoneticUk']),
      phoneticUs: serializer.fromJson<String?>(json['phoneticUs']),
      translationZh: serializer.fromJson<String?>(json['translationZh']),
      definitionEn: serializer.fromJson<String?>(json['definitionEn']),
      mnemonic: serializer.fromJson<String?>(json['mnemonic']),
      occurrences: serializer.fromJson<int>(json['occurrences']),
      frequencyGroupId: serializer.fromJson<int>(json['frequencyGroupId']),
      firstLetter: serializer.fromJson<String>(json['firstLetter']),
      audioUkAsset: serializer.fromJson<String?>(json['audioUkAsset']),
      audioUsAsset: serializer.fromJson<String?>(json['audioUsAsset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'phoneticUk': serializer.toJson<String?>(phoneticUk),
      'phoneticUs': serializer.toJson<String?>(phoneticUs),
      'translationZh': serializer.toJson<String?>(translationZh),
      'definitionEn': serializer.toJson<String?>(definitionEn),
      'mnemonic': serializer.toJson<String?>(mnemonic),
      'occurrences': serializer.toJson<int>(occurrences),
      'frequencyGroupId': serializer.toJson<int>(frequencyGroupId),
      'firstLetter': serializer.toJson<String>(firstLetter),
      'audioUkAsset': serializer.toJson<String?>(audioUkAsset),
      'audioUsAsset': serializer.toJson<String?>(audioUsAsset),
    };
  }

  Word copyWith({
    int? id,
    String? word,
    Value<String?> phoneticUk = const Value.absent(),
    Value<String?> phoneticUs = const Value.absent(),
    Value<String?> translationZh = const Value.absent(),
    Value<String?> definitionEn = const Value.absent(),
    Value<String?> mnemonic = const Value.absent(),
    int? occurrences,
    int? frequencyGroupId,
    String? firstLetter,
    Value<String?> audioUkAsset = const Value.absent(),
    Value<String?> audioUsAsset = const Value.absent(),
  }) => Word(
    id: id ?? this.id,
    word: word ?? this.word,
    phoneticUk: phoneticUk.present ? phoneticUk.value : this.phoneticUk,
    phoneticUs: phoneticUs.present ? phoneticUs.value : this.phoneticUs,
    translationZh: translationZh.present
        ? translationZh.value
        : this.translationZh,
    definitionEn: definitionEn.present ? definitionEn.value : this.definitionEn,
    mnemonic: mnemonic.present ? mnemonic.value : this.mnemonic,
    occurrences: occurrences ?? this.occurrences,
    frequencyGroupId: frequencyGroupId ?? this.frequencyGroupId,
    firstLetter: firstLetter ?? this.firstLetter,
    audioUkAsset: audioUkAsset.present ? audioUkAsset.value : this.audioUkAsset,
    audioUsAsset: audioUsAsset.present ? audioUsAsset.value : this.audioUsAsset,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      phoneticUk: data.phoneticUk.present
          ? data.phoneticUk.value
          : this.phoneticUk,
      phoneticUs: data.phoneticUs.present
          ? data.phoneticUs.value
          : this.phoneticUs,
      translationZh: data.translationZh.present
          ? data.translationZh.value
          : this.translationZh,
      definitionEn: data.definitionEn.present
          ? data.definitionEn.value
          : this.definitionEn,
      mnemonic: data.mnemonic.present ? data.mnemonic.value : this.mnemonic,
      occurrences: data.occurrences.present
          ? data.occurrences.value
          : this.occurrences,
      frequencyGroupId: data.frequencyGroupId.present
          ? data.frequencyGroupId.value
          : this.frequencyGroupId,
      firstLetter: data.firstLetter.present
          ? data.firstLetter.value
          : this.firstLetter,
      audioUkAsset: data.audioUkAsset.present
          ? data.audioUkAsset.value
          : this.audioUkAsset,
      audioUsAsset: data.audioUsAsset.present
          ? data.audioUsAsset.value
          : this.audioUsAsset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('phoneticUs: $phoneticUs, ')
          ..write('translationZh: $translationZh, ')
          ..write('definitionEn: $definitionEn, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('occurrences: $occurrences, ')
          ..write('frequencyGroupId: $frequencyGroupId, ')
          ..write('firstLetter: $firstLetter, ')
          ..write('audioUkAsset: $audioUkAsset, ')
          ..write('audioUsAsset: $audioUsAsset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    word,
    phoneticUk,
    phoneticUs,
    translationZh,
    definitionEn,
    mnemonic,
    occurrences,
    frequencyGroupId,
    firstLetter,
    audioUkAsset,
    audioUsAsset,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.word == this.word &&
          other.phoneticUk == this.phoneticUk &&
          other.phoneticUs == this.phoneticUs &&
          other.translationZh == this.translationZh &&
          other.definitionEn == this.definitionEn &&
          other.mnemonic == this.mnemonic &&
          other.occurrences == this.occurrences &&
          other.frequencyGroupId == this.frequencyGroupId &&
          other.firstLetter == this.firstLetter &&
          other.audioUkAsset == this.audioUkAsset &&
          other.audioUsAsset == this.audioUsAsset);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> word;
  final Value<String?> phoneticUk;
  final Value<String?> phoneticUs;
  final Value<String?> translationZh;
  final Value<String?> definitionEn;
  final Value<String?> mnemonic;
  final Value<int> occurrences;
  final Value<int> frequencyGroupId;
  final Value<String> firstLetter;
  final Value<String?> audioUkAsset;
  final Value<String?> audioUsAsset;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.phoneticUk = const Value.absent(),
    this.phoneticUs = const Value.absent(),
    this.translationZh = const Value.absent(),
    this.definitionEn = const Value.absent(),
    this.mnemonic = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.frequencyGroupId = const Value.absent(),
    this.firstLetter = const Value.absent(),
    this.audioUkAsset = const Value.absent(),
    this.audioUsAsset = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    this.phoneticUk = const Value.absent(),
    this.phoneticUs = const Value.absent(),
    this.translationZh = const Value.absent(),
    this.definitionEn = const Value.absent(),
    this.mnemonic = const Value.absent(),
    required int occurrences,
    required int frequencyGroupId,
    required String firstLetter,
    this.audioUkAsset = const Value.absent(),
    this.audioUsAsset = const Value.absent(),
  }) : word = Value(word),
       occurrences = Value(occurrences),
       frequencyGroupId = Value(frequencyGroupId),
       firstLetter = Value(firstLetter);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? phoneticUk,
    Expression<String>? phoneticUs,
    Expression<String>? translationZh,
    Expression<String>? definitionEn,
    Expression<String>? mnemonic,
    Expression<int>? occurrences,
    Expression<int>? frequencyGroupId,
    Expression<String>? firstLetter,
    Expression<String>? audioUkAsset,
    Expression<String>? audioUsAsset,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (phoneticUk != null) 'phonetic_uk': phoneticUk,
      if (phoneticUs != null) 'phonetic_us': phoneticUs,
      if (translationZh != null) 'translation_zh': translationZh,
      if (definitionEn != null) 'definition_en': definitionEn,
      if (mnemonic != null) 'mnemonic': mnemonic,
      if (occurrences != null) 'occurrences': occurrences,
      if (frequencyGroupId != null) 'frequency_group_id': frequencyGroupId,
      if (firstLetter != null) 'first_letter': firstLetter,
      if (audioUkAsset != null) 'audio_uk_asset': audioUkAsset,
      if (audioUsAsset != null) 'audio_us_asset': audioUsAsset,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String?>? phoneticUk,
    Value<String?>? phoneticUs,
    Value<String?>? translationZh,
    Value<String?>? definitionEn,
    Value<String?>? mnemonic,
    Value<int>? occurrences,
    Value<int>? frequencyGroupId,
    Value<String>? firstLetter,
    Value<String?>? audioUkAsset,
    Value<String?>? audioUsAsset,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      phoneticUs: phoneticUs ?? this.phoneticUs,
      translationZh: translationZh ?? this.translationZh,
      definitionEn: definitionEn ?? this.definitionEn,
      mnemonic: mnemonic ?? this.mnemonic,
      occurrences: occurrences ?? this.occurrences,
      frequencyGroupId: frequencyGroupId ?? this.frequencyGroupId,
      firstLetter: firstLetter ?? this.firstLetter,
      audioUkAsset: audioUkAsset ?? this.audioUkAsset,
      audioUsAsset: audioUsAsset ?? this.audioUsAsset,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (phoneticUk.present) {
      map['phonetic_uk'] = Variable<String>(phoneticUk.value);
    }
    if (phoneticUs.present) {
      map['phonetic_us'] = Variable<String>(phoneticUs.value);
    }
    if (translationZh.present) {
      map['translation_zh'] = Variable<String>(translationZh.value);
    }
    if (definitionEn.present) {
      map['definition_en'] = Variable<String>(definitionEn.value);
    }
    if (mnemonic.present) {
      map['mnemonic'] = Variable<String>(mnemonic.value);
    }
    if (occurrences.present) {
      map['occurrences'] = Variable<int>(occurrences.value);
    }
    if (frequencyGroupId.present) {
      map['frequency_group_id'] = Variable<int>(frequencyGroupId.value);
    }
    if (firstLetter.present) {
      map['first_letter'] = Variable<String>(firstLetter.value);
    }
    if (audioUkAsset.present) {
      map['audio_uk_asset'] = Variable<String>(audioUkAsset.value);
    }
    if (audioUsAsset.present) {
      map['audio_us_asset'] = Variable<String>(audioUsAsset.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('phoneticUs: $phoneticUs, ')
          ..write('translationZh: $translationZh, ')
          ..write('definitionEn: $definitionEn, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('occurrences: $occurrences, ')
          ..write('frequencyGroupId: $frequencyGroupId, ')
          ..write('firstLetter: $firstLetter, ')
          ..write('audioUkAsset: $audioUkAsset, ')
          ..write('audioUsAsset: $audioUsAsset')
          ..write(')'))
        .toString();
  }
}

class $SentencesTable extends Sentences
    with TableInfo<$SentencesTable, Sentence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetFormMeta = const VerificationMeta(
    'targetForm',
  );
  @override
  late final GeneratedColumn<String> targetForm = GeneratedColumn<String>(
    'target_form',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceEnMeta = const VerificationMeta(
    'sentenceEn',
  );
  @override
  late final GeneratedColumn<String> sentenceEn = GeneratedColumn<String>(
    'sentence_en',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationZhMeta = const VerificationMeta(
    'translationZh',
  );
  @override
  late final GeneratedColumn<String> translationZh = GeneratedColumn<String>(
    'translation_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    targetForm,
    sentenceEn,
    translationZh,
    source,
    location,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sentence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('target_form')) {
      context.handle(
        _targetFormMeta,
        targetForm.isAcceptableOrUnknown(data['target_form']!, _targetFormMeta),
      );
    } else if (isInserting) {
      context.missing(_targetFormMeta);
    }
    if (data.containsKey('sentence_en')) {
      context.handle(
        _sentenceEnMeta,
        sentenceEn.isAcceptableOrUnknown(data['sentence_en']!, _sentenceEnMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceEnMeta);
    }
    if (data.containsKey('translation_zh')) {
      context.handle(
        _translationZhMeta,
        translationZh.isAcceptableOrUnknown(
          data['translation_zh']!,
          _translationZhMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sentence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sentence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      targetForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_form'],
      )!,
      sentenceEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_en'],
      )!,
      translationZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_zh'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
    );
  }

  @override
  $SentencesTable createAlias(String alias) {
    return $SentencesTable(attachedDatabase, alias);
  }
}

class Sentence extends DataClass implements Insertable<Sentence> {
  final int id;
  final int wordId;
  final String targetForm;
  final String sentenceEn;
  final String? translationZh;
  final String? source;
  final String? location;
  const Sentence({
    required this.id,
    required this.wordId,
    required this.targetForm,
    required this.sentenceEn,
    this.translationZh,
    this.source,
    this.location,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['target_form'] = Variable<String>(targetForm);
    map['sentence_en'] = Variable<String>(sentenceEn);
    if (!nullToAbsent || translationZh != null) {
      map['translation_zh'] = Variable<String>(translationZh);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    return map;
  }

  SentencesCompanion toCompanion(bool nullToAbsent) {
    return SentencesCompanion(
      id: Value(id),
      wordId: Value(wordId),
      targetForm: Value(targetForm),
      sentenceEn: Value(sentenceEn),
      translationZh: translationZh == null && nullToAbsent
          ? const Value.absent()
          : Value(translationZh),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
    );
  }

  factory Sentence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sentence(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      targetForm: serializer.fromJson<String>(json['targetForm']),
      sentenceEn: serializer.fromJson<String>(json['sentenceEn']),
      translationZh: serializer.fromJson<String?>(json['translationZh']),
      source: serializer.fromJson<String?>(json['source']),
      location: serializer.fromJson<String?>(json['location']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'targetForm': serializer.toJson<String>(targetForm),
      'sentenceEn': serializer.toJson<String>(sentenceEn),
      'translationZh': serializer.toJson<String?>(translationZh),
      'source': serializer.toJson<String?>(source),
      'location': serializer.toJson<String?>(location),
    };
  }

  Sentence copyWith({
    int? id,
    int? wordId,
    String? targetForm,
    String? sentenceEn,
    Value<String?> translationZh = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> location = const Value.absent(),
  }) => Sentence(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    targetForm: targetForm ?? this.targetForm,
    sentenceEn: sentenceEn ?? this.sentenceEn,
    translationZh: translationZh.present
        ? translationZh.value
        : this.translationZh,
    source: source.present ? source.value : this.source,
    location: location.present ? location.value : this.location,
  );
  Sentence copyWithCompanion(SentencesCompanion data) {
    return Sentence(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      targetForm: data.targetForm.present
          ? data.targetForm.value
          : this.targetForm,
      sentenceEn: data.sentenceEn.present
          ? data.sentenceEn.value
          : this.sentenceEn,
      translationZh: data.translationZh.present
          ? data.translationZh.value
          : this.translationZh,
      source: data.source.present ? data.source.value : this.source,
      location: data.location.present ? data.location.value : this.location,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sentence(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('targetForm: $targetForm, ')
          ..write('sentenceEn: $sentenceEn, ')
          ..write('translationZh: $translationZh, ')
          ..write('source: $source, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    targetForm,
    sentenceEn,
    translationZh,
    source,
    location,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sentence &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.targetForm == this.targetForm &&
          other.sentenceEn == this.sentenceEn &&
          other.translationZh == this.translationZh &&
          other.source == this.source &&
          other.location == this.location);
}

class SentencesCompanion extends UpdateCompanion<Sentence> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<String> targetForm;
  final Value<String> sentenceEn;
  final Value<String?> translationZh;
  final Value<String?> source;
  final Value<String?> location;
  const SentencesCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.targetForm = const Value.absent(),
    this.sentenceEn = const Value.absent(),
    this.translationZh = const Value.absent(),
    this.source = const Value.absent(),
    this.location = const Value.absent(),
  });
  SentencesCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required String targetForm,
    required String sentenceEn,
    this.translationZh = const Value.absent(),
    this.source = const Value.absent(),
    this.location = const Value.absent(),
  }) : wordId = Value(wordId),
       targetForm = Value(targetForm),
       sentenceEn = Value(sentenceEn);
  static Insertable<Sentence> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? targetForm,
    Expression<String>? sentenceEn,
    Expression<String>? translationZh,
    Expression<String>? source,
    Expression<String>? location,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (targetForm != null) 'target_form': targetForm,
      if (sentenceEn != null) 'sentence_en': sentenceEn,
      if (translationZh != null) 'translation_zh': translationZh,
      if (source != null) 'source': source,
      if (location != null) 'location': location,
    });
  }

  SentencesCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<String>? targetForm,
    Value<String>? sentenceEn,
    Value<String?>? translationZh,
    Value<String?>? source,
    Value<String?>? location,
  }) {
    return SentencesCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      targetForm: targetForm ?? this.targetForm,
      sentenceEn: sentenceEn ?? this.sentenceEn,
      translationZh: translationZh ?? this.translationZh,
      source: source ?? this.source,
      location: location ?? this.location,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (targetForm.present) {
      map['target_form'] = Variable<String>(targetForm.value);
    }
    if (sentenceEn.present) {
      map['sentence_en'] = Variable<String>(sentenceEn.value);
    }
    if (translationZh.present) {
      map['translation_zh'] = Variable<String>(translationZh.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentencesCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('targetForm: $targetForm, ')
          ..write('sentenceEn: $sentenceEn, ')
          ..write('translationZh: $translationZh, ')
          ..write('source: $source, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }
}

class $ContentMetadataTable extends ContentMetadata
    with TableInfo<$ContentMetadataTable, ContentMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentMetadataTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('format_version > 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRepositoryMeta = const VerificationMeta(
    'sourceRepository',
  );
  @override
  late final GeneratedColumn<String> sourceRepository = GeneratedColumn<String>(
    'source_repository',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRevisionMeta = const VerificationMeta(
    'sourceRevision',
  );
  @override
  late final GeneratedColumn<String> sourceRevision = GeneratedColumn<String>(
    'source_revision',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> generatedAt =
      GeneratedColumn<int>(
        'generated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ContentMetadataTable.$convertergeneratedAt);
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('word_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceCountMeta = const VerificationMeta(
    'sentenceCount',
  );
  @override
  late final GeneratedColumn<int> sentenceCount = GeneratedColumn<int>(
    'sentence_count',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('sentence_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licenseNoticeMeta = const VerificationMeta(
    'licenseNotice',
  );
  @override
  late final GeneratedColumn<String> licenseNotice = GeneratedColumn<String>(
    'license_notice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contentVersion,
    formatVersion,
    sourceRepository,
    sourceRevision,
    generatedAt,
    wordCount,
    sentenceCount,
    licenseNotice,
    sha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatVersionMeta);
    }
    if (data.containsKey('source_repository')) {
      context.handle(
        _sourceRepositoryMeta,
        sourceRepository.isAcceptableOrUnknown(
          data['source_repository']!,
          _sourceRepositoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRepositoryMeta);
    }
    if (data.containsKey('source_revision')) {
      context.handle(
        _sourceRevisionMeta,
        sourceRevision.isAcceptableOrUnknown(
          data['source_revision']!,
          _sourceRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRevisionMeta);
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wordCountMeta);
    }
    if (data.containsKey('sentence_count')) {
      context.handle(
        _sentenceCountMeta,
        sentenceCount.isAcceptableOrUnknown(
          data['sentence_count']!,
          _sentenceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentenceCountMeta);
    }
    if (data.containsKey('license_notice')) {
      context.handle(
        _licenseNoticeMeta,
        licenseNotice.isAcceptableOrUnknown(
          data['license_notice']!,
          _licenseNoticeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_licenseNoticeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentMetadataEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      sourceRepository: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_repository'],
      )!,
      sourceRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_revision'],
      )!,
      generatedAt: $ContentMetadataTable.$convertergeneratedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}generated_at'],
        )!,
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      sentenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentence_count'],
      )!,
      licenseNotice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_notice'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
    );
  }

  @override
  $ContentMetadataTable createAlias(String alias) {
    return $ContentMetadataTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertergeneratedAt =
      const UtcDateTimeMillisecondsConverter();
}

class ContentMetadataEntry extends DataClass
    implements Insertable<ContentMetadataEntry> {
  final int id;
  final String contentVersion;
  final int formatVersion;
  final String sourceRepository;
  final String sourceRevision;
  final DateTime generatedAt;
  final int wordCount;
  final int sentenceCount;
  final String licenseNotice;
  final String sha256;
  const ContentMetadataEntry({
    required this.id,
    required this.contentVersion,
    required this.formatVersion,
    required this.sourceRepository,
    required this.sourceRevision,
    required this.generatedAt,
    required this.wordCount,
    required this.sentenceCount,
    required this.licenseNotice,
    required this.sha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content_version'] = Variable<String>(contentVersion);
    map['format_version'] = Variable<int>(formatVersion);
    map['source_repository'] = Variable<String>(sourceRepository);
    map['source_revision'] = Variable<String>(sourceRevision);
    {
      map['generated_at'] = Variable<int>(
        $ContentMetadataTable.$convertergeneratedAt.toSql(generatedAt),
      );
    }
    map['word_count'] = Variable<int>(wordCount);
    map['sentence_count'] = Variable<int>(sentenceCount);
    map['license_notice'] = Variable<String>(licenseNotice);
    map['sha256'] = Variable<String>(sha256);
    return map;
  }

  ContentMetadataCompanion toCompanion(bool nullToAbsent) {
    return ContentMetadataCompanion(
      id: Value(id),
      contentVersion: Value(contentVersion),
      formatVersion: Value(formatVersion),
      sourceRepository: Value(sourceRepository),
      sourceRevision: Value(sourceRevision),
      generatedAt: Value(generatedAt),
      wordCount: Value(wordCount),
      sentenceCount: Value(sentenceCount),
      licenseNotice: Value(licenseNotice),
      sha256: Value(sha256),
    );
  }

  factory ContentMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentMetadataEntry(
      id: serializer.fromJson<int>(json['id']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      sourceRepository: serializer.fromJson<String>(json['sourceRepository']),
      sourceRevision: serializer.fromJson<String>(json['sourceRevision']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      sentenceCount: serializer.fromJson<int>(json['sentenceCount']),
      licenseNotice: serializer.fromJson<String>(json['licenseNotice']),
      sha256: serializer.fromJson<String>(json['sha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'sourceRepository': serializer.toJson<String>(sourceRepository),
      'sourceRevision': serializer.toJson<String>(sourceRevision),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'wordCount': serializer.toJson<int>(wordCount),
      'sentenceCount': serializer.toJson<int>(sentenceCount),
      'licenseNotice': serializer.toJson<String>(licenseNotice),
      'sha256': serializer.toJson<String>(sha256),
    };
  }

  ContentMetadataEntry copyWith({
    int? id,
    String? contentVersion,
    int? formatVersion,
    String? sourceRepository,
    String? sourceRevision,
    DateTime? generatedAt,
    int? wordCount,
    int? sentenceCount,
    String? licenseNotice,
    String? sha256,
  }) => ContentMetadataEntry(
    id: id ?? this.id,
    contentVersion: contentVersion ?? this.contentVersion,
    formatVersion: formatVersion ?? this.formatVersion,
    sourceRepository: sourceRepository ?? this.sourceRepository,
    sourceRevision: sourceRevision ?? this.sourceRevision,
    generatedAt: generatedAt ?? this.generatedAt,
    wordCount: wordCount ?? this.wordCount,
    sentenceCount: sentenceCount ?? this.sentenceCount,
    licenseNotice: licenseNotice ?? this.licenseNotice,
    sha256: sha256 ?? this.sha256,
  );
  ContentMetadataEntry copyWithCompanion(ContentMetadataCompanion data) {
    return ContentMetadataEntry(
      id: data.id.present ? data.id.value : this.id,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      sourceRepository: data.sourceRepository.present
          ? data.sourceRepository.value
          : this.sourceRepository,
      sourceRevision: data.sourceRevision.present
          ? data.sourceRevision.value
          : this.sourceRevision,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      sentenceCount: data.sentenceCount.present
          ? data.sentenceCount.value
          : this.sentenceCount,
      licenseNotice: data.licenseNotice.present
          ? data.licenseNotice.value
          : this.licenseNotice,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentMetadataEntry(')
          ..write('id: $id, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('sourceRepository: $sourceRepository, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('wordCount: $wordCount, ')
          ..write('sentenceCount: $sentenceCount, ')
          ..write('licenseNotice: $licenseNotice, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentVersion,
    formatVersion,
    sourceRepository,
    sourceRevision,
    generatedAt,
    wordCount,
    sentenceCount,
    licenseNotice,
    sha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentMetadataEntry &&
          other.id == this.id &&
          other.contentVersion == this.contentVersion &&
          other.formatVersion == this.formatVersion &&
          other.sourceRepository == this.sourceRepository &&
          other.sourceRevision == this.sourceRevision &&
          other.generatedAt == this.generatedAt &&
          other.wordCount == this.wordCount &&
          other.sentenceCount == this.sentenceCount &&
          other.licenseNotice == this.licenseNotice &&
          other.sha256 == this.sha256);
}

class ContentMetadataCompanion extends UpdateCompanion<ContentMetadataEntry> {
  final Value<int> id;
  final Value<String> contentVersion;
  final Value<int> formatVersion;
  final Value<String> sourceRepository;
  final Value<String> sourceRevision;
  final Value<DateTime> generatedAt;
  final Value<int> wordCount;
  final Value<int> sentenceCount;
  final Value<String> licenseNotice;
  final Value<String> sha256;
  const ContentMetadataCompanion({
    this.id = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.sourceRepository = const Value.absent(),
    this.sourceRevision = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.sentenceCount = const Value.absent(),
    this.licenseNotice = const Value.absent(),
    this.sha256 = const Value.absent(),
  });
  ContentMetadataCompanion.insert({
    this.id = const Value.absent(),
    required String contentVersion,
    required int formatVersion,
    required String sourceRepository,
    required String sourceRevision,
    required DateTime generatedAt,
    required int wordCount,
    required int sentenceCount,
    required String licenseNotice,
    required String sha256,
  }) : contentVersion = Value(contentVersion),
       formatVersion = Value(formatVersion),
       sourceRepository = Value(sourceRepository),
       sourceRevision = Value(sourceRevision),
       generatedAt = Value(generatedAt),
       wordCount = Value(wordCount),
       sentenceCount = Value(sentenceCount),
       licenseNotice = Value(licenseNotice),
       sha256 = Value(sha256);
  static Insertable<ContentMetadataEntry> custom({
    Expression<int>? id,
    Expression<String>? contentVersion,
    Expression<int>? formatVersion,
    Expression<String>? sourceRepository,
    Expression<String>? sourceRevision,
    Expression<int>? generatedAt,
    Expression<int>? wordCount,
    Expression<int>? sentenceCount,
    Expression<String>? licenseNotice,
    Expression<String>? sha256,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentVersion != null) 'content_version': contentVersion,
      if (formatVersion != null) 'format_version': formatVersion,
      if (sourceRepository != null) 'source_repository': sourceRepository,
      if (sourceRevision != null) 'source_revision': sourceRevision,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (wordCount != null) 'word_count': wordCount,
      if (sentenceCount != null) 'sentence_count': sentenceCount,
      if (licenseNotice != null) 'license_notice': licenseNotice,
      if (sha256 != null) 'sha256': sha256,
    });
  }

  ContentMetadataCompanion copyWith({
    Value<int>? id,
    Value<String>? contentVersion,
    Value<int>? formatVersion,
    Value<String>? sourceRepository,
    Value<String>? sourceRevision,
    Value<DateTime>? generatedAt,
    Value<int>? wordCount,
    Value<int>? sentenceCount,
    Value<String>? licenseNotice,
    Value<String>? sha256,
  }) {
    return ContentMetadataCompanion(
      id: id ?? this.id,
      contentVersion: contentVersion ?? this.contentVersion,
      formatVersion: formatVersion ?? this.formatVersion,
      sourceRepository: sourceRepository ?? this.sourceRepository,
      sourceRevision: sourceRevision ?? this.sourceRevision,
      generatedAt: generatedAt ?? this.generatedAt,
      wordCount: wordCount ?? this.wordCount,
      sentenceCount: sentenceCount ?? this.sentenceCount,
      licenseNotice: licenseNotice ?? this.licenseNotice,
      sha256: sha256 ?? this.sha256,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (sourceRepository.present) {
      map['source_repository'] = Variable<String>(sourceRepository.value);
    }
    if (sourceRevision.present) {
      map['source_revision'] = Variable<String>(sourceRevision.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<int>(
        $ContentMetadataTable.$convertergeneratedAt.toSql(generatedAt.value),
      );
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (sentenceCount.present) {
      map['sentence_count'] = Variable<int>(sentenceCount.value);
    }
    if (licenseNotice.present) {
      map['license_notice'] = Variable<String>(licenseNotice.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentMetadataCompanion(')
          ..write('id: $id, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('sourceRepository: $sourceRepository, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('wordCount: $wordCount, ')
          ..write('sentenceCount: $sentenceCount, ')
          ..write('licenseNotice: $licenseNotice, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDatabase extends GeneratedDatabase {
  _$ContentDatabase(QueryExecutor e) : super(e);
  $ContentDatabaseManager get managers => $ContentDatabaseManager(this);
  late final $FrequencyGroupsTable frequencyGroups = $FrequencyGroupsTable(
    this,
  );
  late final $WordsTable words = $WordsTable(this);
  late final $SentencesTable sentences = $SentencesTable(this);
  late final $ContentMetadataTable contentMetadata = $ContentMetadataTable(
    this,
  );
  late final Index frequencyGroupsRank = Index(
    'frequency_groups_rank',
    'CREATE UNIQUE INDEX frequency_groups_rank ON frequency_groups (rank)',
  );
  late final Index wordsFrequencyGroupId = Index(
    'words_frequency_group_id',
    'CREATE INDEX words_frequency_group_id ON words (frequency_group_id)',
  );
  late final Index wordsFirstLetter = Index(
    'words_first_letter',
    'CREATE INDEX words_first_letter ON words (first_letter)',
  );
  late final Index wordsOccurrences = Index(
    'words_occurrences',
    'CREATE INDEX words_occurrences ON words (occurrences)',
  );
  late final Index sentencesWordId = Index(
    'sentences_word_id',
    'CREATE INDEX sentences_word_id ON sentences (word_id)',
  );
  late final ContentDao contentDao = ContentDao(this as ContentDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    frequencyGroups,
    words,
    sentences,
    contentMetadata,
    frequencyGroupsRank,
    wordsFrequencyGroupId,
    wordsFirstLetter,
    wordsOccurrences,
    sentencesWordId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sentences', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FrequencyGroupsTableCreateCompanionBuilder =
    FrequencyGroupsCompanion Function({
      Value<int> id,
      required String name,
      required int rank,
      required int minOccurrences,
      Value<int?> maxOccurrences,
    });
typedef $$FrequencyGroupsTableUpdateCompanionBuilder =
    FrequencyGroupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> rank,
      Value<int> minOccurrences,
      Value<int?> maxOccurrences,
    });

final class $$FrequencyGroupsTableReferences
    extends
        BaseReferences<
          _$ContentDatabase,
          $FrequencyGroupsTable,
          FrequencyGroup
        > {
  $$FrequencyGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$WordsTable, List<Word>> _wordsRefsTable(
    _$ContentDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.words,
    aliasName: 'frequency_groups__id__words__frequency_group_id',
  );

  $$WordsTableProcessedTableManager get wordsRefs {
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.frequencyGroupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FrequencyGroupsTableFilterComposer
    extends Composer<_$ContentDatabase, $FrequencyGroupsTable> {
  $$FrequencyGroupsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minOccurrences => $composableBuilder(
    column: $table.minOccurrences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxOccurrences => $composableBuilder(
    column: $table.maxOccurrences,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordsRefs(
    Expression<bool> Function($$WordsTableFilterComposer f) f,
  ) {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.frequencyGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FrequencyGroupsTableOrderingComposer
    extends Composer<_$ContentDatabase, $FrequencyGroupsTable> {
  $$FrequencyGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minOccurrences => $composableBuilder(
    column: $table.minOccurrences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxOccurrences => $composableBuilder(
    column: $table.maxOccurrences,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FrequencyGroupsTableAnnotationComposer
    extends Composer<_$ContentDatabase, $FrequencyGroupsTable> {
  $$FrequencyGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<int> get minOccurrences => $composableBuilder(
    column: $table.minOccurrences,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxOccurrences => $composableBuilder(
    column: $table.maxOccurrences,
    builder: (column) => column,
  );

  Expression<T> wordsRefs<T extends Object>(
    Expression<T> Function($$WordsTableAnnotationComposer a) f,
  ) {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.frequencyGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FrequencyGroupsTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $FrequencyGroupsTable,
          FrequencyGroup,
          $$FrequencyGroupsTableFilterComposer,
          $$FrequencyGroupsTableOrderingComposer,
          $$FrequencyGroupsTableAnnotationComposer,
          $$FrequencyGroupsTableCreateCompanionBuilder,
          $$FrequencyGroupsTableUpdateCompanionBuilder,
          (FrequencyGroup, $$FrequencyGroupsTableReferences),
          FrequencyGroup,
          PrefetchHooks Function({bool wordsRefs})
        > {
  $$FrequencyGroupsTableTableManager(
    _$ContentDatabase db,
    $FrequencyGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrequencyGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrequencyGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrequencyGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<int> minOccurrences = const Value.absent(),
                Value<int?> maxOccurrences = const Value.absent(),
              }) => FrequencyGroupsCompanion(
                id: id,
                name: name,
                rank: rank,
                minOccurrences: minOccurrences,
                maxOccurrences: maxOccurrences,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int rank,
                required int minOccurrences,
                Value<int?> maxOccurrences = const Value.absent(),
              }) => FrequencyGroupsCompanion.insert(
                id: id,
                name: name,
                rank: rank,
                minOccurrences: minOccurrences,
                maxOccurrences: maxOccurrences,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FrequencyGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wordsRefs) db.words],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordsRefs)
                    await $_getPrefetchedData<
                      FrequencyGroup,
                      $FrequencyGroupsTable,
                      Word
                    >(
                      currentTable: table,
                      referencedTable: $$FrequencyGroupsTableReferences
                          ._wordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FrequencyGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).wordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.frequencyGroupId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FrequencyGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $FrequencyGroupsTable,
      FrequencyGroup,
      $$FrequencyGroupsTableFilterComposer,
      $$FrequencyGroupsTableOrderingComposer,
      $$FrequencyGroupsTableAnnotationComposer,
      $$FrequencyGroupsTableCreateCompanionBuilder,
      $$FrequencyGroupsTableUpdateCompanionBuilder,
      (FrequencyGroup, $$FrequencyGroupsTableReferences),
      FrequencyGroup,
      PrefetchHooks Function({bool wordsRefs})
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required String word,
      Value<String?> phoneticUk,
      Value<String?> phoneticUs,
      Value<String?> translationZh,
      Value<String?> definitionEn,
      Value<String?> mnemonic,
      required int occurrences,
      required int frequencyGroupId,
      required String firstLetter,
      Value<String?> audioUkAsset,
      Value<String?> audioUsAsset,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String?> phoneticUk,
      Value<String?> phoneticUs,
      Value<String?> translationZh,
      Value<String?> definitionEn,
      Value<String?> mnemonic,
      Value<int> occurrences,
      Value<int> frequencyGroupId,
      Value<String> firstLetter,
      Value<String?> audioUkAsset,
      Value<String?> audioUsAsset,
    });

final class $$WordsTableReferences
    extends BaseReferences<_$ContentDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FrequencyGroupsTable _frequencyGroupIdTable(_$ContentDatabase db) =>
      db.frequencyGroups.createAlias(
        'words__frequency_group_id__frequency_groups__id',
      );

  $$FrequencyGroupsTableProcessedTableManager get frequencyGroupId {
    final $_column = $_itemColumn<int>('frequency_group_id')!;

    final manager = $$FrequencyGroupsTableTableManager(
      $_db,
      $_db.frequencyGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_frequencyGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SentencesTable, List<Sentence>>
  _sentencesRefsTable(_$ContentDatabase db) => MultiTypedResultKey.fromTable(
    db.sentences,
    aliasName: 'words__id__sentences__word_id',
  );

  $$SentencesTableProcessedTableManager get sentencesRefs {
    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sentencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer
    extends Composer<_$ContentDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneticUs => $composableBuilder(
    column: $table.phoneticUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationZh => $composableBuilder(
    column: $table.translationZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionEn => $composableBuilder(
    column: $table.definitionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mnemonic => $composableBuilder(
    column: $table.mnemonic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstLetter => $composableBuilder(
    column: $table.firstLetter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUkAsset => $composableBuilder(
    column: $table.audioUkAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUsAsset => $composableBuilder(
    column: $table.audioUsAsset,
    builder: (column) => ColumnFilters(column),
  );

  $$FrequencyGroupsTableFilterComposer get frequencyGroupId {
    final $$FrequencyGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.frequencyGroupId,
      referencedTable: $db.frequencyGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequencyGroupsTableFilterComposer(
            $db: $db,
            $table: $db.frequencyGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sentencesRefs(
    Expression<bool> Function($$SentencesTableFilterComposer f) f,
  ) {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$ContentDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneticUs => $composableBuilder(
    column: $table.phoneticUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationZh => $composableBuilder(
    column: $table.translationZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionEn => $composableBuilder(
    column: $table.definitionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mnemonic => $composableBuilder(
    column: $table.mnemonic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstLetter => $composableBuilder(
    column: $table.firstLetter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUkAsset => $composableBuilder(
    column: $table.audioUkAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUsAsset => $composableBuilder(
    column: $table.audioUsAsset,
    builder: (column) => ColumnOrderings(column),
  );

  $$FrequencyGroupsTableOrderingComposer get frequencyGroupId {
    final $$FrequencyGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.frequencyGroupId,
      referencedTable: $db.frequencyGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequencyGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.frequencyGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordsTableAnnotationComposer
    extends Composer<_$ContentDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneticUs => $composableBuilder(
    column: $table.phoneticUs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translationZh => $composableBuilder(
    column: $table.translationZh,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionEn => $composableBuilder(
    column: $table.definitionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mnemonic =>
      $composableBuilder(column: $table.mnemonic, builder: (column) => column);

  GeneratedColumn<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstLetter => $composableBuilder(
    column: $table.firstLetter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUkAsset => $composableBuilder(
    column: $table.audioUkAsset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUsAsset => $composableBuilder(
    column: $table.audioUsAsset,
    builder: (column) => column,
  );

  $$FrequencyGroupsTableAnnotationComposer get frequencyGroupId {
    final $$FrequencyGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.frequencyGroupId,
      referencedTable: $db.frequencyGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequencyGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.frequencyGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sentencesRefs<T extends Object>(
    Expression<T> Function($$SentencesTableAnnotationComposer a) f,
  ) {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({bool frequencyGroupId, bool sentencesRefs})
        > {
  $$WordsTableTableManager(_$ContentDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String?> phoneticUk = const Value.absent(),
                Value<String?> phoneticUs = const Value.absent(),
                Value<String?> translationZh = const Value.absent(),
                Value<String?> definitionEn = const Value.absent(),
                Value<String?> mnemonic = const Value.absent(),
                Value<int> occurrences = const Value.absent(),
                Value<int> frequencyGroupId = const Value.absent(),
                Value<String> firstLetter = const Value.absent(),
                Value<String?> audioUkAsset = const Value.absent(),
                Value<String?> audioUsAsset = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                word: word,
                phoneticUk: phoneticUk,
                phoneticUs: phoneticUs,
                translationZh: translationZh,
                definitionEn: definitionEn,
                mnemonic: mnemonic,
                occurrences: occurrences,
                frequencyGroupId: frequencyGroupId,
                firstLetter: firstLetter,
                audioUkAsset: audioUkAsset,
                audioUsAsset: audioUsAsset,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                Value<String?> phoneticUk = const Value.absent(),
                Value<String?> phoneticUs = const Value.absent(),
                Value<String?> translationZh = const Value.absent(),
                Value<String?> definitionEn = const Value.absent(),
                Value<String?> mnemonic = const Value.absent(),
                required int occurrences,
                required int frequencyGroupId,
                required String firstLetter,
                Value<String?> audioUkAsset = const Value.absent(),
                Value<String?> audioUsAsset = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                word: word,
                phoneticUk: phoneticUk,
                phoneticUs: phoneticUs,
                translationZh: translationZh,
                definitionEn: definitionEn,
                mnemonic: mnemonic,
                occurrences: occurrences,
                frequencyGroupId: frequencyGroupId,
                firstLetter: firstLetter,
                audioUkAsset: audioUkAsset,
                audioUsAsset: audioUsAsset,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WordsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({frequencyGroupId = false, sentencesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (sentencesRefs) db.sentences],
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
                        if (frequencyGroupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.frequencyGroupId,
                                    referencedTable: $$WordsTableReferences
                                        ._frequencyGroupIdTable(db),
                                    referencedColumn: $$WordsTableReferences
                                        ._frequencyGroupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sentencesRefs)
                        await $_getPrefetchedData<Word, $WordsTable, Sentence>(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._sentencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).sentencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({bool frequencyGroupId, bool sentencesRefs})
    >;
typedef $$SentencesTableCreateCompanionBuilder =
    SentencesCompanion Function({
      Value<int> id,
      required int wordId,
      required String targetForm,
      required String sentenceEn,
      Value<String?> translationZh,
      Value<String?> source,
      Value<String?> location,
    });
typedef $$SentencesTableUpdateCompanionBuilder =
    SentencesCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<String> targetForm,
      Value<String> sentenceEn,
      Value<String?> translationZh,
      Value<String?> source,
      Value<String?> location,
    });

final class $$SentencesTableReferences
    extends BaseReferences<_$ContentDatabase, $SentencesTable, Sentence> {
  $$SentencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$ContentDatabase db) =>
      db.words.createAlias('sentences__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SentencesTableFilterComposer
    extends Composer<_$ContentDatabase, $SentencesTable> {
  $$SentencesTableFilterComposer({
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

  ColumnFilters<String> get targetForm => $composableBuilder(
    column: $table.targetForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentenceEn => $composableBuilder(
    column: $table.sentenceEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationZh => $composableBuilder(
    column: $table.translationZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableOrderingComposer
    extends Composer<_$ContentDatabase, $SentencesTable> {
  $$SentencesTableOrderingComposer({
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

  ColumnOrderings<String> get targetForm => $composableBuilder(
    column: $table.targetForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentenceEn => $composableBuilder(
    column: $table.sentenceEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationZh => $composableBuilder(
    column: $table.translationZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableAnnotationComposer
    extends Composer<_$ContentDatabase, $SentencesTable> {
  $$SentencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetForm => $composableBuilder(
    column: $table.targetForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sentenceEn => $composableBuilder(
    column: $table.sentenceEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translationZh => $composableBuilder(
    column: $table.translationZh,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $SentencesTable,
          Sentence,
          $$SentencesTableFilterComposer,
          $$SentencesTableOrderingComposer,
          $$SentencesTableAnnotationComposer,
          $$SentencesTableCreateCompanionBuilder,
          $$SentencesTableUpdateCompanionBuilder,
          (Sentence, $$SentencesTableReferences),
          Sentence,
          PrefetchHooks Function({bool wordId})
        > {
  $$SentencesTableTableManager(_$ContentDatabase db, $SentencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SentencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> targetForm = const Value.absent(),
                Value<String> sentenceEn = const Value.absent(),
                Value<String?> translationZh = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> location = const Value.absent(),
              }) => SentencesCompanion(
                id: id,
                wordId: wordId,
                targetForm: targetForm,
                sentenceEn: sentenceEn,
                translationZh: translationZh,
                source: source,
                location: location,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required String targetForm,
                required String sentenceEn,
                Value<String?> translationZh = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> location = const Value.absent(),
              }) => SentencesCompanion.insert(
                id: id,
                wordId: wordId,
                targetForm: targetForm,
                sentenceEn: sentenceEn,
                translationZh: translationZh,
                source: source,
                location: location,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SentencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
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
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$SentencesTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$SentencesTableReferences
                                    ._wordIdTable(db)
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

typedef $$SentencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $SentencesTable,
      Sentence,
      $$SentencesTableFilterComposer,
      $$SentencesTableOrderingComposer,
      $$SentencesTableAnnotationComposer,
      $$SentencesTableCreateCompanionBuilder,
      $$SentencesTableUpdateCompanionBuilder,
      (Sentence, $$SentencesTableReferences),
      Sentence,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$ContentMetadataTableCreateCompanionBuilder =
    ContentMetadataCompanion Function({
      Value<int> id,
      required String contentVersion,
      required int formatVersion,
      required String sourceRepository,
      required String sourceRevision,
      required DateTime generatedAt,
      required int wordCount,
      required int sentenceCount,
      required String licenseNotice,
      required String sha256,
    });
typedef $$ContentMetadataTableUpdateCompanionBuilder =
    ContentMetadataCompanion Function({
      Value<int> id,
      Value<String> contentVersion,
      Value<int> formatVersion,
      Value<String> sourceRepository,
      Value<String> sourceRevision,
      Value<DateTime> generatedAt,
      Value<int> wordCount,
      Value<int> sentenceCount,
      Value<String> licenseNotice,
      Value<String> sha256,
    });

class $$ContentMetadataTableFilterComposer
    extends Composer<_$ContentDatabase, $ContentMetadataTable> {
  $$ContentMetadataTableFilterComposer({
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

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRepository => $composableBuilder(
    column: $table.sourceRepository,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get generatedAt =>
      $composableBuilder(
        column: $table.generatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentenceCount => $composableBuilder(
    column: $table.sentenceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licenseNotice => $composableBuilder(
    column: $table.licenseNotice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentMetadataTableOrderingComposer
    extends Composer<_$ContentDatabase, $ContentMetadataTable> {
  $$ContentMetadataTableOrderingComposer({
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

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRepository => $composableBuilder(
    column: $table.sourceRepository,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentenceCount => $composableBuilder(
    column: $table.sentenceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licenseNotice => $composableBuilder(
    column: $table.licenseNotice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentMetadataTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ContentMetadataTable> {
  $$ContentMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRepository => $composableBuilder(
    column: $table.sourceRepository,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get generatedAt =>
      $composableBuilder(
        column: $table.generatedAt,
        builder: (column) => column,
      );

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<int> get sentenceCount => $composableBuilder(
    column: $table.sentenceCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get licenseNotice => $composableBuilder(
    column: $table.licenseNotice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);
}

class $$ContentMetadataTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ContentMetadataTable,
          ContentMetadataEntry,
          $$ContentMetadataTableFilterComposer,
          $$ContentMetadataTableOrderingComposer,
          $$ContentMetadataTableAnnotationComposer,
          $$ContentMetadataTableCreateCompanionBuilder,
          $$ContentMetadataTableUpdateCompanionBuilder,
          (
            ContentMetadataEntry,
            BaseReferences<
              _$ContentDatabase,
              $ContentMetadataTable,
              ContentMetadataEntry
            >,
          ),
          ContentMetadataEntry,
          PrefetchHooks Function()
        > {
  $$ContentMetadataTableTableManager(
    _$ContentDatabase db,
    $ContentMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<String> sourceRepository = const Value.absent(),
                Value<String> sourceRevision = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<int> sentenceCount = const Value.absent(),
                Value<String> licenseNotice = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
              }) => ContentMetadataCompanion(
                id: id,
                contentVersion: contentVersion,
                formatVersion: formatVersion,
                sourceRepository: sourceRepository,
                sourceRevision: sourceRevision,
                generatedAt: generatedAt,
                wordCount: wordCount,
                sentenceCount: sentenceCount,
                licenseNotice: licenseNotice,
                sha256: sha256,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contentVersion,
                required int formatVersion,
                required String sourceRepository,
                required String sourceRevision,
                required DateTime generatedAt,
                required int wordCount,
                required int sentenceCount,
                required String licenseNotice,
                required String sha256,
              }) => ContentMetadataCompanion.insert(
                id: id,
                contentVersion: contentVersion,
                formatVersion: formatVersion,
                sourceRepository: sourceRepository,
                sourceRevision: sourceRevision,
                generatedAt: generatedAt,
                wordCount: wordCount,
                sentenceCount: sentenceCount,
                licenseNotice: licenseNotice,
                sha256: sha256,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ContentMetadataTable,
      ContentMetadataEntry,
      $$ContentMetadataTableFilterComposer,
      $$ContentMetadataTableOrderingComposer,
      $$ContentMetadataTableAnnotationComposer,
      $$ContentMetadataTableCreateCompanionBuilder,
      $$ContentMetadataTableUpdateCompanionBuilder,
      (
        ContentMetadataEntry,
        BaseReferences<
          _$ContentDatabase,
          $ContentMetadataTable,
          ContentMetadataEntry
        >,
      ),
      ContentMetadataEntry,
      PrefetchHooks Function()
    >;

class $ContentDatabaseManager {
  final _$ContentDatabase _db;
  $ContentDatabaseManager(this._db);
  $$FrequencyGroupsTableTableManager get frequencyGroups =>
      $$FrequencyGroupsTableTableManager(_db, _db.frequencyGroups);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$SentencesTableTableManager get sentences =>
      $$SentencesTableTableManager(_db, _db.sentences);
  $$ContentMetadataTableTableManager get contentMetadata =>
      $$ContentMetadataTableTableManager(_db, _db.contentMetadata);
}
