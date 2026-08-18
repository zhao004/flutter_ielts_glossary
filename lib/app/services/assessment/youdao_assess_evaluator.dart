import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../models/domain/pronunciation_score.dart';
import '../youdao/youdao_api_signer.dart';
import 'pronunciation_evaluator.dart';

/// 有道智云语音评测的稳定凭据。
final class YoudaoAssessCredentials {
  const YoudaoAssessCredentials({
    required this.appKey,
    required this.appSecret,
  });

  final String appKey;
  final String appSecret;
}

/// 使用有道智云「语音评测」HTTP 接口评分。
///
/// 将 16kHz/16bit/单声道 PCM 封装为 WAV，并按官方 v2 表单协议上传。
/// 未显式注入 Client 时，每次请求创建并关闭独立连接，避免泄漏连接池。
final class YoudaoAssessEvaluator implements PronunciationEvaluatorPort {
  YoudaoAssessEvaluator({
    required this.credentials,
    this.client,
    this.timeout = const Duration(seconds: 15),
  }) {
    if (credentials.appKey.trim().isEmpty ||
        credentials.appSecret.trim().isEmpty) {
      throw ArgumentError('有道评测凭据不完整');
    }
  }

  static const String endpoint = 'https://openapi.youdao.com/iseapi';
  static const int sampleRate = 16000;
  static const int maxAudioDurationSeconds = 120;
  static const int maxEncodedAudioBytes = 20 * 1000 * 1000;
  static const int _bytesPerSample = 2;

  final YoudaoAssessCredentials credentials;
  final http.Client? client;
  final Duration timeout;

  @override
  Future<PronunciationScore> evaluate(
    PronunciationEvaluationRequest request,
  ) async {
    final normalizedText = request.referenceText.trim();
    if (normalizedText.isEmpty || normalizedText.length > 200) {
      throw const PronunciationEvaluationException('invalid_text', '参考文本长度无效');
    }
    if (request.pcmBytes.isEmpty) {
      throw const PronunciationEvaluationException('empty_audio', '录音为空，无法评测');
    }
    if (request.pcmBytes.length.isOdd ||
        request.pcmBytes.length >
            sampleRate * _bytesPerSample * maxAudioDurationSeconds) {
      throw const PronunciationEvaluationException(
        'invalid_audio',
        '录音格式或时长不符合有道评测要求',
      );
    }

    final encodedAudio = base64Encode(_toWav(request.pcmBytes));
    if (encodedAudio.length > maxEncodedAudioBytes) {
      throw const PronunciationEvaluationException(
        'audio_too_large',
        '录音编码后超过有道评测大小限制',
      );
    }
    final salt = YoudaoApiSigner.createSalt();
    final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = YoudaoApiSigner.sign(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      query: encodedAudio,
      salt: salt,
      curtime: curtime,
    );

    final Uri uri = Uri.parse(endpoint);
    final requestClient = client ?? http.Client();
    final http.Response response;
    try {
      response = await requestClient
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'q': encodedAudio,
              'text': normalizedText,
              'langType': 'en',
              'appKey': credentials.appKey,
              'salt': salt,
              'curtime': curtime,
              'sign': sign,
              'signType': 'v2',
              'format': 'wav',
              'rate': '$sampleRate',
              'channel': '1',
              'type': '1',
            },
          )
          .timeout(timeout);
    } on Object {
      throw const PronunciationEvaluationException(
        'network_error',
        '有道评测网络请求失败',
      );
    } finally {
      if (client == null) {
        requestClient.close();
      }
    }

    if (response.statusCode != 200) {
      throw PronunciationEvaluationException(
        'http_${response.statusCode}',
        '有道评测请求失败（HTTP ${response.statusCode}）',
      );
    }
    return _parseScore(response.body);
  }

  PronunciationScore _parseScore(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const PronunciationEvaluationException(
        'malformed_result',
        '有道评测返回不是合法 JSON',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const PronunciationEvaluationException(
        'malformed_result',
        '有道评测返回结构无效',
      );
    }
    final errorCode = decoded['errorCode']?.toString();
    if (errorCode == null) {
      throw const PronunciationEvaluationException(
        'malformed_result',
        '有道评测返回缺少 errorCode',
      );
    }
    if (errorCode != '0') {
      throw PronunciationEvaluationException(
        'youdao_$errorCode',
        '有道评测失败（$errorCode）',
      );
    }
    return PronunciationScore(
      totalScore: _readScore(decoded, 'overall'),
      accuracyScore: _readScore(decoded, 'pronunciation'),
      fluencyScore: _readScore(decoded, 'fluency'),
      integrityScore: _readScore(decoded, 'integrity'),
    );
  }

  double _readScore(Map<String, Object?> map, String key) {
    final raw = map[key];
    final value = switch (raw) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };
    if (value != null && value.isFinite && value >= 0 && value <= 100) {
      return value;
    }
    throw const PronunciationEvaluationException(
      'malformed_result',
      '有道评测返回缺少评分字段',
    );
  }

  /// 给 16kHz/16bit/单声道 PCM 加上 44 字节 WAV 头。
  Uint8List _toWav(Uint8List pcm) {
    final byteRate = sampleRate * 2;
    final bytes = Uint8List(44 + pcm.length);
    final data = ByteData.view(bytes.buffer);
    void writeAscii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        bytes[offset + index] = value.codeUnitAt(index);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + pcm.length, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, 2, Endian.little); // block align
    data.setUint16(34, 16, Endian.little); // bits per sample
    writeAscii(36, 'data');
    data.setUint32(40, pcm.length, Endian.little);
    bytes.setRange(44, bytes.length, pcm);
    return bytes;
  }
}
