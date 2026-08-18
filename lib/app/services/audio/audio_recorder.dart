import 'dart:typed_data';

/// 一段已结束的录音：16kHz / 16bit / 单声道 raw PCM。
final class RecordedAudio {
  const RecordedAudio({required this.pcmBytes});

  final Uint8List pcmBytes;
}

/// 录音失败；`code` 是稳定错误码，平台异常正文不向 UI 泄露。
final class AudioRecordingException implements Exception {
  const AudioRecordingException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'audio_recording_error: $code';
}

/// 原始音频录制边界，用于把录音字节交给第三方发音评测平台。
abstract interface class AudioRecorderPort {
  Future<bool> hasPermission();

  /// 开始录音；调用 [stop] 结束并交付 PCM 字节。
  Future<void> start();

  /// 结束录音并返回 PCM 字节；未在录音时调用视为取消。
  Future<RecordedAudio> stop();

  /// 丢弃当前录音，不交付任何结果。
  Future<void> cancel();

  Future<void> dispose();
}
