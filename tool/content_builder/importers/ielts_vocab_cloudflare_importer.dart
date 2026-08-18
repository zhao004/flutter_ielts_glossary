import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../content_build_config.dart';
import '../content_build_exception.dart';
import '../source_models.dart';

/// 读取参考仓库固定分块格式，并转换为不依赖 JSON 字段名的源模型。
final class IeltsVocabCloudflareImporter {
  const IeltsVocabCloudflareImporter();

  Future<ImportedContent> load(ContentBuildConfig config) async {
    final preflightIssues = <ContentBuildIssue>[];
    var totalSourceBytes = 0;
    for (final fileName in config.requiredSourceFileNames) {
      final file = File(p.join(config.inputDirectory.path, fileName));
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.file) {
        preflightIssues.add(
          ContentBuildIssue(
            code: 'missing_source_file',
            message: '缺少必需普通文件，符号链接不会被读取',
            sourceFile: fileName,
          ),
        );
        continue;
      }
      final length = await file.length();
      totalSourceBytes += length;
      if (length > config.maxSourceFileBytes) {
        preflightIssues.add(
          ContentBuildIssue(
            code: 'source_file_too_large',
            message: '文件大小 $length 超过 ${config.maxSourceFileBytes} 字节上限',
            sourceFile: fileName,
          ),
        );
      }
    }
    if (totalSourceBytes > config.maxTotalSourceBytes) {
      preflightIssues.add(
        ContentBuildIssue(
          code: 'source_total_too_large',
          message:
              '源数据总大小 $totalSourceBytes 超过 ${config.maxTotalSourceBytes} 字节上限',
        ),
      );
    }
    if (preflightIssues.isNotEmpty) {
      throw ContentValidationException(preflightIssues);
    }

    final sourceDigests = <String>[];
    final groupsJson = await _readJson(config, 'groups.json', sourceDigests);
    final statsJson = await _readJson(config, 'stats.json', sourceDigests);

    final groups = _requiredList(groupsJson, 'groups.json').indexed
        .map(
          (entry) => _parseGroup(
            _requiredMap(entry.$2, 'groups.json', entry.$1),
            'groups.json',
            entry.$1,
          ),
        )
        .toList(growable: false);
    final statsMap = _requiredMap(statsJson, 'stats.json', null);
    final statsGroups =
        _requiredList(statsMap['groups'], 'stats.json', fieldName: 'groups')
            .indexed
            .map((entry) {
              return _parseGroup(
                _requiredMap(entry.$2, 'stats.json', entry.$1),
                'stats.json',
                entry.$1,
              );
            })
            .toList(growable: false);
    final stats = SourceStats(
      wordCount: _requiredInt(statsMap, 'wordCount', 'stats.json'),
      sentenceCount: _requiredInt(statsMap, 'sentenceCount', 'stats.json'),
      groupCount: _requiredInt(statsMap, 'groupCount', 'stats.json'),
      letters:
          _requiredList(statsMap['letters'], 'stats.json', fieldName: 'letters')
              .indexed
              .map((entry) {
                final value = entry.$2;
                if (value is! String || value.trim().isEmpty) {
                  _throwField('stats.json', 'letters[${entry.$1}]', '非空字符串');
                }
                return value.trim();
              })
              .toList(growable: false),
      groups: statsGroups,
    );

    final words = <SourceWord>[];
    for (final letter in config.expectedLetters) {
      final fileName = 'words-$letter.json';
      final json = await _readJson(config, fileName, sourceDigests);
      final records = _requiredList(json, fileName);
      for (final entry in records.indexed) {
        words.add(
          _parseWord(
            _requiredMap(entry.$2, fileName, entry.$1),
            fileName,
            entry.$1,
          ),
        );
      }
    }

    final sentences = <SourceSentence>[];
    for (var chunk = 0; chunk < config.expectedSentenceChunkCount; chunk++) {
      final fileName = 'sentences-$chunk.json';
      final json = await _readJson(config, fileName, sourceDigests);
      final records = _requiredList(json, fileName);
      for (final entry in records.indexed) {
        sentences.add(
          _parseSentence(
            _requiredMap(entry.$2, fileName, entry.$1),
            fileName,
            entry.$1,
          ),
        );
      }
    }

