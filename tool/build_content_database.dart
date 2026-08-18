import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'content_builder/audio_assets.dart';
import 'content_builder/content_build_config.dart';
import 'content_builder/content_build_exception.dart';
import 'content_builder/content_database_builder.dart';

const int _maxLicenseNoticeBytes = 256 * 1024;

/// 解析冻结来源并生成 SQLite、内容清单和构建报告。
Future<void> main(List<String> arguments) async {
  final parser = _buildParser();
  late final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('参数错误：${error.message}');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }
  if (options.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  try {
    final licenseFile = File(options.option('license-notice-file')!);
    if (!await licenseFile.exists()) {
      throw const ContentBuildException(
        code: 'missing_license_file',
        message: '授权说明文件不存在',
      );
    }
    final licenseLength = await licenseFile.length();
    if (licenseLength <= 0 || licenseLength > _maxLicenseNoticeBytes) {
      throw const ContentBuildException(
        code: 'invalid_license_file_size',
        message: '授权说明文件必须在 1-256 KiB 之间',
      );
    }
    final licenseNotice = (await licenseFile.readAsString()).trim();
    final audioMapPath = options.option('audio-map-file');
    final audioDirectoryPath = options.option('audio-directory');
    if ((audioMapPath == null) != (audioDirectoryPath == null)) {
      throw const ContentBuildException(
        code: 'incomplete_audio_options',
        message: '--audio-map-file 与 --audio-directory 必须同时提供',
      );
    }
    final audioAssets = audioMapPath == null
        ? const ContentAudioAssetMap.empty()
        : await ContentAudioAssetMap.fromFile(
            mapFile: File(audioMapPath),
            audioDirectory: Directory(audioDirectoryPath!),
          );
    final config = ContentBuildConfig(
      inputDirectory: Directory(options.option('input')!),
      outputDirectory: Directory(options.option('output')!),
      contentVersion: options.option('content-version')!,
      sourceRepository: options.option('source-repository')!,
      sourceRevision: options.option('source-revision')!,
      licenseNotice: licenseNotice,
      expectedWordCount: _positiveInt(options, 'expected-word-count'),
      expectedSentenceCount: _positiveInt(options, 'expected-sentence-count'),
      expectedLetters: _letters(options.option('expected-letters')!),
      expectedSentenceChunkCount: _positiveInt(
        options,
        'expected-sentence-chunks',
      ),
      maxSourceFileBytes:
          _positiveInt(options, 'max-source-file-mib') * 1024 * 1024,
      maxTotalSourceBytes:
          _positiveInt(options, 'max-total-source-mib') * 1024 * 1024,
      audioAssets: audioAssets,
      sourceIssuePolicy: options.flag('preserve-known-source-inconsistencies')
          ? ContentSourceIssuePolicy.preserveKnownSourceInconsistencies
          : ContentSourceIssuePolicy.strict,
      expectedSourceDataSha256: options.option('expected-source-sha256'),
      expectedSourceWarningCounts: _warningCounts(
        options.option('expected-source-warning-counts'),
      ),
      overwrite: options.flag('overwrite'),
    );
    final generatedAt = _generatedAt(options.option('generated-at'));
    final result = await ContentDatabaseBuilder(
      nowUtc: generatedAt == null ? null : () => generatedAt,
    ).build(config);
    stdout.writeln('词库构建完成：${result.manifest.contentVersion}');
    stdout.writeln('单词：${result.report.wordCount}');
    stdout.writeln('例句：${result.report.sentenceCount}');
    stdout.writeln('生成时间：${result.manifest.generatedAt.toIso8601String()}');
    if (result.report.sourceWarningCount > 0) {
      final warningSummary = result.report.sourceWarningCounts.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      stdout.writeln(
        '已保留的来源警告：${result.report.sourceWarningCount}（$warningSummary）',
      );
    }
    stdout.writeln('本地音频引用：${result.report.localAudioReferences}');
    stdout.writeln('忽略远程音频引用：${result.report.remoteAudioReferencesIgnored}');
    stdout.writeln('数据库：${result.databaseFile.path}');
    stdout.writeln('清单：${result.manifestFile.path}');
    stdout.writeln('报告：${result.reportFile.path}');
  } on ContentValidationException catch (error) {
    await _writeValidationIssues(
      error,
      reportPath: options.option('validation-report-file'),
    );
    exitCode = 2;
  } on ContentBuildException catch (error) {
    stderr.writeln(error);
    exitCode = 3;
  } on FileSystemException catch (error) {
    stderr.writeln(
      'filesystem_error: ${error.osError?.errorCode ?? 'unknown'}',
    );
    exitCode = 4;
  }
}

