import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_database_verifier.dart';

import '../../tool/content_builder/content_build_config.dart';
import '../../tool/content_builder/content_build_exception.dart';
import '../../tool/content_builder/content_database_builder.dart';
import '../../tool/content_builder/content_source_validator.dart';
import '../../tool/content_builder/audio_assets.dart';
import '../../tool/content_builder/importers/ielts_vocab_cloudflare_importer.dart';
import '../../tool/content_builder/source_models.dart';

void main() {
  final workspace = Directory.current.absolute;
  final fixtureDirectory = Directory(
    p.join(workspace.path, 'test', 'fixtures', 'content_source'),
  );
  final cacheRoot = Directory(
    p.join(workspace.path, '.cache', 'content_builder_tests'),
  );
  final cleanupDirectories = <Directory>[];

  tearDown(() async {
    for (final directory in cleanupDirectories.reversed) {
      if (p.isWithin(cacheRoot.path, directory.path) &&
          await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    cleanupDirectories.clear();
  });

  test('适配器解析固定分块并生成确定性源数据摘要', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'import');
    final config = _fixtureConfig(fixtureDirectory, output);

    final imported = await const IeltsVocabCloudflareImporter().load(config);
    final validated = const ContentSourceValidator().validate(imported, config);

    expect(imported.sourceDataSha256, hasLength(64));
    expect(validated.words, hasLength(3));
    expect(validated.sentences, hasLength(3));
    expect(validated.report.groupWordCounts, {
      1: 2,
      2: 1,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
    });
    expect(validated.report.remoteAudioReferencesIgnored, 2);
  });

  test('缺少任一分块时在解析前报告明确错误', () async {
    final sandbox = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'missing',
    );
    final input = Directory(p.join(sandbox.path, 'input'));
    final output = Directory(p.join(sandbox.path, 'output'));
    await _copyFixture(fixtureDirectory, input);
    await File(p.join(input.path, 'words-B.json')).delete();
    final config = _fixtureConfig(input, output);

    final operation = const IeltsVocabCloudflareImporter().load(config);

    await expectLater(
      operation,
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issues.map((issue) => issue.code),
          'codes',
          contains('missing_source_file'),
        ),
      ),
    );
  });

  test('严格模式不会静默接受 stats 统计漂移', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'drift');
    final config = _fixtureConfig(fixtureDirectory, output);
    final imported = await const IeltsVocabCloudflareImporter().load(config);
    final drifted = ImportedContent(
      groups: imported.groups,
      stats: SourceStats(
        wordCount: 4,
        sentenceCount: imported.stats.sentenceCount,
        groupCount: imported.stats.groupCount,
        letters: imported.stats.letters,
        groups: imported.stats.groups,
      ),
      words: imported.words,
      sentences: imported.sentences,
      sourceDataSha256: imported.sourceDataSha256,
    );

    expect(
      () => const ContentSourceValidator().validate(drifted, config),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issues.map((issue) => issue.code),
          'codes',
          contains('stats_word_count_mismatch'),
        ),
      ),
    );
  });

  test('显式保留策略把已知来源问题写入报告且不删除记录', () async {
    final output = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'preserve-source',
    );
    final baseConfig = _fixtureConfig(fixtureDirectory, output);
    final imported = await const IeltsVocabCloudflareImporter().load(
      baseConfig,
    );
    final knownIssues = ImportedContent(
      groups: imported.groups,
      stats: SourceStats(
        wordCount: imported.stats.wordCount + 1,
        sentenceCount: imported.stats.sentenceCount,
        groupCount: imported.stats.groupCount,
        letters: imported.stats.letters,
        groups: imported.stats.groups,
      ),
      words: imported.words,
      sentences: [
        _copySentence(imported.sentences.first, targetForm: 'cad'),
        ...imported.sentences.skip(1),
      ],
      sourceDataSha256: imported.sourceDataSha256,
    );
    final config = _fixtureConfig(
      fixtureDirectory,
      output,
      sourceIssuePolicy:
          ContentSourceIssuePolicy.preserveKnownSourceInconsistencies,
      expectedSourceDataSha256: imported.sourceDataSha256,
      expectedSourceWarningCounts: const {
        'invalid_target_form': 1,
        'stats_word_count_mismatch': 1,
      },
    );

    final validated = const ContentSourceValidator().validate(
      knownIssues,
      config,
    );

    expect(validated.words, hasLength(3));
    expect(validated.sentences, hasLength(3));
    expect(validated.report.sourceWarningCount, 2);
    expect(validated.report.sourceWarningCounts, {
      'invalid_target_form': 1,
      'stats_word_count_mismatch': 1,
    });
    expect(
      validated.report.toJson()['sourceWarnings'],
      isA<List<Object>>().having((warnings) => warnings.length, 'length', 2),
    );
  });

  test('已知来源问题数量漂移时仍拒绝构建', () async {
    final output = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'warning-drift',
    );
    final baseConfig = _fixtureConfig(fixtureDirectory, output);
    final imported = await const IeltsVocabCloudflareImporter().load(
      baseConfig,
    );
    final config = _fixtureConfig(
      fixtureDirectory,
      output,
      sourceIssuePolicy:
          ContentSourceIssuePolicy.preserveKnownSourceInconsistencies,
      expectedSourceDataSha256: imported.sourceDataSha256,
      expectedSourceWarningCounts: const {'invalid_target_form': 1},
    );

    expect(
      () => const ContentSourceValidator().validate(imported, config),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('source_warning_set_mismatch'),
        ),
      ),
    );
  });

  test('来源文件摘要漂移时拒绝构建', () async {
    final output = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'source-hash-drift',
    );
    final imported = await const IeltsVocabCloudflareImporter().load(
      _fixtureConfig(fixtureDirectory, output),
    );
    final config = _fixtureConfig(
      fixtureDirectory,
      output,
      expectedSourceDataSha256: List.filled(64, '0').join(),
    );

    expect(
      () => const ContentSourceValidator().validate(imported, config),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('source_data_checksum_mismatch'),
        ),
      ),
    );
  });

  test('总大小上限在解析 JSON 前生效', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'size');
    final config = ContentBuildConfig(
      inputDirectory: fixtureDirectory,
      outputDirectory: output,
      contentVersion: 'fixture-v1',
      sourceRepository: 'https://example.invalid/fixture',
      sourceRevision: 'fixture-revision-1',
      licenseNotice: '仅用于自动化测试的合成数据。',
      expectedWordCount: 3,
      expectedSentenceCount: 3,
      expectedLetters: const ['A', 'B'],
      expectedSentenceChunkCount: 2,
      maxSourceFileBytes: 2048,
      maxTotalSourceBytes: 2048,
    );

    await expectLater(
      const IeltsVocabCloudflareImporter().load(config),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('source_total_too_large'),
        ),
      ),
    );
  });

  test('相同句子来自不同出处时保留独立稳定 ID', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'source');
    final baseConfig = _fixtureConfig(fixtureDirectory, output);
    final imported = await const IeltsVocabCloudflareImporter().load(
      baseConfig,
    );
    final firstSentence = imported.sentences.first;
    final expanded = ImportedContent(
      groups: imported.groups,
      stats: SourceStats(
        wordCount: imported.stats.wordCount,
        sentenceCount: 4,
        groupCount: imported.stats.groupCount,
        letters: imported.stats.letters,
        groups: imported.stats.groups,
      ),
      words: imported.words
          .map(
            (word) => word.id == firstSentence.wordId
                ? _copyWord(word, sentenceCount: word.sentenceCount + 1)
                : word,
          )
          .toList(),
      sentences: [
        ...imported.sentences,
        _copySentence(
          firstSentence,
          id: 4,
          source: '另一测试来源',
          location: 'Test 9 Part 9',
        ),
      ],
      sourceDataSha256: imported.sourceDataSha256,
    );
    final config = ContentBuildConfig(
      inputDirectory: fixtureDirectory,
      outputDirectory: output,
      contentVersion: 'fixture-v1',
      sourceRepository: 'https://example.invalid/fixture',
      sourceRevision: 'fixture-revision-1',
      licenseNotice: '仅用于自动化测试的合成数据。',
      expectedWordCount: 3,
      expectedSentenceCount: 4,
      expectedLetters: const ['A', 'B'],
      expectedSentenceChunkCount: 2,
    );

    final validated = const ContentSourceValidator().validate(expanded, config);

    expect(validated.sentences, hasLength(4));
    expect(validated.report.duplicateSentencesRemoved, 0);
  });

  test('目标词形只命中其他单词内部时拒绝构建', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'target');
    final config = _fixtureConfig(fixtureDirectory, output);
    final imported = await const IeltsVocabCloudflareImporter().load(config);
    final invalid = ImportedContent(
      groups: imported.groups,
      stats: imported.stats,
      words: imported.words,
      sentences: [
        _copySentence(imported.sentences.first, targetForm: 'cad'),
        ...imported.sentences.skip(1),
      ],
      sourceDataSha256: imported.sourceDataSha256,
    );

    try {
      const ContentSourceValidator().validate(invalid, config);
      fail('应拒绝不包含目标词形的例句');
    } on ContentValidationException catch (error) {
      expect(error.issueCounts['invalid_target_form'], 1);
      final issue = error.issues.firstWhere(
        (issue) => issue.code == 'invalid_target_form',
      );
      expect(issue.sourceFile, 'sentences-0.json[0]');
      expect(issue.details, {
        'sentenceId': 1,
        'wordId': 1,
        'targetForm': 'cad',
        'word': 'academic',
      });
    }
  });

  test('音频映射引用未知单词时拒绝构建', () async {
    final output = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'audio-id',
    );
    final config = _fixtureConfig(
      fixtureDirectory,
      output,
      audioAssets: const ContentAudioAssetMap({
        999: ContentAudioAssetPaths(uk: 'assets/audio/uk/missing.mp3'),
      }),
    );
    final imported = await const IeltsVocabCloudflareImporter().load(config);

    await expectLater(
      Future<void>.sync(() {
        const ContentSourceValidator().validate(imported, config);
      }),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('unknown_audio_word_id'),
        ),
      ),
    );
  });

  test('SQLite 构建、FTS5、内容清单和只读复核形成完整闭环', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'build');
    final config = _fixtureConfig(fixtureDirectory, output);
    final builder = ContentDatabaseBuilder(
      nowUtc: () => DateTime.utc(2026, 8, 14, 12),
    );

    final result = await builder.build(config);
    final verified = await const ContentDatabaseVerifier().verify(
      databaseFile: result.databaseFile,
      manifestFile: result.manifestFile,
    );

    expect(verified.contentVersion, 'fixture-v1');
    expect(verified.databaseSha256, hasLength(64));
    expect(result.report.wordCount, 3);
    expect(await result.reportFile.exists(), isTrue);

    final database = ContentDatabase.forExecutor(
      NativeDatabase(result.databaseFile),
    );
    try {
      final matches = await database.contentDao.findWords(
        WordFilter(keyword: 'acad'),
      );
      final academic = await database.contentDao.findWordById(1);

      expect(matches.map((word) => word.word), ['academic', 'academy']);
      expect(academic?.phoneticUk, 'ˌækəˈdemɪk');
      expect(academic?.phoneticUs, isNull);
      expect(academic?.audioUkAsset, isNull);
      expect(academic?.audioUsAsset, isNull);
    } finally {
      await database.close();
    }
  });

  test('固定来源与生成时间可得到字节级一致的数据库', () async {
    final firstOutput = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'deterministic-first',
    );
    final secondOutput = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'deterministic-second',
    );
    final builder = ContentDatabaseBuilder(
      nowUtc: () => DateTime.utc(2026, 8, 5, 11, 15, 42),
    );

    final first = await builder.build(
      _fixtureConfig(fixtureDirectory, firstOutput),
    );
    final second = await builder.build(
      _fixtureConfig(fixtureDirectory, secondOutput),
    );

    expect(first.manifest.databaseSha256, second.manifest.databaseSha256);
    expect(
      await first.databaseFile.readAsBytes(),
      await second.databaseFile.readAsBytes(),
    );
  });

  test('经确认的本地音频映射会写入词条资源字段', () async {
    final output = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'audio-build',
    );
    final config = _fixtureConfig(
      fixtureDirectory,
      output,
      audioAssets: const ContentAudioAssetMap({
        1: ContentAudioAssetPaths(
          uk: 'assets/audio/uk/academic.mp3',
          us: 'assets/audio/us/academic.m4a',
        ),
      }),
    );
    final result = await ContentDatabaseBuilder().build(config);

    expect(result.report.localAudioReferences, 2);
    final database = ContentDatabase.forExecutor(
      NativeDatabase(result.databaseFile),
    );
    try {
      final academic = await database.contentDao.findWordById(1);
      expect(academic?.audioUkAsset, 'assets/audio/uk/academic.mp3');
      expect(academic?.audioUsAsset, 'assets/audio/us/academic.m4a');
    } finally {
      await database.close();
    }
  });

  test('默认拒绝覆盖，显式覆盖后发布完整新版本', () async {
    final output = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'overwrite',
    );
    final builder = ContentDatabaseBuilder(
      nowUtc: () => DateTime.utc(2026, 8, 14, 12),
    );
    final firstConfig = _fixtureConfig(fixtureDirectory, output);
    await builder.build(firstConfig);

    await expectLater(
      builder.build(firstConfig),
      throwsA(
        isA<ContentBuildException>().having(
          (error) => error.code,
          'code',
          'output_exists',
        ),
      ),
    );

    final replacement = ContentBuildConfig(
      inputDirectory: fixtureDirectory,
      outputDirectory: output,
      contentVersion: 'fixture-v2',
      sourceRepository: 'https://example.invalid/fixture',
      sourceRevision: 'fixture-revision-2',
      licenseNotice: '仅用于自动化测试的合成数据。',
      expectedWordCount: 3,
      expectedSentenceCount: 3,
      expectedLetters: const ['A', 'B'],
      expectedSentenceChunkCount: 2,
      overwrite: true,
    );
    final result = await builder.build(replacement);
    final manifest = await const ContentDatabaseVerifier().verify(
      databaseFile: result.databaseFile,
      manifestFile: result.manifestFile,
    );

    expect(manifest.contentVersion, 'fixture-v2');
    expect(
      output.listSync().whereType<File>().where(
        (file) => p.basename(file.path).contains('.previous-'),
      ),
      isEmpty,
    );
  });

  test('数据库字节变化会在打开 SQLite 前被校验和拒绝', () async {
    final output = _newCacheDirectory(cacheRoot, cleanupDirectories, 'corrupt');
    final result = await ContentDatabaseBuilder().build(
      _fixtureConfig(fixtureDirectory, output),
    );
    final sink = result.databaseFile.openWrite(mode: FileMode.append);
    sink.add([0]);
    await sink.close();

    final operation = const ContentDatabaseVerifier().verify(
      databaseFile: result.databaseFile,
      manifestFile: result.manifestFile,
    );

    await expectLater(
      operation,
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issues.map((issue) => issue.code),
          'codes',
          contains('database_size_mismatch'),
        ),
      ),
    );
  });
}

