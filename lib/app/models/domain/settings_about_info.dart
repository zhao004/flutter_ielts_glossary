import '../content/content_manifest.dart';

/// 设置页展示的应用、词库和授权信息，不属于用户可编辑设置。
final class SettingsAboutInfo {
  /// 常规版本和来源元数据最大长度，单位为 UTF-16 代码单元。
  static const int maximumMetadataTextLength = 512;

  /// 完整许可证及第三方归属说明最大长度，单位为 UTF-16 代码单元。
  ///
  /// 上限允许展示标准许可证正文，同时避免异常内容进入设置页。
  static const int maximumLicenseNoticeLength = 64 * 1024;

  SettingsAboutInfo({
    required String appVersion,
    required String contentVersion,
    required String sourceRepository,
    required String sourceRevision,
    required String licenseNotice,
    required this.wordCount,
    required this.sentenceCount,
    required DateTime generatedAtUtc,
  }) : appVersion = _requiredText(appVersion, 'appVersion'),
       contentVersion = _requiredText(contentVersion, 'contentVersion'),
       sourceRepository = _requiredText(sourceRepository, 'sourceRepository'),
       sourceRevision = _requiredText(sourceRevision, 'sourceRevision'),
       licenseNotice = _requiredText(
         licenseNotice,
         'licenseNotice',
         maximumLength: maximumLicenseNoticeLength,
       ),
       generatedAtUtc = generatedAtUtc.toUtc() {
    if (wordCount <= 0 || sentenceCount <= 0) {
      throw ArgumentError('词库记录数量必须为正数');
    }
  }

  factory SettingsAboutInfo.fromManifest({
    required String appVersion,
    required ContentManifest manifest,
  }) {
    return SettingsAboutInfo(
      appVersion: appVersion,
      contentVersion: manifest.contentVersion,
      sourceRepository: manifest.sourceRepository,
      sourceRevision: manifest.sourceRevision,
      licenseNotice: manifest.licenseNotice,
      wordCount: manifest.wordCount,
      sentenceCount: manifest.sentenceCount,
      generatedAtUtc: manifest.generatedAt,
    );
  }

  final String appVersion;
  final String contentVersion;
  final String sourceRepository;
  final String sourceRevision;
  final String licenseNotice;
  final int wordCount;
  final int sentenceCount;
  final DateTime generatedAtUtc;
}

String _requiredText(
  String value,
  String name, {
  int maximumLength = SettingsAboutInfo.maximumMetadataTextLength,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maximumLength) {
    throw ArgumentError.value(value, name, '信息文本不能为空且长度不能超过 $maximumLength');
  }
  return normalized;
}
