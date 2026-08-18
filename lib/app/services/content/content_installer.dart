import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../models/content/content_asset_names.dart';
import '../../models/content/content_manifest.dart';
import '../files/atomic_file_set_publisher.dart';
import 'content_asset_reader.dart';
import 'content_database_verifier.dart';
import 'content_installation.dart';
import 'content_validation.dart';

/// 把已打包内容资产安装到应用支持目录，并保证失败时保留旧版本。
final class ContentInstaller implements ContentInstallationService {
  ContentInstaller({
    required Directory applicationSupportDirectory,
    required this.assetReader,
    this.verifier = const ContentDatabaseVerifier(),
    this.publisher = const AtomicFileSetPublisher(),
    this.maxDatabaseBytes = defaultMaxDatabaseBytes,
  }) : applicationSupportDirectory = Directory(
         p.normalize(applicationSupportDirectory.absolute.path),
       ) {
    if (_isFileSystemRoot(this.applicationSupportDirectory.path) ||
        maxDatabaseBytes <= 0) {
      throw ArgumentError('应用支持目录或数据库大小上限无效');
    }
  }

  static const int defaultMaxDatabaseBytes = 512 * 1024 * 1024;

  final Directory applicationSupportDirectory;
  final ContentAssetReader assetReader;
  final ContentDatabaseVerifier verifier;
  final AtomicFileSetPublisher publisher;
  final int maxDatabaseBytes;

  @override
  Future<ContentInstallResult> install({
    ContentInstallProgressCallback? onProgress,
  }) async {
    _notify(
      onProgress,
      const ContentInstallProgress(phase: ContentInstallPhase.readingManifest),
    );
    final manifestBytes = await _readBundledManifest();
    final bundledManifest = verifier.parseManifestBytes(manifestBytes);
    _validateBundledManifest(bundledManifest);
    await _prepareSupportDirectory();

    _notify(
      onProgress,
      const ContentInstallProgress(phase: ContentInstallPhase.checkingExisting),
    );

    final databaseFile = File(
      p.join(applicationSupportDirectory.path, ContentAssetNames.databaseFile),
    );
    final manifestFile = File(
      p.join(applicationSupportDirectory.path, ContentAssetNames.manifestFile),
    );
    final hadExistingFiles =
        await databaseFile.exists() || await manifestFile.exists();
    final existingManifest = await _verifyExisting(
      databaseFile: databaseFile,
      manifestFile: manifestFile,
    );
    if (existingManifest != null) {
      final decision = _decideVersion(
        existing: existingManifest,
        bundled: bundledManifest,
      );
      if (decision != null) {
        return ContentInstallResult(
          status: decision,
          manifest: existingManifest,
          databaseFile: databaseFile,
          manifestFile: manifestFile,
          retainedBackupFiles: const [],
        );
      }
    }

    final stagingDirectory = await applicationSupportDirectory.createTemp(
      '.content_install_',
    );
    try {
      final stagedDatabase = File(
        p.join(stagingDirectory.path, ContentAssetNames.databaseFile),
      );
      final stagedManifest = File(
        p.join(stagingDirectory.path, ContentAssetNames.manifestFile),
      );
      await _copyAndValidateDatabase(
        destination: stagedDatabase,
        manifest: bundledManifest,
        onProgress: onProgress,
      );
      await stagedManifest.writeAsBytes(manifestBytes, flush: true);
      _notify(
        onProgress,
        ContentInstallProgress(
          phase: ContentInstallPhase.verifying,
          completedBytes: bundledManifest.databaseBytes,
          totalBytes: bundledManifest.databaseBytes,
        ),
      );
      await verifier.verify(
        databaseFile: stagedDatabase,
        manifestFile: stagedManifest,
      );

      _notify(
        onProgress,
        ContentInstallProgress(
          phase: ContentInstallPhase.publishing,
          completedBytes: bundledManifest.databaseBytes,
          totalBytes: bundledManifest.databaseBytes,
        ),
      );
      final publishResult = await publisher.publish(
        stagedToTarget: {
          stagedDatabase: databaseFile,
          stagedManifest: manifestFile,
        },
        replaceExisting: true,
      );
      return ContentInstallResult(
        status: existingManifest != null
            ? ContentInstallStatus.updated
            : hadExistingFiles
            ? ContentInstallStatus.repaired
            : ContentInstallStatus.installed,
        manifest: bundledManifest,
        databaseFile: databaseFile,
        manifestFile: manifestFile,
        retainedBackupFiles: publishResult.retainedBackups,
      );
    } on AtomicFilePublishException catch (error) {
      throw ContentInstallException(code: error.code, message: error.message);
    } finally {
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
    }
  }

  Future<List<int>> _readBundledManifest() async {
    try {
      return await assetReader.readManifestBytes();
    } on ContentAssetReadException catch (error) {
      throw ContentInstallException(code: error.code, message: error.message);
    }
  }

