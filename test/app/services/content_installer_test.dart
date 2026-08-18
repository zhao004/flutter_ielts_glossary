import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_ielts_glossary/app/models/content/content_asset_names.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_asset_reader.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_database_verifier.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_installation.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_installer.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_validation.dart';

import '../../../tool/content_builder/content_build_config.dart';
import '../../../tool/content_builder/content_database_builder.dart';

void main() {
  final workspace = Directory.current.absolute;
  final fixtureDirectory = Directory(
    p.join(workspace.path, 'test', 'fixtures', 'content_source'),
  );
  final cacheRoot = Directory(
    p.join(workspace.path, '.cache', 'content_installer_tests'),
  );
  final cleanupDirectories = <Directory>[];

  tearDown(() async {
    for (final directory in cleanupDirectories.reversed) {
      if (p.isWithin(cacheRoot.path, directory.path) &&
          await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    cleanupDirectories.clear();
  });

  test('首次安装后重复启动不会再次读取数据库资产', () async {
    final sandbox = _newCacheDirectory(cacheRoot, cleanupDirectories, 'first');
    final assets = Directory(p.join(sandbox.path, 'assets'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assets,
      version: 'fixture-v1',
      revision: 'revision-v1',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    final reader = _FileContentAssetReader(assets);
    final installer = ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: reader,
    );
    final progress = <ContentInstallProgress>[];

    final first = await installer.install(onProgress: progress.add);
    final second = await installer.install();

    expect(first.status, ContentInstallStatus.installed);
    expect(second.status, ContentInstallStatus.alreadyCurrent);
    expect(reader.databaseReadCount, 1);
    expect(second.manifest.contentVersion, 'fixture-v1');
    expect(
      progress.map((item) => item.phase),
      containsAllInOrder([
        ContentInstallPhase.readingManifest,
        ContentInstallPhase.checkingExisting,
        ContentInstallPhase.copyingDatabase,
        ContentInstallPhase.verifying,
        ContentInstallPhase.publishing,
      ]),
    );
    expect(progress.any((item) => item.fraction == 1), isTrue);
    await _verifyInstalled(support, expectedVersion: 'fixture-v1');
  });

  test('较新的打包内容通过原子替换完成升级', () async {
    final sandbox = _newCacheDirectory(cacheRoot, cleanupDirectories, 'update');
    final assetsV1 = Directory(p.join(sandbox.path, 'assets-v1'));
    final assetsV2 = Directory(p.join(sandbox.path, 'assets-v2'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV1,
      version: 'fixture-v1',
      revision: 'revision-v1',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV2,
      version: 'fixture-v2',
      revision: 'revision-v2',
      generatedAt: DateTime.utc(2026, 8, 14, 13),
    );
    await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsV1),
    ).install();

    final result = await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsV2),
    ).install();

    expect(result.status, ContentInstallStatus.updated);
    expect(result.retainedBackupFiles, isEmpty);
    await _verifyInstalled(support, expectedVersion: 'fixture-v2');
  });

  test('设备上的较新有效内容不会被旧应用包降级', () async {
    final sandbox = _newCacheDirectory(cacheRoot, cleanupDirectories, 'newer');
    final assetsV1 = Directory(p.join(sandbox.path, 'assets-v1'));
    final assetsV2 = Directory(p.join(sandbox.path, 'assets-v2'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV1,
      version: 'fixture-v1',
      revision: 'revision-v1',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV2,
      version: 'fixture-v2',
      revision: 'revision-v2',
      generatedAt: DateTime.utc(2026, 8, 14, 13),
    );
    await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsV2),
    ).install();
    final olderReader = _FileContentAssetReader(assetsV1);

    final result = await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: olderReader,
    ).install();

    expect(result.status, ContentInstallStatus.keptNewerExisting);
    expect(olderReader.databaseReadCount, 0);
    await _verifyInstalled(support, expectedVersion: 'fixture-v2');
  });

  test('升级资产损坏时旧数据库保持完整可用', () async {
    final sandbox = _newCacheDirectory(cacheRoot, cleanupDirectories, 'failed');
    final assetsV1 = Directory(p.join(sandbox.path, 'assets-v1'));
    final assetsV2 = Directory(p.join(sandbox.path, 'assets-v2'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV1,
      version: 'fixture-v1',
      revision: 'revision-v1',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV2,
      version: 'fixture-v2',
      revision: 'revision-v2',
      generatedAt: DateTime.utc(2026, 8, 14, 13),
    );
    await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsV1),
    ).install();

    final operation = ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsV2, appendCorruptByte: true),
    ).install();

    await expectLater(
      operation,
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('database_size_mismatch'),
        ),
      ),
    );
    await _verifyInstalled(support, expectedVersion: 'fixture-v1');
  });

  test('未来内容格式在读取数据库资产前被拒绝并保留旧版本', () async {
    final sandbox = _newCacheDirectory(cacheRoot, cleanupDirectories, 'future');
    final assetsV1 = Directory(p.join(sandbox.path, 'assets-v1'));
    final futureAssets = Directory(p.join(sandbox.path, 'assets-future'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsV1,
      version: 'fixture-v1',
      revision: 'revision-v1',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: futureAssets,
      version: 'fixture-v2',
      revision: 'revision-v2',
      generatedAt: DateTime.utc(2026, 8, 14, 13),
    );
    await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsV1),
    ).install();
    final futureManifestFile = File(
      p.join(futureAssets.path, ContentAssetNames.manifestFile),
    );
    final futureManifest =
        jsonDecode(await futureManifestFile.readAsString())
            as Map<String, dynamic>;
    futureManifest['formatVersion'] = 2;
    await futureManifestFile.writeAsString(jsonEncode(futureManifest));
    final futureReader = _FileContentAssetReader(futureAssets);

    final operation = ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: futureReader,
    ).install();

    await expectLater(
      operation,
      throwsA(
        isA<ContentValidationException>().having(
          (error) => error.issueCounts.keys,
          'codes',
          contains('unsupported_content_format'),
        ),
      ),
    );
    expect(futureReader.databaseReadCount, 0);
    await _verifyInstalled(support, expectedVersion: 'fixture-v1');
  });

  test('现有内容损坏时使用已验证资产修复', () async {
    final sandbox = _newCacheDirectory(cacheRoot, cleanupDirectories, 'repair');
    final assets = Directory(p.join(sandbox.path, 'assets'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assets,
      version: 'fixture-v1',
      revision: 'revision-v1',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    final reader = _FileContentAssetReader(assets);
    final installer = ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: reader,
    );
    final first = await installer.install();
    await first.databaseFile.writeAsBytes([0], mode: FileMode.append);

    final repaired = await installer.install();

    expect(repaired.status, ContentInstallStatus.repaired);
    expect(reader.databaseReadCount, 2);
    await _verifyInstalled(support, expectedVersion: 'fixture-v1');
  });

  test('相同版本不同哈希被视为冲突并保留设备版本', () async {
    final sandbox = _newCacheDirectory(
      cacheRoot,
      cleanupDirectories,
      'collision',
    );
    final assetsA = Directory(p.join(sandbox.path, 'assets-a'));
    final assetsB = Directory(p.join(sandbox.path, 'assets-b'));
    final support = Directory(p.join(sandbox.path, 'support'));
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsA,
      version: 'fixture-v1',
      revision: 'revision-a',
      generatedAt: DateTime.utc(2026, 8, 14, 12),
    );
    await _buildAssets(
      fixtureDirectory: fixtureDirectory,
      outputDirectory: assetsB,
      version: 'fixture-v1',
      revision: 'revision-b',
      generatedAt: DateTime.utc(2026, 8, 14, 13),
    );
    await ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsA),
    ).install();

    final operation = ContentInstaller(
      applicationSupportDirectory: support,
      assetReader: _FileContentAssetReader(assetsB),
    ).install();

    await expectLater(
      operation,
      throwsA(
        isA<ContentInstallException>().having(
          (error) => error.code,
          'code',
          'content_version_collision',
        ),
      ),
    );
    await _verifyInstalled(support, expectedVersion: 'fixture-v1');
  });
}

