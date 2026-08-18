import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/content_builder/audio_assets.dart';
import '../../tool/content_builder/content_build_exception.dart';

void main() {
  final workspace = Directory.current.absolute;
  final cacheRoot = Directory(
    p.join(workspace.path, '.cache', 'content_audio_asset_map_tests'),
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

  test('加载有效映射并校验 UK/US 音频文件', () async {
    final root = await _createCase(cacheRoot, cleanupDirectories);
    final audioDirectory = Directory(p.join(root.path, 'audio'));
    await Directory(p.join(audioDirectory.path, 'uk')).create(recursive: true);
    await Directory(p.join(audioDirectory.path, 'us')).create(recursive: true);
    await File(
      p.join(audioDirectory.path, 'uk', 'academic.mp3'),
    ).writeAsBytes([1, 2, 3]);
    await File(
      p.join(audioDirectory.path, 'us', 'academic.m4a'),
    ).writeAsBytes([4, 5, 6]);
    final mapFile = File(p.join(root.path, 'audio-map.json'));
    await mapFile.writeAsString(
      jsonEncode({
        '1': {
          'uk': 'assets/audio/uk/academic.mp3',
          'us': 'assets/audio/us/academic.m4a',
        },
      }),
    );

    final result = await ContentAudioAssetMap.fromFile(
      mapFile: mapFile,
      audioDirectory: audioDirectory,
    );

    expect(result.entries[1]?.uk, 'assets/audio/uk/academic.mp3');
    expect(result.entries[1]?.us, 'assets/audio/us/academic.m4a');
  });

  test('拒绝目录越界的资源路径', () async {
    final root = await _createCase(cacheRoot, cleanupDirectories);
    final audioDirectory = Directory(p.join(root.path, 'audio'));
    await audioDirectory.create(recursive: true);
    final mapFile = File(p.join(root.path, 'audio-map.json'));
    await mapFile.writeAsString(
      jsonEncode({
        '1': {'uk': 'assets/audio/uk/../secret.mp3'},
      }),
    );

    await expectLater(
      ContentAudioAssetMap.fromFile(
        mapFile: mapFile,
        audioDirectory: audioDirectory,
      ),
      throwsA(
        isA<ContentBuildException>().having(
          (error) => error.code,
          'code',
          'invalid_audio_asset_path',
        ),
      ),
    );
  });

  test('拒绝缺失的本地音频文件', () async {
    final root = await _createCase(cacheRoot, cleanupDirectories);
    final audioDirectory = Directory(p.join(root.path, 'audio'));
    await Directory(p.join(audioDirectory.path, 'uk')).create(recursive: true);
    final mapFile = File(p.join(root.path, 'audio-map.json'));
    await mapFile.writeAsString(
      jsonEncode({
        '1': {'uk': 'assets/audio/uk/academic.mp3'},
      }),
    );

    await expectLater(
      ContentAudioAssetMap.fromFile(
        mapFile: mapFile,
        audioDirectory: audioDirectory,
      ),
      throwsA(
        isA<ContentBuildException>().having(
          (error) => error.code,
          'code',
          'missing_audio_file',
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