    return ImportedContent(
      groups: List.unmodifiable(groups),
      stats: stats,
      words: List.unmodifiable(words),
      sentences: List.unmodifiable(sentences),
      sourceDataSha256: sha256
          .convert(utf8.encode(sourceDigests.join('\n')))
          .toString(),
    );
  }

  Future<Object?> _readJson(
    ContentBuildConfig config,
    String fileName,
    List<String> sourceDigests,
  ) async {
    final file = File(p.join(config.inputDirectory.path, fileName));
    final length = await file.length();
    if (length > config.maxSourceFileBytes) {
      throw ContentValidationException([
        ContentBuildIssue(
          code: 'source_file_too_large',
          message: '文件大小 $length 超过 ${config.maxSourceFileBytes} 字节上限',
          sourceFile: fileName,
        ),
      ]);
    }
    final bytes = await file.readAsBytes();
    sourceDigests.add('$fileName:${sha256.convert(bytes)}');
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw ContentValidationException([
        ContentBuildIssue(
          code: 'invalid_json',
          message: '文件不是合法 UTF-8 JSON',
          sourceFile: fileName,
        ),
      ]);
    }
  }

  SourceFrequencyGroup _parseGroup(
    Map<String, Object?> json,
    String fileName,
    int index,
  ) {
    return SourceFrequencyGroup(
      id: _requiredInt(json, 'id', fileName, index: index),
      name: _requiredString(json, 'name', fileName, index: index),
      rank: _requiredInt(json, 'rank', fileName, index: index),
      minOccurrences: _requiredInt(json, 'minOccur', fileName, index: index),
      maxOccurrences: _requiredInt(json, 'maxOccur', fileName, index: index),
      wordCount: _requiredInt(json, 'wordCount', fileName, index: index),
    );
  }

  SourceWord _parseWord(Map<String, Object?> json, String fileName, int index) {
    return SourceWord(
      id: _requiredInt(json, 'id', fileName, index: index),
      word: _requiredString(json, 'word', fileName, index: index),
      translation: _optionalString(json, 'translation', fileName, index),
      phonetic: _optionalString(json, 'phonetic', fileName, index),
      englishDefinition: _optionalString(
        json,
        'englishDefinition',
        fileName,
        index,
      ),
      mnemonic: _optionalString(json, 'mnemonic', fileName, index),
      audioUk: _optionalString(json, 'audioUk', fileName, index),
      audioUs: _optionalString(json, 'audioUs', fileName, index),
      occurrences: _requiredInt(json, 'occurrences', fileName, index: index),
      groupId: _requiredInt(json, 'groupId', fileName, index: index),
      firstLetter: _requiredString(json, 'firstLetter', fileName, index: index),
      length: _requiredInt(json, 'length', fileName, index: index),
      sentenceCount: _requiredInt(
        json,
        'sentenceCount',
        fileName,
        index: index,
      ),
    );
  }

  SourceSentence _parseSentence(
    Map<String, Object?> json,
    String fileName,
    int index,
  ) {
    return SourceSentence(
      id: _requiredInt(json, 'id', fileName, index: index),
      wordId: _requiredInt(json, 'wordId', fileName, index: index),
      targetForm: _requiredString(json, 'form', fileName, index: index),
      sentence: _requiredString(json, 'sentence', fileName, index: index),
      translation: _optionalString(json, 'translation', fileName, index),
      source: _optionalString(json, 'source', fileName, index),
      location: _optionalString(json, 'location', fileName, index),
      sourceFile: fileName,
      sourceIndex: index,
    );
  }
}

List<Object?> _requiredList(
  Object? value,
  String fileName, {
  String? fieldName,
}) {
  if (value is List<Object?>) {
    return value;
  }
  _throwField(fileName, fieldName ?? 'root', '数组');
}

Map<String, Object?> _requiredMap(Object? value, String fileName, int? index) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  _throwField(fileName, index == null ? 'root' : 'record[$index]', '对象');
}

String _requiredString(
  Map<String, Object?> json,
  String fieldName,
  String fileName, {
  int? index,
}) {
  final value = json[fieldName];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  _throwField(fileName, _fieldPath(fieldName, index), '非空字符串');
}

String? _optionalString(
  Map<String, Object?> json,
  String fieldName,
  String fileName,
  int index,
) {
  final value = json[fieldName];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    _throwField(fileName, _fieldPath(fieldName, index), '字符串或 null');
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

int _requiredInt(
  Map<String, Object?> json,
  String fieldName,
  String fileName, {
  int? index,
}) {
  final value = json[fieldName];
  if (value is int) {
    return value;
  }
  _throwField(fileName, _fieldPath(fieldName, index), '整数');
}

String _fieldPath(String fieldName, int? index) {
  return index == null ? fieldName : 'record[$index].$fieldName';
}

Never _throwField(String fileName, String fieldName, String expected) {
  throw ContentValidationException([
    ContentBuildIssue(
      code: 'invalid_source_field',
      message: '字段 $fieldName 必须是$expected',
      sourceFile: fileName,
    ),
  ]);
}
