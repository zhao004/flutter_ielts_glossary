import 'dart:typed_data';

import '../../models/domain/pronunciation_score.dart';

/// 一次云端发音评测的输入：参考文本与 16kHz/16bit 单声道 raw PCM。
final class PronunciationEvaluationRequest {
  const PronunciationEvaluationRequest({
    required this.referenceText,
    required this.pcmBytes,
  });

  final String referenceText;
  final Uint8List pcmBytes;
}

/// 第三方发音评测失败；`code` 是稳定错误码，平台原始正文不向 UI 泄露。
final class PronunciationEvaluationException implements Exception {
  const PronunciationEvaluationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'pronunciation_evaluation_error: $code';
}

/// 第三方发音评测平台边界，便于纯 Dart 测试和替换网络实现。
abstract interface class PronunciationEvaluatorPort {
  Future<PronunciationScore> evaluate(PronunciationEvaluationRequest request);
}
