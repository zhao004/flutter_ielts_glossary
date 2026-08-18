import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/models/content/content_asset_names.dart';
import 'package:flutter_ielts_glossary/app/models/content/content_manifest.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_database_verifier.dart';
import 'package:flutter_ielts_glossary/app/services/files/atomic_file_set_publisher.dart';
import 'content_build_config.dart';
import 'content_build_exception.dart';
import 'content_build_report.dart';
import 'content_source_validator.dart';
import 'importers/ielts_vocab_cloudflare_importer.dart';

/// 构建完成并已通过清单校验的输出路径。
final class ContentBuildResult {
  const ContentBuildResult({
    required this.databaseFile,
    required this.manifestFile,
    required this.reportFile,
    required this.manifest,
    required this.report,
  });

  final File databaseFile;
  final File manifestFile;
  final File reportFile;
  final ContentManifest manifest;
  final ContentBuildReport report;
}

/// 将已冻结的参考仓库 JSON 原子构建为可发布 SQLite 与内容清单。
final class ContentDatabaseBuilder {
  ContentDatabaseBuilder({DateTime Function()? nowUtc})
    : _importer = const IeltsVocabCloudflareImporter(),
      _validator = const ContentSourceValidator(),
      _verifier = const ContentDatabaseVerifier(),
      _publisher = const AtomicFileSetPublisher(),
      _nowUtc = nowUtc ?? _systemNowUtc;

  static const int insertBatchSize = 1000;

  final IeltsVocabCloudflareImporter _importer;
  final ContentSourceValidator _validator;
  final ContentDatabaseVerifier _verifier;
  final AtomicFileSetPublisher _publisher;
  final DateTime Function() _nowUtc;

