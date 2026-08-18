import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../models/domain/app_settings_state.dart';
import 'tts_synthesizer.dart';

/// 科大讯飞在线语音合成的稳定凭据。
final class XfyunTtsCredentials {
  const XfyunTtsCredentials({
    required this.appId,
    required this.apiKey,
    required this.apiSecret,
  });

  final String appId;
  final String apiKey;
  final String apiSecret;
}

/// 使用讯飞开放平台「在线语音合成」WebSocket 接口合成单词发音。
///
/// 返回 MP3（`aue=lame`），由调用方交给播放器播放。
final class XfyunTtsSynthesizer implements TtsSynthesizerPort {
  XfyunTtsSynthesizer({
    required this.credentials,
    required this.voice,
    this.supportedAccent = PronunciationAccent.us,
    this.speed = 50,
    this.volume = 50,
    this.pitch = 50,
    this.timeout = const Duration(seconds: 15),
  }) {
    if (credentials.appId.trim().isEmpty ||
        credentials.apiKey.trim().isEmpty ||
        credentials.apiSecret.trim().isEmpty) {
      throw ArgumentError('讯飞 TTS 凭据不完整');
    }
    if (voice.trim().isEmpty) {
      throw ArgumentError('讯飞 TTS 发音人不能为空');
    }
  }

  static const String host = 'tts-api.xfyun.cn';
  static const String path = '/v2/tts';

  final XfyunTtsCredentials credentials;
  final String voice;

  /// 当前 `vcn` 发音人实际支持的口音；讯飞 TTS 不提供请求级口音切换。
  final PronunciationAccent supportedAccent;
  final int speed;
  final int volume;
  final int pitch;
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
    if (accent != supportedAccent) {
      throw const TtsSynthesisException(
        'unsupported_accent',
        '当前讯飞发音人不支持所请求的口音',
      );
    }

    final url = _buildWebSocketUrl();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(url).timeout(timeout);
      final bytes = await _runSession(socket, normalized).timeout(timeout);
      if (bytes.isEmpty) {
        throw const TtsSynthesisException('empty_audio', '讯飞 TTS 返回空音频');
      }
      return TtsAudio(bytes: bytes, mimeType: 'audio/mpeg');
    } on Object catch (error) {
      throw _toException(error);
    } finally {
      try {
        await socket?.close();
      } on Object {
        // 连接已失败时忽略关闭错误。
      }
    }
  }

  Future<Uint8List> _runSession(WebSocket socket, String text) {
    final completer = Completer<Uint8List>();
    final chunks = <Uint8List>[];
    late final StreamSubscription<dynamic> subscription;
    subscription = socket.listen(
      (message) {
        try {
          final error = _readErrorCode(message);
          if (error != null) {
            throw TtsSynthesisException('xfyun_$error', '讯飞 TTS 失败（$error）');
          }
          final chunk = _parseAudioChunk(message);
          if (chunk != null && chunk.isNotEmpty) {
            chunks.add(chunk);
          }
          if (_isLastFrame(message)) {
            if (!completer.isCompleted) {
              completer.complete(_concat(chunks));
            }
          }
        } on TtsSynthesisException catch (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const TtsSynthesisException('connection_closed', '讯飞 TTS 服务提前断开'),
          );
        }
      },
      cancelOnError: true,
    );

    // 首帧：common + business + 待合成文本（单词文本一次发送，status=2 表示结束）。
    socket.add(
      jsonEncode({
        'common': {'app_id': credentials.appId},
        'business': {
          'aue': 'lame',
          'sfl': 1,
          'auf': 'audio/L16;rate=16000',
          'vcn': voice,
          'speed': speed,
          'volume': volume,
          'pitch': pitch,
          'tte': 'UTF8',
          'bgs': 0,
        },
        'data': {'status': 2, 'text': base64Encode(utf8.encode(text))},
      }),
    );

    return completer.future.whenComplete(() => subscription.cancel());
  }

  int? _readErrorCode(Object? message) {
    final map = _asMap(message);
    if (map == null) {
      return null;
    }
    final code = map['code'];
    if (code is int && code != 0) {
      return code;
    }
    return null;
  }

  bool _isLastFrame(Object? message) {
    final map = _asMap(message);
    final data = map?['data'];
    if (data is Map<String, Object?>) {
      return data['status'] == 2;
    }
    return false;
  }

  Uint8List? _parseAudioChunk(Object? message) {
    final map = _asMap(message);
    final data = map?['data'];
    if (data is Map<String, Object?>) {
      final audio = data['audio'];
      if (audio is String && audio.isNotEmpty) {
        return base64Decode(audio);
      }
    }
    return null;
  }

  Map<String, Object?>? _asMap(Object? message) {
    if (message is! String) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return null;
    }
    return decoded is Map<String, Object?> ? decoded : null;
  }

  Uint8List _concat(List<Uint8List> chunks) {
    final total = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final bytes = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  String _buildWebSocketUrl() {
    final date = _httpDate(DateTime.now().toUtc());
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';
    final signature = base64Encode(
      Hmac(
        sha256,
        utf8.encode(credentials.apiSecret),
      ).convert(utf8.encode(signatureOrigin)).bytes,
    );
    final authorizationOrigin =
        'api_key="${credentials.apiKey}", algorithm="hmac-sha256", '
        'headers="host date request-line", signature="$signature"';
    final authorization = base64Encode(utf8.encode(authorizationOrigin));
    return 'wss://$host$path'
        '?authorization=${Uri.encodeComponent(authorization)}'
        '&date=${Uri.encodeComponent(date)}'
        '&host=$host';
  }

  String _httpDate(DateTime time) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[time.weekday - 1];
    final month = months[time.month - 1];
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$weekday, $day $month ${time.year} $hour:$minute:$second GMT';
  }

  TtsSynthesisException _toException(Object error) {
    if (error is TtsSynthesisException) {
      return error;
    }
    if (error is TimeoutException) {
      return const TtsSynthesisException('timeout', '讯飞 TTS 超时');
    }
    return const TtsSynthesisException('network_error', '讯飞 TTS 网络请求失败');
  }
}
