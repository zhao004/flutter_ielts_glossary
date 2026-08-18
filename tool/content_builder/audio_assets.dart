import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'content_build_exception.dart';

const String _assetPrefix = 'assets/audio/';
const Set<String> _supportedAudioExtensions = {'.mp3', '.m4a', '.aac'};

/// 一个词条可发布的 UK/US 本地音频资源路径。
final class ContentAudioAssetPaths {
  const ContentAudioAssetPaths({this.uk, this.us});

  final String? uk;
  final String? us;

  bool get isEmpty => uk == null && us == null;
}

/// 经校验的词条音频映射；远程 URL 不会直接进入内容库。
final class ContentAudioAssetMap {
  const ContentAudioAssetMap(this.entries);

  const ContentAudioAssetMap.empty() : entries = const {};

  final Map<int, ContentAudioAssetPaths> entries;

  /// 从映射 JSON 和本地音频目录读取资源，并拒绝越界、符号链接和缺失文件。
  static Future<ContentAudioAssetMap> fromFile({
    required File mapFile,
    required Directory audioDirectory,
  }) async {
    final mapType = await FileSystemEntity.type(
      mapFile.path,
      followLinks: false,
    );
    if (mapType != FileSystemEntityType.file) {
      throw ContentBuildException(
        code: 'missing_audio_map_file',
        message: '音频映射必须是普通文件：${mapFile.path}',
      );
    }
    final audioType = await FileSystemEntity.type(
      audioDirectory.path,
      followLinks: false,
    );
    if (audioType != FileSystemEntityType.directory) {
      throw ContentBuildException(
        code: 'missing_audio_directory',
        message: '音频目录必须是普通目录：${audioDirectory.path}',
      );
    }
    final bytes = await mapFile.readAsBytes();
    if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
      throw ContentBuildException(
        code: 'invalid_audio_map_size',
        message: '音频映射文件必须在 1-4 MiB 之间',
      );
    }
    final decoded = _decodeObject(bytes, mapFile.path);
    final entries = <int, ContentAudioAssetPaths>{};
    for (final entry in decoded.entries) {
      final wordId = int.tryParse(entry.key);
      if (wordId == null || wordId <= 0) {
        throw ContentBuildException(
          code: 'invalid_audio_word_id',
          message: '音频映射包含无效单词 ID：${entry.key}',
        );
      }
      final value = _asObject(entry.value, mapFile.path, entry.key);
      final uk = await _readAssetPath(
        value['uk'],
        accent: 'uk',
        wordId: wordId,
        mapFile: mapFile,
        audioDirectory: audioDirectory,
      );
      final us = await _readAssetPath(
        value['us'],
        accent: 'us',
        wordId: wordId,
        mapFile: mapFile,
        audioDirectory: audioDirectory,
      );
      if (uk == null && us == null) {
        throw ContentBuildException(
          code: 'empty_audio_mapping',
          message: '单词 ID $wordId 至少需要一个 UK 或 US 音频路径',
        );
      }
      entries[wordId] = ContentAudioAssetPaths(uk: uk, us: us);
    }
    return ContentAudioAssetMap(Map.unmodifiable(entries));
  }

  static Map<String, Object?> _decodeObject(List<int> bytes, String path) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      // 统一转换为不包含原始正文的稳定错误。
    }
    throw ContentBuildException(
      code: 'invalid_audio_map_json',
      message: '音频映射不是合法 JSON 对象：$path',
    );
  }

  static Map<String, Object?> _asObject(
    Object? value,
    String path,
    String wordId,
  ) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw ContentBuildException(
      code: 'invalid_audio_mapping',
      message: '单词 ID $wordId 的音频映射必须是对象：$path',
    );
  }

  static Future<String?> _readAssetPath(
    Object? value, {
    required String accent,
    required int wordId,
    required File mapFile,
    required Directory audioDirectory,
  }) async {
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw ContentBuildException(
        code: 'invalid_audio_asset_path',
        message: '单词 ID $wordId 的 $accent 音频路径无效：${mapFile.path}',
      );
    }
    final assetPath = value.trim();
    final expectedPrefix = '$_assetPrefix$accent/';
    final extension = p.extension(assetPath).toLowerCase();
    final relativePath = assetPath.startsWith(expectedPrefix)
        ? assetPath.substring(_assetPrefix.length).split('/')
        : const <String>[];
    final hasDotSegment = relativePath.any((segment) => segment == '.');
    if (!assetPath.startsWith(expectedPrefix) ||
        assetPath.length > 255 ||
        assetPath.contains('..') ||
        assetPath.contains('\\') ||
        assetPath.contains('//') ||
        hasDotSegment ||
        !_supportedAudioExtensions.contains(extension)) {
      throw ContentBuildException(
        code: 'invalid_audio_asset_path',
        message: '单词 ID $wordId 的 $accent 音频路径不符合资源白名单',
      );
    }
    var currentPath = audioDirectory.path;
    for (var index = 0; index < relativePath.length; index++) {
      currentPath = p.join(currentPath, relativePath[index]);
      final fileType = await FileSystemEntity.type(
        currentPath,
        followLinks: false,
      );
      if (fileType == FileSystemEntityType.link) {
        throw ContentBuildException(
          code: 'invalid_audio_asset_path',
          message: '音频路径不能经过符号链接：$assetPath',
        );
      }
      final isLast = index == relativePath.length - 1;
      if ((!isLast && fileType != FileSystemEntityType.directory) ||
          (isLast && fileType != FileSystemEntityType.file)) {
        throw ContentBuildException(
          code: 'missing_audio_file',
          message: '音频文件不存在或不是普通文件：$assetPath',
        );
      }
    }
    return assetPath;
  }
}
