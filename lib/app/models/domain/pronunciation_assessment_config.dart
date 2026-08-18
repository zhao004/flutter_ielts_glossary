import 'pronunciation_assessment_platform.dart';

/// 第三方发音评测的完整配置：平台选择与对应平台凭据。
///
/// 凭据只保存在本机，不进入备份导出文件。
final class PronunciationAssessmentConfig {
  const PronunciationAssessmentConfig({
    required this.platform,
    this.xfyunAppId = '',
    this.xfyunApiKey = '',
    this.xfyunApiSecret = '',
    this.youdaoAppKey = '',
    this.youdaoAppSecret = '',
  });

  factory PronunciationAssessmentConfig.defaults() {
    return const PronunciationAssessmentConfig(
      platform: PronunciationAssessmentPlatform.off,
    );
  }

  final PronunciationAssessmentPlatform platform;

  /// 讯飞开放平台的 AppID。
  final String xfyunAppId;

  /// 讯飞开放平台的 APIKey。
  final String xfyunApiKey;

  /// 讯飞开放平台的 APISecret。
  final String xfyunApiSecret;

  /// 有道智云的应用 Key。
  final String youdaoAppKey;

  /// 有道智云的应用 Secret。
  final String youdaoAppSecret;

  /// 当前所选平台是否已填写完整、可发起云端评测。
  bool get isReady => switch (platform) {
    PronunciationAssessmentPlatform.off => false,
    PronunciationAssessmentPlatform.xfyun =>
      xfyunAppId.trim().isNotEmpty &&
          xfyunApiKey.trim().isNotEmpty &&
          xfyunApiSecret.trim().isNotEmpty,
    PronunciationAssessmentPlatform.youdao =>
      youdaoAppKey.trim().isNotEmpty && youdaoAppSecret.trim().isNotEmpty,
  };

  PronunciationAssessmentConfig copyWith({
    PronunciationAssessmentPlatform? platform,
    String? xfyunAppId,
    String? xfyunApiKey,
    String? xfyunApiSecret,
    String? youdaoAppKey,
    String? youdaoAppSecret,
  }) {
    return PronunciationAssessmentConfig(
      platform: platform ?? this.platform,
      xfyunAppId: xfyunAppId ?? this.xfyunAppId,
      xfyunApiKey: xfyunApiKey ?? this.xfyunApiKey,
      xfyunApiSecret: xfyunApiSecret ?? this.xfyunApiSecret,
      youdaoAppKey: youdaoAppKey ?? this.youdaoAppKey,
      youdaoAppSecret: youdaoAppSecret ?? this.youdaoAppSecret,
    );
  }
}
