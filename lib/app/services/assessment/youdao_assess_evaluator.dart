import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../models/domain/pronunciation_score.dart';
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
/// 有道文档页为动态渲染，接口路径与返回字段以官方文档为准；
/// 本实现按公开约定编码，并对返回字段做容错读取。
final class YoudaoAssessEvaluator implements PronunciationEvaluatorPort {
  YoudaoAssessEvaluator({
    required this.credentials,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client() {
    if (credentials.appKey.trim().isEmpty ||
        credentials.appSecret.trim().isEmpty) {
      throw ArgumentError('有道评测凭据不完整');
    }
  }

  // 待核对：以官方「实时语音评测」文档「接口地址」节为准。
  static const String endpoint = 'https://openapi.youdao.com/v2/asr_sentence';
  static const int sampleRate = 16000;

  final YoudaoAssessCredentials credentials;
  final http.Client _client;
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

    final salt = _randomSalt();
    final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final input = normalizedText.length <= 20
        ? normalizedText
        : '${normalizedText.substring(0, 10)}'
              '${normalizedText.length}'
              '${normalizedText.substring(normalizedText.length - 10)}';
    final sign = _sign(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      input: input,
      salt: salt,
      curtime: curtime,
    );

    final Uri uri = Uri.parse(endpoint);
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'q': normalizedText,
              'data': base64Encode(_toWav(request.pcmBytes)),
              'rate': '$sampleRate',
              'format': 'wav',
              'appKey': credentials.appKey,
              'salt': salt,
              'curtime': curtime,
              'sign': sign,
              'signType': 'v3',
            },
          )
          .timeout(timeout);
    } on Object {
      throw const PronunciationEvaluationException(
        'network_error',
        '有道评测网络请求失败',
      );
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
    if (errorCode != null && errorCode != '0') {
      throw PronunciationEvaluationException(
        'youdao_$errorCode',
        '有道评测失败（$errorCode）',
      );
    }
    final result = decoded['result'];
    if (result is! Map<String, Object?>) {
      throw const PronunciationEvaluationException(
        'malformed_result',
        '有道评测返回缺少 result',
      );
    }
    return PronunciationScore(
      totalScore: _readScore(result, const [
        'score',
        'totalScore',
        'total_score',
      ]),
      accuracyScore: _readScore(result, const [
        'accuracyScore',
        'accuracy',
        'accuracy_score',
      ]),
      fluencyScore: _readScore(result, const [
        'fluencyScore',
        'fluency',
        'fluency_score',
      ]),
      integrityScore: _readScore(result, const [
        'integrityScore',
        'integrity',
        'integrity_score',
      ]),
    );
  }

  double _readScore(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toDouble().clamp(0, 100);
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed.clamp(0, 100);
        }
      }
    }
    throw const PronunciationEvaluationException(
      'malformed_result',
      '有道评测返回缺少评分字段',
    );
  }

  String _sign({
    required String appKey,
    required String appSecret,
    required String input,
    required String salt,
    required String curtime,
  }) {
    final signStr = '$appKey$input$salt$curtime$appSecret';
    return sha256.convert(utf8.encode(signStr)).toString();
  }

  String _randomSalt() {
    final random = Uint8List(8);
    for (var index = 0; index < random.length; index++) {
      random[index] =
          (DateTime.now().microsecondsSinceEpoch >> (index * 4)) & 0xFF;
    }
    return base64UrlEncode(random).replaceAll('=', '');
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
