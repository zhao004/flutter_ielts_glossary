import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/content/content_manifest.dart';
import 'package:flutter_ielts_glossary/app/models/domain/settings_about_info.dart';

const _testSha256 =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

void main() {
  group('SettingsAboutInfo', () {
    test('允许超过短元数据上限的完整授权文本', () {
      final licenseNotice = List.filled(
        SettingsAboutInfo.maximumMetadataTextLength + 1,
        'L',
      ).join();

      final info = _createInfo(licenseNotice: licenseNotice);

      expect(info.licenseNotice, licenseNotice);
    });

    test('拒绝超过授权文本上限的内容', () {
      final licenseNotice = List.filled(
        SettingsAboutInfo.maximumLicenseNoticeLength + 1,
        'L',
      ).join();

      expect(
        () => _createInfo(licenseNotice: licenseNotice),
        throwsArgumentError,
      );
    });

    test('继续限制短元数据长度', () {
      final sourceRepository = List.filled(
        SettingsAboutInfo.maximumMetadataTextLength + 1,
        'R',
      ).join();

      expect(
        () => _createInfo(sourceRepository: sourceRepository),
        throwsArgumentError,
      );
    });
  });
}

SettingsAboutInfo _createInfo({
  String sourceRepository = 'https://example.invalid/source',
  String licenseNotice = 'MIT License',
}) {
  return SettingsAboutInfo.fromManifest(
    appVersion: '1.0.0+1',
    manifest: ContentManifest(
      formatVersion: ContentManifest.currentFormatVersion,
      contentVersion: 'content-v1',
      sourceRepository: sourceRepository,
      sourceRevision: '0123456789abcdef0123456789abcdef01234567',
      generatedAt: DateTime.utc(2026, 8, 16),
      databaseFile: 'content.sqlite',
      databaseBytes: 1,
      databaseSha256: _testSha256,
      sourceDataSha256: _testSha256,
      wordCount: 1,
      sentenceCount: 1,
      activeGroupCount: ContentManifest.expectedActiveGroupCount,
      groupWordCounts: const {1: 1, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
      licenseNotice: licenseNotice,
    ),
  );
}
