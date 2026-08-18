import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter_ielts_glossary/app/models/content/content_manifest.dart';

import 'audio_assets.dart';
import 'content_build_exception.dart';

/// 来源数据问题的处理策略；严格模式始终用于未审计的新快照。
enum ContentSourceIssuePolicy {
  strict,
  preserveKnownSourceInconsistencies;

  static const Set<String> _knownWarningCodes = {
    'invalid_target_form',
    'stats_word_count_mismatch',
    'group_word_count_mismatch',
  };

  /// 仅允许已经审计、且不会破坏数据库结构或运行时安全的问题继续构建。
  bool acceptsAsWarning(String code) {
    return this == preserveKnownSourceInconsistencies &&
        _knownWarningCodes.contains(code);
  }
}

/// 一次可复现词库构建的全部输入和冻结基线。
final class ContentBuildConfig {
  ContentBuildConfig({
    required Directory inputDirectory,
    required Directory outputDirectory,
    required this.contentVersion,
    required this.sourceRepository,
    required this.sourceRevision,
    required this.licenseNotice,
    this.expectedWordCount = defaultExpectedWordCount,
    this.expectedSentenceCount = defaultExpectedSentenceCount,
    List<String> expectedLetters = defaultExpectedLetters,
    this.expectedSentenceChunkCount = defaultExpectedSentenceChunkCount,
    this.maxSourceFileBytes = defaultMaxSourceFileBytes,
    this.maxTotalSourceBytes = defaultMaxTotalSourceBytes,
    ContentAudioAssetMap audioAssets = const ContentAudioAssetMap.empty(),
    this.sourceIssuePolicy = ContentSourceIssuePolicy.strict,
    this.expectedSourceDataSha256,
    Map<String, int> expectedSourceWarningCounts = const {},
    this.overwrite = false,
  }) : inputDirectory = Directory(p.normalize(inputDirectory.absolute.path)),
       outputDirectory = Directory(p.normalize(outputDirectory.absolute.path)),
       expectedLetters = List<String>.unmodifiable(expectedLetters),
       audioAssets = ContentAudioAssetMap(
         Map.unmodifiable(audioAssets.entries),
       ),
       expectedSourceWarningCounts = Map.unmodifiable(
         expectedSourceWarningCounts,
       ) {
    _validate();
  }

  static const int contentFormatVersion = ContentManifest.currentFormatVersion;
  static const int defaultExpectedWordCount = 34212;
  static const int defaultExpectedSentenceCount = 76332;
  static const int defaultExpectedSentenceChunkCount = 35;
  static const int defaultMaxSourceFileBytes = 128 * 1024 * 1024;
  static const int defaultMaxTotalSourceBytes = 512 * 1024 * 1024;
  static const List<String> defaultExpectedLetters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  final Directory inputDirectory;
  final Directory outputDirectory;
  final String contentVersion;
  final String sourceRepository;
  final String sourceRevision;
  final String licenseNotice;
  final int expectedWordCount;
  final int expectedSentenceCount;
  final List<String> expectedLetters;
  final int expectedSentenceChunkCount;
  final int maxSourceFileBytes;
  final int maxTotalSourceBytes;
  final ContentAudioAssetMap audioAssets;
  final ContentSourceIssuePolicy sourceIssuePolicy;
  final String? expectedSourceDataSha256;
  final Map<String, int> expectedSourceWarningCounts;
  final bool overwrite;

  List<String> get requiredSourceFileNames => [
    'groups.json',
    'stats.json',
    ...expectedLetters.map((letter) => 'words-$letter.json'),
    ...List.generate(
      expectedSentenceChunkCount,
      (index) => 'sentences-$index.json',
    ),
  ];

  void _validate() {
    if (contentVersion.trim().isEmpty || contentVersion.length > 100) {
      throw const ContentBuildException(
        code: 'invalid_content_version',
        message: '内容版本不能为空且不能超过 100 个字符',
      );
    }
    if (sourceRepository.trim().isEmpty || sourceRepository.length > 500) {
      throw const ContentBuildException(
        code: 'invalid_source_repository',
        message: '来源仓库不能为空且不能超过 500 个字符',
      );
    }
    if (sourceRevision.trim().isEmpty || sourceRevision.length > 200) {
      throw const ContentBuildException(
        code: 'invalid_source_revision',
        message: '来源提交不能为空且不能超过 200 个字符',
      );
    }
    if (licenseNotice.trim().isEmpty) {
      throw const ContentBuildException(
        code: 'missing_license_notice',
        message: '必须显式提供词库授权或署名说明',
      );
    }
    if (expectedWordCount <= 0 || expectedSentenceCount <= 0) {
      throw const ContentBuildException(
        code: 'invalid_expected_counts',
        message: '冻结基线中的单词数和例句数必须为正整数',
      );
    }
    final expectedHash = expectedSourceDataSha256;
    if (expectedHash != null &&
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedHash)) {
      throw const ContentBuildException(
        code: 'invalid_source_data_sha256',
        message: '来源数据 SHA-256 必须是 64 位小写十六进制字符串',
      );
    }
    if (sourceIssuePolicy ==
        ContentSourceIssuePolicy.preserveKnownSourceInconsistencies) {
      if (expectedHash == null || expectedSourceWarningCounts.isEmpty) {
        throw const ContentBuildException(
          code: 'missing_source_acceptance_baseline',
          message: '保留已知来源问题时必须提供来源 SHA-256 和精确警告计数',
        );
      }
      if (expectedSourceWarningCounts.entries.any(
        (entry) =>
            entry.value <= 0 || !sourceIssuePolicy.acceptsAsWarning(entry.key),
      )) {
        throw const ContentBuildException(
          code: 'invalid_source_warning_counts',
          message: '来源警告基线只能包含受支持的问题码和正整数计数',
        );
      }
    } else if (expectedSourceWarningCounts.isNotEmpty) {
      throw const ContentBuildException(
        code: 'unexpected_source_warning_counts',
        message: '严格模式不能配置可接受的来源警告',
      );
    }
    if (expectedLetters.isEmpty ||
        expectedLetters.toSet().length != expectedLetters.length ||
        expectedLetters.any((letter) => !RegExp(r'^[A-Z]$').hasMatch(letter))) {
      throw const ContentBuildException(
        code: 'invalid_expected_letters',
        message: '单词分块标识必须是无重复的 A-Z 大写字母',
      );
    }
    if (expectedSentenceChunkCount <= 0 ||
        maxSourceFileBytes <= 0 ||
        maxTotalSourceBytes < maxSourceFileBytes) {
      throw const ContentBuildException(
        code: 'invalid_build_limits',
        message: '分块数量和大小上限无效，且总大小上限不能小于单文件上限',
      );
    }
    if (_isFileSystemRoot(inputDirectory.path) ||
        _isFileSystemRoot(outputDirectory.path)) {
      throw const ContentBuildException(
        code: 'unsafe_directory',
        message: '输入或输出目录不能是文件系统根目录',
      );
    }
    if (p.equals(inputDirectory.path, outputDirectory.path)) {
      throw const ContentBuildException(
        code: 'overlapping_directories',
        message: '输入目录与输出目录必须分离',
      );
    }
  }

  bool _isFileSystemRoot(String path) => p.equals(path, p.dirname(path));
}
