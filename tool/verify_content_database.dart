import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_ielts_glossary/app/models/content/content_asset_names.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_audio_asset_verifier.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_database_verifier.dart';

import 'content_builder/content_build_exception.dart';

/// 独立复核已构建内容库，供本地开发和 CI 使用。
Future<void> main(List<String> arguments) async {
  final parser = ArgParser(allowTrailingOptions: false)
    ..addFlag('help', abbr: 'h', negatable: false, help: '显示帮助')
    ..addOption('directory', mandatory: true, help: '构建产物目录')
    ..addOption('audio-directory', help: '可选，和 assets/audio/ 对应的最终音频资源目录');
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

  final directory = Directory(options.option('directory')!).absolute;
  try {
    final databaseFile = File(
      p.join(directory.path, ContentAssetNames.databaseFile),
    );
    final manifestFile = File(
      p.join(directory.path, ContentAssetNames.manifestFile),
    );
    final manifest = await const ContentDatabaseVerifier().verify(
      databaseFile: databaseFile,
      manifestFile: manifestFile,
    );
    final audioDirectoryPath = options.option('audio-directory');
    if (audioDirectoryPath != null) {
      await const ContentAudioAssetVerifier().verify(
        databaseFile: databaseFile,
        audioDirectory: Directory(audioDirectoryPath).absolute,
      );
    }
    stdout.writeln(
      '内容库校验通过：${manifest.contentVersion}，'
      '${manifest.wordCount} 词，${manifest.sentenceCount} 例句',
    );
  } on ContentValidationException catch (error) {
    for (final issue in error.issues.take(50)) {
      stderr.writeln(issue);
    }
    final summary = error.issueCounts.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    stderr.writeln('问题汇总：$summary');
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