ArgParser _buildParser() {
  return ArgParser(allowTrailingOptions: false)
    ..addFlag('help', abbr: 'h', negatable: false, help: '显示帮助')
    ..addOption('input', mandatory: true, help: '参考仓库 public/data 目录')
    ..addOption('output', mandatory: true, help: '构建产物目录')
    ..addOption('content-version', mandatory: true, help: '应用词库版本')
    ..addOption(
      'source-repository',
      defaultsTo: 'https://github.com/chunsi-w/ielts-vocab-cloudflare',
      help: '来源仓库地址',
    )
    ..addOption('source-revision', mandatory: true, help: '冻结的来源提交 SHA')
    ..addOption('generated-at', help: '可选的冻结 UTC 生成时间（ISO-8601，以 Z 结尾），用于字节级复现')
    ..addOption('license-notice-file', mandatory: true, help: '已确认的授权或署名说明文件')
    ..addOption(
      'audio-map-file',
      help: '已确认授权的本地音频映射 JSON，需与 --audio-directory 同时提供',
    )
    ..addOption(
      'audio-directory',
      help: '与 assets/audio/ 对应的本地音频目录，需与 --audio-map-file 同时提供',
    )
    ..addOption(
      'expected-word-count',
      defaultsTo: ContentBuildConfig.defaultExpectedWordCount.toString(),
      help: '冻结单词数',
    )
    ..addOption(
      'expected-sentence-count',
      defaultsTo: ContentBuildConfig.defaultExpectedSentenceCount.toString(),
      help: '冻结例句数',
    )
    ..addOption(
      'expected-letters',
      defaultsTo: ContentBuildConfig.defaultExpectedLetters.join(','),
      help: '逗号分隔的冻结单词分块标识',
    )
    ..addOption(
      'expected-sentence-chunks',
      defaultsTo: ContentBuildConfig.defaultExpectedSentenceChunkCount
          .toString(),
      help: '冻结例句分块数量',
    )
    ..addOption(
      'max-source-file-mib',
      defaultsTo: '128',
      help: '单个源文件大小上限（MiB）',
    )
    ..addOption(
      'max-total-source-mib',
      defaultsTo: '512',
      help: '全部源分块总大小上限（MiB）',
    )
    ..addFlag(
      'preserve-known-source-inconsistencies',
      negatable: false,
      help: '保留已审计的统计、分组数量和目标词形不一致，并写入构建警告',
    )
    ..addOption(
      'expected-source-sha256',
      help: '冻结的 63 个来源文件整体 SHA-256；保留来源问题时必填',
    )
    ..addOption(
      'expected-source-warning-counts',
      help: '冻结的来源警告计数，例如 invalid_target_form=140',
    )
    ..addOption('validation-report-file', help: '校验失败时写入结构化 JSON 问题报告')
    ..addFlag('overwrite', negatable: false, help: '在新产物验证通过后原子替换旧版本');
}

int _positiveInt(ArgResults options, String name) {
  final value = int.tryParse(options.option(name)!);
  if (value == null || value <= 0) {
    throw ContentBuildException(
      code: 'invalid_$name',
      message: '--$name 必须为正整数',
    );
  }
  return value;
}

List<String> _letters(String value) {
  final letters = value
      .split(',')
      .map((letter) => letter.trim().toUpperCase())
      .where((letter) => letter.isNotEmpty)
      .toList(growable: false);
  if (letters.isEmpty) {
    throw const ContentBuildException(
      code: 'invalid_expected_letters',
      message: '--expected-letters 不能为空',
    );
  }
  return letters;
}

Map<String, int> _warningCounts(String? value) {
  if (value == null || value.trim().isEmpty) {
    return const {};
  }
  final counts = <String, int>{};
  for (final item in value.split(',')) {
    final parts = item.trim().split('=');
    if (parts.length != 2 || parts.first.isEmpty) {
      throw const ContentBuildException(
        code: 'invalid_source_warning_counts',
        message: '--expected-source-warning-counts 必须使用 code=count 格式',
      );
    }
    final count = int.tryParse(parts.last);
    if (count == null || count <= 0 || counts.containsKey(parts.first)) {
      throw const ContentBuildException(
        code: 'invalid_source_warning_counts',
        message: '来源警告计数必须为正整数且问题码不能重复',
      );
    }
    counts[parts.first] = count;
  }
  return counts;
}

DateTime? _generatedAt(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim();
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null || !parsed.isUtc || !normalized.endsWith('Z')) {
    throw const ContentBuildException(
      code: 'invalid_generated_at',
      message: '--generated-at 必须是以 Z 结尾的 UTC ISO-8601 时间',
    );
  }
  return parsed;
}

Future<void> _writeValidationIssues(
  ContentValidationException error, {
  String? reportPath,
}) async {
  const maxDetails = 50;
  for (final issue in error.issues.take(maxDetails)) {
    stderr.writeln(issue);
  }
  if (error.issues.length > maxDetails || error.totalIssueCount > maxDetails) {
    stderr.writeln('其余问题明细已省略。');
  }
  final summary = error.issueCounts.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
  stderr.writeln('问题汇总：$summary');
  if (reportPath == null || reportPath.trim().isEmpty) {
    return;
  }
  try {
    final file = File(reportPath);
    await file.parent.create(recursive: true);
    final payload = <String, Object>{'reportVersion': 1, ...error.toJson()};
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      '${encoder.convert(payload)}\n',
      encoding: utf8,
      flush: true,
    );
    stderr.writeln('校验报告：${file.path}');
  } on FileSystemException catch (writeError) {
    stderr.writeln('校验报告写入失败：${writeError.osError?.errorCode ?? 'unknown'}');
  }
}
