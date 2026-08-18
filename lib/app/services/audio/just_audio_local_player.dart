import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'audio_playback_service.dart';

/// `just_audio` 的本地 Flutter 资产适配器；不接受任意文件系统 URI。
final class JustAudioLocalPlayer implements LocalAudioPlayer {
  JustAudioLocalPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } on Object {
      throw const AudioPlaybackException('asset_playback_failed', '本地音频播放失败');
    }
  }

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(
            bytes,
            mimeType: mimeType ?? 'application/octet-stream',
          ),
        ),
      );
      await _player.play();
    } on Object {
      throw const AudioPlaybackException('bytes_playback_failed', '在线音频播放失败');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } on Object {
      throw const AudioPlaybackException('player_stop_failed', '音频播放器停止失败');
    }
  }

  @override
  Future<void> dispose() => _player.dispose();
}
