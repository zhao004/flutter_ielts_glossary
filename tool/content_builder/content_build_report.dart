import 'source_models.dart';

import 'audio_assets.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_validation.dart';

/// 校验通过后生成的统计和数据清理报告。
final class ContentBuildReport {
  const ContentBuildReport({
    required this.wordCount,
    required this.sentenceCount,
    required this.groupWordCounts,
    required this.duplicateWordsRemoved,
    required this.duplicateSentencesRemoved,
    required this.missingTranslations,
    required this.missingEnglishDefinitions,
    required this.missingPhonetics,
    required this.remoteAudioReferencesIgnored,
    required this.localAudioReferences,
    required this.sourceWarningCounts,
    required this.sourceWarnings,
  });

  final int wordCount;
  final int sentenceCount;
  final Map<int, int> groupWordCounts;
  final int duplicateWordsRemoved;
  final int duplicateSentencesRemoved;
  final int missingTranslations;
  final int missingEnglishDefinitions;
  final int missingPhonetics;
  final int remoteAudioReferencesIgnored;
  final int localAudioReferences;
  final Map<String, int> sourceWarningCounts;
  final List<ContentValidationIssue> sourceWarnings;

  int get sourceWarningCount =>
      sourceWarningCounts.values.fold(0, (sum, count) => sum + count);

  Map<String, Object> toJson() => {
    'wordCount': wordCount,
    'sentenceCount': sentenceCount,
    'groupWordCounts': {
      for (final entry in groupWordCounts.entries)
        entry.key.toString(): entry.value,
    },
    'duplicateWordsRemoved': duplicateWordsRemoved,
    'duplicateSentencesRemoved': duplicateSentencesRemoved,
    'missingTranslations': missingTranslations,
    'missingEnglishDefinitions': missingEnglishDefinitions,
    'missingPhonetics': missingPhonetics,
    'remoteAudioReferencesIgnored': remoteAudioReferencesIgnored,
    'localAudioReferences': localAudioReferences,
    'sourceWarningCount': sourceWarningCount,
    'sourceWarningCounts': Map<String, int>.from(sourceWarningCounts),
    'sourceWarnings': [for (final warning in sourceWarnings) warning.toJson()],
  };
}

/// 已完成去重和全部业务约束校验，可安全写入数据库的数据。
final class ValidatedContent {
  const ValidatedContent({
    required this.groups,
    required this.words,
    required this.sentences,
    required this.audioAssets,
    required this.sourceDataSha256,
    required this.report,
  });

  final List<SourceFrequencyGroup> groups;
  final List<SourceWord> words;
  final List<SourceSentence> sentences;
  final Map<int, ContentAudioAssetPaths> audioAssets;
  final String sourceDataSha256;
  final ContentBuildReport report;
}
