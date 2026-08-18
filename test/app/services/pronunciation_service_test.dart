import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_platform.dart';
import 'package:flutter_ielts_glossary/app/repositories/tts_config_repository.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';
import 'package:flutter_ielts_glossary/app/services/tts/tts_synthesizer.dart';
import 'package:flutter_ielts_glossary/app/services/tts/tts_synthesizer_factory.dart';

void main() {
  test('优先播放通过白名单校验的词库音频', () async {
    final player = _FakeLocalAudioPlayer();
    final service = PronunciationService(localPlayer: player);

    final result = await service.play(
      word: 'alpha',
      accent: PronunciationAccent.uk,
      audioUkAsset: 'assets/audio/uk/alpha.mp3',
      audioUsAsset: 'assets/audio/us/alpha.mp3',
    );

    expect(result.source, PronunciationPlaybackSource.localAsset);
    expect(player.stopCount, 1);
    expect(player.playedAssets, ['assets/audio/uk/alpha.mp3']);
  });

  test('词库音频失败时使用已配置的第三方 TTS', () async {
    final player = _FakeLocalAudioPlayer(failAssetPlayback: true);
    final service = PronunciationService(
      localPlayer: player,
      ttsConfigRepository: _MemoryTtsConfigRepository(_readyTtsConfig()),
      ttsSynthesizerFactory: _FixedTtsFactory(const _FixedSynthesizer()),
    );

    final result = await service.play(
      word: 'alpha',
      accent: PronunciationAccent.us,
      audioUsAsset: 'assets/audio/us/alpha.aac',
    );

    expect(result.source, PronunciationPlaybackSource.onlineTts);
    expect(player.playedAssets, ['assets/audio/us/alpha.aac']);
    expect(player.playedBytes, hasLength(1));
  });

  test('未配置第三方 TTS 且没有词库音频时返回不可用', () async {
    final service = PronunciationService(localPlayer: _FakeLocalAudioPlayer());

    final result = await service.play(
      word: 'alpha',
      accent: PronunciationAccent.uk,
    );

    expect(result.source, PronunciationPlaybackSource.unavailable);
  });

  test('配置第三方 TTS 后在线合成并播放字节', () async {
    final player = _FakeLocalAudioPlayer();
    final service = PronunciationService(
      localPlayer: player,
      ttsConfigRepository: _MemoryTtsConfigRepository(_readyTtsConfig()),
      ttsSynthesizerFactory: _FixedTtsFactory(const _FixedSynthesizer()),
    );

    final result = await service.play(
      word: 'alpha',
      accent: PronunciationAccent.us,
    );

    expect(result.source, PronunciationPlaybackSource.onlineTts);
    expect(player.playedBytes, hasLength(1));
    expect(player.playedAssets, isEmpty);
  });
}

TtsConfig _readyTtsConfig() {
  return const TtsConfig(
    platform: TtsPlatform.youdao,
    youdaoAppKey: 'key',
    youdaoAppSecret: 'secret',
  );
}

final class _FakeLocalAudioPlayer implements LocalAudioPlayer {
  _FakeLocalAudioPlayer({this.failAssetPlayback = false});

  final bool failAssetPlayback;
  final List<String> playedAssets = [];
  final List<Uint8List> playedBytes = [];
  int stopCount = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
    if (failAssetPlayback) {
      throw const AudioPlaybackException('asset_playback_failed', '测试播放失败');
    }
  }

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {
    playedBytes.add(bytes);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}

final class _MemoryTtsConfigRepository implements TtsConfigRepository {
  _MemoryTtsConfigRepository(this.config);

  final TtsConfig config;

  @override
  Future<TtsConfig> load() async => config;

  @override
  Future<TtsConfig> save(TtsConfig config) async => config;
}

final class _FixedTtsFactory extends TtsSynthesizerFactory {
  const _FixedTtsFactory(this.synthesizer);

  final TtsSynthesizerPort synthesizer;

  @override
  TtsSynthesizerPort? create(TtsConfig config) => synthesizer;
}

final class _FixedSynthesizer implements TtsSynthesizerPort {
  const _FixedSynthesizer();

  @override
  Future<TtsAudio> synthesize(
    String text, {
    required PronunciationAccent accent,
  }) async {
    return TtsAudio(bytes: Uint8List(4), mimeType: 'audio/mpeg');
  }
}