Future<void> _buildAssets({
  required Directory fixtureDirectory,
  required Directory outputDirectory,
  required String version,
  required String revision,
  required DateTime generatedAt,
}) async {
  await ContentDatabaseBuilder(nowUtc: () => generatedAt).build(
    ContentBuildConfig(
      inputDirectory: fixtureDirectory,
      outputDirectory: outputDirectory,
      contentVersion: version,
      sourceRepository: 'https://example.invalid/fixture',
      sourceRevision: revision,
      licenseNotice: '仅用于自动化测试的合成数据。',
      expectedWordCount: 3,
      expectedSentenceCount: 3,
      expectedLetters: const ['A', 'B'],
      expectedSentenceChunkCount: 2,
    ),
  );
}

Future<void> _verifyInstalled(
  Directory support, {
  required String expectedVersion,
}) async {
  final manifest = await const ContentDatabaseVerifier().verify(
    databaseFile: File(p.join(support.path, ContentAssetNames.databaseFile)),
    manifestFile: File(p.join(support.path, ContentAssetNames.manifestFile)),
  );
  expect(manifest.contentVersion, expectedVersion);
}

Directory _newCacheDirectory(
  Directory cacheRoot,
  List<Directory> cleanupDirectories,
  String name,
) {
  final directory = Directory(
    p.join(
      cacheRoot.path,
      '$name-${DateTime.now().microsecondsSinceEpoch}-$pid',
    ),
  );
  cleanupDirectories.add(directory);
  return directory;
}

final class _FileContentAssetReader implements ContentAssetReader {
  _FileContentAssetReader(this.directory, {this.appendCorruptByte = false});

  final Directory directory;
  final bool appendCorruptByte;
  int databaseReadCount = 0;

  @override
  Future<List<int>> readManifestBytes() {
    return File(
      p.join(directory.path, ContentAssetNames.manifestFile),
    ).readAsBytes();
  }

  @override
  Stream<List<int>> readDatabaseBytes() async* {
    databaseReadCount++;
    yield* File(
      p.join(directory.path, ContentAssetNames.databaseFile),
    ).openRead();
    if (appendCorruptByte) {
      yield const [0];
    }
  }
}