  Future<ContentBuildResult> build(ContentBuildConfig config) async {
    final imported = await _importer.load(config);
    final content = _validator.validate(imported, config);
    await _prepareOutputDirectory(config.outputDirectory);

    final stagingDirectory = await config.outputDirectory.createTemp(
      '.content_build_',
    );
    try {
      final stagedDatabase = File(
        p.join(stagingDirectory.path, ContentAssetNames.databaseFile),
      );
      final generatedAt = DateTime.fromMillisecondsSinceEpoch(
        _nowUtc().toUtc().millisecondsSinceEpoch,
        isUtc: true,
      );
      await _writeDatabase(
        databaseFile: stagedDatabase,
        config: config,
        content: content,
        generatedAt: generatedAt,
      );

      final manifest = ContentManifest(
        formatVersion: ContentBuildConfig.contentFormatVersion,
        contentVersion: config.contentVersion,
        sourceRepository: config.sourceRepository,
        sourceRevision: config.sourceRevision,
        generatedAt: generatedAt,
        databaseFile: ContentAssetNames.databaseFile,
        databaseBytes: await stagedDatabase.length(),
        databaseSha256: await _sha256File(stagedDatabase),
        sourceDataSha256: content.sourceDataSha256,
        wordCount: content.report.wordCount,
        sentenceCount: content.report.sentenceCount,
        activeGroupCount: content.groups
            .where((group) => group.rank >= 1 && group.rank <= 6)
            .length,
        groupWordCounts: content.report.groupWordCounts,
        licenseNotice: config.licenseNotice,
      );
      final stagedManifest = File(
        p.join(stagingDirectory.path, ContentAssetNames.manifestFile),
      );
      final stagedReport = File(
        p.join(stagingDirectory.path, ContentBuildOutputNames.reportFile),
      );
      await _writeJson(stagedManifest, manifest.toJson());
      await _writeJson(stagedReport, content.report.toJson());
      await _verifier.verify(
        databaseFile: stagedDatabase,
        manifestFile: stagedManifest,
      );

      final outputFiles = await _publish(
        stagingDirectory: stagingDirectory,
        outputDirectory: config.outputDirectory,
        overwrite: config.overwrite,
      );
      return ContentBuildResult(
        databaseFile: outputFiles.database,
        manifestFile: outputFiles.manifest,
        reportFile: outputFiles.report,
        manifest: manifest,
        report: content.report,
      );
    } finally {
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> _writeDatabase({
    required File databaseFile,
    required ContentBuildConfig config,
    required ValidatedContent content,
    required DateTime generatedAt,
  }) async {
    final database = ContentDatabase.forExecutor(
      NativeDatabase(
        databaseFile,
        setup: (sqlite) {
          sqlite.execute('PRAGMA journal_mode = DELETE');
          sqlite.execute('PRAGMA synchronous = FULL');
        },
      ),
    );
    try {
      await database.transaction(() async {
        await database.batch((batch) {
          batch.insertAll(
            database.frequencyGroups,
            content.groups.map(
              (group) => FrequencyGroupsCompanion.insert(
                id: Value(group.id),
                name: group.name,
                rank: group.rank,
                minOccurrences: group.minOccurrences,
                maxOccurrences: Value(group.maxOccurrences),
              ),
            ),
          );
        });

        for (
          var offset = 0;
          offset < content.words.length;
          offset += insertBatchSize
        ) {
          final end = min(offset + insertBatchSize, content.words.length);
          await database.batch((batch) {
            batch.insertAll(
              database.words,
              content.words.sublist(offset, end).map((word) {
                final audio = content.audioAssets[word.id];
                return WordsCompanion.insert(
                  id: Value(word.id),
                  word: word.word,
                  phoneticUk: Value(word.phonetic),
                  translationZh: Value(word.translation),
                  definitionEn: Value(word.englishDefinition),
                  mnemonic: Value(word.mnemonic),
                  occurrences: word.occurrences,
                  frequencyGroupId: word.groupId,
                  firstLetter: word.firstLetter,
                  audioUkAsset: Value(audio?.uk),
                  audioUsAsset: Value(audio?.us),
                );
              }),
            );
          });
        }
        for (
          var offset = 0;
          offset < content.sentences.length;
          offset += insertBatchSize
        ) {
          final end = min(offset + insertBatchSize, content.sentences.length);
          await database.batch((batch) {
            batch.insertAll(
              database.sentences,
              content.sentences
                  .sublist(offset, end)
                  .map(
                    (sentence) => SentencesCompanion.insert(
                      id: Value(sentence.id),
                      wordId: sentence.wordId,
                      targetForm: sentence.targetForm,
                      sentenceEn: sentence.sentence,
                      translationZh: Value(sentence.translation),
                      source: Value(sentence.source),
                      location: Value(sentence.location),
                    ),
                  ),
            );
          });
        }
        await database
            .into(database.contentMetadata)
            .insert(
              ContentMetadataCompanion.insert(
                contentVersion: config.contentVersion,
                formatVersion: ContentBuildConfig.contentFormatVersion,
                sourceRepository: config.sourceRepository,
                sourceRevision: config.sourceRevision,
                generatedAt: generatedAt,
                wordCount: content.report.wordCount,
                sentenceCount: content.report.sentenceCount,
                licenseNotice: config.licenseNotice,
                sha256: content.sourceDataSha256,
              ),
            );
        await database.rebuildWordSearchIndex();
      });
      await database.customStatement('PRAGMA optimize');
    } finally {
      await database.close();
    }
  }

  Future<_PublishedFiles> _publish({
    required Directory stagingDirectory,
    required Directory outputDirectory,
    required bool overwrite,
  }) async {
    final names = [
      ContentAssetNames.databaseFile,
      ContentAssetNames.manifestFile,
      ContentBuildOutputNames.reportFile,
    ];
    final targets = {
      for (final name in names) name: File(p.join(outputDirectory.path, name)),
    };
    try {
      await _publisher.publish(
        stagedToTarget: {
          for (final name in names)
            File(p.join(stagingDirectory.path, name)): targets[name]!,
        },
        replaceExisting: overwrite,
      );
    } on AtomicFilePublishException catch (error) {
      throw ContentBuildException(code: error.code, message: error.message);
    }
    return _PublishedFiles(
      database: targets[ContentAssetNames.databaseFile]!,
      manifest: targets[ContentAssetNames.manifestFile]!,
      report: targets[ContentBuildOutputNames.reportFile]!,
    );
  }

  Future<void> _prepareOutputDirectory(Directory outputDirectory) async {
    final outputAsFile = File(outputDirectory.path);
    if (await outputAsFile.exists()) {
      throw const ContentBuildException(
        code: 'output_is_file',
        message: '输出路径已被普通文件占用',
      );
    }
    await outputDirectory.create(recursive: true);
  }

  Future<void> _writeJson(File file, Map<String, Object> json) async {
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      '${encoder.convert(json)}\n',
      encoding: utf8,
      flush: true,
    );
  }

  Future<String> _sha256File(File file) async {
    return (await sha256.bind(file.openRead()).first).toString();
  }

  static DateTime _systemNowUtc() => DateTime.now().toUtc();
}

final class _PublishedFiles {
  const _PublishedFiles({
    required this.database,
    required this.manifest,
    required this.report,
  });

  final File database;
  final File manifest;
  final File report;
}

/// 仅构建阶段额外生成的报告名称。
abstract final class ContentBuildOutputNames {
  static const String reportFile = 'content_build_report.json';
}
