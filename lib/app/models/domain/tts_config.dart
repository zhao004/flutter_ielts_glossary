import 'tts_platform.dart';

/// 第三方 TTS 的完整配置：平台选择、对应平台凭据与音色参数。
///
/// 凭据只保存在本机，不进入备份导出文件。
final class TtsConfig {
  const TtsConfig({
    required this.platform,
    this.xfyunAppId = '',
    this.xfyunApiKey = '',
    this.xfyunApiSecret = '',
    this.xfyunVoice = 'catherine',
    this.youdaoAppKey = '',
    this.youdaoAppSecret = '',
    this.youdaoUsVoiceName = 'youmeimei',
    this.youdaoUkVoiceName = 'youyingying',
    this.speed = 50,
    this.volume = 50,
    this.pitch = 50,
  });

  factory TtsConfig.defaults() {
    return const TtsConfig(platform: TtsPlatform.off);
  }

  final TtsPlatform platform;

  /// 讯飞开放平台的 AppID。
  final String xfyunAppId;

  /// 讯飞开放平台的 APIKey。
  final String xfyunApiKey;

  /// 讯飞开放平台的 APISecret。
  final String xfyunApiSecret;

  /// 讯飞发音人（`vcn`），如 `catherine`（女声）、`henry`（男声）。
  final String xfyunVoice;

  /// 有道智云的应用 Key。
  final String youdaoAppKey;

  /// 有道智云的应用 Secret。
  final String youdaoAppSecret;

  /// 有道美式词典发音人（`voiceName`）。
  final String youdaoUsVoiceName;

  /// 有道英式词典发音人（`voiceName`）。
  final String youdaoUkVoiceName;

  /// 语速（0-100，50 为默认）。
  final int speed;

  /// 音量（0-100，50 为默认）。
  final int volume;

  /// 音调（0-100，50 为默认）。
  final int pitch;

  /// 当前所选平台的凭据与发音人是否已填写完整、可发起在线合成。
  bool get hasCredentials => switch (platform) {
    TtsPlatform.off => false,
    TtsPlatform.xfyun =>
      xfyunAppId.trim().isNotEmpty &&
          xfyunApiKey.trim().isNotEmpty &&
          xfyunApiSecret.trim().isNotEmpty &&
          xfyunVoice.trim().isNotEmpty,
    TtsPlatform.youdao =>
      youdaoAppKey.trim().isNotEmpty &&
          youdaoAppSecret.trim().isNotEmpty &&
          youdaoUsVoiceName.trim().isNotEmpty &&
          youdaoUkVoiceName.trim().isNotEmpty,
  };

  /// 当前平台是否可发起在线合成（凭据完整）。
  bool get isReady => hasCredentials;

  TtsConfig copyWith({
    TtsPlatform? platform,
    String? xfyunAppId,
    String? xfyunApiKey,
    String? xfyunApiSecret,
    String? xfyunVoice,
    String? youdaoAppKey,
    String? youdaoAppSecret,
    String? youdaoUsVoiceName,
    String? youdaoUkVoiceName,
    int? speed,
    int? volume,
    int? pitch,
  }) {
    return TtsConfig(
      platform: platform ?? this.platform,
      xfyunAppId: xfyunAppId ?? this.xfyunAppId,
      xfyunApiKey: xfyunApiKey ?? this.xfyunApiKey,
      xfyunApiSecret: xfyunApiSecret ?? this.xfyunApiSecret,
      xfyunVoice: xfyunVoice ?? this.xfyunVoice,
      youdaoAppKey: youdaoAppKey ?? this.youdaoAppKey,
      youdaoAppSecret: youdaoAppSecret ?? this.youdaoAppSecret,
      youdaoUsVoiceName: youdaoUsVoiceName ?? this.youdaoUsVoiceName,
      youdaoUkVoiceName: youdaoUkVoiceName ?? this.youdaoUkVoiceName,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
    );
  }
}
