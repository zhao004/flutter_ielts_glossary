import 'dart:convert';

/// 内容清单字段或 JSON 结构无效。
final class ContentManifestException implements Exception {
  const ContentManifestException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// 与 SQLite 一起发布的版本化内容清单。
final class ContentManifest {
  const ContentManifest({
    required this.formatVersion,
    required this.contentVersion,
    required this.sourceRepository,
    required this.sourceRevision,
    required this.generatedAt,
    required this.databaseFile,
    required this.databaseBytes,
    required this.databaseSha256,
    required this.sourceDataSha256,
    required this.wordCount,
    required this.sentenceCount,
    required this.activeGroupCount,
    required this.groupWordCounts,
    required this.licenseNotice,
  });

  static const int currentFormatVersion = 1;
  static const int expectedActiveGroupCount = 6;
  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  final int formatVersion;
  final String contentVersion;
  final String sourceRepository;
  final String sourceRevision;
  final DateTime generatedAt;
  final String databaseFile;
  final int databaseBytes;
  final String databaseSha256;
  final String sourceDataSha256;
  final int wordCount;
  final int sentenceCount;
  final int activeGroupCount;
  final Map<int, int> groupWordCounts;
  final String licenseNotice;

  Map<String, Object> toJson() => {
    'formatVersion': formatVersion,
    'contentVersion': contentVersion,
    'sourceRepository': sourceRepository,
    'sourceRevision': sourceRevision,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'databaseFile': databaseFile,
    'databaseBytes': databaseBytes,
    'databaseSha256': databaseSha256,
    'sourceDataSha256': sourceDataSha256,
    'recordCounts': {
      'words': wordCount,
      'sentences': sentenceCount,
      'activeGroups': activeGroupCount,
      'groupWords': {
        for (final entry in groupWordCounts.entries)
          entry.key.toString(): entry.value,
      },
    },
    'licenseNotice': licenseNotice,
  };

  factory ContentManifest.fromBytes(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException();
      }
      return ContentManifest.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on ContentManifestException {
      rethrow;
    } on FormatException {
      throw const ContentManifestException(
        code: 'invalid_manifest_json',
        message: '内容清单不是合法 UTF-8 JSON 对象',
      );
    }
  }

  factory ContentManifest.fromJson(Map<String, Object?> json) {
    final counts = _requiredMap(json, 'recordCounts');
    final generatedAtText = _requiredString(json, 'generatedAt');
    final generatedAt = DateTime.tryParse(generatedAtText)?.toUtc();
    if (generatedAt == null) {
      throw const ContentManifestException(
        code: 'invalid_manifest_date',
        message: '内容清单 generatedAt 不是合法时间',
      );
    }
    final manifest = ContentManifest(
      formatVersion: _requiredInt(json, 'formatVersion'),
      contentVersion: _requiredString(json, 'contentVersion'),
      sourceRepository: _requiredString(json, 'sourceRepository'),
      sourceRevision: _requiredString(json, 'sourceRevision'),
      generatedAt: generatedAt,
      databaseFile: _requiredString(json, 'databaseFile'),
      databaseBytes: _requiredInt(json, 'databaseBytes'),
      databaseSha256: _requiredString(json, 'databaseSha256'),
      sourceDataSha256: _requiredString(json, 'sourceDataSha256'),
      wordCount: _requiredInt(counts, 'words'),
      sentenceCount: _requiredInt(counts, 'sentences'),
      activeGroupCount: _requiredInt(counts, 'activeGroups'),
      groupWordCounts: _requiredIntMap(counts, 'groupWords'),
      licenseNotice: _requiredString(json, 'licenseNotice'),
    );
    manifest._validateValues();
    return manifest;
  }

  void _validateValues() {
    if (formatVersion <= 0 ||
        databaseBytes <= 0 ||
        wordCount <= 0 ||
        sentenceCount <= 0 ||
        activeGroupCount != expectedActiveGroupCount ||
        groupWordCounts.length != expectedActiveGroupCount ||
        !groupWordCounts.keys.toSet().containsAll(const {1, 2, 3, 4, 5, 6}) ||
        groupWordCounts.values.any((count) => count < 0) ||
        groupWordCounts.values.fold(0, (sum, count) => sum + count) !=
            wordCount) {
      throw const ContentManifestException(
        code: 'invalid_manifest_value',
        message: '内容清单包含非正数或相互矛盾的记录统计',
      );
    }
    if (!_sha256Pattern.hasMatch(databaseSha256) ||
        !_sha256Pattern.hasMatch(sourceDataSha256)) {
      throw const ContentManifestException(
        code: 'invalid_manifest_checksum',
        message: '内容清单 SHA-256 必须是 64 位小写十六进制',
      );
    }
  }
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw ContentManifestException(
    code: 'invalid_manifest_field',
    message: '内容清单字段 $key 必须是对象',
  );
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw ContentManifestException(
    code: 'invalid_manifest_field',
    message: '内容清单字段 $key 必须是非空字符串',
  );
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw ContentManifestException(
    code: 'invalid_manifest_field',
    message: '内容清单字段 $key 必须是整数',
  );
}

Map<int, int> _requiredIntMap(Map<String, Object?> json, String key) {
  final values = _requiredMap(json, key);
  final result = <int, int>{};
  for (final entry in values.entries) {
    final parsedKey = int.tryParse(entry.key);
    if (parsedKey == null || entry.value is! int) {
      throw ContentManifestException(
        code: 'invalid_manifest_field',
        message: '内容清单字段 $key 必须是整数键值对象',
      );
    }
    result[parsedKey] = entry.value! as int;
  }
  return Map.unmodifiable(result);
}