  void _validateBundledManifest(ContentManifest manifest) {
    if (manifest.formatVersion != ContentManifest.currentFormatVersion) {
      throw ContentValidationException([
        ContentValidationIssue(
          code: 'unsupported_content_format',
          message: '不支持内容格式版本 ${manifest.formatVersion}',
        ),
      ]);
    }
    if (manifest.databaseFile != ContentAssetNames.databaseFile) {
      throw ContentValidationException([
        const ContentValidationIssue(
          code: 'database_name_mismatch',
          message: '内容清单中的数据库文件名不正确',
        ),
      ]);
    }
    if (manifest.databaseBytes > maxDatabaseBytes) {
      throw ContentValidationException([
        ContentValidationIssue(
          code: 'database_too_large',
          message: '数据库超过 $maxDatabaseBytes 字节安装上限',
        ),
      ]);
    }
  }

  Future<ContentManifest?> _verifyExisting({
    required File databaseFile,
    required File manifestFile,
  }) async {
    if (!await databaseFile.exists() || !await manifestFile.exists()) {
      return null;
    }
    try {
      return await verifier.verify(
        databaseFile: databaseFile,
        manifestFile: manifestFile,
      );
    } on ContentValidationException {
      return null;
    }
  }

  ContentInstallStatus? _decideVersion({
    required ContentManifest existing,
    required ContentManifest bundled,
  }) {
    if (existing.contentVersion == bundled.contentVersion) {
      if (existing.databaseSha256 == bundled.databaseSha256) {
        return ContentInstallStatus.alreadyCurrent;
      }
      throw const ContentInstallException(
        code: 'content_version_collision',
        message: '相同内容版本对应不同数据库，已保留设备上的有效版本',
      );
    }
    if (existing.generatedAt.isAfter(bundled.generatedAt)) {
      return ContentInstallStatus.keptNewerExisting;
    }
    if (existing.generatedAt.isAtSameMomentAs(bundled.generatedAt)) {
      throw const ContentInstallException(
        code: 'content_version_collision',
        message: '不同内容版本使用相同生成时间，已保留设备上的有效版本',
      );
    }
    return null;
  }

  Future<void> _copyAndValidateDatabase({
    required File destination,
    required ContentManifest manifest,
    required ContentInstallProgressCallback? onProgress,
  }) async {
    final digestSink = _DigestSink();
    final hashSink = sha256.startChunkedConversion(digestSink);
    final output = await destination.open(mode: FileMode.write);
    var totalBytes = 0;
    var hashClosed = false;
    _notify(
      onProgress,
      ContentInstallProgress(
        phase: ContentInstallPhase.copyingDatabase,
        totalBytes: manifest.databaseBytes,
      ),
    );
    try {
      await for (final chunk in assetReader.readDatabaseBytes()) {
        if (chunk.isEmpty) {
          continue;
        }
        totalBytes += chunk.length;
        if (totalBytes > manifest.databaseBytes ||
            totalBytes > maxDatabaseBytes) {
          throw ContentValidationException([
            const ContentValidationIssue(
              code: 'database_size_mismatch',
              message: '打包数据库字节数超过内容清单或安装上限',
            ),
          ]);
        }
        hashSink.add(chunk);
        await output.writeFrom(chunk);
        _notify(
          onProgress,
          ContentInstallProgress(
            phase: ContentInstallPhase.copyingDatabase,
            completedBytes: totalBytes,
            totalBytes: manifest.databaseBytes,
          ),
        );
      }
      await output.flush();
      hashSink.close();
      hashClosed = true;
    } on ContentAssetReadException catch (error) {
      throw ContentInstallException(code: error.code, message: error.message);
    } finally {
      if (!hashClosed) {
        hashSink.close();
      }
      await output.close();
    }

    if (totalBytes != manifest.databaseBytes ||
        digestSink.value?.toString() != manifest.databaseSha256) {
      throw ContentValidationException([
        const ContentValidationIssue(
          code: 'database_checksum_mismatch',
          message: '打包数据库长度或 SHA-256 与内容清单不一致',
        ),
      ]);
    }
  }

  void _notify(
    ContentInstallProgressCallback? onProgress,
    ContentInstallProgress progress,
  ) {
    try {
      onProgress?.call(progress);
    } on Object {
      // 进度观察器不是安装结果的一部分，观察器异常不应破坏原子安装。
    }
  }

  Future<void> _prepareSupportDirectory() async {
    if (await File(applicationSupportDirectory.path).exists()) {
      throw const ContentInstallException(
        code: 'support_directory_is_file',
        message: '应用支持目录路径已被普通文件占用',
      );
    }
    await applicationSupportDirectory.create(recursive: true);
  }

  bool _isFileSystemRoot(String path) => p.equals(path, p.dirname(path));
}

final class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
