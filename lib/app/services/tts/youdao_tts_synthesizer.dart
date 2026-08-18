import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../models/domain/app_settings_state.dart';
import 'tts_synthesizer.dart';

/// 有道智云在线语音合成的稳定凭据。
final class YoudaoTtsCredentials {
  const YoudaoTtsCredentials({required this.appKey, required this.appSecret});

  final String appKey;
  final String appSecret;
}

/// 使用有道智云「在线语音合成」HTTP 接口合成单词发音。
///
/// 返回 MP3。有道在线合成仅提供美式音色（`female`/`male`）；
/// 英式请求抛出异常，由上层报告当前第三方服务不可用。
final class YoudaoTtsSynthesizer implements TtsSynthesizerPort {
  YoudaoTtsSynthesizer({
    required this.credentials,
    required this.voice,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client() {
    if (credentials.appKey.trim().isEmpty ||
        credentials.appSecret.trim().isEmpty) {
      throw ArgumentError('有道 TTS 凭据不完整');
    }
  }

  static const String endpoint = 'https://openapi.youdao.com/ttsapi';
  static const String langType = 'en';

  final YoudaoTtsCredentials credentials;
  final String voice;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<TtsAudio> synthesize(
    String text, {
    required PronunciationAccent accent,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty || normalized.length > 1000) {
      throw const TtsSynthesisException('invalid_text', '待合成文本长度无效');
    }
    if (accent == PronunciationAccent.uk) {
      throw const TtsSynthesisException(
        'unsupported_accent',
        '有道 TTS 仅支持美式发音',
      );
    }

    final salt = _randomSalt();
    final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final input = normalized.length <= 20
        ? normalized
        : '${normalized.substring(0, 10)}'
              '${normalized.length}'
              '${normalized.substring(normalized.length - 10)}';
    final sign = _sign(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      input: input,
      salt: salt,
      curtime: curtime,
    );

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'q': normalized,
              'langType': langType,
              'voice': voice,
              'format': 'mp3',
              'appKey': credentials.appKey,
              'salt': salt,
              'curtime': curtime,
              'sign': sign,
              'signType': 'v3',
            },
          )
          .timeout(timeout);
    } on Object {
      throw const TtsSynthesisException('network_error', '有道 TTS 网络请求失败');
    }

    if (response.statusCode == 200 && _isAudio(response)) {
      return TtsAudio(bytes: response.bodyBytes, mimeType: 'audio/mpeg');
    }
    final errorCode = _parseErrorCode(response);
    throw TtsSynthesisException(
      'youdao_${errorCode ?? response.statusCode}',
      '有道 TTS 失败（${errorCode ?? 'HTTP ${response.statusCode}'}）',
    );
  }

  bool _isAudio(http.Response response) {
    final contentType =
        response.headers['content-type'] ?? ''.toLowerCase();
    return contentType.contains('audio') || contentType.contains('mpeg');
  }

  String? _parseErrorCode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) {
        final code = decoded['errorCode'];
        if (code != null) {
          return code.toString();
        }
      }
    } on FormatException {
      // 响应不是 JSON，可能是意外音频，交给错误码兜底。
    }
    return null;
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
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
