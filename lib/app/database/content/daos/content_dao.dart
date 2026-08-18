import 'package:drift/drift.dart';

import '../../../models/domain/question_config.dart';
import '../../../models/domain/word_filter.dart';
import '../content_database.dart';
import '../tables/content_metadata.dart';
import '../tables/frequency_groups.dart';
import '../tables/sentences.dart';
import '../tables/words.dart';

part 'content_dao.g.dart';

/// 封装只读词库查询，页面和 Logic 不直接访问 Drift。
@DriftAccessor(tables: [FrequencyGroups, Words, Sentences, ContentMetadata])
class ContentDao extends DatabaseAccessor<ContentDatabase>
    with _$ContentDaoMixin {
  ContentDao(super.attachedDatabase);

  static const int maxQuestionCandidateLimit = 500;
  static const int maxQuestionFilterIdCount = 900;

  /// 统计数据库字段层面满足题型和词频范围的候选单词。
  Future<int> countQuestionWords(QuestionConfig config) async {
    final parts = _questionWhereParts(
      config,
      includedWordIds: config.isTargeted ? config.targetWordIds : null,
    );
    final row = await customSelect(
      'SELECT COUNT(*) AS candidate_count FROM words AS w '
      'WHERE ${parts.clauses.join(' AND ')}',
      variables: parts.variables,
      readsFrom: {words, sentences},
    ).getSingle();
    return row.read<int>('candidate_count');
  }

  /// 使用可复现的数据库侧顺序读取受限候选池，不把完整词库加载到 Dart。
  Future<List<Word>> findQuestionWords({
    required QuestionConfig config,
    required int limit,
    required int orderSeed,
    Set<int>? includedWordIds,
    Set<int> excludedWordIds = const {},
  }) {
    _validateQuestionQuery(
      limit: limit,
      orderSeed: orderSeed,
      includedWordIds: includedWordIds,
      excludedWordIds: excludedWordIds,
    );
    if (includedWordIds != null && includedWordIds.isEmpty) {
      return Future.value(const <Word>[]);
    }
    final parts = _questionWhereParts(
      config,
      includedWordIds: includedWordIds,
      excludedWordIds: excludedWordIds,
    );
    final variables = <Variable>[
      ...parts.variables,
      Variable<int>(orderSeed),
      Variable<int>(limit),
    ];
    return customSelect(
      '''
        SELECT w.*
        FROM words AS w
        WHERE ${parts.clauses.join(' AND ')}
        ORDER BY (((w.id * 1103515245) + ?) & 2147483647), w.id
        LIMIT ?
      ''',
      variables: variables,
      readsFrom: {words, sentences},
    ).map((row) => words.map(row.data)).get();
  }

  /// 一次查询候选池关联例句，避免按题目逐条访问数据库。
  Future<List<Sentence>> findSentencesByWordIds(Set<int> wordIds) {
    if (wordIds.isEmpty) {
      return Future.value(const <Sentence>[]);
    }
    if (wordIds.length > maxQuestionCandidateLimit ||
        wordIds.any((wordId) => wordId <= 0)) {
      throw ArgumentError.value(wordIds, 'wordIds', '候选单词 ID 集合无效');
    }
    final query = select(sentences)
      ..where((row) => row.wordId.isIn(wordIds))
      ..orderBy([
        (row) => OrderingTerm.asc(row.wordId),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.get();
  }

  /// 返回 rank 1-6 的有效词频组，预留的第 7 组不会进入业务查询。
  Future<List<FrequencyGroup>> findActiveFrequencyGroups() {
    final query = select(frequencyGroups)
      ..where((row) => row.rank.isBetweenValues(1, 6))
      ..orderBy([(row) => OrderingTerm.asc(row.rank)]);
    return query.get();
  }

  /// 按组合条件分页查询单词；关键词通过 FTS5 参数查询，不拼接外部输入。
  Future<List<Word>> findWords(WordFilter filter, {int lookahead = 0}) {
    if (lookahead < 0 || lookahead > 1) {
      throw ArgumentError.value(lookahead, 'lookahead', '分页前瞻只能为 0 或 1');
    }
    final queryLimit = filter.pageSize + lookahead;
    if (filter.keyword != null) {
      return _findWordsWithSearchIndex(filter, limit: queryLimit);
    }

    final query = select(words);

    if (filter.frequencyGroupIds.isNotEmpty) {
      query.where((row) => row.frequencyGroupId.isIn(filter.frequencyGroupIds));
    }
    final firstLetter = filter.firstLetter;
    if (firstLetter != null) {
      query.where((row) => row.firstLetter.equals(firstLetter));
    }
    query
      ..orderBy(_orderBy(filter.sortOrder))
      ..limit(queryLimit, offset: filter.offset);
    return query.get();
  }

  /// 使用与词库列表相同的组合条件统计匹配数量。
  Future<int> countWords(WordFilter filter) {
    final clauses = <String>[];
    final variables = <Variable>[];
    var from = 'words AS w';
    if (filter.keyword != null) {
      from = 'words AS w INNER JOIN word_search ON word_search.rowid = w.id';
      clauses.add('word_search MATCH ?');
      variables.add(Variable<String>(_toFtsQuery(filter.keyword!)));
    }
    if (filter.frequencyGroupIds.isNotEmpty) {
      final groupIds = filter.frequencyGroupIds.toList()..sort();
      clauses.add(
        'w.frequency_group_id IN (${List.filled(groupIds.length, '?').join(', ')})',
      );
      variables.addAll(groupIds.map(Variable<int>.new));
    }
    if (filter.firstLetter != null) {
      clauses.add('w.first_letter = ?');
      variables.add(Variable<String>(filter.firstLetter!));
    }
    final where = clauses.isEmpty ? '' : ' WHERE ${clauses.join(' AND ')}';
    return customSelect(
      'SELECT COUNT(*) AS word_count FROM $from$where',
      variables: variables,
      readsFrom: {words},
    ).getSingle().then((row) => row.read<int>('word_count'));
  }

  /// 查询单词详情所需的词条。
  Future<Word?> findWordById(int wordId) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    return (select(
      words,
    )..where((row) => row.id.equals(wordId))).getSingleOrNull();
  }

  /// 按受限稳定 ID 集合批量读取复习队列单词，保持数据库查询边界。
  Future<List<Word>> findWordsByIds(Set<int> wordIds) {
    if (wordIds.length > ContentDao.maxQuestionCandidateLimit ||
        wordIds.any((wordId) => wordId <= 0)) {
      throw ArgumentError.value(wordIds, 'wordIds', '单词 ID 集合无效');
    }
    if (wordIds.isEmpty) {
      return Future.value(const <Word>[]);
    }
    final query = select(words)
      ..where((row) => row.id.isIn(wordIds))
      ..orderBy([
        (row) => OrderingTerm.desc(row.occurrences),
        (row) => OrderingTerm.asc(row.word),
      ]);
    return query.get();
  }

  /// 统计指定词频组中可用于随机学习的单词数量。
  Future<int> countStudyWords(Set<int> frequencyGroupIds) {
    _validateStudyGroupIds(frequencyGroupIds);
    if (frequencyGroupIds.isEmpty) {
      return Future.value(0);
    }
    final ids = frequencyGroupIds.toList()..sort();
    return customSelect(
      'SELECT COUNT(*) AS word_count FROM words '
      'WHERE frequency_group_id IN (${List.filled(ids.length, '?').join(', ')})',
      variables: ids.map(Variable<int>.new).toList(growable: false),
      readsFrom: {words},
    ).getSingle().then((row) => row.read<int>('word_count'));
  }

  /// 按固定种子生成数据库侧随机顺序，返回不重复的学习单词。
  Future<List<Word>> findRandomStudyWords({
    required Set<int> frequencyGroupIds,
    required int limit,
    required int orderSeed,
  }) {
    _validateStudyGroupIds(frequencyGroupIds);
    if (frequencyGroupIds.isEmpty) {
      return Future.value(const <Word>[]);
    }
    if (limit <= 0 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', '随机学习数量必须在 1-100 之间');
    }
    if (orderSeed < 0 || orderSeed >= (1 << 30)) {
      throw ArgumentError.value(orderSeed, 'orderSeed', '随机排序种子超出范围');
    }
    final ids = frequencyGroupIds.toList()..sort();
    final variables = <Variable<int>>[
      ...ids.map(Variable<int>.new),
      Variable<int>(orderSeed),
      Variable<int>(limit),
    ];
    return customSelect(
      '''
        SELECT w.*
        FROM words AS w
        WHERE w.frequency_group_id IN (${List.filled(ids.length, '?').join(', ')})
        ORDER BY (((w.id * 1103515245) + ?) & 2147483647), w.id
        LIMIT ?
      ''',
      variables: variables,
      readsFrom: {words},
    ).map((row) => words.map(row.data)).get();
  }

  /// 按稳定单词 ID 返回关联例句。
  Future<List<Sentence>> findSentencesByWordId(int wordId) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    final query = select(sentences)
      ..where((row) => row.wordId.equals(wordId))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    return query.get();
  }

  /// 按稳定例句 ID 查询单条例句，供收藏和导入边界校验使用。
  Future<Sentence?> findSentenceById(int sentenceId) {
    if (sentenceId <= 0) {
      throw ArgumentError.value(sentenceId, 'sentenceId', '例句 ID 必须为正整数');
    }
    return (select(
      sentences,
    )..where((row) => row.id.equals(sentenceId))).getSingleOrNull();
  }

  /// 在受限 ID 集合内批量读取例句，供收藏和备份导入校验使用。
  Future<List<Sentence>> findSentencesByIds(Set<int> sentenceIds) {
    if (sentenceIds.length > maxQuestionCandidateLimit ||
        sentenceIds.any((sentenceId) => sentenceId <= 0)) {
      throw ArgumentError.value(sentenceIds, 'sentenceIds', '例句 ID 集合无效');
    }
    if (sentenceIds.isEmpty) {
      return Future.value(const <Sentence>[]);
    }
    final query = select(sentences)
      ..where((row) => row.id.isIn(sentenceIds))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    return query.get();
  }

  /// 返回当前词库唯一的元数据记录。
  Future<ContentMetadataEntry?> findMetadata() {
    return (select(
      contentMetadata,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
  }

  _QuestionWhereParts _questionWhereParts(
    QuestionConfig config, {
    Set<int>? includedWordIds,
    Set<int> excludedWordIds = const {},
  }) {
    final groupIds = config.effectiveFrequencyGroupIds.toList()..sort();
    final clauses = <String>[
      'w.frequency_group_id IN (${List.filled(groupIds.length, '?').join(', ')})',
      _questionEligibilityClause(config),
    ];
    final variables = <Variable>[...groupIds.map(Variable<int>.new)];
    if (includedWordIds != null) {
      final ids = includedWordIds.toList()..sort();
      clauses.add('w.id IN (${List.filled(ids.length, '?').join(', ')})');
      variables.addAll(ids.map(Variable<int>.new));
    }
    if (excludedWordIds.isNotEmpty) {
      final ids = excludedWordIds.toList()..sort();
      clauses.add('w.id NOT IN (${List.filled(ids.length, '?').join(', ')})');
      variables.addAll(ids.map(Variable<int>.new));
    }
    return _QuestionWhereParts(clauses: clauses, variables: variables);
  }

  String _questionEligibilityClause(QuestionConfig config) {
    const hasTranslation = "TRIM(COALESCE(w.translation_zh, '')) <> ''";
    const hasSentence =
        'EXISTS (SELECT 1 FROM sentences AS s WHERE s.word_id = w.id)';
    return switch (config.type) {
      QuestionType.choiceEnglishToChinese ||
      QuestionType.choiceChineseToEnglish => hasTranslation,
      QuestionType.choiceWordToSentence || QuestionType.cloze => hasSentence,
      QuestionType.spelling => switch (config.spellingPromptType!) {
        SpellingPromptType.translation => hasTranslation,
        SpellingPromptType.definition =>
          "TRIM(COALESCE(w.definition_en, '')) <> ''",
        SpellingPromptType.phonetic =>
          "(TRIM(COALESCE(w.phonetic_uk, '')) <> '' OR "
              "TRIM(COALESCE(w.phonetic_us, '')) <> '')",
        SpellingPromptType.audio =>
          "(TRIM(COALESCE(w.audio_uk_asset, '')) <> '' OR "
              "TRIM(COALESCE(w.audio_us_asset, '')) <> '')",
      },
    };
  }

  void _validateQuestionQuery({
    required int limit,
    required int orderSeed,
    required Set<int>? includedWordIds,
    required Set<int> excludedWordIds,
  }) {
    if (limit <= 0 || limit > maxQuestionCandidateLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        '候选查询数量必须在 1-$maxQuestionCandidateLimit 之间',
      );
    }
    if (orderSeed < 0 || orderSeed >= (1 << 30)) {
      throw ArgumentError.value(orderSeed, 'orderSeed', '候选排序种子超出范围');
    }
    final includedCount = includedWordIds?.length ?? 0;
    if (includedCount + excludedWordIds.length > maxQuestionFilterIdCount ||
        includedWordIds?.any((id) => id <= 0) == true ||
        excludedWordIds.any((id) => id <= 0)) {
      throw ArgumentError('候选查询的单词 ID 集合无效');
    }
  }

  void _validateStudyGroupIds(Set<int> groupIds) {
    if (groupIds.length > 6 ||
        groupIds.any((groupId) => groupId < 1 || groupId > 6)) {
      throw ArgumentError.value(groupIds, 'frequencyGroupIds', '学习词频组必须属于 1-6');
    }
  }

  Future<List<Word>> _findWordsWithSearchIndex(
    WordFilter filter, {
    required int limit,
  }) {
    final clauses = <String>['word_search MATCH ?'];
    final variables = <Variable>[
      Variable<String>(_toFtsQuery(filter.keyword!)),
    ];

    if (filter.frequencyGroupIds.isNotEmpty) {
      final groupIds = filter.frequencyGroupIds.toList()..sort();
      clauses.add(
        'w.frequency_group_id IN (${List.filled(groupIds.length, '?').join(', ')})',
      );
      variables.addAll(groupIds.map(Variable<int>.new));
    }
    final firstLetter = filter.firstLetter;
    if (firstLetter != null) {
      clauses.add('w.first_letter = ?');
      variables.add(Variable<String>(firstLetter));
    }
    variables
      ..add(Variable<int>(limit))
      ..add(Variable<int>(filter.offset));

    final statement =
        '''
      SELECT w.*
      FROM words AS w
      INNER JOIN word_search ON word_search.rowid = w.id
      WHERE ${clauses.join(' AND ')}
      ORDER BY ${_sqlOrderBy(filter.sortOrder)}
      LIMIT ? OFFSET ?
    ''';
    return customSelect(
      statement,
      variables: variables,
      readsFrom: {words},
    ).map((row) => words.map(row.data)).get();
  }

  String _toFtsQuery(String keyword) {
    return keyword
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .map((token) => '"${token.replaceAll('"', '""')}"*')
        .join(' AND ');
  }

  String _sqlOrderBy(WordSortOrder sortOrder) {
    return switch (sortOrder) {
      WordSortOrder.frequencyDescending => 'w.occurrences DESC, w.word ASC',
      WordSortOrder.frequencyAscending => 'w.occurrences ASC, w.word ASC',
      WordSortOrder.alphabetAscending => 'w.word ASC',
      WordSortOrder.alphabetDescending => 'w.word DESC',
    };
  }

  List<OrderClauseGenerator<$WordsTable>> _orderBy(WordSortOrder sortOrder) {
    return switch (sortOrder) {
      WordSortOrder.frequencyDescending => [
        (row) => OrderingTerm.desc(row.occurrences),
        (row) => OrderingTerm.asc(row.word),
      ],
      WordSortOrder.frequencyAscending => [
        (row) => OrderingTerm.asc(row.occurrences),
        (row) => OrderingTerm.asc(row.word),
      ],
      WordSortOrder.alphabetAscending => [(row) => OrderingTerm.asc(row.word)],
      WordSortOrder.alphabetDescending => [
        (row) => OrderingTerm.desc(row.word),
      ],
    };
  }
}

final class _QuestionWhereParts {
  const _QuestionWhereParts({required this.clauses, required this.variables});

  final List<String> clauses;
  final List<Variable> variables;
}
