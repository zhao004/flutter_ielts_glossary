import 'dart:typed_data';

import '../../models/domain/app_settings_state.dart';

/// 一次在线语音合成的音频结果：字节与 MIME 类型（mp3 / wav / raw）。
final class TtsAudio {
  const TtsAudio({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// 在线语音合成失败；`code` 是稳定错误码，平台原始正文不向 UI 泄露。
final class TtsSynthesisException implements Exception {
  const TtsSynthesisException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'tts_synthesis_error: $code';
}

/// 第三方 TTS 合成平台边界，便于纯 Dart 测试和替换网络实现。
abstract interface class TtsSynthesizerPort {
  /// 把 [text] 合成为 [accent] 对应的音频字节。
  Future<TtsAudio> synthesize(String text, {required PronunciationAccent accent});
}
