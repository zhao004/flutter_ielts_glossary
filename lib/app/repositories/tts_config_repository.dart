import '../models/domain/tts_config.dart';

/// 第三方 TTS 配置无法解码或值不合法。
final class UnsupportedTtsConfigException implements Exception {
  const UnsupportedTtsConfigException(this.message);

  final String message;

  @override
  String toString() => 'unsupported_tts_config: $message';
}

/// 第三方 TTS 配置的领域接口；凭据只保存在本机，不进入备份。
abstract interface class TtsConfigRepository {
  Future<TtsConfig> load();

  Future<TtsConfig> save(TtsConfig config);
}