ContentBuildConfig _fixtureConfig(
  Directory input,
  Directory output, {
  ContentAudioAssetMap audioAssets = const ContentAudioAssetMap.empty(),
  ContentSourceIssuePolicy sourceIssuePolicy = ContentSourceIssuePolicy.strict,
  String? expectedSourceDataSha256,
  Map<String, int> expectedSourceWarningCounts = const {},
}) {
  return ContentBuildConfig(
    inputDirectory: input,
    outputDirectory: output,
    contentVersion: 'fixture-v1',
    sourceRepository: 'https://example.invalid/fixture',
    sourceRevision: 'fixture-revision-1',
    licenseNotice: '仅用于自动化测试的合成数据。',
    expectedWordCount: 3,
    expectedSentenceCount: 3,
    expectedLetters: const ['A', 'B'],
    expectedSentenceChunkCount: 2,
    audioAssets: audioAssets,
    sourceIssuePolicy: sourceIssuePolicy,
    expectedSourceDataSha256: expectedSourceDataSha256,
    expectedSourceWarningCounts: expectedSourceWarningCounts,
  );
}

Directory _newCacheDirectory(
  Directory cacheRoot,
  List<Directory> cleanupDirectories,
  String name,
) {
  final directory = Directory(
    p.join(
      cacheRoot.path,
      '$name-${DateTime.now().microsecondsSinceEpoch}-$pid',
    ),
  );
  cleanupDirectories.add(directory);
  return directory;
}

Future<void> _copyFixture(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    if (entity is File) {
      await entity.copy(p.join(destination.path, p.basename(entity.path)));
    }
  }
}

SourceWord _copyWord(SourceWord word, {required int sentenceCount}) {
  return SourceWord(
    id: word.id,
    word: word.word,
    translation: word.translation,
    phonetic: word.phonetic,
    englishDefinition: word.englishDefinition,
    mnemonic: word.mnemonic,
    audioUk: word.audioUk,
    audioUs: word.audioUs,
    occurrences: word.occurrences,
    groupId: word.groupId,
    firstLetter: word.firstLetter,
    length: word.length,
    sentenceCount: sentenceCount,
  );
}

SourceSentence _copySentence(
  SourceSentence sentence, {
  int? id,
  String? targetForm,
  String? source,
  String? location,
}) {
  return SourceSentence(
    id: id ?? sentence.id,
    wordId: sentence.wordId,
    targetForm: targetForm ?? sentence.targetForm,
    sentence: sentence.sentence,
    translation: sentence.translation,
    source: source ?? sentence.source,
    location: location ?? sentence.location,
    sourceFile: sentence.sourceFile,
    sourceIndex: sentence.sourceIndex,
  );
}
