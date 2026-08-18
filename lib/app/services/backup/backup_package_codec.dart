import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../models/backup/backup_exceptions.dart';
import '../../models/backup/backup_manifest.dart';
import '../../models/backup/backup_record_counts.dart';
import '../../models/backup/backup_snapshot.dart';
import 'backup_data_codec.dart';

/// `.ieltsbackup` ZIP 包的编码、大小限制、条目白名单和哈希校验。
final class BackupPackageCodec {
  const BackupPackageCodec({
    this.maxBackupBytes = defaultMaxBackupBytes,
    this.maxDecompressedBytes = defaultMaxDecompressedBytes,
    this.dataCodec = const BackupDataCodec(),
  }) : assert(maxBackupBytes > 0),
       assert(maxDecompressedBytes > 0);

  static const int defaultMaxBackupBytes = 100 * 1024 * 1024;
  static const int defaultMaxDecompressedBytes = 200 * 1024 * 1024;
  static const String manifestEntryName = 'manifest.json';
  static const String dataEntryName = 'data.json';

  final int maxBackupBytes;
  final int maxDecompressedBytes;
  final BackupDataCodec dataCodec;

  /// 将用户快照写成包含两个根文件的 ZIP 字节流。
  Uint8List encode({
    required String appVersion,
    required int userSchemaVersion,
    required String contentVersion,
    required DateTime exportedAt,
    required BackupSnapshot snapshot,
  }) {
    final dataBytes = Uint8List.fromList(
      utf8.encode(dataCodec.encode(snapshot)),
    );
    final manifest = BackupManifest(
      formatVersion: BackupManifest.currentFormatVersion,
      appVersion: appVersion,
      userSchemaVersion: userSchemaVersion,
      contentVersion: contentVersion,
      exportedAt: exportedAt.toUtc(),
      recordCounts: _countsOf(snapshot),
      dataSha256: sha256.convert(dataBytes).toString(),
    );
    final manifestBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(manifest.toJson())),
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile(manifestEntryName, manifestBytes.length, manifestBytes),
      )
      ..addFile(ArchiveFile(dataEntryName, dataBytes.length, dataBytes));
    final encoded = ZipEncoder().encode(archive);
    if (encoded.length > maxBackupBytes) {
      throw const BackupFormatException('backup_too_large', '压缩后的备份超过大小上限');
    }
    return Uint8List.fromList(encoded);
  }

  /// 只读解析 ZIP，先验证条目、解压大小和 data.json 哈希，再解析记录。
  DecodedBackupPackage decode(
    List<int> bytes, {
    bool allowFutureFormat = false,
  }) {
    if (bytes.isEmpty || bytes.length > maxBackupBytes) {
      throw const BackupFormatException('backup_too_large', '备份文件为空或超过大小上限');
    }
    final archive = _decodeArchive(bytes);
    final entries = <String, List<int>>{};
    var decompressedBytes = 0;
    for (final file in archive) {
      if (!file.isFile ||
          file.name != manifestEntryName && file.name != dataEntryName ||
          entries.containsKey(file.name)) {
        throw const BackupFormatException(
          'invalid_zip_entries',
          '备份 ZIP 只能包含 manifest.json 和 data.json 各一份',
        );
      }
      final content = file.content;
      decompressedBytes += content.length;
      if (decompressedBytes > maxDecompressedBytes ||
          content.length > maxDecompressedBytes) {
        throw const BackupFormatException(
          'decompressed_too_large',
          '备份解压后超过大小上限',
        );
      }
      entries[file.name] = List<int>.unmodifiable(content);
    }
    if (entries.length != 2 ||
        !entries.containsKey(manifestEntryName) ||
        !entries.containsKey(dataEntryName)) {
      throw const BackupFormatException('invalid_zip_entries', '备份 ZIP 缺少必需条目');
    }

    final manifest = _decodeManifest(entries[manifestEntryName]!);
    final isFutureFormat =
        manifest.formatVersion > BackupManifest.currentFormatVersion;
    if (isFutureFormat && !allowFutureFormat) {
      throw const BackupFormatException(
        'future_format_version',
        '备份格式版本高于当前支持版本，只允许预览',
      );
    }
    if (!isFutureFormat &&
        manifest.formatVersion != BackupManifest.currentFormatVersion) {
      throw const BackupFormatException(
        'unsupported_format_version',
        '备份格式版本不受支持',
      );
    }
    final dataBytes = entries[dataEntryName]!;
    final actualHash = sha256.convert(dataBytes).toString();
    if (actualHash != manifest.dataSha256) {
      throw const BackupFormatException(
        'data_checksum_mismatch',
        'data.json SHA-256 校验失败',
      );
    }
    if (isFutureFormat) {
      return DecodedBackupPackage(
        manifest: manifest,
        snapshot: null,
        dataBytes: Uint8List.fromList(dataBytes),
        isFutureFormat: true,
      );
    }
    final dataSource = _decodeUtf8(dataBytes, dataEntryName);
    final snapshot = dataCodec.decode(dataSource);
    final actualCounts = _countsOf(snapshot);
    if (!_countsEqual(actualCounts, manifest.recordCounts)) {
      throw const BackupFormatException(
        'record_count_mismatch',
        'manifest 记录数与 data.json 不一致',
      );
    }
    return DecodedBackupPackage(
      manifest: manifest,
      snapshot: snapshot,
      dataBytes: Uint8List.fromList(dataBytes),
      isFutureFormat: false,
    );
  }

  /// 在后台 Isolate 完成 ZIP、哈希和 JSON 解析，再在当前 Isolate 恢复领域对象。
  Future<DecodedBackupPackage> decodeInBackground(
    List<int> bytes, {
    bool allowFutureFormat = false,
  }) async {
    late final Map<String, Object?> payload;
    try {
      payload = await Isolate.run<Map<String, Object?>>(
        () => _decodePayloadInIsolate(
          bytes,
          maxBackupBytes,
          maxDecompressedBytes,
          allowFutureFormat,
        ),
      );
    } on Object {
      throw const BackupFormatException('background_decode_failed', '后台备份校验失败');
    }
    final errorCode = payload['errorCode'];
    if (errorCode is String) {
      final message = payload['errorMessage'];
      throw BackupFormatException(
        errorCode,
        message is String ? message : '后台备份校验失败',
      );
    }
    return _restoreBackgroundPayload(payload);
  }

  DecodedBackupPackage _restoreBackgroundPayload(Map<String, Object?> payload) {
    final manifestValue = payload['manifest'];
    if (manifestValue is! Map) {
      throw const BackupFormatException(
        'background_decode_failed',
        '后台备份清单返回值无效',
      );
    }
    final manifest = BackupManifest.fromJson(
      manifestValue.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final isFutureFormat = payload['isFutureFormat'];
    if (isFutureFormat is! bool) {
      throw const BackupFormatException(
        'background_decode_failed',
        '后台备份版本返回值无效',
      );
    }
    final dataBytesValue = payload['dataBytes'];
    if (dataBytesValue is! List ||
        dataBytesValue.any((value) => value is! int)) {
      throw const BackupFormatException(
        'background_decode_failed',
        '后台备份数据返回值无效',
      );
    }
    final snapshotValue = payload['snapshot'];
    final snapshot = isFutureFormat
        ? null
        : dataCodec.decodeValue(snapshotValue);
    if (!isFutureFormat && snapshot == null) {
      throw const BackupFormatException(
        'background_decode_failed',
        '后台备份缺少数据快照',
      );
    }
    if (snapshot != null &&
        !_countsEqual(_countsOf(snapshot), manifest.recordCounts)) {
      throw const BackupFormatException(
        'record_count_mismatch',
        'manifest 记录数与 data.json 不一致',
      );
    }
    return DecodedBackupPackage(
      manifest: manifest,
      snapshot: snapshot,
      dataBytes: Uint8List.fromList(dataBytesValue.cast<int>()),
      isFutureFormat: isFutureFormat,
    );
  }

  Archive _decodeArchive(List<int> bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes, verify: true);
    } on Object {
      throw const BackupFormatException('invalid_zip', '备份不是可验证的 ZIP 数据包');
    }
  }

  BackupManifest _decodeManifest(List<int> bytes) {
    final source = _decodeUtf8(bytes, manifestEntryName);
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const BackupFormatException(
          'invalid_manifest_json',
          'manifest.json 根节点必须是对象',
        );
      }
      final map = decoded.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      );
      return BackupManifest.fromJson(map);
    } on BackupFormatException {
      rethrow;
    } on FormatException {
      throw const BackupFormatException(
        'invalid_manifest_json',
        'manifest.json 不是合法 JSON',
      );
    }
  }

  String _decodeUtf8(List<int> bytes, String entryName) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw BackupFormatException('invalid_utf8', '$entryName 不是合法 UTF-8');
    }
  }

  BackupRecordCounts _countsOf(BackupSnapshot snapshot) {
    return BackupRecordCounts(
      userWordStates: snapshot.userWordStates.length,
      favoriteWords: snapshot.favoriteWords.length,
      favoriteSentences: snapshot.favoriteSentences.length,
      practiceSessions: snapshot.practiceSessions.length,
      practiceAnswers: snapshot.practiceAnswers.length,
      learningEvents: snapshot.learningEvents.length,
      appSettings: snapshot.appSettings == null ? 0 : 1,
    );
  }

  bool _countsEqual(BackupRecordCounts left, BackupRecordCounts right) {
    return left.userWordStates == right.userWordStates &&
        left.favoriteWords == right.favoriteWords &&
        left.favoriteSentences == right.favoriteSentences &&
        left.practiceSessions == right.practiceSessions &&
        left.practiceAnswers == right.practiceAnswers &&
        left.learningEvents == right.learningEvents &&
        left.appSettings == right.appSettings;
  }
}

