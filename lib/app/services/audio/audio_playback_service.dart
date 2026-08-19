import 'dart:typed_data';

import '../../models/domain/app_settings_state.dart';
import '../../models/domain/tts_config.dart';
import '../../repositories/tts_config_repository.dart';
import '../tts/tts_synthesizer_factory.dart';
import 'audio_asset_path_policy.dart';

export 'audio_asset_path_policy.dart';

/// 参考发音最终选择的播放来源。
enum PronunciationPlaybackSource { localAsset, onlineTts, unavailable }

/// 播放请求经过资源和设备能力判断后的结果。
final class PronunciationPlaybackResult {
  const PronunciationPlaybackResult({
    required this.source,
    required this.accent,
    required this.assetPath,
    required this.locale,
  });

  final PronunciationPlaybackSource source;
  final PronunciationAccent accent;
  final String? assetPath;
  final String? locale;
}

/// 音频平台错误，页面只需根据稳定 code 展示状态。
final class AudioPlaybackException implements Exception {
  const AudioPlaybackException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'audio_playback_error: $code';
}

/// 受控本地音频播放器接口；实现可以替换平台插件。
abstract interface class LocalAudioPlayer {
  Future<void> playAsset(String assetPath);

  /// 播放内存中的音频字节（用于在线 TTS 返回的 mp3/wav）。
  Future<void> playBytes(Uint8List bytes, {String? mimeType});

  Future<void> stop();

  Future<void> dispose();
}

/// 统一编排词库本地音频、第三方 TTS 和播放前停止旧音频的服务。
final class PronunciationService {
  PronunciationService({
    required this.localPlayer,
    TtsConfigRepository? ttsConfigRepository,
    TtsSynthesizerFactory? ttsSynthesizerFactory,
    this.assetPathPolicy = const AudioAssetPathPolicy(),
  }) : ttsConfigRepository =
           ttsConfigRepository ?? const _DisabledTtsConfigRepository(),
       ttsSynthesizerFactory =
           ttsSynthesizerFactory ?? const TtsSynthesizerFactory();

  final LocalAudioPlayer localPlayer;
  final TtsConfigRepository ttsConfigRepository;
  final TtsSynthesizerFactory ttsSynthesizerFactory;
  final AudioAssetPathPolicy assetPathPolicy;

  Future<PronunciationPlaybackResult> play({
    required String word,
    required PronunciationAccent accent,
    String? audioUkAsset,
    String? audioUsAsset,
  }) async {
    final normalizedWord = word.trim();
    if (normalizedWord.isEmpty || normalizedWord.length > 200) {
      throw const AudioPlaybackException('invalid_word', '发音文本不能为空');
    }
    await stop();

    final assetPath = accent == PronunciationAccent.uk
        ? audioUkAsset
        : audioUsAsset;
    final accentDirectory = accent == PronunciationAccent.uk ? 'uk' : 'us';
    if (assetPathPolicy.isAllowed(assetPath, accent: accentDirectory)) {
      try {
        await localPlayer.playAsset(assetPath!);
        return PronunciationPlaybackResult(
          source: PronunciationPlaybackSource.localAsset,
          accent: accent,
          assetPath: assetPath,
          locale: null,
        );
      } on Object {
        // 资源损坏时继续尝试第三方 TTS，平台异常正文不向 UI 泄露。
        try {
          await localPlayer.stop();
        } on Object {
          // 播放器释放由应用级生命周期处理。
        }
      }
    }

    final onlineResult = await _tryOnlineTts(normalizedWord, accent);
    if (onlineResult != null) {
      return onlineResult;
    }

    return PronunciationPlaybackResult(
      source: PronunciationPlaybackSource.unavailable,
      accent: accent,
      assetPath: null,
      locale: null,
    );
  }

  /// 配置了第三方 TTS 时尝试在线合成并播放；未配置或失败时返回不可用。
  Future<PronunciationPlaybackResult?> _tryOnlineTts(
    String word,
    PronunciationAccent accent,
  ) async {
    try {
      final config = await ttsConfigRepository.load();
      final synthesizer = ttsSynthesizerFactory.create(config);
      if (synthesizer == null) {
        return null;
      }
      final audio = await synthesizer.synthesize(word, accent: accent);
      await localPlayer.playBytes(audio.bytes, mimeType: audio.mimeType);
      return PronunciationPlaybackResult(
        source: PronunciationPlaybackSource.onlineTts,
        accent: accent,
        assetPath: null,
        locale: null,
      );
    } on Object {
      return null;
    }
  }

  Future<void> stop() async {
    await localPlayer.stop();
  }

  Future<void> dispose() async {
    await ttsSynthesizerFactory.dispose();
    await localPlayer.dispose();
  }
}

/// 未注入配置仓库时显式禁用在线合成，避免测试或预览环境隐式使用设备 TTS。
final class _DisabledTtsConfigRepository implements TtsConfigRepository {
  const _DisabledTtsConfigRepository();

  @override
  Future<TtsConfig> load() async => TtsConfig.defaults();

  @override
  Future<TtsConfig> save(TtsConfig config) async => config;
}
