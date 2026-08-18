import 'content_build_config.dart';
import 'content_build_exception.dart';
import 'content_build_report.dart';
import 'source_models.dart';

typedef _AddValidationIssue =
    void Function(
      String code,
      String message, {
      String? sourceFile,
      Map<String, Object>? details,
    });

/// 执行跨文件统计、稳定 ID、外键、词频区间和目标词形校验。
final class ContentSourceValidator {
  const ContentSourceValidator();

  static const int maxReportedIssues = 200;
  static const int minActiveGroupRank = 1;
  static const int maxActiveGroupRank = 6;
  static const int reservedGroupRank = 7;
  static const int maxWordLength = 200;

  ValidatedContent validate(
    ImportedContent imported,
    ContentBuildConfig config,
  ) {
    final issues = <ContentBuildIssue>[];
    final issueCounts = <String, int>{};
    final warnings = <ContentBuildIssue>[];
    final warningCounts = <String, int>{};
    void addIssue(
      String code,
      String message, {
      String? sourceFile,
      Map<String, Object>? details,
    }) {
      final isWarning = config.sourceIssuePolicy.acceptsAsWarning(code);
      final counts = isWarning ? warningCounts : issueCounts;
      final target = isWarning ? warnings : issues;
      counts.update(code, (count) => count + 1, ifAbsent: () => 1);
      if (target.length < maxReportedIssues) {
        target.add(
          ContentBuildIssue(
            code: code,
            message: message,
            sourceFile: sourceFile,
            details: details ?? const <String, Object>{},
          ),
        );
      }
    }

    final expectedSourceHash = config.expectedSourceDataSha256;
    if (expectedSourceHash != null &&
        imported.sourceDataSha256 != expectedSourceHash) {
      addIssue(
        'source_data_checksum_mismatch',
        '来源数据 SHA-256 与冻结基线不一致',
        details: {
          'expected': expectedSourceHash,
          'actual': imported.sourceDataSha256,
        },
      );
    }

    _validateStatsAndGroups(imported, config, addIssue);

    var duplicateWordsRemoved = 0;
    final wordsById = <int, SourceWord>{};
    final wordIdsByNormalizedWord = <String, int>{};
    for (final word in imported.words) {
      final existingById = wordsById[word.id];
      if (existingById != null) {
        if (existingById.equalityKey == word.equalityKey) {
          duplicateWordsRemoved++;
        } else {
          addIssue('conflicting_word_id', '单词 ID ${word.id} 对应多条不同记录');
        }
        continue;
      }
      final normalizedWord = word.word.toLowerCase();
      final existingWordId = wordIdsByNormalizedWord[normalizedWord];
      if (existingWordId != null) {
        addIssue(
          'duplicate_word',
          '单词 ${word.word} 同时使用 ID $existingWordId 和 ${word.id}',
        );
        continue;
      }
      wordsById[word.id] = word;
      wordIdsByNormalizedWord[normalizedWord] = word.id;
    }

    final groupsById = {for (final group in imported.groups) group.id: group};
    final groupWordCounts = <int, int>{
      for (var rank = minActiveGroupRank; rank <= maxActiveGroupRank; rank++)
        rank: 0,
    };
    for (final word in wordsById.values) {
      _validateWord(word, groupsById, config, addIssue);
      final group = groupsById[word.groupId];
      if (group != null &&
          group.rank >= minActiveGroupRank &&
          group.rank <= maxActiveGroupRank) {
        groupWordCounts[group.rank] = groupWordCounts[group.rank]! + 1;
      }
    }
    _validateAudioAssets(wordsById, config, addIssue);

    var duplicateSentencesRemoved = 0;
    final sentencesById = <int, SourceSentence>{};
    final sentenceIdsByContent = <Object, int>{};
    for (final sentence in imported.sentences) {
      final existingById = sentencesById[sentence.id];
      if (existingById != null) {
        if (existingById.equalityKey == sentence.equalityKey) {
          duplicateSentencesRemoved++;
        } else {
          addIssue('conflicting_sentence_id', '例句 ID ${sentence.id} 对应多条不同记录');
        }
        continue;
      }
      final contentKey = sentence.contentEqualityKey;
      final existingSentenceId = sentenceIdsByContent[contentKey];
      if (existingSentenceId != null) {
        duplicateSentencesRemoved++;
        continue;
      }
      sentencesById[sentence.id] = sentence;
      sentenceIdsByContent[contentKey] = sentence.id;
    }

    final actualSentenceCounts = <int, int>{};
    for (final sentence in sentencesById.values) {
      _validateSentence(sentence, wordsById, addIssue);
      actualSentenceCounts.update(
        sentence.wordId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    for (final word in wordsById.values) {
      final actualCount = actualSentenceCounts[word.id] ?? 0;
      if (word.sentenceCount != actualCount) {
        addIssue(
          'word_sentence_count_mismatch',
          '单词 ID ${word.id} 声明 ${word.sentenceCount} 条例句，实际为 $actualCount 条',
        );
      }
    }

    _validateCounts(
      imported,
      config,
      wordsById.length,
      sentencesById.length,
      groupWordCounts,
      addIssue,
    );

    if (config.sourceIssuePolicy ==
            ContentSourceIssuePolicy.preserveKnownSourceInconsistencies &&
        !_sameCountMap(warningCounts, config.expectedSourceWarningCounts)) {
      addIssue(
        'source_warning_set_mismatch',
        '来源警告集合与冻结基线不一致',
        details: {
          'expected': Map<String, int>.from(config.expectedSourceWarningCounts),
          'actual': Map<String, int>.from(warningCounts),
        },
      );
    }

    final totalIssueCount = issueCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    if (totalIssueCount > issues.length) {
      issues.add(
        ContentBuildIssue(
          code: 'issue_limit_reached',
          message: '共发现 $totalIssueCount 个问题，仅保留前 $maxReportedIssues 条明细',
        ),
      );
    }
    if (issues.isNotEmpty) {
      throw ContentValidationException(issues, issueCounts: issueCounts);
    }

    final words = wordsById.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final sentences = sentencesById.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return ValidatedContent(
      groups: List.unmodifiable(
        imported.groups.toList()..sort((a, b) => a.rank.compareTo(b.rank)),
      ),
      words: List.unmodifiable(words),
      sentences: List.unmodifiable(sentences),
      audioAssets: Map.unmodifiable(config.audioAssets.entries),
      sourceDataSha256: imported.sourceDataSha256,
      report: ContentBuildReport(
        wordCount: words.length,
        sentenceCount: sentences.length,
        groupWordCounts: Map.unmodifiable(groupWordCounts),
        duplicateWordsRemoved: duplicateWordsRemoved,
        duplicateSentencesRemoved: duplicateSentencesRemoved,
        missingTranslations: words
            .where((word) => word.translation == null)
            .length,
        missingEnglishDefinitions: words
            .where((word) => word.englishDefinition == null)
            .length,
        missingPhonetics: words.where((word) => word.phonetic == null).length,
        remoteAudioReferencesIgnored: words.fold(
          0,
          (count, word) =>
              count +
              (word.audioUk == null ? 0 : 1) +
              (word.audioUs == null ? 0 : 1),
        ),
        localAudioReferences: config.audioAssets.entries.values.fold(
          0,
          (count, audio) =>
              count + (audio.uk == null ? 0 : 1) + (audio.us == null ? 0 : 1),
        ),
        sourceWarningCounts: Map.unmodifiable(warningCounts),
        sourceWarnings: List.unmodifiable(warnings),
      ),
    );
  }

  void _validateAudioAssets(
    Map<int, SourceWord> wordsById,
    ContentBuildConfig config,
    _AddValidationIssue addIssue,
  ) {
    for (final entry in config.audioAssets.entries.entries) {
      if (wordsById.containsKey(entry.key)) {
        continue;
      }
      addIssue(
        'unknown_audio_word_id',
        '音频映射引用了不存在的单词 ID ${entry.key}',
        details: {'wordId': entry.key},
      );
    }
  }

  void _validateStatsAndGroups(
    ImportedContent imported,
    ContentBuildConfig config,
    _AddValidationIssue addIssue,
  ) {
    final groupIds = <int>{};
    final ranks = <int>{};
    for (final group in imported.groups) {
      if (group.id <= 0) {
        addIssue('invalid_group_id', '词频组 ID 必须为正整数');
      }
      if (!groupIds.add(group.id)) {
        addIssue('duplicate_group_id', '词频组 ID ${group.id} 重复');
      }
      if (!ranks.add(group.rank)) {
        addIssue('duplicate_group_rank', '词频组 rank ${group.rank} 重复');
      }
      if (group.rank < minActiveGroupRank || group.rank > reservedGroupRank) {
        addIssue('invalid_group_rank', '词频组 rank ${group.rank} 不在 1-7 范围');
      }
      if (group.minOccurrences < 0 ||
          group.maxOccurrences < group.minOccurrences ||
          group.wordCount < 0) {
        addIssue('invalid_group_range', '词频组 ${group.id} 的区间或数量无效');
      }
      if (group.rank == reservedGroupRank && group.wordCount != 0) {
        addIssue('reserved_group_not_empty', '预留的第 7 组必须保持 0 个单词');
      }
    }
    final expectedRanks = {
      for (var rank = minActiveGroupRank; rank <= reservedGroupRank; rank++)
        rank,
    };
    if (ranks.length != expectedRanks.length ||
        !ranks.containsAll(expectedRanks)) {
      addIssue('missing_group_rank', '词频组必须完整包含 rank 1-7');
    }
    if (imported.stats.groupCount != imported.groups.length) {
      addIssue(
        'stats_group_count_mismatch',
        'stats.groupCount 与 groups.json 实际数量不一致',
      );
    }
    if (!_sameStringList(imported.stats.letters, config.expectedLetters)) {
      addIssue('stats_letters_mismatch', 'stats.letters 与冻结分块字母不一致');
    }

    final statsGroupsById = {
      for (final group in imported.stats.groups) group.id: group,
    };
    for (final group in imported.groups) {
      final statsGroup = statsGroupsById[group.id];
      if (statsGroup == null || statsGroup.equalityKey != group.equalityKey) {
        addIssue(
          'stats_group_mismatch',
          'stats.groups 与 groups.json 的词频组 ${group.id} 不一致',
        );
      }
    }
  }

  void _validateWord(
    SourceWord word,
    Map<int, SourceFrequencyGroup> groupsById,
    ContentBuildConfig config,
    _AddValidationIssue addIssue,
  ) {
    if (word.id <= 0) {
      addIssue('invalid_word_id', '单词 ID 必须为正整数');
    }
    final runeLength = word.word.runes.length;
    if (runeLength <= 0 ||
        runeLength > maxWordLength ||
        word.length != runeLength) {
      addIssue('invalid_word_length', '单词 ID ${word.id} 的长度字段不正确');
    }
    final expectedFirstLetter = word.word.substring(0, 1).toUpperCase();
    if (word.firstLetter != expectedFirstLetter ||
        !config.expectedLetters.contains(word.firstLetter)) {
      addIssue('invalid_first_letter', '单词 ID ${word.id} 的首字母字段不正确');
    }
    if (word.sentenceCount < 0) {
      addIssue('invalid_sentence_count', '单词 ID ${word.id} 的例句数量不能为负数');
    }
    final group = groupsById[word.groupId];
    if (group == null) {
      addIssue('unknown_word_group', '单词 ID ${word.id} 引用了不存在的词频组');
      return;
    }
    if (group.rank < minActiveGroupRank || group.rank > maxActiveGroupRank) {
      addIssue('reserved_group_word', '单词 ID ${word.id} 不能进入预留词频组');
    }
    if (word.occurrences < group.minOccurrences ||
        word.occurrences > group.maxOccurrences) {
      addIssue('word_frequency_out_of_range', '单词 ID ${word.id} 的词频不属于当前分组');
    }
  }

  void _validateSentence(
    SourceSentence sentence,
    Map<int, SourceWord> wordsById,
    _AddValidationIssue addIssue,
  ) {
    final sourceLocation = sentence.sourceFile == null
        ? null
        : '${sentence.sourceFile}[${sentence.sourceIndex ?? '?'}]';
    final details = <String, Object>{
      'sentenceId': sentence.id,
      'wordId': sentence.wordId,
      'targetForm': sentence.targetForm,
    };
    final word = wordsById[sentence.wordId];
    if (word != null) {
      details['word'] = word.word;
    }
    if (sentence.id <= 0) {
      addIssue(
        'invalid_sentence_id',
        '例句 ID 必须为正整数',
        sourceFile: sourceLocation,
        details: details,
      );
    }
    if (!wordsById.containsKey(sentence.wordId)) {
      addIssue(
        'unknown_sentence_word',
        '例句 ID ${sentence.id} 引用了不存在的单词',
        sourceFile: sourceLocation,
        details: details,
      );
    }
    if (sentence.targetForm.runes.length > maxWordLength ||
        !_containsTargetForm(sentence.sentence, sentence.targetForm)) {
      addIssue(
        'invalid_target_form',
        '例句 ID ${sentence.id} 不包含独立的目标词形',
        sourceFile: sourceLocation,
        details: details,
      );
    }
  }

  void _validateCounts(
    ImportedContent imported,
    ContentBuildConfig config,
    int wordCount,
    int sentenceCount,
    Map<int, int> groupWordCounts,
    _AddValidationIssue addIssue,
  ) {
    if (wordCount != config.expectedWordCount) {
      addIssue(
        'word_count_mismatch',
        '实际单词数 $wordCount 与冻结基线 ${config.expectedWordCount} 不一致',
      );
    }
    if (imported.stats.wordCount != wordCount) {
      addIssue(
        'stats_word_count_mismatch',
        'stats 声明 ${imported.stats.wordCount} 个单词，实际分块为 $wordCount 个',
      );
    }
    if (sentenceCount != config.expectedSentenceCount) {
      addIssue(
        'sentence_count_mismatch',
        '实际例句数 $sentenceCount 与冻结基线 ${config.expectedSentenceCount} 不一致',
      );
    }
    if (imported.stats.sentenceCount != sentenceCount) {
      addIssue(
        'stats_sentence_count_mismatch',
        'stats 声明 ${imported.stats.sentenceCount} 条例句，实际分块为 $sentenceCount 条',
      );
    }
    final groupsByRank = {
      for (final group in imported.groups) group.rank: group,
    };
    var activeGroupTotal = 0;
    for (var rank = minActiveGroupRank; rank <= maxActiveGroupRank; rank++) {
      final declared = groupsByRank[rank]?.wordCount;
      final actual = groupWordCounts[rank] ?? 0;
      if (declared != actual) {
        addIssue(
          'group_word_count_mismatch',
          '词频组 rank $rank 声明 ${declared ?? 0} 个单词，实际为 $actual 个',
        );
      }
      activeGroupTotal += actual;
    }
    if (activeGroupTotal != config.expectedWordCount) {
      addIssue(
        'active_group_total_mismatch',
        '六个有效词频组总数 $activeGroupTotal 与冻结基线不一致',
      );
    }
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  bool _sameCountMap(Map<String, int> left, Map<String, int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  bool _containsTargetForm(String sentence, String targetForm) {
    final lowerSentence = sentence.toLowerCase();
    final lowerTarget = targetForm.toLowerCase();
    var start = lowerSentence.indexOf(lowerTarget);
    while (start >= 0) {
      final end = start + lowerTarget.length;
      final beforeIsLetter =
          start > 0 && _isAsciiLetter(lowerSentence.codeUnitAt(start - 1));
      final afterIsLetter =
          end < lowerSentence.length &&
          _isAsciiLetter(lowerSentence.codeUnitAt(end));
      if (!beforeIsLetter && !afterIsLetter) {
        return true;
      }
      start = lowerSentence.indexOf(lowerTarget, start + 1);
    }
    return false;
  }

  bool _isAsciiLetter(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }
}