Map<String, Object?> _decodePayloadInIsolate(
  List<int> bytes,
  int maxBackupBytes,
  int maxDecompressedBytes,
  bool allowFutureFormat,
) {
  try {
    final decoded = BackupPackageCodec(
      maxBackupBytes: maxBackupBytes,
      maxDecompressedBytes: maxDecompressedBytes,
    ).decode(bytes, allowFutureFormat: allowFutureFormat);
    return <String, Object?>{
      'manifest': decoded.manifest.toJson(),
      'snapshot': decoded.snapshot == null
          ? null
          : const BackupDataCodec().encodeValue(decoded.snapshot!),
      'dataBytes': List<int>.unmodifiable(decoded.dataBytes),
      'isFutureFormat': decoded.isFutureFormat,
    };
  } on BackupFormatException catch (error) {
    return <String, Object?>{
      'errorCode': error.code,
      'errorMessage': error.message,
    };
  } on Object {
    return const <String, Object?>{
      'errorCode': 'background_decode_failed',
      'errorMessage': '后台备份校验失败',
    };
  }
}

/// ZIP 解码后的只读备份包，供预览和导入共用，未持有文件句柄。
final class DecodedBackupPackage {
  const DecodedBackupPackage({
    required this.manifest,
    required this.snapshot,
    required this.dataBytes,
    required this.isFutureFormat,
  });

  final BackupManifest manifest;
  final BackupSnapshot? snapshot;
  final Uint8List dataBytes;
  final bool isFutureFormat;
}
