import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_audio_asset_verifier.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_validation.dart';

void main() {
  final workspace = Directory.current.absolute;
  final cacheRoot = Directory(
    p.join(workspace.path, '.cache', 'content_audio_asset_verifier_tests'),
  );
  final cleanupDirectories = <Directory>[];

  tearDown(() async {
    for (final directory in cleanupDirectories.reversed) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    cleanupDirectories.clear();
  });

  test('校验数据库引用的最终音频资源', () async {
    final root = await _createCase(cacheRoot, cleanupDirectories);
    final audioDirectory = Directory(p.join(root.path, 'audio'));
    await Directory(p.join(audioDirectory.path, 'uk')).create(recursive: true);
    await File(
      p.join(audioDirectory.path, 'uk', 'academic.mp3'),
    ).writeAsBytes([1, 2, 3]);
    final databaseFile = await _createDatabase(
      root,
      'assets/audio/uk/academic.mp3',
    );

    await const ContentAudioAssetVerifier().verify(
      databaseFile: databaseFile,
      audioDirectory: audioDirectory,
    );
  });

  test('缺失音频文件时返回结构化问题', () async {
    final root = await _createCase(cacheRoot, cleanupDirectories);
    final audioDirectory = Directory(p.join(root.path, 'audio'));
    await audioDirectory.create(recursive: true);
    final databaseFile = await _createDatabase(
      root,
      'assets/audio/uk/academic.mp3',
    );

    await expectLater(
      const ContentAudioAssetVerifier().verify(
        databaseFile: databaseFile,
        audioDirectory: audioDirectory,
      ),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('missing_audio_file'),
        ),
      ),
    );
  });

  test('拒绝数据库中的越界音频路径', () async {
    final root = await _createCase(cacheRoot, cleanupDirectories);
    final audioDirectory = Directory(p.join(root.path, 'audio'));
    await audioDirectory.create(recursive: true);
    final databaseFile = await _createDatabase(
      root,
      'assets/audio/../outside.mp3',
    );

    await expectLater(
      const ContentAudioAssetVerifier().verify(
        databaseFile: databaseFile,
        audioDirectory: audioDirectory,
      ),
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('invalid_audio_asset_path'),
        ),
      ),
    );
  });
}

Future<Directory> _createCase(
  Directory cacheRoot,
  List<Directory> cleanupDirectories,
) async {
  await cacheRoot.create(recursive: true);
  final directory = await cacheRoot.createTemp('case-');
  cleanupDirectories.add(directory);
  return directory;
}

Future<File> _createDatabase(Directory root, String audioPath) async {
  final databaseFile = File(p.join(root.path, 'content.sqlite'));
  final database = ContentDatabase.forExecutor(NativeDatabase(databaseFile));
  try {
    await database
        .into(database.frequencyGroups)
        .insert(
          FrequencyGroupsCompanion.insert(
            id: const drift.Value(1),
            name: '第一组',
            rank: 1,
            minOccurrences: 1,
            maxOccurrences: const drift.Value(100),
          ),
        );
    await database
        .into(database.words)
        .insert(
          WordsCompanion.insert(
            id: const drift.Value(1),
            word: 'academic',
            occurrences: 10,
            frequencyGroupId: 1,
            firstLetter: 'A',
            audioUkAsset: drift.Value(audioPath),
          ),
        );
  } finally {
    await database.close();
  }
  return databaseFile;
}
