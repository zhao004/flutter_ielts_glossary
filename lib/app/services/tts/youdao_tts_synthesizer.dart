import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/domain/app_settings_state.dart';
import '../youdao/youdao_api_signer.dart';
import 'tts_synthesizer.dart';

/// 有道智云在线语音合成的稳定凭据。
final class YoudaoTtsCredentials {
  const YoudaoTtsCredentials({required this.appKey, required this.appSecret});

  final String appKey;
  final String appSecret;
}

/// 使用有道智云「在线语音合成」HTTP 接口合成单词发音。
///
/// 返回 MP3，并依据用户选择的口音使用独立的官方 `voiceName`。
/// 默认复用应用级 HTTP Client；显式注入的 Client 仍由调用方负责关闭。
final class YoudaoTtsSynthesizer implements TtsSynthesizerPort {
  YoudaoTtsSynthesizer({
    required this.credentials,
    required this.usVoiceName,
    required this.ukVoiceName,
    this.speed = 50,
    this.volume = 50,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? _applicationClient() {
    if (credentials.appKey.trim().isEmpty ||
        credentials.appSecret.trim().isEmpty) {
      throw ArgumentError('有道 TTS 凭据不完整');
    }
    if (usVoiceName.trim().isEmpty || ukVoiceName.trim().isEmpty) {
      throw ArgumentError('有道 TTS 发音人不能为空');
    }
    if (speed < 0 || speed > 100 || volume < 0 || volume > 100) {
      throw RangeError('有道 TTS 语速和音量必须在 0-100 之间');
    }
  }

  static const String endpoint = 'https://openapi.youdao.com/ttsapi';
  static const int maxTextUtf8Bytes = 2048;
  static http.Client? _sharedClient;

  final YoudaoTtsCredentials credentials;
  final String usVoiceName;
  final String ukVoiceName;
  final int speed;
  final int volume;
  final http.Client _client;
  final Duration timeout;

  /// 应用退出或语音服务生命周期结束时释放共享连接池。
  static Future<void> closeSharedClient() async {
    final client = _sharedClient;
    _sharedClient = null;
    client?.close();
  }

  static http.Client _applicationClient() {
    return _sharedClient ??= http.Client();
  }

  @override
  Future<TtsAudio> synthesize(
    String text, {
    required PronunciationAccent accent,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty ||
        utf8.encode(normalized).length > maxTextUtf8Bytes) {
      throw const TtsSynthesisException('invalid_text', '待合成文本长度无效');
    }

    final salt = YoudaoApiSigner.createSalt();
    final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = YoudaoApiSigner.sign(
      appKey: credentials.appKey,
      appSecret: credentials.appSecret,
      query: normalized,
      salt: salt,
      curtime: curtime,
    );
    final voiceName = switch (accent) {
      PronunciationAccent.us => usVoiceName.trim(),
      PronunciationAccent.uk => ukVoiceName.trim(),
    };

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
              'appKey': credentials.appKey,
              'salt': salt,
              'curtime': curtime,
              'sign': sign,
              'signType': 'v3',
              'format': 'mp3',
              'speed': _formatSpeed(speed),
              'volume': _formatVolume(volume),
              'voiceName': voiceName,
            },
          )
          .timeout(timeout);
    } on Object {
      throw const TtsSynthesisException('network_error', '有道 TTS 网络请求失败');
    }

    if (response.statusCode == 200 && _isAudio(response)) {
      if (response.bodyBytes.isEmpty) {
        throw const TtsSynthesisException('malformed_result', '有道 TTS 返回空音频');
      }
      return TtsAudio(bytes: response.bodyBytes, mimeType: 'audio/mpeg');
    }
    final errorCode = _parseErrorCode(response);
    throw TtsSynthesisException(
      'youdao_${errorCode ?? response.statusCode}',
      '有道 TTS 失败（${errorCode ?? 'HTTP ${response.statusCode}'}）',
    );
  }

  bool _isAudio(http.Response response) {
    final contentType = response.headers['content-type'] ?? ''.toLowerCase();
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

  /// 保持应用滑块中点 50 对应有道服务默认值 1.00。
  String _formatSpeed(int value) {
    final normalized = value <= 50 ? 0.5 + value / 100 : 1 + (value - 50) / 50;
    return normalized.toStringAsFixed(2);
  }

  /// 将应用 0-100 音量滑块映射到有道要求的 0.50-5.00 范围。
  String _formatVolume(int value) {
    final normalized = value <= 50
        ? 0.5 + value / 100
        : 1 + (value - 50) * 4 / 50;
    return normalized.toStringAsFixed(2);
  }
}
