import 'backup_exceptions.dart';
import 'backup_record_counts.dart';

/// `.ieltsbackup` 文件根清单；dataSha256 覆盖 data.json 的原始 UTF-8 字节。
final class BackupManifest {
  BackupManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.userSchemaVersion,
    required this.contentVersion,
    required this.exportedAt,
    required this.recordCounts,
    required this.dataSha256,
  }) {
    _validate();
  }

  static const int currentFormatVersion = 1;
  static final RegExp sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static const int maximumVersionLength = 128;

  final int formatVersion;
  final String appVersion;
  final int userSchemaVersion;
  final String contentVersion;
  final DateTime exportedAt;
  final BackupRecordCounts recordCounts;
  final String dataSha256;

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'appVersion': appVersion,
    'userSchemaVersion': userSchemaVersion,
    'contentVersion': contentVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'recordCounts': recordCounts.toJson(),
    'dataSha256': dataSha256,
  };

  factory BackupManifest.fromJson(Map<String, Object?> json) {
    const keys = {
      'formatVersion',
      'appVersion',
      'userSchemaVersion',
      'contentVersion',
      'exportedAt',
      'recordCounts',
      'dataSha256',
    };
    if (!json.keys.toSet().containsAll(keys) || !keys.containsAll(json.keys)) {
      throw const BackupFormatException(
        'invalid_manifest_fields',
        'manifest 字段集合不匹配协议',
      );
    }
    final exportedAtValue = json['exportedAt'];
    if (exportedAtValue is! String) {
      throw const BackupFormatException(
        'invalid_manifest_date',
        'exportedAt 必须是字符串',
      );
    }
    final exportedAt = DateTime.tryParse(exportedAtValue)?.toUtc();
    if (exportedAt == null || !exportedAtValue.endsWith('Z')) {
      throw const BackupFormatException(
        'invalid_manifest_date',
        'exportedAt 不是合法时间',
      );
    }
    final manifest = BackupManifest(
      formatVersion: _readInt(json, 'formatVersion'),
      appVersion: _readVersion(json, 'appVersion'),
      userSchemaVersion: _readPositiveInt(json, 'userSchemaVersion'),
      contentVersion: _readVersion(json, 'contentVersion'),
      exportedAt: exportedAt,
      recordCounts: BackupRecordCounts.fromJson(json['recordCounts']),
      dataSha256: _readHash(json['dataSha256']),
    );
    return manifest;
  }

  BackupManifest copyWith({String? dataSha256}) {
    return BackupManifest(
      formatVersion: formatVersion,
      appVersion: appVersion,
      userSchemaVersion: userSchemaVersion,
      contentVersion: contentVersion,
      exportedAt: exportedAt,
      recordCounts: recordCounts,
      dataSha256: dataSha256 ?? this.dataSha256,
    );
  }

  void _validate() {
    if (formatVersion <= 0 || userSchemaVersion <= 0) {
      throw const BackupFormatException(
        'invalid_manifest_version',
        'manifest 版本必须为正整数',
      );
    }
    if (appVersion.trim().isEmpty ||
        appVersion.length > maximumVersionLength ||
        contentVersion.trim().isEmpty ||
        contentVersion.length > maximumVersionLength) {
      throw const BackupFormatException(
        'invalid_manifest_version',
        '应用版本和词库版本长度无效',
      );
    }
    if (!exportedAt.isUtc || !sha256Pattern.hasMatch(dataSha256)) {
      throw const BackupFormatException(
        'invalid_manifest_checksum',
        'manifest 时间或 SHA-256 格式无效',
      );
    }
    recordCounts.validate();
  }
}

int _readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw BackupFormatException('invalid_manifest_field', '$key 必须是整数');
  }
  return value;
}

int _readPositiveInt(Map<String, Object?> json, String key) {
  final value = _readInt(json, key);
  if (value <= 0) {
    throw BackupFormatException('invalid_manifest_field', '$key 必须为正整数');
  }
  return value;
}

String _readVersion(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > BackupManifest.maximumVersionLength) {
    throw BackupFormatException('invalid_manifest_field', '$key 字符串无效');
  }
  return value.trim();
}

String _readHash(Object? value) {
  if (value is! String || !BackupManifest.sha256Pattern.hasMatch(value)) {
    throw const BackupFormatException(
      'invalid_manifest_checksum',
      'dataSha256 必须是 64 位小写十六进制',
    );
  }
  return value;
}
